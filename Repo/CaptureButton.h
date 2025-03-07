//
//  CaptureButton.h
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

@class CaptureButton;

@protocol CaptureButtonDelegate<NSObject>
@optional

- (void)captureButtonWasPressed:(CaptureButton *)button;
- (void)captureButtonWasReleased:(CaptureButton *)button;
- (void)captureButtonWasTapped:(CaptureButton *)button;

@end

@interface CaptureButton : UIVisualEffectView
{
        NSTimer *contactTimer;
        UIVisualEffectView *button;
        BOOL isPress;
}

@property (nonatomic, weak) id <CaptureButtonDelegate> delegate;

@end
