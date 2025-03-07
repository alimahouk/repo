//
//  MainViewController.m
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "MainViewController.h"

#import "AppDelegate.h"
#import "CollectionExplorerViewController.h"
#import "constants.h"
#import "DarkNavigationController.h"
#import "LinkItem.h"
#import "LocationItem.h"
#import "MediaItem.h"
#import "TextItem.h"
#import "Util.h"

@implementation MainViewController


- (instancetype)init
{
        /*
         * NOTE ABOUT UITABBARCONTROLLER
         * calling [super init] causes viewDidLoad
         * to be called before the init method
         * continues, so make sure to put all
         * viewDidLoad-critical code in viewDidLoad
         * itself.
         */
        self = [super init];
        
        if ( self ) {
                cameraController          = [CameraViewController new];
                cameraController.delegate = self;
                
                isHighlightingItemDeletionZone = NO;
                isHighlightingItemEditZone     = NO;
                isShowingItemDeletionZone      = NO;
                isShowingItemEditZone          = NO;
                iOSVersionCheck                = (NSOperatingSystemVersion){10, 0, 0};
                
                libraryController          = [LibraryViewController new];
                libraryController.delegate = self;
                
                libraryNavigationController = [[DarkNavigationController alloc] initWithRootViewController:libraryController];
                
                locationController          = [LocationViewController new];
                locationController.delegate = self;
                
                textEditorController          = [TextEditorViewController new];
                textEditorController.delegate = self;
                
                if ( [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOSVersionCheck] )
                        impactFeedbackGenerator = [UIImpactFeedbackGenerator new];
                
                self.delegate            = self;
                self.tabBar.barTintColor = UIColor.blackColor;
                self.viewControllers     = @[cameraController, textEditorController, locationController, libraryNavigationController];
        }
        
        return self;
}

- (ViewController *)focusedControllerForOffset:(CGFloat)offset
{
        if ( offset == [self cameraViewOffset] )
                return cameraController;
        else if ( offset == [self libraryViewOffset] )
                return libraryController;
        else if ( offset == [self locationViewOffset] )
                return locationController;
        else if ( offset == [self textEditorViewOffset] )
                return textEditorController;
        
        return nil;
}

- (CGFloat)locationViewOffset
{
        return locationController.view.frame.origin.x;
}

- (CGFloat)cameraViewOffset
{
        return cameraController.view.frame.origin.x;
}

- (CGFloat)libraryViewOffset
{
        return libraryNavigationController.view.frame.origin.x;
}

- (CGFloat)textEditorViewOffset
{
        return textEditorController.view.frame.origin.x;
}

- (void)cameraViewDidBeginAnnotating:(CameraViewController *)cameraViewController
{
        if ( [cameraViewController isEqual:cameraController] ) {
                shouldShowItems = NO;
                
                [self hideFreeItems];
        }
}

- (void)cameraViewDidEndAnnotating:(CameraViewController *)cameraViewController
{
        if ( [cameraViewController isEqual:cameraController] ) {
                shouldShowItems = YES;
                
                [self showFreeItems];
        }
}

- (void)cameraView:(CameraViewController *)cameraViewController didHandOverItem:(MediaItem *)item isEdit:(BOOL)isEdit
{
        if ( [cameraViewController isEqual:cameraController] ) {
                UIImageView *preview;
                CGFloat animationDelay;
                
                animationDelay = 0;
                
                if ( !item.coordinates )
                        item.coordinates = currentCoordinates;
                
                preview                        = [[UIImageView alloc] initWithFrame:self.view.bounds];
                preview.backgroundColor        = UIColor.blackColor;
                preview.contentMode            = UIViewContentModeScaleAspectFit;
                preview.userInteractionEnabled = YES;
                
                if ( item.itemType == ItemTypePhoto )
                        preview.image = item.image;
                
                [self removeItem:item fromView:self.view]; // In case sync happened in the background & added a copy.
                
                if ( !isEdit ) {
                        if ( item.itemType == ItemTypePhoto )
                                animationDelay = 0.8;
                        
                        /*NSDateFormatter *dateFormatter;
                        
                        dateFormatter  = [NSDateFormatter new];
                        
                        if ( [[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"en_US"] )
                                [dateFormatter setDateFormat:@"M d ''yy"]; // Americans…
                        else
                                [dateFormatter setDateFormat:@"d M ''yy"];
                        
                        // Next, we want to bake a timestamp into the photo/video.
                        if ( item.itemType == ItemTypePhoto ) {
                                UILabel *timestamp;
                                
                                animationDelay = 0.8;
                         
                                timestamp                     = [[UILabel alloc] initWithFrame:CGRectMake(preview.bounds.size.width - 220, preview.bounds.size.height - 43, 200, 23)];
                                timestamp.font                = [UIFont fontWithName:@"LCDMono2Bold" size:22];
                                timestamp.layer.shadowColor   = [UIColor orangeColor].CGColor;
                                timestamp.layer.shadowOpacity = 1.0;
                                timestamp.layer.shadowRadius  = 8;
                                timestamp.text                = [dateFormatter stringFromDate:item.created];
                                timestamp.textAlignment       = NSTextAlignmentRight;
                                timestamp.textColor           = [UIColor colorWithRed:252/255.0 green:233/255.0 blue:197/255.0 alpha:1.0];
                                
                                [preview addSubview:timestamp];
                                
                                UIGraphicsBeginImageContextWithOptions(preview.bounds.size, NO, 0.0);
                                
                                [preview drawViewHierarchyInRect:preview.bounds afterScreenUpdates:YES];
                                
                                preview.image = UIGraphicsGetImageFromCurrentImageContext();
                                item.image    = preview.image;
                                
                                UIGraphicsEndImageContext();
                        } else if ( item.itemType == ItemTypeMovie ) {
                                AVAssetExportSession *exportSession;
                                AVAssetTrack *clipAudioTrack;
                                AVAssetTrack *clipVideoTrack;
                                AVAssetTrack *videoTrack;
                                AVMutableComposition *composition;
                                AVMutableCompositionTrack *compositionAudioTrack;
                                AVMutableCompositionTrack *compositionVideoTrack;
                                AVMutableVideoComposition *videoComp;
                                AVMutableVideoCompositionInstruction *instruction;
                                AVMutableVideoCompositionLayerInstruction *layerInstruction;
                                AVURLAsset *asset;
                                CALayer *parentLayer;
                                CALayer *videoLayer;
                                CATextLayer *timestamp;
                                NSFileManager *fileManager;
                                
                                asset                 = [[AVURLAsset alloc] initWithURL:[Util pathForMedia:item.identifier extension:@"mov"] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
                                clipAudioTrack        = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                                clipVideoTrack        = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                                composition           = [AVMutableComposition composition];
                                compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                                compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                                fileManager           = [NSFileManager defaultManager];
                                
                                [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, clipAudioTrack.timeRange.duration)
                                                               ofTrack:clipAudioTrack
                                                                atTime:kCMTimeZero
                                                                 error:nil];
                                [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, clipVideoTrack.timeRange.duration)
                                                               ofTrack:clipVideoTrack
                                                                atTime:kCMTimeZero
                                                                 error:nil];
                                
                                timestamp                 = [CATextLayer layer];
                                timestamp.alignmentMode   = kCAAlignmentRight;
                                timestamp.font            = (__bridge CFTypeRef _Nullable)(@"LCDMono2Bold");
                                timestamp.fontSize        = 22;
                                timestamp.foregroundColor = [UIColor colorWithRed:252/255.0 green:233/255.0 blue:197/255.0 alpha:1.0].CGColor;
                                timestamp.frame           = CGRectMake(clipVideoTrack.naturalSize.width - 220, clipVideoTrack.naturalSize.height - 43, 200, 23);
                                timestamp.shadowColor     = [UIColor orangeColor].CGColor;
                                timestamp.shadowOpacity   = 1.0;
                                timestamp.shadowRadius    = 8;
                                timestamp.string          = [dateFormatter stringFromDate:item.created];
                                
                                parentLayer       = [CALayer layer];
                                parentLayer.frame = CGRectMake(0, 0, clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height);
                                
                                videoLayer       = [CALayer layer];
                                videoLayer.frame = CGRectMake(0, 0, clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height);
                                
                                [parentLayer addSublayer:videoLayer];
                                [parentLayer addSublayer:timestamp];
                                
                                videoComp               = [AVMutableVideoComposition videoComposition];
                                videoComp.renderSize    = clipVideoTrack.naturalSize;
                                videoComp.frameDuration = clipVideoTrack.minFrameDuration;
                                videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
                                
                                instruction           = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
                                instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
                                
                                videoTrack       = [[composition tracksWithMediaType:AVMediaTypeVideo] firstObject];
                                layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
                                
                                [layerInstruction setTransform:clipVideoTrack.preferredTransform atTime:kCMTimeZero];
                                
                                instruction.layerInstructions = @[layerInstruction];
                                videoComp.instructions        = @[instruction];
                                
                                // We first need to delete the existing file.
                                if ( [fileManager fileExistsAtPath:asset.URL.path] ) {
                                        NSError *error;
                                        
                                        if ( ![fileManager removeItemAtURL:asset.URL error:&error] )
                                                NSLog(@"%@", error);
                                }
                                
                                exportSession                  = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
                                exportSession.outputFileType   = AVFileTypeQuickTimeMovie;
                                exportSession.outputURL        = asset.URL;
                                exportSession.videoComposition = videoComp;
                                
                                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                                        switch ( exportSession.status ) {
                                                case AVAssetExportSessionStatusCompleted: {
                                                        
                                                        break;
                                                }
                                                        
                                                case AVAssetExportSessionStatusFailed: {
                                                        NSLog (@"AVAssetExportSessionStatusFailed: %@", exportSession.error);
                                                        
                                                        break;
                                                }
                                                        
                                                default:
                                                        break;
                                        };
                                }];
                        }*/
                        
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createMediaItem:item];
                } else {
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaItem:item inCollection:nil];
                }
                
                [self.view addSubview:preview];
                [UIView animateWithDuration:0.2 delay:animationDelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                        preview.alpha             = 0.0;
                        preview.layer.borderColor = UIColor.whiteColor.CGColor;
                        preview.transform         = CGAffineTransformMakeScale(0.1, 0.1);
                } completion:^(BOOL finished){
                        UIPanGestureRecognizer *panRecognizer;
                        UITapGestureRecognizer *tapRecognizer;
                        int magnitude;
                        
                        [preview removeFromSuperview];
                        
                        item.snapshot = nil;
                        
                        magnitude     = arc4random_uniform(10) - 5;
                        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanItem:)];
                        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)];
                        
                        item.alpha                  = 1.0;
                        item.hidden                 = NO;
                        item.pushBehavior           = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
                        item.pushBehavior.angle     = arc4random_uniform(180) * (M_PI / 180);
                        item.pushBehavior.magnitude = magnitude;
                        
                        [item addGestureRecognizer:panRecognizer];
                        [item addGestureRecognizer:tapRecognizer];
                        [self.view addSubview:item];
                        [collisionBehavior addItem:item];
                        [gravityBehavior addItem:item];
                        [animator addBehavior:item.pushBehavior];
                        
                        if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_NEW_ITEM] )
                                [self playNewItemTutorial];
                }];
                
                if ( item.coordinates &&
                     !item.location ) { // Use reverse geocoding to get some info on the location.
                        [geocoder reverseGeocodeLocation:item.coordinates completionHandler:^(NSArray *placemarks, NSError *error){
                                if ( placemarks.count > 0) {
                                        MKPlacemark *placemark;
                                        NSString *title;
                                        NSString *subtitle;
                                        
                                        placemark = placemarks[0];
                                        
                                        if ( placemark.areasOfInterest.count > 0 ) {
                                                title    = [NSString stringWithFormat:@"Near %@", placemark.areasOfInterest[0]];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.thoroughfare ) {
                                                title    = [NSString stringWithFormat:@"%@", placemark.thoroughfare];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.subLocality ) {
                                                title    = [NSString stringWithFormat:@"%@", placemark.subLocality];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else {
                                                title    = [NSString stringWithFormat:@"%@", placemark.locality];
                                                subtitle = [NSString stringWithFormat:@"%@", placemark.country];
                                        }
                                        
                                        item.location = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
                                        
                                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaItem:item inCollection:nil];
                                }
                        }];
                }
        }
}

- (void)deleteItem:(Item *)item
{
        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] deleteItem:item fromCollection:nil];
}

- (void)didEnterBackground
{
        dispatch_async(dispatch_get_main_queue(), ^{
                if ( !textEditorController.showingKeyboard &&
                     !UIApplication.sharedApplication.keyWindow.rootViewController.presentedViewController )
                        [self resetOffset];
                
                [cameraController closeViewfinder];
        });
}

- (void)didEnterForeground
{
        [cameraController openViewfinder];
        [textEditorController getCurrentDate];
        [self syncWifiOnly:NO];
}

- (void)didPanItem:(UIPanGestureRecognizer *)gestureRecognizer
{
        CGPoint location;
        Item *item;
        
        item     = (Item *)gestureRecognizer.view;
        location = [gestureRecognizer locationInView:self.view];
        
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ||
             gestureRecognizer.state == UIGestureRecognizerStateChanged ) {
                CGFloat x;
                CGFloat y;
                CGPoint translation;
                
                if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ) {
                        [UIView animateWithDuration:0.1 animations:^{
                                gestureRecognizer.view.transform = CGAffineTransformIdentity;
                        }];
                        
                        [gestureRecognizer.view.superview bringSubviewToFront:gestureRecognizer.view];
                        [animator removeBehavior:item.dynamicBehavior];
                        [animator removeBehavior:item.pushBehavior];
                        [collisionBehavior removeItem:item];
                        [gravityBehavior removeItem:item];
                        [self showItemDeletionZone];
                }
                
                translation = [gestureRecognizer translationInView:gestureRecognizer.view.superview];
                x           = gestureRecognizer.view.center.x;
                y           = gestureRecognizer.view.center.y;
                
                // The item must never go beyond the view's boundaries!
                if ( x + translation.x > ITEM_PREVIEW_SIZE / 2 &&
                     x + translation.x < self.view.bounds.size.width - (ITEM_PREVIEW_SIZE / 2) )
                        x += translation.x;
                
                if ( y + translation.y > ITEM_PREVIEW_SIZE / 2 &&
                     y + translation.y < self.view.bounds.size.height - self.tabBar.bounds.size.height - (ITEM_PREVIEW_SIZE / 2) )
                        y += translation.y;
                
                gestureRecognizer.view.center = CGPointMake(x, y);
                
                [gestureRecognizer setTranslation:CGPointZero inView:gestureRecognizer.view.superview];
                
                /*
                 * If you pick up a text item in the camera view, nothing shows.
                 * Likewise for media in the text editor view.
                 */
                if ( ([self.selectedViewController isEqual:cameraController] && [item isKindOfClass:MediaItem.class]) ||
                     ([self.selectedViewController isEqual:textEditorController] && [item isKindOfClass:TextItem.class]) )
                        [self showItemEditZone];
                else
                        [self hideItemEditZone];
                
                if ( isShowingItemDeletionZone &&
                     CGRectContainsPoint(itemDeletionZone.frame, location) ) {
                        [self highlightItemDeletionZone];
                        
                        if ( [self.selectedViewController isEqual:libraryNavigationController] )
                                [libraryController didMoveItemToPoint:CGPointMake(-1, -1)];
                } else {
                        [self fadeItemDeletionZone];
                        
                        if ( [self.selectedViewController isEqual:libraryNavigationController] )
                                [libraryController didMoveItemToPoint:gestureRecognizer.view.center];
                }
                
                if ( isShowingItemEditZone &&
                     CGRectContainsPoint(itemEditZone.frame, location) )
                        [self highlightItemEditZone];
                else
                        [self fadeItemEditZone];
        } else {
                CGFloat magnitude;
                CGPoint velocity;
                NSInteger angle;
                
                if ( (isShowingItemDeletionZone && CGRectContainsPoint(itemDeletionZone.frame, location)) ||
                     (isShowingItemEditZone && CGRectContainsPoint(itemEditZone.frame, location)) ) {
                        if ( isShowingItemDeletionZone &&
                             CGRectContainsPoint(itemDeletionZone.frame, location) ) {
                                if ( impactFeedbackGenerator ) // Play some haptic feedback.
                                        [impactFeedbackGenerator impactOccurred];
                                
                                [self removeItemFromSuperview:item animated:YES];
                                [self deleteItem:item];
                        }
                        
                        if ( isShowingItemEditZone &&
                             CGRectContainsPoint(itemEditZone.frame, location) ) {
                                if ( impactFeedbackGenerator ) // Play some haptic feedback.
                                        [impactFeedbackGenerator impactOccurred];
                                
                                if ( [self.selectedViewController isEqual:cameraController] )
                                        [cameraController didDropItem:(MediaItem *)item];
                                else if ( [self.selectedViewController isEqual:textEditorController] )
                                        [textEditorController didDropItem:(TextItem *)item];
                                
                                [self removeItemFromSuperview:item animated:NO];
                        }
                } else {
                        if ( [self.selectedViewController isEqual:libraryNavigationController] ) {
                                [libraryController didDropItem:item atPoint:gestureRecognizer.view.center];
                        }
                        
                        if ( item.free ) {
                                angle                = 0;
                                item.dynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[gestureRecognizer.view]];
                                velocity             = [gestureRecognizer velocityInView:gestureRecognizer.view.superview];
                                magnitude            = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
                                
                                if ( magnitude > THROWING_THRESHOLD )
                                        angle = arc4random_uniform(3);
                                
                                [item.dynamicBehavior addLinearVelocity:velocity forItem:gestureRecognizer.view];
                                [item.dynamicBehavior addAngularVelocity:angle forItem:gestureRecognizer.view];
                                [animator addBehavior:item.dynamicBehavior];
                                [collisionBehavior addItem:item];
                                [gravityBehavior addItem:item];
                        }
                }
                
                [self hideItemDeletionZone];
                [self hideItemEditZone];
        }
}

- (void)didTapItem:(UITapGestureRecognizer *)gestureRecognizer
{
        CollectionExplorerViewController *explorerView;
        
        explorerView                      = [CollectionExplorerViewController new];
        explorerView.item                 = (Item *)gestureRecognizer.view;
        explorerView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:explorerView animated:YES completion:nil];
}

- (void)fadeItemDeletionZone
{
        if ( isHighlightingItemDeletionZone ) {
                isHighlightingItemDeletionZone = NO;
                
                [UIView animateWithDuration:0.2 animations:^{
                        itemDeletionZone.alpha                = 0.5;
                        itemDeletionZone.backgroundColor      = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2];
                        itemDeletionZone.titleLabel.textColor = UIColor.redColor;
                        itemDeletionZone.transform            = CGAffineTransformIdentity;
                        
                        self.selectedViewController.view.alpha = 1.0;
                }];
        }
}

- (void)fadeItemEditZone
{
        if ( isHighlightingItemEditZone ) {
                isHighlightingItemEditZone = NO;
                
                [UIView animateWithDuration:0.2 animations:^{
                        itemEditZone.alpha                = 0.5;
                        itemEditZone.backgroundColor      = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:0.2];
                        itemEditZone.titleLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
                        itemEditZone.transform            = CGAffineTransformIdentity;
                        
                        self.selectedViewController.view.alpha = 1.0;
                }];
        }
}

- (void)hideFreeItems
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                for ( UIView *v in self.view.subviews ) {
                        if ( [v isKindOfClass:Item.class] ) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                        [UIView animateWithDuration:0.2 animations:^{
                                                v.alpha = 0.0;
                                        } completion:^(BOOL finished){
                                                v.hidden = YES;
                                        }];
                                });
                        }
                }
        });
}

- (void)hideItemDeletionZone
{
        if ( isShowingItemDeletionZone ) {
                isShowingItemDeletionZone = NO;
                
                [self fadeItemDeletionZone];
                [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationOptionCurveLinear animations:^{
                        itemDeletionZone.alpha = 0.0;
                        
                        self.selectedViewController.view.alpha = 1.0;
                } completion:^(BOOL finished){
                        itemDeletionZone.hidden = YES;
                }];
        }
}

- (void)hideItemEditZone
{
        if ( isShowingItemEditZone ) {
                isShowingItemEditZone = NO;
                
                [self fadeItemDeletionZone];
                [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationOptionCurveLinear animations:^{
                        itemEditZone.alpha = 0.0;
                        
                        self.selectedViewController.view.alpha = 1.0;
                } completion:^(BOOL finished){
                        itemEditZone.hidden = YES;
                }];
        }
}

- (void)highlightItemDeletionZone
{
        if ( !isHighlightingItemDeletionZone ) {
                isHighlightingItemDeletionZone = YES;
                
                [UIView animateWithDuration:0.2 animations:^{
                        itemDeletionZone.alpha                = 1.0;
                        itemDeletionZone.backgroundColor      = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
                        itemDeletionZone.titleLabel.textColor = UIColor.whiteColor;
                        itemDeletionZone.transform            = CGAffineTransformMakeScale(1.5, 1.5);
                        
                        self.selectedViewController.view.alpha = 0.5;
                }];
        }
}

- (void)highlightItemEditZone
{
        if ( !isHighlightingItemEditZone ) {
                isHighlightingItemEditZone = YES;
                
                [UIView animateWithDuration:0.2 animations:^{
                        itemEditZone.alpha                = 1.0;
                        itemEditZone.backgroundColor      = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
                        itemEditZone.titleLabel.textColor = UIColor.whiteColor;
                        itemEditZone.transform            = CGAffineTransformMakeScale(1.5, 1.5);
                        
                        self.selectedViewController.view.alpha = 0.5;
                }];
        }
}

- (void)libraryView:(LibraryViewController *)libraryViewController didHandOverItem:(Item *)item atPoint:(CGPoint)point imported:(BOOL)imported
{
        if ( [libraryViewController isEqual:libraryController] ) {
                UIPanGestureRecognizer *panRecognizer;
                UITapGestureRecognizer *tapRecognizer;
                int magnitude;
                
                magnitude = arc4random_uniform(10) - 5;
                panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanItem:)];
                tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)];
                
                if ( !imported ) {
                       point = [self.view convertPoint:point fromView:libraryViewController.tableView];
                } else {
                        if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_NEW_ITEM] )
                                [self playNewItemTutorial];
                        
                        [self removeItem:item fromView:self.view]; // In case sync happened in the background & added a copy.
                }
                
                if ( !item.coordinates )
                        item.coordinates = currentCoordinates;
                
                item.center                 = point;
                item.pushBehavior           = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
                item.pushBehavior.angle     = arc4random_uniform(180) * (M_PI / 180);
                item.pushBehavior.magnitude = magnitude;
                
                [item addGestureRecognizer:panRecognizer];
                [item addGestureRecognizer:tapRecognizer];
                [self.view addSubview:item];
                [collisionBehavior addItem:item];
                [gravityBehavior addItem:item];
                [animator addBehavior:item.pushBehavior];
                
                if ( item.coordinates &&
                     !item.location ) { // Use reverse geocoding to get some info on the location.
                        [geocoder reverseGeocodeLocation:item.coordinates completionHandler:^(NSArray *placemarks, NSError *error){
                                if ( placemarks.count > 0) {
                                        MKPlacemark *placemark;
                                        NSString *title;
                                        NSString *subtitle;
                                        
                                        placemark = placemarks[0];
                                        
                                        if ( placemark.areasOfInterest.count > 0 ) {
                                                title    = [NSString stringWithFormat:@"Near %@", placemark.areasOfInterest[0]];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.thoroughfare ) {
                                                title    = [NSString stringWithFormat:@"%@", placemark.thoroughfare];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.subLocality ) {
                                                title    = [NSString stringWithFormat:@"%@", placemark.subLocality];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else {
                                                title    = [NSString stringWithFormat:@"%@", placemark.locality];
                                                subtitle = [NSString stringWithFormat:@"%@", placemark.country];
                                        }
                                        
                                        item.collectionIdentifier = nil;
                                        item.location             = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
                                        
                                        if ( [item isKindOfClass:LinkItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLinkItem:(LinkItem *)item inCollection:nil];
                                        else if ( [item isKindOfClass:LocationItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLocationItem:(LocationItem *)item inCollection:nil];
                                        else if ( [item isKindOfClass:MediaItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaItem:(MediaItem *)item inCollection:nil];
                                        else if ( [item isKindOfClass:TextItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateTextItem:(TextItem *)item inCollection:nil];
                                }
                        }];
                }
        }
}

- (void)libraryView:(LibraryViewController *)libraryViewController didReceiveItem:(Item *)item
{
        if ( [libraryViewController isEqual:libraryController] ) {
                [self removeItem:item fromView:self.view];
        }
}

- (void)loadFreeItems
{
        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] loadFreeItemsCompletion:^(NSMutableArray *list){
                dispatch_async(dispatch_get_main_queue(), ^{
                        /*
                         * Multiple passes required. 1st pass sets
                         * new items in the positions of their existing
                         * copies. 2nd pass removes all items to start clean.
                         * 3rd pass adds the latest free items in their
                         * correct positions.
                         */
                        for ( Item *item in list ) {
                                CGPoint center;
                                NSInteger x;
                                NSInteger y;
                                
                                [item redraw];
                                
                                x      = arc4random_uniform(UIScreen.mainScreen.bounds.size.width - item.bounds.size.width);
                                y      = arc4random_uniform(UIScreen.mainScreen.bounds.size.height / 2);
                                center = CGPointMake(x, y);
                                
                                for ( UIView *v in self.view.subviews ) {
                                        if ( [v isKindOfClass:Item.class] ) {
                                                Item *i = (Item *)v;
                                                
                                                if ( [i isEqual:item] ) {
                                                        center = i.center;
                                                        
                                                        break;
                                                }
                                        }
                                }
                                
                                item.center = center;
                        }
                        
                        for ( UIView *v in self.view.subviews ) {
                                if ( [v isKindOfClass:Item.class] ) {
                                        Item *i = (Item *)v;
                                        
                                        [collisionBehavior removeItem:i];
                                        [gravityBehavior removeItem:i];
                                        [i removeFromSuperview];
                                }
                        }
                        
                        for ( Item *item in list ) {
                                UIPanGestureRecognizer *panRecognizer;
                                UITapGestureRecognizer *tapRecognizer;
                                
                                panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanItem:)];
                                tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)];
                                
                                if ( !shouldShowItems ) {
                                        item.alpha  = 0.0;
                                        item.hidden = YES;
                                }
                                
                                [item addGestureRecognizer:panRecognizer];
                                [item addGestureRecognizer:tapRecognizer];
                                [self.view addSubview:item];
                                [collisionBehavior addItem:item];
                                [gravityBehavior addItem:item];
                        }
                });
        }];
}

- (void)loadView
{
        [super loadView];
        
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        
        collisionBehavior                                       = [[UICollisionBehavior alloc] initWithItems:@[]];
        collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
        
        [collisionBehavior addBoundaryWithIdentifier:@"TabBarBarrier"
                                    fromPoint:self.tabBar.frame.origin
                                      toPoint:CGPointMake(self.tabBar.bounds.size.width, self.tabBar.frame.origin.y)];
        
        gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[]];
        
        itemEditZone                    = [UIButton buttonWithType:UIButtonTypeCustom];
        itemEditZone.alpha              = 0.0;
        itemEditZone.backgroundColor    = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:0.2];
        itemEditZone.clipsToBounds      = YES;
        itemEditZone.frame              = CGRectMake((self.view.bounds.size.width / 2) - 32, (self.view.bounds.size.height / 2) - 32, 64, 64);
        itemEditZone.hidden             = YES;
        itemEditZone.layer.borderColor  = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor;
        itemEditZone.layer.borderWidth  = 3.0;
        itemEditZone.layer.cornerRadius = itemEditZone.bounds.size.width / 2;
        itemEditZone.titleLabel.font      = [UIFont systemFontOfSize:32];
        
        [itemEditZone setTitle:@"□" forState:UIControlStateNormal];
        [itemEditZone setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        
        itemDeletionZone                    = [UIButton buttonWithType:UIButtonTypeCustom];
        itemDeletionZone.alpha              = 0.0;
        itemDeletionZone.backgroundColor    = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2];
        itemDeletionZone.clipsToBounds      = YES;
        itemDeletionZone.frame              = CGRectMake(20, 40, 64, 64);
        itemDeletionZone.hidden             = YES;
        itemDeletionZone.layer.borderColor  = UIColor.redColor.CGColor;
        itemDeletionZone.layer.borderWidth  = 3.0;
        itemDeletionZone.layer.cornerRadius = itemDeletionZone.bounds.size.width / 2;
        itemDeletionZone.titleLabel.font    = [UIFont systemFontOfSize:48];
        
        [itemDeletionZone setTitle:@"×" forState:UIControlStateNormal];
        [itemDeletionZone setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [itemDeletionZone setTitleEdgeInsets:UIEdgeInsetsMake(-7.0, 0.0, 0.0, 0.0)];
        
        [animator addBehavior:collisionBehavior];
        [animator addBehavior:gravityBehavior];
        [self.view addSubview:itemEditZone];
        [self.view addSubview:itemDeletionZone];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
        if ( status == kCLAuthorizationStatusAuthorizedWhenInUse ||
             status == kCLAuthorizationStatusNotDetermined ) {
                didAuthorizeLocation = YES;
                
                [locationManager startUpdatingLocation];
        } else {
                didAuthorizeLocation = NO;
        }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
        NSLog(@"%@", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
        currentCoordinates = [locations lastObject];
        
        [locationManager stopUpdatingLocation];
        [geocoder reverseGeocodeLocation:currentCoordinates completionHandler:^(NSArray *placemarks, NSError *error){
                if ( placemarks.count > 0) {
                        MKPlacemark *placemark;
                        
                        placemark                            = placemarks[0];
                        currentLocation                      = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                        textEditorController.currentLocation = currentLocation;
                        
                        [NSUserDefaults.standardUserDefaults setObject:currentLocation forKey:@"CurrentLocation"];
                } else {
                        currentLocation                      = [NSUserDefaults.standardUserDefaults objectForKey:@"CurrentLocation"];
                        textEditorController.currentLocation = currentLocation;
                }
        }];
}

- (void)locationView:(LocationViewController *)locationViewController didHandOverItem:(LocationItem *)item
{
        UIImageView *photo;
        
        photo                   = [[UIImageView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64)];
        photo.backgroundColor   = UIColor.blackColor;
        photo.contentMode       = UIViewContentModeScaleAspectFit;
        photo.image             = item.snapshot;
        photo.layer.borderColor = UIColor.clearColor.CGColor;
        
        [self removeItem:item fromView:self.view]; // In case sync happened in the background & added a copy.
        
        [self.view addSubview:photo];
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                photo.alpha             = 0.0;
                photo.layer.borderColor = UIColor.whiteColor.CGColor;
                photo.transform         = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished){
                UIPanGestureRecognizer *panRecognizer;
                UITapGestureRecognizer *tapRecognizer;
                int magnitude;
                
                [photo removeFromSuperview];
                
                item.snapshot = nil;
                
                magnitude     = arc4random_uniform(10) - 5;
                panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanItem:)];
                tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)];
                
                item.pushBehavior           = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
                item.pushBehavior.angle     = arc4random_uniform(180) * (M_PI / 180);
                item.pushBehavior.magnitude = magnitude;
                
                [item addGestureRecognizer:panRecognizer];
                [item addGestureRecognizer:tapRecognizer];
                [self.view addSubview:item];
                [collisionBehavior addItem:item];
                [gravityBehavior addItem:item];
                [animator addBehavior:item.pushBehavior];
                
                if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_NEW_ITEM] )
                        [self playNewItemTutorial];
        }];
        
        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createLocationItem:item];
        
        if ( item.coordinates &&
             !item.location ) { // Use reverse geocoding to get some info on the location.
                [geocoder reverseGeocodeLocation:item.coordinates completionHandler:^(NSArray *placemarks, NSError *error){
                        if ( placemarks.count > 0) {
                                MKPlacemark *placemark;
                                NSString *title;
                                NSString *subtitle;
                                
                                placemark = placemarks[0];
                                
                                if ( placemark.areasOfInterest.count > 0 ) {
                                        title    = [NSString stringWithFormat:@"Near %@", placemark.areasOfInterest[0]];
                                        subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                } else if ( placemark.thoroughfare ) {
                                        title    = [NSString stringWithFormat:@"%@", placemark.thoroughfare];
                                        subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                } else if ( placemark.subLocality ) {
                                        title    = [NSString stringWithFormat:@"%@", placemark.subLocality];
                                        subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                } else {
                                        title    = [NSString stringWithFormat:@"%@", placemark.locality];
                                        subtitle = [NSString stringWithFormat:@"%@", placemark.country];
                                }
                                
                                item.location = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
                                
                                [item redraw];
                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLocationItem:item inCollection:nil];
                        }
                }];
        }
}

- (void)playNewItemTutorial
{
        __block UILabel *explanationLabel;
        __block UIView *overlay;
        
        explanationLabel               = [[UILabel alloc] initWithFrame:CGRectMake(35, 35, self.view.bounds.size.width - 70, self.view.bounds.size.height - 70)];
        explanationLabel.font          = [UIFont systemFontOfSize:UIFont.buttonFontSize];
        explanationLabel.numberOfLines = 0;
        explanationLabel.text          = @"You've just created a new item!";
        explanationLabel.textAlignment = NSTextAlignmentCenter;
        explanationLabel.textColor     = UIColor.whiteColor;
        
        overlay                 = [[UIView alloc] initWithFrame:self.view.bounds];
        overlay.alpha           = 0;
        overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        
        [overlay addSubview:explanationLabel];
        [self.view addSubview:overlay];
        [UIView animateWithDuration:0.2 animations:^{
                overlay.alpha = 1.0;
        } completion:^(BOOL finished){
                [UIView animateWithDuration:0.2 delay:2.0 options:UIViewAnimationOptionCurveLinear animations:^{
                        explanationLabel.alpha = 0.0;
                } completion:^(BOOL finished){
                        explanationLabel.text = @"When you pick up an item, drop zones will appear where you can drop the item to do things like delete or edit it.";
                        
                        [UIView animateWithDuration:0.2 animations:^{
                                explanationLabel.alpha = 1.0;
                        } completion:^(BOOL finished){
                                [UIView animateWithDuration:0.2 delay:4.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                        explanationLabel.alpha = 0.0;
                                } completion:^(BOOL finished){
                                        explanationLabel.text = @"Once you're ready to file your item, go to your Library & drop it in a collection.";
                                        
                                        [UIView animateWithDuration:0.2 animations:^{
                                                explanationLabel.alpha = 1.0;
                                        } completion:^(BOOL finished){
                                                [UIView animateWithDuration:0.2 delay:3.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                        overlay.alpha = 0.0;
                                                } completion:^(BOOL finished){
                                                        [NSUserDefaults.standardUserDefaults setObject:@"1" forKey:NSUDKEY_TUTORIAL_NEW_ITEM];
                                                        [overlay removeFromSuperview];
                                                        
                                                        explanationLabel = nil;
                                                        overlay          = nil;
                                                }];
                                        }];
                                }];
                        }];
                }];
        }];
}

- (void)removeItem:(Item *)item fromView:(UIView *)view
{
        for ( int i = 0; i < view.subviews.count; i++ ) {
                UIView *subview;
                
                subview = view.subviews[i];
                
                if ( [subview isKindOfClass:item.class] ) {
                        Item *i = (Item *)subview;
                        
                        if ( [i isEqual:item] ) {
                                [collisionBehavior removeItem:i];
                                [gravityBehavior removeItem:i];
                                [i removeFromSuperview];
                                
                                subview = nil;
                        }
                }
        }
}

- (void)removeItemFromSuperview:(Item *)item animated:(BOOL)animated
{
        [collisionBehavior removeItem:item];
        [gravityBehavior removeItem:item];
        
        if ( animated ) {
                [UIView animateWithDuration:0.3 animations:^{
                        item.alpha     = 0.0;
                        item.transform = CGAffineTransformScale(item.transform, 2.0, 2.0);
                } completion:^(BOOL finished){
                        [item removeFromSuperview];
                }];
        } else {
                [item removeFromSuperview];
        }
}

- (void)resetOffset
{
        [textEditorController blurEditor];
        [self showCamera];
}

- (void)showCamera
{
        self.selectedViewController = cameraController;
}

- (void)showFreeItems
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                for ( UIView *v in self.view.subviews ) {
                        if ( [v isKindOfClass:Item.class] ) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                        v.hidden = NO;
                                        
                                        [UIView animateWithDuration:0.2 animations:^{
                                                v.alpha = 1.0;
                                        }];
                                });
                        }
                }
        });
}

- (void)showItemDeletionZone
{
        if ( !isShowingItemDeletionZone ) {
                isShowingItemDeletionZone = YES;
                itemDeletionZone.hidden   = NO;
                
                [UIView animateWithDuration:0.2 animations:^{
                        itemDeletionZone.alpha = 0.5;
                }];
        }
}

- (void)showItemEditZone
{
        if ( !isShowingItemEditZone ) {
                isShowingItemEditZone = YES;
                itemEditZone.hidden   = NO;
                
                [UIView animateWithDuration:0.2 animations:^{
                        itemEditZone.alpha = 0.5;
                }];
        }
}

- (void)showLibrary
{
        self.selectedViewController = libraryNavigationController;
}

- (void)showLocationPickerAndMark:(BOOL)markLocation
{
        self.selectedViewController = locationController;
        
        if ( markLocation )
                locationController.handOverOnUpdate = YES;
}

- (void)showTextEditorAndFocus:(BOOL)focus
{
        self.selectedViewController = textEditorController;
        
        if ( focus )
                [textEditorController focusEditor];
}

- (void)sync
{
        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] syncCompletion:^(BOOL done, NSMutableArray *fetchedCollections, NSMutableArray *fetchedItems){
                if ( done ) {
                        [NSUserDefaults.standardUserDefaults setObject:[NSDate date] forKey:NSUDKEY_LAST_SYNC_DATE];
                        
                        if ( fetchedCollections.count > 0 ||
                             fetchedItems.count > 0 ) {
                                if ( fetchedItems.count > 0 )
                                        [self loadFreeItems];
                                
                                [libraryController reloadDataSource];
                        }
                } else {
                        UIAlertAction *dismiss;
                        UIAlertController *alert;
                        
                        dismiss = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil];
                        alert   = [UIAlertController alertControllerWithTitle:@"Sync Error" message:@"An error occurred while syncing with iCloud." preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addAction:dismiss];
                        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
                }
        }];
}

- (void)syncWifiOnly:(BOOL)wifiOnly
{
        if ( wifiOnly &&
            networkStatus != ReachableViaWiFi ) {
                NSString *alertMessage;
                UIAlertAction *cellular;
                UIAlertAction *wifi;
                UIAlertController *alert;
                
                alertMessage = [NSString stringWithFormat:@"If you've ever used %@ before, your items will be downloaded once you're connected to Wi-Fi, unless you don't mind restoring over cellular data (might consume a lot of data, depending on your backup size).", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"]];
                cellular = [UIAlertAction actionWithTitle:@"Use Cellular" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                        [self syncWifiOnly:NO];
                }];
                wifi     = [UIAlertAction actionWithTitle:@"Wi-Fi" style:UIAlertActionStyleCancel handler:nil];
                alert    = [UIAlertController alertControllerWithTitle:@"iCloud Restore"
                                                               message:alertMessage
                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:wifi];
                [alert addAction:cellular];
                [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        } else if ( networkStatus != NotReachable ) {
                [self sync];
        }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(ViewController *)viewController
{
        if ( ![viewController isEqual:activeController] ) {
                [activeController didChangeControllerFocus:NO];
                [viewController didChangeControllerFocus:YES];
                
                if ( [viewController isEqual:textEditorController] )
                        [(TextEditorViewController *)viewController setCurrentLocation:currentLocation];
                
                activeController = viewController;
        }
}

- (void)textEditorViewDidBeginAnnotating:(TextEditorViewController *)editorViewController
{
        if ( [editorViewController isEqual:textEditorController] ) {
                [self hideFreeItems];
        }
}

- (void)textEditorViewDidBeginEditing:(TextEditorViewController *)editorViewController
{
        if ( [editorViewController isEqual:textEditorController] ) {
                [self hideFreeItems];
        }
}

- (void)textEditorView:(TextEditorViewController *)editorViewController didChangeKeyboardVisibility:(BOOL)visible
{
        if ( [editorViewController isEqual:textEditorController] ) {
                if ( visible )
                        shouldShowItems = NO;
                else
                        shouldShowItems = YES;
        }
}

- (void)textEditorViewDidEndAnnotating:(TextEditorViewController *)editorViewController
{
        if ( [editorViewController isEqual:textEditorController] ) {
                [self showFreeItems];
        }
}

- (void)textEditorViewDidEndEditing:(TextEditorViewController *)editorViewController
{
        if ( [editorViewController isEqual:textEditorController] ) {
                [self showFreeItems];
        }
}

- (void)textEditorView:(TextEditorViewController *)editorViewController didHandOverItem:(Item *)item isEdit:(BOOL)isEdit
{
        if ( [editorViewController isEqual:textEditorController] ) {
                UIImageView *photo;
                
                if ( !item.coordinates )
                        item.coordinates = currentCoordinates;
                
                [self removeItem:item fromView:self.view]; // In case sync happened in the background & added a copy.
                
                photo                   = [[UIImageView alloc] initWithFrame:self.view.bounds];
                photo.backgroundColor   = UIColor.whiteColor;
                photo.contentMode       = UIViewContentModeScaleAspectFit;
                photo.layer.borderColor = UIColor.clearColor.CGColor;
                
                if ( [item isKindOfClass:LinkItem.class] ) {
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createLinkItem:(LinkItem *)item];
                        
                        photo.image = item.snapshot;
                } else if ( [item isKindOfClass:LocationItem.class] ) { // Extracted via link.
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createLocationItem:(LocationItem *)item];
                        
                        photo.image = item.snapshot;
                } else if ( [item isKindOfClass:MediaItem.class] ) { // Downloaded via link.
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createMediaItem:(MediaItem *)item];
                        
                        photo.backgroundColor = UIColor.blackColor;
                        photo.image           = [(MediaItem *)item image];
                } else if ( [item isKindOfClass:TextItem.class] ) {
                        if ( !isEdit ) {
                                /*
                                 * Text item requirements (1 or more):
                                 * --
                                 * • Body text
                                 * • Ink
                                 * • Current location
                                 */
                                if ( [(TextItem *)item string].length > 0 ||
                                     [(TextItem *)item ink] ||
                                     item.coordinates ) {
                                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createTextItem:(TextItem *)item];
                                } else {
                                        return;
                                }
                        } else {
                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateTextItem:(TextItem *)item inCollection:nil];
                        }
                        
                        photo.image = item.snapshot;
                }
                
                [self.view addSubview:photo];
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        photo.alpha             = 0.0;
                        photo.layer.borderColor = UIColor.whiteColor.CGColor;
                        photo.transform         = CGAffineTransformMakeScale(0.1, 0.1);
                } completion:^(BOOL finished){
                        UIPanGestureRecognizer *panRecognizer;
                        UITapGestureRecognizer *tapRecognizer;
                        int magnitude;
                        
                        [photo removeFromSuperview];
                        
                        item.snapshot = nil;
                        
                        magnitude     = arc4random_uniform(10) - 5;
                        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanItem:)];
                        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)];
                        
                        item.alpha                  = 1.0;
                        item.hidden                 = NO;
                        item.pushBehavior           = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
                        item.pushBehavior.angle     = arc4random_uniform(180) * (M_PI / 180);
                        item.pushBehavior.magnitude = magnitude;
                        
                        [item addGestureRecognizer:panRecognizer];
                        [item addGestureRecognizer:tapRecognizer];
                        [self.view addSubview:item];
                        [collisionBehavior addItem:item];
                        [gravityBehavior addItem:item];
                        [animator addBehavior:item.pushBehavior];
                        
                        if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_NEW_ITEM] )
                                [self playNewItemTutorial];
                }];
                
                if ( item.coordinates &&
                     !item.location ) { // Use reverse geocoding to get some info on the location.
                        [geocoder reverseGeocodeLocation:item.coordinates completionHandler:^(NSArray *placemarks, NSError *error){
                                if ( placemarks.count > 0) {
                                        MKPlacemark *placemark;
                                        NSString *title;
                                        NSString *subtitle;
                                        
                                        placemark = placemarks[0];
                                        
                                        if ( placemark.areasOfInterest.count > 0 ) {
                                                title    = [NSString stringWithFormat:@"Near %@", placemark.areasOfInterest[0]];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.thoroughfare ) {
                                                title    = [NSString stringWithFormat:@"%@", placemark.thoroughfare];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.subLocality ) {
                                                title    = [NSString stringWithFormat:@"%@", placemark.subLocality];
                                                subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else {
                                                title    = [NSString stringWithFormat:@"%@", placemark.locality];
                                                subtitle = [NSString stringWithFormat:@"%@", placemark.country];
                                        }
                                        
                                        item.location = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
                                        
                                        [item redraw];
                                        
                                        if ( [item isKindOfClass:LinkItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLinkItem:(LinkItem *)item inCollection:nil];
                                        else if ( [item isKindOfClass:LocationItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLocationItem:(LocationItem *)item inCollection:nil];
                                        else if ( [item isKindOfClass:MediaItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaItem:(MediaItem *)item inCollection:nil];
                                        else if ( [item isKindOfClass:TextItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateTextItem:(TextItem *)item inCollection:nil];
                                }
                        }];
                }
        }
}

- (void)viewDidLoad
{
        NSArray *reachabilityHosts;
        Reachability *reachability;
        
        [super viewDidLoad];
        
        didAuthorizeLocation           = NO;
        geocoder                       = [CLGeocoder new];
        
        locationManager                 = [CLLocationManager new];
        locationManager.delegate        = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        
        networkStatus   = NotReachable;
        shouldShowItems = YES;
        
        [locationManager requestWhenInUseAuthorization];
        
        locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:LOCATION_UPDATE_INTERVAL repeats:YES block:^(NSTimer *timer){
                if ( didAuthorizeLocation )
                        [locationManager startUpdatingLocation];
        }];
        
        // Get any free-floating items.
        [self loadFreeItems];
        
        // For reachability, let's not rely on just 1 host every time.
        reachabilityHosts           = @[@"www.apple.com", @"www.google.com"];
        reachability                = [Reachability reachabilityWithHostname:reachabilityHosts[arc4random_uniform((unsigned int)reachabilityHosts.count)]];
        reachability.reachableBlock = ^(Reachability *reachability){
                dispatch_async(dispatch_get_main_queue(), ^{
                        if ( reachability.currentReachabilityStatus != networkStatus ) {
                                networkStatus = reachability.currentReachabilityStatus;
                                
                                if ( [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE] )
                                        [self syncWifiOnly:NO];
                                else // First time syncing; prefer Wi-Fi in case it's a huge database.
                                        [self syncWifiOnly:YES];
                        }
                });
        };
        reachability.unreachableBlock = ^(Reachability *reachability){
                if ( reachability.currentReachabilityStatus != networkStatus ) {
                        networkStatus = reachability.currentReachabilityStatus;
                        
                        [self sync]; // To obtain ubiquity status.
                }
        };
        
        [reachability startNotifier];
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}


@end
