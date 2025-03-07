//
//  CaptureButton.m
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "CaptureButton.h"

@implementation CaptureButton

- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                UIBlurEffect *blurEffect;
                UIBlurEffect *buttonBlurEffect;
                
                isPress          = NO;
                blurEffect       = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                buttonBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
                
                self.bounds             = CGRectMake(0, 0, 64, 64);
                self.clipsToBounds      = YES;
                self.effect             = blurEffect;
                self.layer.cornerRadius = self.bounds.size.width / 2;
                
                button                    = [[UIVisualEffectView alloc] initWithEffect:buttonBlurEffect];
                button.center             = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
                button.clipsToBounds      = YES;
                button.bounds             = CGRectMake(0, 0, 32, 32);
                button.layer.anchorPoint  = CGPointMake(0.5, 0.5);
                button.layer.cornerRadius = button.bounds.size.width / 2;
                
                [self.contentView addSubview:button];
        }
        
        return self;
}

/**
 * Called if the button was held down.
 */
- (void)captureButtonWasPressed
{
        if ( [_delegate respondsToSelector:@selector(captureButtonWasPressed:)] )
                [_delegate captureButtonWasPressed:self];
}

/**
 * Called after the held-down button is released.
 */
- (void)captureButtonWasReleased
{
        if ( [_delegate respondsToSelector:@selector(captureButtonWasReleased:)] )
                [_delegate captureButtonWasReleased:self];
}

- (void)captureButtonWasTapped
{
        if ( [_delegate respondsToSelector:@selector(captureButtonWasTapped:)] )
                [_delegate captureButtonWasTapped:self];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
        UIVisualEffect *blurEffect;
        
        blurEffect   = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        contactTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 repeats:NO block:^(NSTimer *timer){
                isPress = YES;
                
                [self captureButtonWasPressed];
        }];
        
        [UIView animateWithDuration:0.1 animations:^{
                self.effect    = blurEffect;
                self.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
        UIVisualEffect *blurEffect;
        
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        [UIView animateWithDuration:0.2 animations:^{
                self.effect    = blurEffect;
                self.transform = CGAffineTransformIdentity;
        }];
        [contactTimer invalidate];
        
        contactTimer = nil;
        isPress      = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
        UIVisualEffect *blurEffect;
        
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        [UIView animateWithDuration:0.1 animations:^{
                self.effect    = blurEffect;
                self.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished){
                [UIView animateWithDuration:0.15 animations:^{
                        self.transform = CGAffineTransformIdentity;
                }];
        }];
        [contactTimer invalidate];
        
        if ( isPress )
                [self captureButtonWasReleased];
        else
                [self captureButtonWasTapped];
        
        contactTimer = nil;
        isPress      = NO;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
        UITouch *touch;
        CGPoint location;
        
        touch    = [touches anyObject];
        location = [touch locationInView:self];
        
        if ( location.x < 0 ||
             location.x > self.bounds.size.width ||
             location.y < 0 ||
             location.y > self.bounds.size.height) {
                [self touchesCancelled:touches withEvent:event];
        }
}

@end
