//
//  Item.m
//  Repo
//
//  Created by Ali Mahouk on 17/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "Item.h"

@implementation Item


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                _created    = [NSDate date];
                _free       = YES;
                _identifier = [NSUUID UUID].UUIDString;
                _itemType   = ItemTypeNone;
                _modified   = [NSDate date];
                _moved      = [NSDate date];
        }
        
        return self;
}

- (BOOL)isEqual:(id)object
{
        Item *item;
        
        if ( object &&
             [object isKindOfClass:Item.class] ) {
                item = (Item *)object;
                
                if ( [item.identifier isEqualToString:_identifier] )
                        return YES;
        }
        
        return NO;
}

- (void)redraw
{
        [self setup];
}

- (void)setup
{
        self.backgroundColor   = UIColor.blackColor;
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        
        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        gradientLayer.colors = @[(id)[UIColor redColor].CGColor, (id)[UIColor blueColor].CGColor];
        
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.lineWidth = 0.5;
        shapeLayer.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        shapeLayer.fillColor = nil;
        shapeLayer.strokeColor = [UIColor blackColor].CGColor;
        gradientLayer.mask = shapeLayer;
        
        [self.layer addSublayer:gradientLayer];
        
        if ( _collectionIdentifier ) { // Items inside collections have no shadows.
                self.layer.shadowRadius = 0.0;
        } else {
                self.layer.shadowColor   = UIColor.grayColor.CGColor;
                self.layer.shadowOffset  = CGSizeMake(0, 0);
                self.layer.shadowOpacity = 0.8;
                self.layer.shadowRadius  = 8.0;
        }
        
}


@end
