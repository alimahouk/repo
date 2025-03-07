//
//  CameraViewController.h
//  Repo
//
//  Created by Ali Mahouk on 13/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVKit;

#import "CameraView.h"
#import "ViewController.h"

@class CameraViewController;
@class InkView;
@class InkWell;
@class MediaItem;

@protocol CameraViewControllerDelegate<NSObject>
@optional

- (void)cameraViewDidBeginAnnotating:(CameraViewController *)cameraViewController;
- (void)cameraViewDidEndAnnotating:(CameraViewController *)cameraViewController;
- (void)cameraView:(CameraViewController *)cameraViewController didHandOverItem:(MediaItem *)item isEdit:(BOOL)isEdit;

@end

@interface CameraViewController : ViewController <CameraDelegate>
{
        AVPlayer *moviePlayer;
        AVPlayerViewController *playerViewController;
        CameraView *camera;
        MediaItem *workingItem;
        InkView *inkLayer;
        InkWell *inkWell;
        UIButton *doneAnnotatingButton;
        UIImageView *imagePreview;
        UISelectionFeedbackGenerator *selectionFeedbackGenerator;
        UIView *annotationView;
        BOOL isShowingStrokeColorOptions;
        BOOL shouldShowStatusBar;
        NSOperatingSystemVersion iOSVersionCheck;
}

@property (nonatomic, weak) id <CameraViewControllerDelegate> delegate;

- (void)closeViewfinder;
- (void)didDropItem:(MediaItem *)item;
- (void)openViewfinder;

@end
