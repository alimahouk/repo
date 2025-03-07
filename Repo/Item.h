//
//  Item.h
//  Repo
//
//  Created by Ali Mahouk on 17/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import CoreLocation;
@import UIKit;

#import "constants.h"

@interface Item : UIView

@property (nonatomic) CLLocation *coordinates;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSDate *modified;
@property (nonatomic) NSDate *moved;
@property (nonatomic) NSString *collectionIdentifier;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *location;
@property (nonatomic) UIDynamicItemBehavior *dynamicBehavior;
@property (nonatomic) UIPushBehavior *pushBehavior;
@property (nonatomic) UIImage *snapshot;
@property (nonatomic) BOOL free;
@property (nonatomic) ItemType itemType;

- (void)redraw;
- (void)setup;

@end
