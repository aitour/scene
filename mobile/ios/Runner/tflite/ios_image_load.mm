#include "ios_image_load.h"

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#import "UIImage+Rotate.h"
#import "ExifInterface.h"

#define WRITE_TO_ALBUM

void saveToAlbum(uint8_t *buf, int width, int height, int channels) {
#ifdef WRITE_TO_ALBUM
    uint8_t *rgba = buf;
    if (channels == 3) {
        rgba = (uint8_t*)malloc(width*height*4);
        for(int i=0; i < width*height; ++i) {
            rgba[4*i] = buf[3*i];
            rgba[4*i+1] = buf[3*i+1];
            rgba[4*i+2] = buf[3*i+2];
            rgba[4*i+3] = 0;
        }
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgba,
                                                 width,
                                                 height,
                                                 8,
                                                 width * 4,
                                                 colorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    UIImageWriteToSavedPhotosAlbum(img, nullptr, nullptr, nullptr);
    CFRelease(imageRef);
    if (channels == 3) {
        free(rgba);
    }
#endif
}

int getImageOrientation(const char *file_name) {
    int orientation = kCGImagePropertyOrientationUp;
    NSURL *imageFileURL = [NSURL fileURLWithPath:[NSString stringWithCString:file_name encoding:NSASCIIStringEncoding]];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageFileURL, NULL);
    if (imageSource) {
        NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache:@NO};
        CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        //NSLog(@"exifDic properties: %@", imageProperties); //all data
        if (imageProperties) {
            CFTypeRef dynamicValue = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
            if (CFGetTypeID(dynamicValue) == CFNumberGetTypeID()) {
                orientation = [(__bridge NSNumber *)dynamicValue intValue];
            }
            NSLog(@"image orientation:%d", orientation);
            
//            CFDictionaryRef exif = (CFDictionaryRef)CFDictionaryGetValue(imageProperties, kCGImagePropertyExifDictionary);
//            if (exif) {
//                NSString *dateTakenString = (NSString *)CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeOriginal);
//                NSLog(@"Date Taken: %@", dateTakenString);
//            }
//
//            CFDictionaryRef tiff = (CFDictionaryRef)CFDictionaryGetValue(imageProperties, kCGImagePropertyTIFFDictionary);
//            if (tiff) {
//                NSString *cameraModel = (NSString *)CFDictionaryGetValue(tiff, kCGImagePropertyTIFFModel);
//                NSLog(@"Camera Model: %@", cameraModel);
//            }
//
//            CFDictionaryRef gps = (CFDictionaryRef)CFDictionaryGetValue(imageProperties, kCGImagePropertyGPSDictionary);
//            if (gps) {
//                NSString *latitudeString = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
//                NSString *latitudeRef = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
//                NSString *longitudeString = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
//                NSString *longitudeRef = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
//                NSLog(@"GPS Coordinates: %@ %@ / %@ %@", longitudeString, longitudeRef, latitudeString, latitudeRef);
//            }
            
            CFRelease(imageProperties);
        }
        CFRelease(imageSource);
    } else {
        NSLog(@"Error loading image");
    }
    return orientation;
}

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

std::vector<std::vector<uint8_t>> corpsImage(uint8_t *in, int imgWidth, int imgHeight, int channels, int corps) {
    int minSideLen = std::min(imgWidth, imgHeight);
    std::vector<std::vector<uint8_t>> result;
    for (int i = 0; i < corps; i++) {
        std::vector<uint8_t> corp_img;
        int offset_x = 0, offset_y = 0;
        if (imgWidth > imgHeight) {
            offset_x = corps <= 1 ? 0 : i * (imgWidth - imgHeight) / (corps - 1);
        } else {
            offset_y = corps <= 1 ? 0 : i * (imgHeight - imgWidth) / (corps - 1);
        }
        
        for (int y = 0; y < minSideLen; y++) {
            uint8_t *row = in + (y + offset_y) * imgWidth * channels;
            for (int x = 0; x < minSideLen; x++) {
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

#define FIX_ROTATE

std::vector<std::vector<uint8_t>> LoadImageFromFile2(const char* file_name, int scale_side_len, int corps) {
#ifdef FIX_ROTATE
    NSString *fpath = [NSString stringWithCString:file_name encoding:NSASCIIStringEncoding];
    UIImage *uiImage = [UIImage imageWithContentsOfFile:fpath];
//    NSLog(@"orientation:%d, width:%f, height:%f",
//          uiImage.imageOrientation, uiImage.size.width, uiImage.size.height);
    uiImage = [uiImage fixOrientation];

//    NSLog(@"after fix:orientation:%d, width:%f, height:%f",
//          uiImage.imageOrientation, uiImage.size.width, uiImage.size.height);
    
    CGImageRef image = uiImage.CGImage;
#else
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
#endif
    
    //scale image
    int width = (int)CGImageGetWidth(image);
    int height = (int)CGImageGetHeight(image);
    //NSLog(@"image width:%d, height:%d, alpha:%d", width, height, alpha);
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

    
    CGContextDrawImage(context, CGRectMake(0, 0 ,new_width, new_height), image);
    CGImageRef transImage = CGBitmapContextCreateImage(context);
//    char saveFile[256];
//    int n = sprintf(saveFile, "%s", file_name);
//    strcpy(saveFile+n, ".scale");
//    [UIImagePNGRepresentation([UIImage imageWithCGImage:transImage]) writeToFile:[NSString stringWithUTF8String:saveFile] atomically:YES];
    
    CGColorSpaceRelease(color_space);
    CGContextRelease(context);
    
#ifdef FIX_ROTATE
    
#else
    CFRelease(image);
    CFRelease(image_provider);
    CFRelease(file_data_ref);
#endif
    CFRelease(transImage);

    uint8_t *in = scaled_image.data();
    auto images = corpsImage(in, new_width, new_height, channels, 3);
//    for (int i = 0; i < images.size(); i++) {
//        saveToAlbum(images[i].data(), 224, 224, 3);
//    }
    return images;
    //return corpsImage(in, new_width, new_height, channels, 3);
}




std::vector<std::vector<uint8_t>> LoadImageFromData(uint8_t* in, int orientation, int width, int height,
                                                    int channels, int scale_side_len, int corps) {
    assert(corps > 0 && width > 0 && height > 0 &&
           width > scale_side_len && height > scale_side_len &&
           in != nullptr && channels == 4);
    
    //from bgra data to CGImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(in,
                                                 width,
                                                 height,
                                                 8,
                                                 width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    //from CGImageRef to UIImage.  to fix orientation
    //rotate: https://www.cnblogs.com/smileEvday/archive/2013/05/14/UIImage.html
    if (orientation == 0) {
        //portraint up
        //orientation = UIImageOrientationLeft;
    } else if (orientation == 1) {
        //orientation = UIImageOrientationRight;
    } else if (orientation == 2) {
        //orientation = 0;
    } else if (orientation == 3) {
        //orientation = UIImageOrientationUp;
    }
    UIImage *img = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:(UIImageOrientation)orientation];
    
    if (orientation == 2) {
        //NSLog(@"orientation: %d, width:%f, height:%f", img.imageOrientation, img.size.width, img.size.height);
        img = [img imageRotatedByDegrees:-90];
        //NSLog(@"after fix. orientation: %d, width:%f, height:%f", img.imageOrientation, img.size.width, img.size.height);
    }
    //img = [img fixOrientation];
    
    
    //Scale image
    float scale = float(scale_side_len) / std::min(width, height);
    int new_width = width * scale;
    int new_height = height * scale;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    const int bytes_per_row = (new_width * channels);
    const int bytes_in_image = (bytes_per_row * new_height);
    std::vector<uint8_t> scaled_image(bytes_in_image);
    const int bits_per_component = 8;
    context = CGBitmapContextCreate(scaled_image.data(), new_width, new_height,
                                                 bits_per_component, bytes_per_row, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0 ,new_width, new_height), img.CGImage);
    CGImageRef transImage = CGBitmapContextCreateImage(context);
    
    //static bool saved = false;
//    if  (orientation == 2 && !saved) {
//        UIImageWriteToSavedPhotosAlbum([UIImage imageWithCGImage:transImage], nullptr, nullptr, nullptr);
//    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(transImage);
    CFRelease(imageRef);
    
    //CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(img.CGImage));
    //UInt8 * buf = (UInt8 *) CFDataGetBytePtr(rawData);
    auto images = corpsImage(scaled_image.data(), width * scale, height * scale, channels, corps);
    
//    if (!saved) {
//        for (int i = 0; i < images.size(); i++) {
//            saveToAlbum(images[i].data(), 224, 224, 3);
//        }
//        saved = true;
//    }
    //CFRelease(rawData);
    return images;
}


