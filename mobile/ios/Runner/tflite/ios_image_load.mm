#include "ios_image_load.h"

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

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

CGImageRef CreateScaledCGImageFromCGImage(CGImageRef image, float scale)
{
    // Create the bitmap context
    CGContextRef    context = NULL;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    int width = CGImageGetWidth(image) * scale;
    int height = CGImageGetHeight(image) * scale;
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * height);
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        return nil;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
    context = CGBitmapContextCreate (bitmapData,width,height,8,bitmapBytesPerRow,
                                     colorspace,kCGImageAlphaNoneSkipFirst);
    CGColorSpaceRelease(colorspace);
    
    if (context == NULL)
        // error creating context
        return nil;
    
    
//    if (image- == kCGImagePropertyOrientationRight) {
//        //rotate 90degree
//        CGContextRotateCTM (context, 90/180*M_PI) ;
//    } else if (image->CGImagePropertyOrientation == kCGImagePropertyOrientationDown) {
//        //rotate 180degree
//        CGContextRotateCTM (context, 180/180*M_PI) ;
//    } else if (image->CGImagePropertyOrientation == kCGImagePropertyOrientationLeft) {
//        //rotate 270degree
//        CGContextRotateCTM (context, 270/180*M_PI) ;
//    }
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, CGRectMake(0,0,width, height), image);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    
    return imgRef;
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
                                                 bits_per_component, new_width * 4, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(color_space);
    CGContextDrawImage(context, CGRectMake(0, 0, new_width, new_height), image);
    CGContextRelease(context);
    CFRelease(image);
    CFRelease(image_provider);
    CFRelease(file_data_ref);
    
    std::vector<std::vector<uint8_t>> result;
    
    for (int i = 0; i < corps; i++) {
        std::vector<uint8_t> corp_img;
        int offset_x = 0, offset_y = 0;
        if (new_width > new_height) {
            offset_x = corps <= 1 ? 0 : i * (new_width- new_height) / (corps - 1);
        } else {
            offset_y = corps <= 1 ? 0 : i * (new_height - new_width) / (corps - 1);
        }
        
        for (int y = 0; y < scale_side_len; y++) {
            for (int x = 0; x < scale_side_len; x++) {
                int offset = (y + offset_y) * new_width * channels + (x + offset_x) * channels;
                corp_img.push_back(scaled_image[offset]); //R
                corp_img.push_back(scaled_image[offset+1]); //G
                corp_img.push_back(scaled_image[offset+2]); //B
            }
        }
        result.push_back(corp_img);
    }
    
    return result;
}
