//
//  InkView.m
//  Repo
//
//  Created by Ali Mahouk on 14/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "InkView.h"

#import "constants.h"

@implementation InkView


- (instancetype)init
{
        self = [super init];
        
        if ( self )
                [self setup];
        
        return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
        self = [super initWithFrame:frame];
        
        if ( self )
                [self setup];
        
        return self;
}

- (CGPoint)midForPoint:(CGPoint)p1 and:(CGPoint)p2
{
        return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

- (void)clear
{
        self.image = nil;
}

- (void)setup
{
        self.backgroundColor        = UIColor.clearColor;
        self.contentMode            = UIViewContentModeTop;
        self.multipleTouchEnabled   = NO;
        self.opaque                 = NO;
        self.userInteractionEnabled = YES;
        
        _drawingEnabled = NO;
        _strokeColor    = DEFAULT_STROKE_COLOR;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
        UITouch *touch;
        
        touch          = [touches anyObject];
        previousPoint1 = [touch previousLocationInView:self];
        previousPoint2 = [touch previousLocationInView:self];
        currentPoint   = [touch locationInView:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
            if ( _drawingEnabled )
                    if ( [_delegate respondsToSelector:@selector(inkViewWasStroked:)] )
                            [_delegate inkViewWasStroked:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
        UITouch *touch;
        
        touch          = [touches anyObject];
        previousPoint2 = previousPoint1;
        previousPoint1 = [touch previousLocationInView:self];
        currentPoint   = [touch locationInView:self];
        
        if ( _drawingEnabled ) {
                CGContextRef context;
                CGPoint mid1;
                CGPoint mid2;
                CGSize contextSize;
                
                if ( self.image )
                        contextSize = self.image.size;
                else
                        contextSize = self.bounds.size;
                
                // Calculate mid points.
                mid1 = [self midForPoint:previousPoint1 and:previousPoint2];
                mid2 = [self midForPoint:currentPoint and:previousPoint1];
                
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
                
                context = UIGraphicsGetCurrentContext();
                
                [self.image drawInRect:CGRectMake(0, 0, self.image.size.width, self.image.size.height)];
                
                CGContextMoveToPoint(context, mid1.x, mid1.y);
                CGContextAddQuadCurveToPoint(context, previousPoint1.x, previousPoint1.y, mid2.x, mid2.y); // Using QuadCurve is the key.
                CGContextSetLineCap(context, kCGLineCapRound);
                
                if ( [_strokeColor isEqual:UIColor.clearColor] ) {
                        CGContextSetLineWidth(context, touch.majorRadius); // The eraser is larger than the ink stroke.
                        CGContextSetBlendMode(context, kCGBlendModeClear);
                } else {
                        CGContextSetLineWidth(context, DEFAULT_STROKE_SIZE);
                        CGContextSetStrokeColorWithColor(context, _strokeColor.CGColor);
                }
                
                CGContextStrokePath(context);
                
                self.image = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
        }
}

@end
