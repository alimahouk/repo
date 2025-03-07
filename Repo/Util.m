//
//  Util.m
//  Repo
//
//  Created by Ali Mahouk on 15/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import Photos;
@import SystemConfiguration;

#import "Util.h"

@implementation Util


+ (NSDictionary *)imageDataFromReferenceURL:(NSURL *)URL
{
        if ( URL ) {
                __block CLLocation *location;
                __block NSData *data;
                __block NSDate *date;
                NSMutableDictionary *returnData;
                PHAsset *asset;
                PHImageRequestOptions *options;
                
                asset = [[PHAsset fetchAssetsWithALAssetURLs:@[URL] options:nil] lastObject];
                
                if ( asset ) {
                        options = [[PHImageRequestOptions alloc] init];
                        options.deliveryMode         = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                        options.networkAccessAllowed = NO;
                        options.synchronous          = YES;
                        
                        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                          options:options
                                                                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                            NSDateFormatter *dateFormatter;
                                                                            NSDictionary *EXIFDictionary;
                                                                            NSDictionary *GPSDictionary;
                                                                            NSDictionary *metadata;
                                                                            NSNumber *error;
                                                                            NSNumber *isCloud;
                                                                            NSString *dateString;
                                                                            double latitude;
                                                                            double longitude;
                                                                            
                                                                            metadata       = [self metadataFromImageData:imageData];
                                                                            EXIFDictionary = metadata[(NSString *)kCGImagePropertyExifDictionary];
                                                                            GPSDictionary  = metadata[(NSString *)kCGImagePropertyGPSDictionary];
                                                                            error          = [info objectForKey:PHImageErrorKey];
                                                                            isCloud        = [info objectForKey:PHImageResultIsInCloudKey];
                                                                            
                                                                            if ( [error boolValue] ||
                                                                                 [isCloud boolValue] ||
                                                                                !imageData ) { // failure.
                                                                                    data = nil;
                                                                            } else {
                                                                                    if ( EXIFDictionary ) {
                                                                                            dateFormatter = [[NSDateFormatter alloc] init];
                                                                                            
                                                                                            [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
                                                                                            [dateFormatter setTimeZone:NSTimeZone.localTimeZone];
                                                                                            
                                                                                            dateString = [EXIFDictionary objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
                                                                                            
                                                                                            if ( dateString )
                                                                                                   date = [dateFormatter dateFromString:dateString];
                                                                                    }
                                                                                    
                                                                                    if ( GPSDictionary ) {
                                                                                            latitude  = [[EXIFDictionary objectForKey:(NSString *)kCGImagePropertyGPSLatitude] doubleValue];
                                                                                            longitude = [[EXIFDictionary objectForKey:(NSString *)kCGImagePropertyGPSLongitude] doubleValue];
                                                                                            location  = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                                                                                    }
                                                                                    
                                                                                    data = imageData;
                                                                            }
                                                                    }];
                        
                        returnData = [@{@"data": data} mutableCopy];
                        
                        if ( date )
                                [returnData setObject:date forKey:@"date"];
                        else
                                [returnData setObject:[NSDate date] forKey:@"date"]; // Don't leave the date as nil.
                        
                        if ( location )
                                [returnData setObject:location forKey:@"coordinates"];
                        
                        return returnData;
                }
        }
        
        return nil;
}

+ (NSDictionary *)metadataFromImageData:(NSData*)imageData
{
        CGImageSourceRef imageSource;
        
        imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL);
        
        if ( imageSource ) {
                NSDictionary *options;
                CFDictionaryRef imageProperties;
                
                options         = @{(NSString *)kCGImageSourceShouldCache : [NSNumber numberWithBool:NO]};
                imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
                
                if ( imageProperties ) {
                        NSDictionary *metadata;
                        
                        metadata = (__bridge NSDictionary *)imageProperties;
                        
                        CFRelease(imageProperties);
                        CFRelease(imageSource);
                        
                        return metadata;
                }
                
                CFRelease(imageSource);
        }
        
        NSLog(@"Can't read media metadata");
        
        return nil;
}

+ (NSURL *)pathForInk:(NSString *)itemIdentifier
{
        NSArray *paths;
        NSString *documentsDirectory;
        
        paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths firstObject];
        
        return [[NSURL fileURLWithPath:documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_ink.png", itemIdentifier]];
}

+ (NSURL *)pathForMedia:(NSString *)itemIdentifier extension:(NSString *)fileExtension
{
        NSArray *paths;
        NSString *documentsDirectory;
        
        paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths firstObject];
        
        return [[NSURL fileURLWithPath:documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_media.%@", itemIdentifier, fileExtension]];
}

+ (NSURL *)pathForSnapshot:(NSString *)itemIdentifier
{
        NSArray *paths;
        NSString *documentsDirectory;
        
        paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths firstObject];
        
        return [[NSURL fileURLWithPath:documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_snapshot.jpg", itemIdentifier]];
}

+ (NSURL *)pathForText:(NSString *)itemIdentifier
{
        NSArray *paths;
        NSString *documentsDirectory;
        
        paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths firstObject];
        
        return [[NSURL fileURLWithPath:documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_text.rtf", itemIdentifier]];
}

+ (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size
{
        UIImage *cropped;
        CGImageRef imageRef;
        CGRect cropRect;
        double newCropHeight;
        double newCropWidth;
        double x;
        double y;
        
        if ( image.size.width < image.size.height ){
                if ( image.size.width < size.width )
                        newCropWidth = size.width;
                else
                        newCropWidth = image.size.width;
                
                newCropHeight = (newCropWidth * size.height) / size.width;
        } else {
                if ( image.size.height < size.height )
                        newCropHeight = size.height;
                else
                        newCropHeight = image.size.height;
                
                newCropWidth = (newCropHeight * size.width) / size.height;
        }
        
        x        = image.size.width / 2.0 - newCropWidth / 2.0;
        y        = image.size.height / 2.0 - newCropHeight / 2.0;
        cropRect = CGRectMake(x, y, newCropWidth, newCropHeight);
        imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
        cropped  = [UIImage imageWithCGImage:imageRef];
        
        CGImageRelease(imageRef);
        
        return cropped;
}

+ (UIImage *)thumbnailForImage:(UIImage *)image
{
        if ( image ) {
                UIImage *thumbnail;
                CGImageSourceRef src;
                CFDictionaryRef options;
                
                src = CGImageSourceCreateWithData((CFDataRef)UIImageJPEGRepresentation(image, 1.0), NULL);
                options = (__bridge CFDictionaryRef) @{(id)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                       (id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                       (id)kCGImageSourceThumbnailMaxPixelSize : @(640)};
                
                thumbnail = [UIImage imageWithCGImage:CGImageSourceCreateThumbnailAtIndex(src, 0, options)];
                
                CFRelease(src);
                
                return thumbnail;
        }
        
        return nil;
}

+ (UIImage *)thumbnailForVideo:(NSURL *)path atTime:(CMTimeValue)frameTime
{
        if ( path ) {
                AVAsset *asset;
                AVAssetImageGenerator *imageGenerator;
                UIImage *thumbnail;
                CGImageRef imageRef;
                CMTime time;
                
                asset = [AVAsset assetWithURL:path];
                
                imageGenerator                                = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                imageGenerator.appliesPreferredTrackTransform = YES;
                
                time       = asset.duration;
                time.value = frameTime;
                
                imageRef  = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
                thumbnail = [UIImage imageWithCGImage:imageRef];
                
                CGImageRelease(imageRef);
                
                return thumbnail;
        }
        
        return nil;
}

+ (BOOL)isClearImage:(UIImage *)image
{
        BOOL clear;
        
        clear = YES;
        
        if ( image ) {
                GLubyte *imageData;
                size_t width;
                size_t height;
                CGContextRef imageContext;
                CGImageRef i;
                long bytesPerRow;
                int byteIndex;
                int bytesPerPixel;
                int bitsPerComponent;
                
                bitsPerComponent = 8;
                byteIndex        = 0;
                bytesPerPixel    = 4;
                i                = image.CGImage;
                height           = CGImageGetHeight(i);
                width            = CGImageGetWidth(i);
                bytesPerRow      = bytesPerPixel * width;
                imageData        = malloc(width * height * 4);
                imageContext     = CGBitmapContextCreate(imageData, width, height, bitsPerComponent, bytesPerRow, CGImageGetColorSpace(i), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
                
                CGContextSetBlendMode(imageContext, kCGBlendModeCopy);
                CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), i);
                CGContextRelease(imageContext);
                
                for ( ; byteIndex < width * height * 4; byteIndex += 4 ) {
                        CGFloat alpha;
                        CGFloat blue;
                        CGFloat green;
                        CGFloat red;
                        
                        red   = ((GLubyte *)imageData)[byteIndex] / 255.0f;
                        green = ((GLubyte *)imageData)[byteIndex + 1] / 255.0f;
                        blue  = ((GLubyte *)imageData)[byteIndex + 2] / 255.0f;
                        alpha = ((GLubyte *)imageData)[byteIndex + 3] / 255.0f;
                        
                        if ( alpha != 0 ) {
                                clear = NO;
                                
                                break;
                        }
                }
        }
        
        return clear;
}

+ (BOOL)isValidURL:(NSString *)string
{
        if ( string &&
             string.length > 0 ) {
                NSString *URLRegex;
                NSPredicate *URLTest;
                
                URLRegex = @"^(?i)(?:(?:https?|ftp):\\/\\/)?(?:\\S+(?::\\S*)?@)?(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))(?::\\d{2,5})?(?:\\/[^\\s]*)?$";
                URLTest  = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", URLRegex];
                
                return [URLTest evaluateWithObject:string];
        }
        
        return NO;
}

+ (void)linkifyHashtagsInTextView:(UITextView *)textView
{
        NSArray *matches;
        NSError *error;
        NSMutableAttributedString *attributedText;
        NSRegularExpression *regex;
        
        attributedText = [textView.attributedText mutableCopy];
        error          = nil;
        regex          = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:&error];  // Hashtags.
        //regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:&error];           // @mentions.
        matches        = [regex matchesInString:attributedText.string options:0 range:NSMakeRange(0, attributedText.length)];
        
        for ( NSTextCheckingResult *match in matches ) {
                NSString *word;
                NSRange wordRange;
                
                wordRange = [match rangeAtIndex:1];
                word      = [attributedText.string substringWithRange:wordRange];
                
                [attributedText addAttribute:NSLinkAttributeName value:[NSString stringWithFormat:@"%@%@", HASHTAG_URL_PREFIX, word] range:wordRange];
        }
        
        textView.attributedText = attributedText;
}


@end
