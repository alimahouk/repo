//
//  LocationViewController.m
//  Repo
//
//  Created by Ali Mahouk on 5/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "LocationViewController.h"

#import "LocationItem.h"

@implementation LocationViewController


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                _handOverOnUpdate     = NO;
                iOSVersionCheck       = (NSOperatingSystemVersion){10, 0, 0};
                didZoomToUserLocation = NO;
                
                if ( [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOSVersionCheck] )
                        selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
                
                self.tabBarItem.image         = [UIImage imageNamed:@"map"];
                self.tabBarItem.selectedImage = [UIImage imageNamed:@"map_selected"];
                self.title                    = @"Map";
        }
        
        return self;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(nonnull id<MKAnnotation>)annotation
{
        MKPinAnnotationView *view;
        
        if ( [annotation isKindOfClass:MKUserLocation.class] )
                return nil;
        
        view                = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"AnnotationIdentifier"];
        view.animatesDrop   = YES;
        view.canShowCallout = YES;
        
        return view;
}

- (UIImage *)screenshot
{
        UIImage *snapshot;
        
        UIGraphicsBeginImageContextWithOptions(map.bounds.size, NO, 0.0);
        
        [map drawViewHierarchyInRect:map.bounds afterScreenUpdates:YES];
        
        snapshot = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return snapshot;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
        return UIStatusBarStyleLightContent;
}

- (void)didChangeControllerFocus:(BOOL)focused
{
        if ( !focused ) {
                didZoomToUserLocation = NO; // Reset this.
        }
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)loadView
{
        UIBarButtonItem *saveLocationButton;
        UINavigationItem *navigationItem;
        
        [super loadView];
        
        map                       = [[MKMapView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64)];
        map.delegate              = self;
        map.showsBuildings        = YES;
        map.showsCompass          = YES;
        map.showsPointsOfInterest = YES;
        map.showsScale            = YES;
        map.showsUserLocation     = YES;
        
        mapTypePicker           = [[UISegmentedControl alloc] initWithItems:@[@"Standard", @"Hybrid", @"Satellite"]];
        mapTypePicker.tintColor = UIColor.whiteColor;
        
        [mapTypePicker addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
        [mapTypePicker sizeToFit];
        
        navigationBar              = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
        navigationBar.barTintColor = UIColor.blackColor;
        
        saveLocationButton = [[UIBarButtonItem alloc] initWithTitle:@"Mark" style:UIBarButtonItemStyleDone target:self action:@selector(save)];
        
        navigationItem                    = [[UINavigationItem alloc] initWithTitle:@""];
        navigationItem.hidesBackButton    = YES;
        navigationItem.rightBarButtonItem = saveLocationButton;
        navigationItem.titleView = mapTypePicker;
        
        [navigationBar pushNavigationItem:navigationItem animated:NO];
        [navigationBar addSubview:mapTypePicker];
        [self.view addSubview:map];
        [self.view addSubview:navigationBar];
}

- (void)mapTypeChanged:(UISegmentedControl *)segmentedControl
{
        [self setMapTypeForSegmentIndex:segmentedControl.selectedSegmentIndex];
        [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithLong:segmentedControl.selectedSegmentIndex] forKey:@"PreferredMapType"];
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
        NSLog(@"%@", error);
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
        if ( !didZoomToUserLocation ) {
                MKCoordinateRegion region;
                MKCoordinateSpan span;
                
                span.latitudeDelta  = 0.01;
                span.longitudeDelta = 0.01;
                
                region.center = userLocation.coordinate;
                region.span   = span;
                
                [mapView setRegion:region animated:YES];
                [mapView regionThatFits:region];
                
                didZoomToUserLocation = YES;
        }
        
        if ( _handOverOnUpdate )
                [self save];
}

- (void)save
{
        if ( map.userLocation.location ) {
                MKPointAnnotation *annotation;
                
                annotation            = [MKPointAnnotation new];
                annotation.coordinate = map.userLocation.coordinate;
                
                [map addAnnotation:annotation];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        LocationItem *item;
                        
                        item             = [[LocationItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                        item.coordinates = map.userLocation.location;
                        item.snapshot    = [self screenshot];
                        
                        [item redraw];
                        
                        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                                [selectionFeedbackGenerator selectionChanged];
                        
                        if ( [_delegate respondsToSelector:@selector(locationView:didHandOverItem:)] )
                                [_delegate locationView:self didHandOverItem:item];
                        
                        for ( MKPointAnnotation *a in map.annotations )
                                [map removeAnnotation:a];
                });
        } else {
                UIAlertAction *dismiss;
                UIAlertController *alert;
                
                dismiss = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil];
                alert   = [UIAlertController alertControllerWithTitle:@"Location Error"
                                                              message:[NSString stringWithFormat:@"Could not detect your current location. Make sure you've allowed %@ to access your location in the Settings app.", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"]]
                                                       preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:dismiss];
                [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
        
        _handOverOnUpdate = NO;
}

- (void)setMapTypeForSegmentIndex:(long)index
{
        switch ( index ) {
                case 0:
                        map.mapType = MKMapTypeStandard;
                        break;
                        
                case 1:
                        map.mapType = MKMapTypeHybrid;
                        break;
                        
                case 2:
                        map.mapType = MKMapTypeSatellite;
                        break;
                        
                default:
                        break;
        }
}

- (void)viewDidLoad
{
        NSNumber *preferredMapType;
        
        [super viewDidLoad];
        
        preferredMapType = [NSUserDefaults.standardUserDefaults objectForKey:@"PreferredMapType"];
        
        if ( preferredMapType )
                mapTypePicker.selectedSegmentIndex = preferredMapType.longValue;
        else
                mapTypePicker.selectedSegmentIndex = 0;
        
        [self setMapTypeForSegmentIndex:mapTypePicker.selectedSegmentIndex];
}


@end
