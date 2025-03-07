//
//  LocationItem.h
//  Repo
//
//  Created by Ali Mahouk on 31/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import MapKit;

#import "Item.h"

@interface LocationItem : Item <MKMapViewDelegate>
{
        MKMapView *map;
        UIImageView *thumbnail;
        UITextView *locationLabel;
}

- (instancetype)initAtPoint:(CGPoint)point;

@end
