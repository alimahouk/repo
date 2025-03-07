//
//  LocationViewController.h
//  Repo
//
//  Created by Ali Mahouk on 5/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import MapKit;

#import "ViewController.h"

@class LocationItem;
@class LocationViewController;

@protocol LocationViewControllerDelegate<NSObject>
@optional

- (void)locationView:(LocationViewController *)locationViewController didHandOverItem:(LocationItem *)item;

@end

@interface LocationViewController : ViewController <MKMapViewDelegate>
{
        MKMapView *map;
        UINavigationBar *navigationBar;
        UISegmentedControl *mapTypePicker;
        UISelectionFeedbackGenerator *selectionFeedbackGenerator;
        BOOL didZoomToUserLocation;
        NSOperatingSystemVersion iOSVersionCheck;
}

@property (nonatomic) BOOL handOverOnUpdate;
@property (nonatomic, weak) id <LocationViewControllerDelegate> delegate;

- (void)save;

@end
