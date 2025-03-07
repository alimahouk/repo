//
//  CameraView.h
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVFoundation;
@import CoreMotion;
@import UIKit;

#import "CaptureButton.h"

#import "constants.h"

#define MAX_VIDEO_LENGTH        10 // Seconds.

@protocol CameraDelegate<NSObject>
@optional

- (void)cameraDidBeginRecordingVideo;
- (void)cameraDidCaptureImage:(UIImage *)image;
- (void)cameraDidFinishRecordingVideoAtURL:(NSURL *)path;

@end

@interface CameraView : UIView <AVCaptureFileOutputRecordingDelegate,
                                CaptureButtonDelegate>
{
        AVCaptureDevice *inputDevice;
        AVCaptureDeviceInput *videoInput;
        AVCaptureDeviceInput *audioInput;
        AVCaptureMovieFileOutput *movieOutput;
        AVCaptureSession *session;
        AVCaptureStillImageOutput *stillImageOutput;
        AVCaptureVideoOrientation orientation;
        AVCaptureVideoPreviewLayer *videoPreviewLayer;
        CaptureButton *captureButton;
        CMMotionManager *motionManager;
        NSTimer *recordingTimer;
        UIButton *flashToggleButton;
        UIButton *gridToggleButton;
        UIView *gridView;
        UIView *recordingLengthIndicator;
        BOOL isRecording;
        BOOL isShowingGrid;
        BOOL isUsingFrontCamera;
        FlashMode flashMode;
        NSInteger clipCount;
        UIDeviceOrientation deviceOrientation;
}

@property (nonatomic, weak) id <CameraDelegate> delegate;
@property (nonatomic) UIView *viewfinder;

- (void)closeViewfinder;
- (void)openViewfinder;

@end
