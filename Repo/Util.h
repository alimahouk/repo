//
//  Util.h
//  Repo
//
//  Created by Ali Mahouk on 15/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import CoreMedia;
@import UIKit;

#import "constants.h"

@interface Util : NSObject

+ (NSDictionary *)imageDataFromReferenceURL:(NSURL *)URL;

+ (NSURL *)pathForInk:(NSString *)itemIdentifier;
+ (NSURL *)pathForMedia:(NSString *)itemIdentifier extension:(NSString *)fileExtension;
+ (NSURL *)pathForSnapshot:(NSString *)itemIdentifier;
+ (NSURL *)pathForText:(NSString *)itemIdentifier;

+ (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)thumbnailForImage:(UIImage *)image;
+ (UIImage *)thumbnailForVideo:(NSURL *)path atTime:(CMTimeValue)frameTime;

+ (BOOL)isClearImage:(UIImage *)image;
+ (BOOL)isValidURL:(NSString *)string;

+ (void)linkifyHashtagsInTextView:(UITextView *)textView;

@end
