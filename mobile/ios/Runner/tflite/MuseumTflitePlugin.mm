#import "MuseumTflitePlugin.h"

#include <pthread.h>
#include <unistd.h>
#include <fstream>
#include <iostream>
#include <queue>
#include <sstream>
#include <string>
#include <numeric>

#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"
#include "tensorflow/contrib/lite/string_util.h"
#include "tensorflow/contrib/lite/op_resolver.h"

#include "ios_image_load.h"
#include <UIKit/UIKit.h>

#define LOG(x) std::cerr

NSString* loadModel(NSObject<FlutterPluginRegistrar>* _registrar, NSDictionary* args);
NSData* runModelOnImage(NSDictionary* args);
//NSMutableArray* runModelOnBinary(NSDictionary* args);
void close();

@implementation MuseumTflitePlugin {
    NSObject<FlutterPluginRegistrar>* _registrar;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"net.pangolinai.mobile/museum_tflite"
                                     binaryMessenger:[registrar messenger]];
    MuseumTflitePlugin* instance = [[MuseumTflitePlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"loadModel" isEqualToString:call.method]) {
        NSString* load_result = loadModel(_registrar, call.arguments);
        result(load_result);
    } else if ([@"runModelOnImage" isEqualToString:call.method]) {
        NSData* inference_result = runModelOnImage(call.arguments);
        result(inference_result);
    }
    //  else if ([@"runModelOnBinary" isEqualToString:call.method]) {
    //    NSMutableArray* inference_result = runModelOnBinary(call.arguments);
    //    result(inference_result);
    //  }
    else if ([@"close" isEqualToString:call.method]) {
        close();
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end

//std::vector<std::string> labels;
std::unique_ptr<tflite::FlatBufferModel> model;
std::unique_ptr<tflite::Interpreter> interpreter;

class FeatureEntry {
public:
    int artId;
    double features[512];
    double featureNorm;
};

class ScoreEntry {
public:
    double score;
    int index;
    
    ScoreEntry(double score, int index) {
        this->score = score;
        this->index = index;
    }
};

std::vector<FeatureEntry> predFeatures;

template<class T>
double norm(T *data, int count) {
    if (count == 0) return 0;
    double sum = std::accumulate(data, data + count, 0);
    double avg = sum / count;
    sum = 0;
    for (int i = 0; i < count; i++) {
        sum += (data[i] - avg) * (data[i] - avg);
    }
    return sqrt(sum);
}


NSString* loadModel(NSObject<FlutterPluginRegistrar>* _registrar, NSDictionary* args) {
    //NSString* key = [_registrar lookupKeyForAsset:args[@"model"]];
    //NSString* graph_path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    NSString *graph_path = args[@"model"];
    model = tflite::FlatBufferModel::BuildFromFile([graph_path UTF8String]);
    if (!model) {
        return [NSString stringWithFormat:@"%s %@", "Failed to mmap model", graph_path];
    }
    LOG(INFO) << "Loaded model " << graph_path;
    model->error_reporter();
    LOG(INFO) << "resolved reporter";
    
    //key = [_registrar lookupKeyForAsset:args[@"labels"]];
    //NSString* labels_path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    //LoadLabels(labels_path, &labels);
    
    tflite::ops::builtin::BuiltinOpResolver resolver;
    tflite::InterpreterBuilder(*model, resolver)(&interpreter);
    if (!interpreter) {
        return @"Failed to construct interpreter";
    }
    
    //读取离线feature索引文件
    if ([args objectForKey:@"index"]) {
        NSString *index_path = args[@"index"];
        
        FILE* file_handle = fopen([index_path UTF8String], "rb");
        fseek(file_handle, 0, SEEK_END);
        const size_t bytes_in_file = ftell(file_handle);
        if ((bytes_in_file - 4) % (513*4) != 0) {
            fclose(file_handle);
            return @"Invalid index dat file";
        }
        fseek(file_handle, 0, SEEK_SET);
        //read dimention
        char buf[4];
        fread(buf, 4, 1,  file_handle);
        int dimention = *((float *)buf);
        if (dimention != 512) {
            fclose(file_handle);
            return @"Invalid index dat dimention";
        }
        
        unsigned long entryCount = (bytes_in_file - 4) / (513*4);
        for (int i = 0; i < entryCount; i++) {
            predFeatures.push_back(FeatureEntry());
            FeatureEntry &entry = predFeatures.back();
            fread(buf, 4, 1, file_handle);
            entry.artId = *((float *)buf);
            for (int j = 0; j < dimention; j++) {
                fread(buf, 4, 1, file_handle);
                entry.features[j] = *((float *)buf);
            }
            //fread(entry.features, 512*4, 1, file_handle);
            entry.featureNorm = norm(entry.features, dimention);
        }
        fclose(file_handle);
        NSLog(@"read index dat ok");
    }
    
    return @"success";
}


NSData * runModelOnImage(NSDictionary* args) {
    const int num_threads = [args[@"numThreads"] intValue];
    const int wanted_width = [args[@"inputSize"] intValue];
    const int wanted_height = [args[@"inputSize"] intValue];
    const int wanted_channels = [args[@"numChannels"] intValue];
    const float input_mean = [args[@"imageMean"] floatValue];
    const float input_std = [args[@"imageStd"] floatValue];
    double threshold = [args[@"threshold"] floatValue];
    int k = [args[@"k"] intValue];
    
    std::vector<std::vector<uint8_t>> image_data;
    if (args[@"path"]) {
        const NSString* image_path = args[@"path"];
        image_data = LoadImageFromFile2([image_path UTF8String], wanted_width, 3);
    } else if (args[@"bytesList"]) {
        const FlutterStandardTypedData* typedData = args[@"bytesList"][0];
        const int image_height = [args[@"imageHeight"] intValue];
        const int image_width = [args[@"imageWidth"] intValue];
        const int orientation = [args[@"orientation"] intValue];
        uint8_t* in = (uint8_t*)[[typedData data] bytes];
        
        image_data = LoadImageFromData(in, orientation, image_width, image_height, 4, wanted_width, 3);
    }
    
    if (!interpreter) {
        NSLog(@"Failed to construct interpreter.");
        return nullptr;
    }
    
    if (num_threads != -1) {
        interpreter->SetNumThreads(num_threads);
    }
    
    float weights[3] = {0.3, 0.4, 0.3};
    const int CLASS_NUMS = 512;
    float composed_feature[CLASS_NUMS];
    memset(composed_feature, 0, CLASS_NUMS*sizeof(float));
    
    int input = interpreter->inputs()[0];
    if (interpreter->AllocateTensors() != kTfLiteOk) {
        NSLog(@"Failed to allocate tensors.");
        return nullptr;
    }
    float *input_tensor = interpreter->typed_tensor<float>(input);
    for (int i = 0; i < 3; i++) {
        //fill the input tensor
        for (int k = 0; k < wanted_width*wanted_width*wanted_channels; k+=3) {
            input_tensor[k] = image_data[i][k];//(image_data[i][k] - input_mean)/input_std; //R
            input_tensor[k+1] = image_data[i][k+1];// - input_mean)/input_std; //G
            input_tensor[k+2] = image_data[i][k+2];//- input_mean)/input_std; //B
        }
        
        if (interpreter->Invoke() != kTfLiteOk) {
            NSLog(@"Failed to invoke!");
            return nullptr;
        }
        
        float* output = interpreter->typed_output_tensor<float>(0);
        for (int j = 0; j < CLASS_NUMS; j++) {
            composed_feature[j] += output[j] * weights[i];
        }
    }
    
    
    if (predFeatures.size() > 0) {
        std::vector<ScoreEntry> topK(k, ScoreEntry(0,0));
        
        double featureNorm = norm<float>(composed_feature, CLASS_NUMS);
        for (int i = 0; i < predFeatures.size(); i++) {
            FeatureEntry &item = predFeatures[i];
            double score = 0;
            for (int j = 0; j < CLASS_NUMS; j++) {
                score += composed_feature[j] * item.features[j];
            }
            score = score / (featureNorm * item.featureNorm);
            //            if (i == 2117) {
            //                Log.e(TAG, String.format("index:%d, score:%f", i, score));
            //            }
            
            for (int j = k - 1; j >= 0; j--) {
                if (j == 0 && score > topK[0].score) {
                    for (int n = k-1; n>0; n--) {
                        topK[n] = topK[n-1];
                    }
                    topK[0] = ScoreEntry(score, item.artId);
                } else if (j > 0 && score > topK[j].score && score < topK[j-1].score) {
                    for (int n = k - 1; n > j; n--) {
                        topK[n] = topK[n - 1];
                    }
                    topK[j] = ScoreEntry(score, item.artId);
                    break;
                }
            }
        }
        
        auto ri = std::remove_if(topK.begin(), topK.end(), [&](ScoreEntry entry) {return entry.score<threshold;});
        if (ri != topK.end()) {
            topK.erase(ri, topK.end());
        }
        std::vector<float> result(1 + topK.size() * 2);
        result[0] = topK.size();
        for (int i = 0; i < topK.size(); i++) {
            result[1 + i*2] = topK[i].index;
            result[1 + i*2 + 1] = topK[i].score;
        }
        return [NSData dataWithBytes:result.data() length:(1 + topK.size() * 2) * sizeof(float)];
    } else {
        float result[1 + CLASS_NUMS];
        result[0] = -1.0f;
        memcpy(result+1, composed_feature, CLASS_NUMS*sizeof(float));
        return [NSData dataWithBytes:result length:(1+CLASS_NUMS) * sizeof(float)];
    }
}


void close() {
    interpreter = NULL;
    model = NULL;
}


