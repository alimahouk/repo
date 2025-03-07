//
//  InkView.h
//  Repo
//
//  Created by Ali Mahouk on 14/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

@class InkView;

@protocol InkViewDelegate<NSObject>
@optional

- (void)inkViewWasStroked:(InkView *)inkView;

@end

@interface InkView : UIImageView
{
        CGPoint currentPoint;
        CGPoint previousPoint1;
        CGPoint previousPoint2;
}

@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) BOOL drawingEnabled;
@property (nonatomic, weak) id <InkViewDelegate> delegate;

- (void)clear;

@end
