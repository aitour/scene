#include "ios_image_load.h"

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

std::vector<uint8_t> LoadImageFromFile(const char* file_name,
                                     int* out_width, int* out_height,
                                     int* out_channels) {
  FILE* file_handle = fopen(file_name, "rb");
  fseek(file_handle, 0, SEEK_END);
  const size_t bytes_in_file = ftell(file_handle);
  fseek(file_handle, 0, SEEK_SET);
  std::vector<uint8_t> file_data(bytes_in_file);
  fread(file_data.data(), 1, bytes_in_file, file_handle);
  fclose(file_handle);

  CFDataRef file_data_ref = CFDataCreateWithBytesNoCopy(NULL, file_data.data(),
                                                        bytes_in_file,
                                                        kCFAllocatorNull);
  CGDataProviderRef image_provider = CGDataProviderCreateWithCFData(file_data_ref);
  
  const char* suffix = strrchr(file_name, '.');
  if (!suffix || suffix == file_name) {
    suffix = "";
  }
  CGImageRef image;
  if (strcasecmp(suffix, ".png") == 0) {
    image = CGImageCreateWithPNGDataProvider(image_provider, NULL, true,
                                             kCGRenderingIntentDefault);
  } else if ((strcasecmp(suffix, ".jpg") == 0) ||
             (strcasecmp(suffix, ".jpeg") == 0)) {
    image = CGImageCreateWithJPEGDataProvider(image_provider, NULL, true,
                                              kCGRenderingIntentDefault);
  } else {
    CFRelease(image_provider);
    CFRelease(file_data_ref);
    fprintf(stderr, "Unknown suffix for file '%s'\n", file_name);
    out_width = 0;
    out_height = 0;
    *out_channels = 0;
    return std::vector<uint8_t>();
  }
  
  int width = (int)CGImageGetWidth(image);
  int height = (int)CGImageGetHeight(image);
  const int channels = 4;
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  const int bytes_per_row = (width * channels);
  const int bytes_in_image = (bytes_per_row * height);
  std::vector<uint8_t> result(bytes_in_image);
  const int bits_per_component = 8;

  CGContextRef context = CGBitmapContextCreate(result.data(), width, height,
                                               bits_per_component, bytes_per_row, color_space,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(color_space);
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  CGContextRelease(context);
  CFRelease(image);
  CFRelease(image_provider);
  CFRelease(file_data_ref);
  
  *out_width = width;
  *out_height = height;
  *out_channels = channels;
  return result;
}


std::vector<std::vector<uint8_t>> LoadImageFromFile2(const char* file_name, int scale_side_len, int corps) {
    FILE* file_handle = fopen(file_name, "rb");
    fseek(file_handle, 0, SEEK_END);
    const size_t bytes_in_file = ftell(file_handle);
    fseek(file_handle, 0, SEEK_SET);
    std::vector<uint8_t> file_data(bytes_in_file);
    fread(file_data.data(), 1, bytes_in_file, file_handle);
    fclose(file_handle);
    
    CFDataRef file_data_ref = CFDataCreateWithBytesNoCopy(NULL, file_data.data(),
                                                          bytes_in_file,
                                                          kCFAllocatorNull);
    CGDataProviderRef image_provider = CGDataProviderCreateWithCFData(file_data_ref);
    
    const char* suffix = strrchr(file_name, '.');
    if (!suffix || suffix == file_name) {
        suffix = "";
    }
    CGImageRef image;
    if (strcasecmp(suffix, ".png") == 0) {
        image = CGImageCreateWithPNGDataProvider(image_provider, NULL, true,
                                                 kCGRenderingIntentDefault);
    } else if ((strcasecmp(suffix, ".jpg") == 0) ||
               (strcasecmp(suffix, ".jpeg") == 0)) {
        image = CGImageCreateWithJPEGDataProvider(image_provider, NULL, true,
                                                  kCGRenderingIntentDefault);
    } else {
        CFRelease(image_provider);
        CFRelease(file_data_ref);
        fprintf(stderr, "Unknown suffix for file '%s'\n", file_name);
        return std::vector<std::vector<uint8_t>>();
    }
    
    
    
    int width = (int)CGImageGetWidth(image);
    int height = (int)CGImageGetHeight(image);
    float scale = float(scale_side_len) / std::min(width, height);
    int new_width = width * scale;
    int new_height = height * scale;
    
    const int channels = 4;
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    const int bytes_per_row = (new_width * channels);
    const int bytes_in_image = (bytes_per_row * new_height);
    std::vector<uint8_t> scaled_image(bytes_in_image);
    const int bits_per_component = 8;
    
    CGContextRef context = CGBitmapContextCreate(scaled_image.data(), new_width, new_height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    CGContextDrawImage(context, CGRectMake(0,0,new_width, new_height), image);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    char saveFile[256];
    int n = sprintf(saveFile, "%s", file_name);
    strcpy(saveFile+n, ".scale");
    //UIImage *img = [UIImage imageWithCGImage:imgRef];
    [UIImagePNGRepresentation([UIImage imageWithCGImage:imgRef]) writeToFile:[NSString stringWithUTF8String:saveFile] atomically:YES];
    
    CGContextRelease(context);
    CFRelease(image);
    CFRelease(image_provider);
    CFRelease(file_data_ref);
    CFRelease(imgRef);
    
    std::vector<std::vector<uint8_t>> result;
    
    uint8_t *in = scaled_image.data();
    for (int i = 0; i < corps; i++) {
        std::vector<uint8_t> corp_img;
        int offset_x = 0, offset_y = 0;
        if (new_width > new_height) {
            offset_x = corps <= 1 ? 0 : i * (new_width- new_height) / (corps - 1);
        } else {
            offset_y = corps <= 1 ? 0 : i * (new_height - new_width) / (corps - 1);
        }
        
        for (int y = 0; y < scale_side_len; y++) {
            uint8_t *row = in + (y + offset_y) * new_width * channels;
            for (int x = 0; x < scale_side_len; x++) {
                uint8_t *pixel = row + (x + offset_x) * channels;
                corp_img.push_back(*pixel); //R
                corp_img.push_back(*(pixel+1)); //G
                corp_img.push_back(*(pixel+2)); //B
            }
        }
        result.push_back(corp_img);
    }
    
    return result;
}
