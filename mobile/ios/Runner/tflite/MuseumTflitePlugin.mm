#import "MuseumTflitePlugin.h"

#include <pthread.h>
#include <unistd.h>
#include <fstream>
#include <iostream>
#include <queue>
#include <sstream>
#include <string>

#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"
#include "tensorflow/contrib/lite/string_util.h"
#include "tensorflow/contrib/lite/op_resolver.h"

#include "ios_image_load.h"

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
  if (interpreter->AllocateTensors() != kTfLiteOk) {
    return @"Failed to allocate tensors!";
  }
  
  return @"success";
}

//NSMutableArray* GetTopN(const float* prediction, const unsigned long prediction_size, const int num_results,
//                    const float threshold) {
//  std::priority_queue<std::pair<float, int>, std::vector<std::pair<float, int>>,
//  std::greater<std::pair<float, int> > >
//  top_result_pq;
//
//  std::vector<std::pair<float, int>> top_results;
//
//  const long count = prediction_size;
//  for (int i = 0; i < count; ++i) {
//    const float value = prediction[i];
//
//    if (value < threshold) {
//      continue;
//    }
//
//    top_result_pq.push(std::pair<float, int>(value, i));
//
//    if (top_result_pq.size() > num_results) {
//      top_result_pq.pop();
//    }
//  }
//
//  while (!top_result_pq.empty()) {
//    top_results.push_back(top_result_pq.top());
//    top_result_pq.pop();
//  }
//  std::reverse(top_results.begin(), top_results.end());
//
//  NSMutableArray* predictions = [NSMutableArray array];
//  for (const auto& result : top_results) {
//    const float confidence = result.first;
//    const int index = result.second;
//    NSString* labelObject = [NSString stringWithUTF8String:labels[index].c_str()];
//    NSNumber* valueObject = [NSNumber numberWithFloat:confidence];
//    NSMutableDictionary* res = [NSMutableDictionary dictionary];
//    [res setValue:[NSNumber numberWithInt:index] forKey:@"index"];
//    [res setObject:labelObject forKey:@"label"];
//    [res setObject:valueObject forKey:@"confidence"];
//    [predictions addObject:res];
//  }
//
//  return predictions;
//}

NSData * runModelOnImage_(NSDictionary* args) {
  const NSString* image_path = args[@"path"];
  const int num_threads = [args[@"numThreads"] intValue];
  const int wanted_width = [args[@"inputSize"] intValue];
  const int wanted_height = [args[@"inputSize"] intValue];
  const int wanted_channels = [args[@"numChannels"] intValue];
  const float input_mean = [args[@"imageMean"] floatValue];
  const float input_std = [args[@"imageStd"] floatValue];

  //NSMutableArray* empty = [@[] mutableCopy];

  if (!interpreter) {
    NSLog(@"Failed to construct interpreter.");
    return nullptr;
  }

  if (num_threads != -1) {
    interpreter->SetNumThreads(num_threads);
  }

  int input = interpreter->inputs()[0];

  if (interpreter->AllocateTensors() != kTfLiteOk) {
    NSLog(@"Failed to allocate tensors.");
    return nullptr;
  }

  int image_width;
  int image_height;
  int image_channels;
  std::vector<uint8_t> image_data = LoadImageFromFile([image_path UTF8String], &image_width, &image_height, &image_channels);

  assert(image_channels >= wanted_channels);
  uint8_t* in = image_data.data();
  float* out = interpreter->typed_tensor<float>(input);
  for (int y = 0; y < wanted_height; ++y) {
    const int in_y = (y * image_height) / wanted_height;
    uint8_t* in_row = in + (in_y * image_width * image_channels);
    float* out_row = out + (y * wanted_width * wanted_channels);
    for (int x = 0; x < wanted_width; ++x) {
      const int in_x = (x * image_width) / wanted_width;
      uint8_t* in_pixel = in_row + (in_x * image_channels);
      float* out_pixel = out_row + (x * wanted_channels);
      for (int c = 0; c < wanted_channels; ++c) {
        out_pixel[c] = (in_pixel[c] - input_mean) / input_std;
      }
    }
  }

  if (interpreter->Invoke() != kTfLiteOk) {
    NSLog(@"Failed to invoke!");
    return nullptr;
  }

  float* output = interpreter->typed_output_tensor<float>(0);
  return [NSData dataWithBytes:output length:1280 * 4];

//  if (output == NULL)
//    return nullptr;
//
//  const unsigned long output_size = labels.size();
//  const int kNumResults = [args[@"numResults"] intValue];
//  const float kThreshold = [args[@"threshold"] floatValue];
//  return GetTopN(output, output_size, kNumResults, kThreshold);
}


NSData * runModelOnImage(NSDictionary* args) {
    const NSString* image_path = args[@"path"];
    const int num_threads = [args[@"numThreads"] intValue];
    const int wanted_width = [args[@"inputSize"] intValue];
    const int wanted_height = [args[@"inputSize"] intValue];
    const int wanted_channels = [args[@"numChannels"] intValue];
    const float input_mean = [args[@"imageMean"] floatValue];
    const float input_std = [args[@"imageStd"] floatValue];
    
    //NSMutableArray* empty = [@[] mutableCopy];
    
    if (!interpreter) {
        NSLog(@"Failed to construct interpreter.");
        return nullptr;
    }
    
    if (num_threads != -1) {
        interpreter->SetNumThreads(num_threads);
    }
    
    int input = interpreter->inputs()[0];
    
    if (interpreter->AllocateTensors() != kTfLiteOk) {
        NSLog(@"Failed to allocate tensors.");
        return nullptr;
    }
    
    std::vector<std::vector<uint8_t>> image_data = LoadImageFromFile2([image_path UTF8String], wanted_width, 3);
    float weights[3] = {0.3, 0.4, 0.3};
    
    const int feature_len = wanted_width * wanted_width * 3;
    float composed_feature[1280];
    memset(composed_feature, 0, 1280*4);
    float *input_tensor = interpreter->typed_tensor<float>(input);
    for (int i = 0; i < 3; i++) {
        //fill the input tensor
        for (int k = 0; k < 224*224; k+=3) {
            input_tensor[k] = image_data[i][k]; //R
            input_tensor[k+1] = image_data[i][k+1]; //G
            input_tensor[k+2] = image_data[i][k+2]; //B
        }
        
        if (interpreter->Invoke() != kTfLiteOk) {
            NSLog(@"Failed to invoke!");
            return nullptr;
        }
        
        float* output = interpreter->typed_output_tensor<float>(0);
        for (int j = 0; j < 1280; j++) {
            composed_feature[j] += output[j] * weights[i];
        }
    }
    return [NSData dataWithBytes:composed_feature length:1280 * 4];
    
    //  if (output == NULL)
    //    return nullptr;
    //
    //  const unsigned long output_size = labels.size();
    //  const int kNumResults = [args[@"numResults"] intValue];
    //  const float kThreshold = [args[@"threshold"] floatValue];
    //  return GetTopN(output, output_size, kNumResults, kThreshold);
}

//NSMutableArray* runModelOnBinary(NSDictionary* args) {
//  FlutterStandardTypedData* typedData = args[@"binary"];
//  const int num_threads = [args[@"numThreads"] intValue];
//  NSMutableArray* empty = [@[] mutableCopy];
//
//  if (!interpreter) {
//    NSLog(@"Failed to construct interpreter.");
//    return empty;
//  }
//
//  if (num_threads != -1) {
//    interpreter->SetNumThreads(num_threads);
//  }
//
//  int input = interpreter->inputs()[0];
//
//  if (interpreter->AllocateTensors() != kTfLiteOk) {
//    NSLog(@"Failed to allocate tensors.");
//    return empty;
//  }
//
//  float* out = interpreter->typed_tensor<float>(input);
//  NSData* in = [typedData data];
//  const float* bytes = (const float*)[in bytes];
//  for (int index = 0; index < [in length]/4; index++)
//    out[index] = bytes[index];
//
//  if (interpreter->Invoke() != kTfLiteOk) {
//    NSLog(@"Failed to invoke!");
//    return empty;
//  }
//
//  float* output = interpreter->typed_output_tensor<float>(0);
//
//  if (output == NULL)
//    return empty;
//
//  const unsigned long output_size = labels.size();
//  const int kNumResults = [args[@"numResults"] intValue];
//  const float kThreshold = [args[@"threshold"] floatValue];
//  return GetTopN(output, output_size, kNumResults, kThreshold);
//}

void close() {
  interpreter = NULL;
  model = NULL;
  //labels.clear();
}
