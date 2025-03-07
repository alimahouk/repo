//
//  InkWell.m
//  Repo
//
//  Created by Ali Mahouk on 14/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "InkWell.h"

@implementation InkWell


- (CGColorRef)borderColor
{
        return color.layer.borderColor;
}

- (instancetype)initWithFrame:(CGRect)frame
{
        self = [super initWithFrame:frame];
        
        if ( self )
                [self setup];
        
        return self;
}

- (UIColor *)backgroundColor
{
        return fillColor;
}

- (void)activate
{
        [UIView animateWithDuration:0.3 animations:^{
                color.transform = CGAffineTransformMakeScale(0.7, 0.7);
        }];
}

- (void)deactivate
{
        [UIView animateWithDuration:0.3 animations:^{
                color.transform = CGAffineTransformIdentity;
        }];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
        fillColor = backgroundColor;
        
        if ( [fillColor isEqual:UIColor.clearColor] )
                color.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
        else
                color.backgroundColor = backgroundColor;
}

- (void)setBounds:(CGRect)bounds
{
        [super setBounds:bounds];
        
        color.frame              = CGRectMake(5, 5, bounds.size.width - 10, bounds.size.height - 10);
        color.layer.cornerRadius = color.bounds.size.width / 3;
}

- (void)setFrame:(CGRect)frame
{
        [super setFrame:frame];
        
        color.frame              = CGRectMake(5, 5, frame.size.width - 10, frame.size.height - 10);
        color.layer.cornerRadius = color.bounds.size.width / 3;
}

- (void)setup
{
        self.backgroundColor = UIColor.clearColor;
        
        color                    = [[UIView alloc] initWithFrame:CGRectMake(5, 5, self.bounds.size.width - 10, self.bounds.size.height - 10)];
        color.clipsToBounds      = YES;
        color.layer.borderColor  = UIColor.blackColor.CGColor;
        color.layer.borderWidth  = 3.0;
        color.layer.cornerRadius = color.bounds.size.width / 3;
        
        [self addSubview:color];
}


@end
