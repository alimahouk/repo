//
//  CameraView.m
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "CameraView.h"

@implementation CameraView


- (instancetype)initWithFrame:(CGRect)frame
{
        self = [super initWithFrame:frame];
        
        if ( self ) {
                NSError *error;
                NSUserDefaults *userDefaults;
                UITapGestureRecognizer *tapRecognizer;
                UITapGestureRecognizer *doubleTapRecognizer;
                
                clipCount     = 0;
                flashMode     = FlashModeOff;
                isRecording   = NO;
                isShowingGrid = NO;
                userDefaults  = [NSUserDefaults standardUserDefaults];
                
                _viewfinder = [[UIView alloc] initWithFrame:CGRectMake(0, 20, frame.size.width, (frame.size.width * 4) / 3)];
                
                doubleTapRecognizer                      = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
                doubleTapRecognizer.numberOfTapsRequired = 2;
                
                tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
                
                [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
                
                captureButton          = [CaptureButton new];
                captureButton.delegate = self;
                captureButton.frame    = CGRectMake((_viewfinder.bounds.size.width / 2) - (captureButton.bounds.size.width / 2),
                                                    _viewfinder.frame.origin.y + _viewfinder.bounds.size.height + ((frame.size.height - _viewfinder.bounds.size.height - _viewfinder.frame.origin.y - 49) / 2) - (captureButton.bounds.size.height / 2),
                                                    captureButton.bounds.size.width,
                                                    captureButton.bounds.size.height);
                
                flashToggleButton           = [UIButton buttonWithType:UIButtonTypeSystem];
                flashToggleButton.frame     = CGRectMake((_viewfinder.bounds.size.width / 4) - 12.5,
                                                         _viewfinder.frame.origin.y + _viewfinder.bounds.size.height + ((frame.size.height - _viewfinder.bounds.size.height - _viewfinder.frame.origin.y - 49) / 2) - 12.5,
                                                         25,
                                                         25);
                flashToggleButton.tintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
                
                [flashToggleButton addTarget:self action:@selector(toggleFlashMode) forControlEvents:UIControlEventTouchUpInside];
                [flashToggleButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
                
                gridToggleButton           = [UIButton buttonWithType:UIButtonTypeSystem];
                gridToggleButton.frame     = CGRectMake((_viewfinder.bounds.size.width / 2) + (_viewfinder.bounds.size.width / 4) - 12.5,
                                                        _viewfinder.frame.origin.y + _viewfinder.bounds.size.height + ((frame.size.height - _viewfinder.bounds.size.height - _viewfinder.frame.origin.y - 49) / 2) - 12.5,
                                                        25,
                                                        25);
                gridToggleButton.tintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
                
                [gridToggleButton addTarget:self action:@selector(toggleGrid) forControlEvents:UIControlEventTouchUpInside];
                [gridToggleButton setImage:[UIImage imageNamed:@"camera_grid"] forState:UIControlStateNormal];
                
                gridView                        = [[UIView alloc] initWithFrame:_viewfinder.bounds];
                gridView.alpha                  = 0;
                gridView.hidden                 = YES;
                gridView.userInteractionEnabled = NO;
                
                audioInput  = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
                orientation = AVCaptureVideoOrientationPortrait;
                
                session               = [[AVCaptureSession alloc] init];
                session.sessionPreset = AVCaptureSessionPresetPhoto;
                
                movieOutput                       = [AVCaptureMovieFileOutput new];
                movieOutput.minFreeDiskSpaceLimit = 1024 * 1024;
                
                motionManager                             = [CMMotionManager new];
                motionManager.accelerometerUpdateInterval = 0.2;
                
                recordingLengthIndicator                        = [UIView new];
                recordingLengthIndicator.backgroundColor        = [UIColor redColor];
                recordingLengthIndicator.hidden                 = YES;
                recordingLengthIndicator.userInteractionEnabled = NO;
                
                stillImageOutput                = [AVCaptureStillImageOutput new];
                stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
                
                if ( [session canAddOutput:stillImageOutput] )
                        [session addOutput:stillImageOutput];
                
                videoPreviewLayer              = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
                videoPreviewLayer.frame        = _viewfinder.bounds;
                videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                
                self.backgroundColor = UIColor.blackColor;
                
                [_viewfinder addGestureRecognizer:tapRecognizer];
                [_viewfinder addGestureRecognizer:doubleTapRecognizer];
                [_viewfinder addSubview:gridView];
                [self addSubview:_viewfinder];
                [self addSubview:recordingLengthIndicator];
                [self addSubview:captureButton];
                [self addSubview:flashToggleButton];
                [self addSubview:gridToggleButton];
                [self layoutGrid];
                [self useRearCamera];
                
                if ( [userDefaults objectForKey:NSUDKEY_CAMERA_GRID] ) {
                        isShowingGrid = ![[userDefaults objectForKey:NSUDKEY_CAMERA_GRID] boolValue]; // Store the inverse of the value because toggleGrid will invert it again.
                        
                        [self toggleGrid];
                }
        }
        
        return self;
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
        for ( AVCaptureConnection *connection in connections )
                for ( AVCaptureInputPort *port in connection.inputPorts )
                        if ( [port.mediaType isEqual:mediaType] )
                                return connection;
        
        return nil;
}

- (AVCaptureDevice *)frontCamera
{
        NSArray *devices;
        
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        for ( AVCaptureDevice *device in devices )
                if ( device.position == AVCaptureDevicePositionFront )
                        return device;
        
        return nil;
}

- (void)captureButtonWasPressed:(CaptureButton *)button
{
        [self startRecording];
}

- (void)captureButtonWasReleased:(CaptureButton *)button
{
        [self stopRecording];
}

- (void)captureButtonWasTapped:(CaptureButton *)button
{
        AVCaptureConnection *stillImageConnection;
        CABasicAnimation *flashAnimation;
        
        stillImageConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:stillImageOutput.connections];
        
        if ( stillImageConnection.isVideoOrientationSupported )
                stillImageConnection.videoOrientation = orientation;
        
        flashAnimation              = [CABasicAnimation animationWithKeyPath:@"opacity"];
        flashAnimation.autoreverses = YES;
        flashAnimation.duration     = 0.1;
        flashAnimation.fromValue    = [NSNumber numberWithFloat:1.0];
        flashAnimation.toValue      = [NSNumber numberWithFloat:0.0];
        
        [videoPreviewLayer addAnimation:flashAnimation forKey:@"flashAnimation"];
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                              NSData *imageData;
                                                              UIImage *image;
                                                              
                                                              if ( imageDataSampleBuffer != NULL ) {
                                                                      imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                      image = [[UIImage alloc] initWithData:imageData];
                                                                      
                                                                      if ( isUsingFrontCamera ) // Front camera returns flipped images.
                                                                              image = [UIImage imageWithCGImage:image.CGImage
                                                                                                          scale:image.scale
                                                                                                    orientation:UIImageOrientationLeftMirrored];
                                                                      
                                                                      if ( [_delegate respondsToSelector:@selector(cameraDidCaptureImage:)] )
                                                                              [_delegate cameraDidCaptureImage:image];
                                                              }
                                                              
                                                              if ( error )
                                                                      NSLog(@"%@", error);
                                                      }];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections
{
        /* 
         * The AVCaptureFileOutputRecordingDelegate delegate methods
         * will get called whenever the user switches between cameras.
         * The CameraViewDelegate must not get notified every time
         * it happens.
         */
        if ( !isRecording ) {
                isRecording    = YES;
                recordingTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_VIDEO_LENGTH target:self selector:@selector(stopRecording) userInfo:nil repeats:NO];
                
                recordingLengthIndicator.frame  = CGRectMake(0, 0, 0, 5);
                recordingLengthIndicator.hidden = NO;
                
                [UIView animateWithDuration:MAX_VIDEO_LENGTH delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        recordingLengthIndicator.frame = CGRectMake(recordingLengthIndicator.frame.origin.x,
                                                                    recordingLengthIndicator.frame.origin.y,
                                                                    _viewfinder.bounds.size.width,
                                                                    recordingLengthIndicator.bounds.size.height);
                } completion:nil];
                
                if ( [_delegate respondsToSelector:@selector(cameraDidBeginRecordingVideo)] )
                        [_delegate cameraDidBeginRecordingVideo];
        }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
        if ( error )
                NSLog(@"%@", error);
        
        if ( !isRecording ) {
                __block NSError *e;
                NSFileManager *fileManager;
                BOOL recordedSuccessfully;
                
                fileManager          = [NSFileManager defaultManager];
                recordedSuccessfully = YES;
                
                if ( error.code != noErr ) {
                        // A problem occurred: Find out if the recording was successful.
                        NSNumber *value;
                        
                        value = [error.userInfo objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
                        
                        if ( value )
                                recordedSuccessfully = value.boolValue;
                }
                
                [session stopRunning];
                
                session.sessionPreset   = AVCaptureSessionPresetPhoto;
                _viewfinder.frame       = CGRectMake(0, 20, self.bounds.size.width, (self.bounds.size.width * 4) / 3);
                videoPreviewLayer.frame = _viewfinder.bounds;
                
                if ( audioInput )
                        [session removeInput:audioInput];
                
                if ( inputDevice.hasTorch ) {
                        if ( [inputDevice lockForConfiguration:&e] ) {
                                inputDevice.torchMode = AVCaptureTorchModeOff;
                                
                                [inputDevice unlockForConfiguration];
                        }
                        
                        if ( e ) {
                                NSLog(@"%@", e);
                                
                                e = nil;
                        }
                }
                
                [session startRunning];
                
                if ( recordedSuccessfully ) {
                        if ( clipCount > 0 ) {
                                AVAssetExportSession *exportSession;
                                AVMutableComposition *composition;
                                AVMutableCompositionTrack *compositionVideoTrack;
                                AVMutableCompositionTrack *compositionAudioTrack;
                                NSString *exportVideoPath;
                                NSURL *exportURL;
                                CMTime insertTime;
                                
                                composition           = [AVMutableComposition composition];
                                compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                                compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                                
                                insertTime            = kCMTimeZero;
                                
                                for ( int i = 0; i <= clipCount; i++ ) {
                                        AVURLAsset *asset;
                                        NSString *filePath;
                                        
                                        filePath = [NSString stringWithFormat:@"%@%d.mov", NSTemporaryDirectory(), i];
                                        asset    = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
                                        
                                        if ( asset ) {
                                                AVAssetTrack *audioAssetTrack;
                                                AVAssetTrack *videoAssetTrack;
                                                
                                                audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                                                videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                                                
                                                [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration)
                                                                               ofTrack:audioAssetTrack
                                                                                atTime:insertTime
                                                                                 error:nil];
                                                [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
                                                                               ofTrack:videoAssetTrack
                                                                                atTime:insertTime
                                                                                 error:nil];
                                                
                                                compositionVideoTrack.preferredTransform = videoAssetTrack.preferredTransform;
                                                
                                                insertTime = CMTimeAdd(insertTime, videoAssetTrack.timeRange.duration);
                                        }
                                }
                                
                                exportVideoPath = [NSString stringWithFormat:@"%@final.mov", NSTemporaryDirectory()];
                                exportURL       = [NSURL fileURLWithPath:exportVideoPath];
                                
                                if ( [fileManager fileExistsAtPath:exportURL.path] ) {
                                        if ( ![fileManager removeItemAtURL:exportURL error:&e] )
                                                NSLog(@"%@", e);
                                }
                                
                                e = nil;
                                
                                exportSession                = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
                                exportSession.outputFileType = AVFileTypeQuickTimeMovie;
                                exportSession.outputURL      = exportURL;
                                
                                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                switch ( exportSession.status ) {
                                                        case AVAssetExportSessionStatusCompleted: {
                                                                if ( [_delegate respondsToSelector:@selector(cameraDidFinishRecordingVideoAtURL:)] )
                                                                        [_delegate cameraDidFinishRecordingVideoAtURL:exportURL];
                                                                
                                                                break;
                                                        }
                                                                
                                                        case AVAssetExportSessionStatusFailed: {
                                                                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportSession.error);
                                                                
                                                                break;
                                                        }
                                                                
                                                        default:
                                                                break;
                                                }
                                                
                                                for ( int i = 0; i < clipCount; i++ ) {
                                                        NSURL *staleFilePath;
                                                        
                                                        staleFilePath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%d.mov", NSTemporaryDirectory(), i]];
                                                        
                                                        if ( [fileManager fileExistsAtPath:staleFilePath.path] )
                                                                if ( ![fileManager removeItemAtURL:staleFilePath error:&e] )
                                                                        NSLog(@"%@", e);
                                                }
                                                
                                                e = nil;
                                                
                                                if ( [fileManager fileExistsAtPath:exportURL.path] )
                                                        if ( ![fileManager removeItemAtURL:exportURL error:&e] )
                                                                NSLog(@"%@", e);
                                        });
                                }];
                        } else {
                                if ( [_delegate respondsToSelector:@selector(cameraDidFinishRecordingVideoAtURL:)] )
                                        [_delegate cameraDidFinishRecordingVideoAtURL:outputFileURL];
                                
                                if ( [fileManager fileExistsAtPath:outputFileURL.path] )
                                        if ( ![fileManager removeItemAtURL:outputFileURL error:&e] )
                                                NSLog(@"%@", e);
                        }
                }
        }
}

- (void)closeViewfinder
{
        if ( session.running ) {
                [session stopRunning];
                [self disableGrid];
                [videoPreviewLayer removeFromSuperlayer];
                [motionManager stopAccelerometerUpdates];
        }
}

- (void)didDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
        if ( isUsingFrontCamera )
                [self useRearCamera];
        else
                [self useFrontCamera];
}

- (void)didTap:(UITapGestureRecognizer *)gestureRecognizer
{
        NSError *error;
        CGPoint location;
        CGPoint pointOfInterest;
        
        location        = [gestureRecognizer locationInView:gestureRecognizer.view];
        pointOfInterest = CGPointMake(location.x / gestureRecognizer.view.bounds.size.width, location.y / gestureRecognizer.view.bounds.size.height);
        
        if ( [inputDevice lockForConfiguration:&error] ) {
                if ( [inputDevice isExposurePointOfInterestSupported] )
                        [inputDevice setExposurePointOfInterest:pointOfInterest];
                
                if ( [inputDevice isFocusPointOfInterestSupported] )
                        [inputDevice setFocusPointOfInterest:pointOfInterest];
                
                if ( [inputDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure] )
                        [inputDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                else if ( [inputDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] )
                        [inputDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                
                if ( [inputDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] )
                        [inputDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                else if ( [inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] )
                        [inputDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                
                [inputDevice unlockForConfiguration];
                [self showFocusRingAtPoint:location];
        }
        
        if ( error )
                NSLog(@"%@", error);
}

/**
 * This method does not toggle the grid.
 * It is used to temporarily hide it.
 */
- (void)disableGrid
{
        if ( isShowingGrid )
                gridView.hidden = YES;
}

/**
 * If the grid was temporarily hidden,
 * this method shows it (if the grid toggle
 * is ON.
 */
- (void)enableGrid
{
        if ( isShowingGrid )
                gridView.hidden = NO;
}

- (void)layoutGrid
{
        UIView *horizontal_1;
        UIView *horizontal_2;
        UIView *vertical_1;
        UIView *vertical_2;
        
        for ( int i = 0; i < gridView.subviews.count; i++ ) {
                UIView *subview;
                
                subview = gridView.subviews[i];
                
                [subview removeFromSuperview];
                
                subview = nil;
        }
        
        horizontal_1                        = [[UIView alloc] initWithFrame:CGRectMake(0, (gridView.bounds.size.height / 3) - 0.5, gridView.bounds.size.width, 1)];
        horizontal_1.backgroundColor        = [UIColor colorWithWhite:1.0 alpha:0.4];
        horizontal_1.layer.shadowColor      = [UIColor colorWithWhite:0.0 alpha:0.4].CGColor;
        horizontal_1.layer.shadowOffset     = CGSizeMake(0, 0);
        horizontal_1.layer.shadowOpacity    = 1.0;
        horizontal_1.layer.shadowRadius     = 1;
        horizontal_1.userInteractionEnabled = NO;
        
        horizontal_2                        = [[UIView alloc] initWithFrame:CGRectMake(0, (gridView.bounds.size.height / 3) * 2 - 0.5, gridView.bounds.size.width, 1)];
        horizontal_2.backgroundColor        = [UIColor colorWithWhite:1.0 alpha:0.4];
        horizontal_2.layer.shadowColor      = [UIColor colorWithWhite:0.0 alpha:0.4].CGColor;
        horizontal_2.layer.shadowOffset     = CGSizeMake(0, 0);
        horizontal_2.layer.shadowOpacity    = 1.0;
        horizontal_2.layer.shadowRadius     = 1;
        horizontal_2.userInteractionEnabled = NO;
        
        vertical_1                        = [[UIView alloc] initWithFrame:CGRectMake((gridView.bounds.size.width / 3) - 0.5, 0, 1, gridView.bounds.size.height)];
        vertical_1.backgroundColor        = [UIColor colorWithWhite:1.0 alpha:0.4];
        vertical_1.layer.shadowColor      = [UIColor colorWithWhite:0.0 alpha:0.4].CGColor;
        vertical_1.layer.shadowOffset     = CGSizeMake(0, 0);
        vertical_1.layer.shadowOpacity    = 1.0;
        vertical_1.layer.shadowRadius     = 1;
        vertical_1.userInteractionEnabled = NO;
        
        vertical_2                        = [[UIView alloc] initWithFrame:CGRectMake((gridView.bounds.size.width / 3) * 2 - 0.5, 0, 1, gridView.bounds.size.height)];
        vertical_2.backgroundColor        = [UIColor colorWithWhite:1.0 alpha:0.4];
        vertical_2.layer.shadowColor      = [UIColor colorWithWhite:0.0 alpha:0.4].CGColor;
        vertical_2.layer.shadowOffset     = CGSizeMake(0, 0);
        vertical_2.layer.shadowOpacity    = 1.0;
        vertical_2.layer.shadowRadius     = 1;
        vertical_2.userInteractionEnabled = NO;
        
        [gridView addSubview:horizontal_1];
        [gridView addSubview:horizontal_2];
        [gridView addSubview:vertical_1];
        [gridView addSubview:vertical_2];
}

- (void)openViewfinder
{
        if ( !session.running ) {
                [_viewfinder.layer insertSublayer:videoPreviewLayer atIndex:0];
                [session startRunning];
                [self enableGrid];
                [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error){
                        if ( error ) {
                                NSLog(@"%@", error);
                        } else if ( accelerometerData ) {
                                UIDeviceOrientation orientationNew;
                                
                                if ( accelerometerData.acceleration.x >= 0.75 )
                                        orientationNew = UIDeviceOrientationLandscapeLeft;
                                else if ( accelerometerData.acceleration.x <= -0.75 )
                                        orientationNew = UIDeviceOrientationLandscapeRight;
                                else if ( accelerometerData.acceleration.y <= -0.75 )
                                        orientationNew = UIDeviceOrientationPortrait;
                                else if ( accelerometerData.acceleration.y >= 0.75 )
                                        orientationNew = UIDeviceOrientationPortraitUpsideDown;
                                else
                                        return; // No change.
                                
                                if ( orientationNew != deviceOrientation )
                                        [self orientationChanged:orientationNew];
                                
                                deviceOrientation = orientationNew;
                        }
                }];
        }
}

- (void)orientationChanged:(UIDeviceOrientation)newOrientation
{
        if ( newOrientation == UIDeviceOrientationPortrait )
                orientation = AVCaptureVideoOrientationPortrait;
        else if ( newOrientation == UIDeviceOrientationPortraitUpsideDown )
                orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        else if ( newOrientation == UIDeviceOrientationLandscapeLeft )
                orientation = AVCaptureVideoOrientationLandscapeLeft;
        else if ( newOrientation == UIDeviceOrientationLandscapeRight )
                orientation = AVCaptureVideoOrientationLandscapeRight;
}

- (void)showFocusRingAtPoint:(CGPoint)location
{
        UIView *focusRing;
        
        focusRing                    = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        focusRing.alpha              = 0.0;
        focusRing.backgroundColor    = [UIColor colorWithWhite:1.0 alpha:0.5];
        focusRing.center             = location;
        focusRing.clipsToBounds      = YES;
        focusRing.layer.anchorPoint  = CGPointMake(0.5, 0.5);
        focusRing.layer.borderColor  = UIColor.whiteColor.CGColor;
        focusRing.layer.cornerRadius = focusRing.bounds.size.width / 2;
        
        [self addSubview:focusRing];
        [UIView animateWithDuration:0.15 animations:^{
                focusRing.alpha = 1.0;
        } completion:^(BOOL finished){
                [UIView animateWithDuration:0.15 delay:0.8 options:UIViewAnimationOptionCurveLinear animations:^{
                        focusRing.alpha = 0.0;
                        focusRing.transform = CGAffineTransformMakeScale(0.1, 0.1);
                } completion:^(BOOL finished){
                        [focusRing removeFromSuperview];
                }];
        }];
}

- (void)startRecording
{
        if ( !isRecording ) {
                AVCaptureConnection *videoConnection;
                NSError *error;
                NSURL *outputURL;
                NSFileManager *fileManager;
                
                fileManager = [NSFileManager defaultManager];
                
                for ( int i = 0; i < clipCount; i++ ) {
                        NSURL *staleFilePath;
                        
                        staleFilePath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%d.mov", NSTemporaryDirectory(), i]];
                        
                        if ( [fileManager fileExistsAtPath:staleFilePath.path] ) {
                                NSError *error;
                                
                                if ( ![fileManager removeItemAtURL:staleFilePath error:&error] )
                                        NSLog(@"%@", error);
                        }
                }
                
                clipCount       = 0;
                outputURL       = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%ld.mov", NSTemporaryDirectory(), (long)clipCount]];
                videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:movieOutput.connections];
                
                [session stopRunning];
                
                session.sessionPreset   = AVCaptureSessionPresetHigh;
                _viewfinder.frame       = self.bounds;
                videoPreviewLayer.frame = _viewfinder.bounds;
                
                if ( audioInput )
                        if ( [session canAddInput:audioInput] )
                                [session addInput:audioInput];
                
                if ( videoConnection.isVideoOrientationSupported )
                        videoConnection.videoOrientation = orientation;
                
                if ( videoConnection.supportsVideoStabilization )
                        videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                
                if ( [inputDevice lockForConfiguration:&error] ) {
                        if ( inputDevice.hasTorch ) {
                                if ( flashMode == FlashModeOn )
                                        inputDevice.torchMode = AVCaptureTorchModeOn;
                                else if ( flashMode == FlashModeOff )
                                        inputDevice.torchMode = AVCaptureTorchModeOff;
                                else if ( flashMode == FlashModeAuto )
                                        inputDevice.torchMode = AVCaptureTorchModeAuto;
                        }
                        
                        [inputDevice unlockForConfiguration];
                }
                
                if ( error )
                        NSLog(@"%@", error);
                
                [self disableGrid];
                [session startRunning];
                [movieOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        }
}

- (void)stopRecording
{
        if ( isRecording ) {
                isRecording                     = NO;
                recordingLengthIndicator.hidden = YES;
                
                if ( recordingTimer ) {
                        [recordingTimer invalidate];
                        
                        recordingTimer = nil;
                }
                
                [self enableGrid];
                [movieOutput stopRecording];
        }
}

- (void)toggleFlashMode
{
        NSError *error;
        
        if ( flashMode == FlashModeOn ) {
                flashMode                   = FlashModeOff;
                flashToggleButton.tintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
                
                [flashToggleButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
        } else if ( flashMode == FlashModeOff ) {
                flashMode = FlashModeAuto;
                flashToggleButton.tintColor = [UIColor colorWithRed:255/255.0 green:204/255.0 blue:0/255.0 alpha:1.0];
                
                [flashToggleButton setImage:[UIImage imageNamed:@"flash_auto"] forState:UIControlStateNormal];
        } else if ( flashMode == FlashModeAuto ) {
                flashMode                   = FlashModeOn;
                flashToggleButton.tintColor = [UIColor colorWithRed:255/255.0 green:204/255.0 blue:0/255.0 alpha:1.0];
                
                [flashToggleButton setImage:[UIImage imageNamed:@"flash_on"] forState:UIControlStateNormal];
        }
        
        if ( [inputDevice lockForConfiguration:&error] ) {
                if ( inputDevice.hasFlash ) {
                        if ( flashMode == FlashModeOn )
                                inputDevice.flashMode = AVCaptureFlashModeOn;
                        else if ( flashMode == FlashModeOff )
                                inputDevice.flashMode = AVCaptureFlashModeOff;
                        else if ( flashMode == FlashModeAuto )
                                inputDevice.flashMode = AVCaptureFlashModeAuto;
                }
                
                [inputDevice unlockForConfiguration];
        }
        
        if ( error )
                NSLog(@"%@", error);
}

- (void)toggleGrid
{
        if ( isShowingGrid ) {
                gridToggleButton.tintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
                
                [UIView animateWithDuration:0.2 animations:^{
                        gridView.alpha = 0.0;
                } completion:^(BOOL finished){
                        gridView.hidden = YES;
                }];
        } else {
                gridToggleButton.tintColor = [UIColor colorWithRed:255/255.0 green:204/255.0 blue:0/255.0 alpha:1.0];
                gridView.hidden            = NO;
                
                [UIView animateWithDuration:0.2 animations:^{
                        gridView.alpha = 1.0;
                }];
        }
        
        isShowingGrid = !isShowingGrid;
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isShowingGrid] forKey:NSUDKEY_CAMERA_GRID];
}

- (void)useFrontCamera
{
        NSError *error;
        CGPoint pointOfInterest;
        
        [session beginConfiguration];
        [session removeOutput:movieOutput];
        [session removeInput:videoInput];
        
        inputDevice        = [self frontCamera];
        isUsingFrontCamera = YES;
        pointOfInterest    = CGPointMake(0.5, 0.5); // Focus on the center of the screen at first.
        
        if ( [inputDevice lockForConfiguration:&error] ) {
                if ( [inputDevice isExposurePointOfInterestSupported] )
                        [inputDevice setExposurePointOfInterest:pointOfInterest];
                
                if ( [inputDevice isFocusPointOfInterestSupported] )
                        [inputDevice setFocusPointOfInterest:pointOfInterest];
                
                if ( [inputDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure] )
                        [inputDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                else if ( [inputDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] )
                        [inputDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                
                if ( [inputDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] )
                        [inputDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                else if ( [inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] )
                        [inputDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if ( [inputDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance] )
                        [inputDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                else if ( [inputDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance] )
                        [inputDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
                
                [inputDevice unlockForConfiguration];
        }
        
        if ( error )
                NSLog(@"%@", error);
        
        videoInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
        
        if ( [session canAddInput:videoInput] )
                [session addInput:videoInput];
        
        if ( [session canAddOutput:movieOutput] )
                [session addOutput:movieOutput];
        
        [session commitConfiguration];
        
        if ( error )
                NSLog(@"%@", error);
        
        if ( isRecording ) {
                NSURL *outputURL;
                
                outputURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%ld.mov", NSTemporaryDirectory(), (long)++clipCount]];
                
                [movieOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        }
}

- (void)useRearCamera
{
        NSError *error;
        CGPoint pointOfInterest;
        
        [session beginConfiguration];
        [session removeOutput:movieOutput];
        [session removeInput:videoInput];
        
        inputDevice        = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        isUsingFrontCamera = NO;
        pointOfInterest    = CGPointMake(0.5, 0.5); // Focus on the center of the screen at first.
        
        if ( [inputDevice lockForConfiguration:&error] ) {
                if ( [inputDevice isExposurePointOfInterestSupported] )
                        [inputDevice setExposurePointOfInterest:pointOfInterest];
                
                if ( [inputDevice isFocusPointOfInterestSupported] )
                        [inputDevice setFocusPointOfInterest:pointOfInterest];
                
                if ( [inputDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure] )
                        [inputDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                else if ( [inputDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] )
                        [inputDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                
                if ( [inputDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] )
                        [inputDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                else if ( [inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] )
                        [inputDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if ( [inputDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance] )
                        [inputDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                else if ( [inputDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance] )
                        [inputDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
                
                [inputDevice unlockForConfiguration];
        }
        
        if ( error )
                NSLog(@"%@", error);
        
        videoInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
        
        if ( [session canAddInput:videoInput] )
                [session addInput:videoInput];
        
        if ( [session canAddOutput:movieOutput] )
                [session addOutput:movieOutput];
        
        [session commitConfiguration];
        
        if ( error )
                NSLog(@"%@", error);
        
        if ( isRecording ) {
                NSURL *outputURL;
                
                outputURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%ld.mov", NSTemporaryDirectory(), (long)++clipCount]];
                
                [movieOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        }
}

@end
