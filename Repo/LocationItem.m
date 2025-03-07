//
//  LocationItem.m
//  Repo
//
//  Created by Ali Mahouk on 31/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "LocationItem.h"

@implementation LocationItem


- (instancetype)initAtPoint:(CGPoint)point
{
        LocationItem *item;
        
        item        = [LocationItem new];
        item.center = point;
        
        return item;
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
        if ( fullyRendered ) {
                NSTimer *timer;
                
                timer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer *timer){
                        [self setThumbnailAndRemoveFromView:YES];
                }];
        }
}

- (MKMapType)preferredMapType
{
        NSNumber *preferredMapType;
        
        preferredMapType = [NSUserDefaults.standardUserDefaults objectForKey:@"PreferredMapType"];
        
        if ( preferredMapType ) {
                switch ( preferredMapType.longValue ) {
                        case 1:
                                return MKMapTypeHybrid;
                                
                        case 2:
                                return MKMapTypeSatellite;
                                
                        default:
                                return MKMapTypeStandard;
                }
        }
        
        return MKMapTypeStandard;
}

- (void)setBounds:(CGRect)bounds
{
        [super setBounds:bounds];
        
        thumbnail.frame     = CGRectMake(0, 0, bounds.size.width, bounds.size.height);;
        locationLabel.frame = CGRectMake(0, bounds.size.height - locationLabel.bounds.size.height, bounds.size.width, locationLabel.bounds.size.height);
}

- (void)setFrame:(CGRect)frame
{
        [super setFrame:frame];
        
        thumbnail.frame     = CGRectMake(0, 0, frame.size.width, frame.size.height);
        locationLabel.frame = CGRectMake(0, frame.size.height - locationLabel.bounds.size.height, frame.size.width, locationLabel.bounds.size.height);
}

- (void)setThumbnailAndRemoveFromView:(BOOL)remove
{
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
        
        [map drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
        
        thumbnail.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        if ( remove ) {
                [map removeFromSuperview];
                
                map = nil;
        }
}

- (void)setup
{
        [super setup];
        
        self.itemType = ItemTypeLocation;
        
        if ( thumbnail )
                [thumbnail removeFromSuperview];
        
        if ( locationLabel )
                [locationLabel removeFromSuperview];
        
        thumbnail = [UIImageView new];
        
        locationLabel                                    = [UITextView new];
        locationLabel.backgroundColor                    = [UIColor colorWithWhite:1.0 alpha:0.7];
        locationLabel.editable                           = NO;
        locationLabel.font                               = [UIFont systemFontOfSize:12];
        locationLabel.scrollEnabled                      = NO;
        locationLabel.scrollsToTop                       = NO;
        locationLabel.textColor                          = UIColor.grayColor;
        locationLabel.textContainer.maximumNumberOfLines = 2;
        locationLabel.textContainer.lineBreakMode        = NSLineBreakByTruncatingTail;
        locationLabel.textContainerInset                 = UIEdgeInsetsMake(5, 5, 5, 5);
        locationLabel.userInteractionEnabled             = NO;
        
        if ( self.location ) {
                locationLabel.hidden = NO;
                locationLabel.text   = self.location;
        } else {
                locationLabel.hidden = YES;
        }
        
        [locationLabel sizeToFit];
        
        self.bounds = CGRectMake(0, 0, ITEM_PREVIEW_SIZE, ITEM_PREVIEW_SIZE);
        
        [self addSubview:thumbnail];
        [self addSubview:locationLabel];
        
        if ( self.coordinates &&
             !thumbnail.image ) {
                MKPointAnnotation *annotation;
                MKCoordinateRegion region;
                MKCoordinateSpan span;
                
                annotation            = [[MKPointAnnotation alloc] init];
                annotation.coordinate = self.coordinates.coordinate;
                
                map                        = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, ITEM_PREVIEW_SIZE, ITEM_PREVIEW_SIZE)];
                map.delegate               = self;
                map.mapType                = [self preferredMapType];
                map.userInteractionEnabled = NO;
                
                span.latitudeDelta  = 0.01;
                span.longitudeDelta = 0.01;
                
                region.center = self.coordinates.coordinate;
                region.span   = span;
                
                [map addAnnotation:annotation];
                [map setRegion:region animated:NO];
                [map regionThatFits:region];
                [self addSubview:map];
                [self sendSubviewToBack:map];
                [self setThumbnailAndRemoveFromView:NO];
        }
}


@end
