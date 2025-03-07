//
//  InkWell.h
//  Repo
//
//  Created by Ali Mahouk on 14/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

@interface InkWell : UIButton
{
        CAGradientLayer *lightGradientLayer;
        CAGradientLayer *shadowGradientLayer;
        UIColor *fillColor;
        UIView *color;
}

@property (nonatomic) CGColorRef borderColor;

- (void)activate;
- (void)deactivate;

@end
