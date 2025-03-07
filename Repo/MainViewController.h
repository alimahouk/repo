//
//  MainViewController.h
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import CoreLocation;
@import UIKit;

#import "CameraViewController.h"
#import "LibraryViewController.h"
#import "LocationViewController.h"
#import "Reachability.h"
#import "TextEditorViewController.h"

@class DarkNavigationController;

@interface MainViewController : UITabBarController <CameraViewControllerDelegate,
                                                CLLocationManagerDelegate,
                                                LibraryViewControllerDelegate,
                                                LocationViewControllerDelegate,
                                                TextEditorViewControllerDelegate,
                                                UITabBarControllerDelegate>
{
        CameraViewController *cameraController;
        CLGeocoder *geocoder;
        CLLocation *currentCoordinates;
        CLLocationManager *locationManager;
        DarkNavigationController *libraryNavigationController;
        LibraryViewController *libraryController;
        LocationViewController *locationController;
        NSString *currentLocation;
        NSTimer *locationUpdateTimer;
        TextEditorViewController *textEditorController;
        UIButton *itemEditZone;
        UIButton *itemDeletionZone;
        UICollisionBehavior *collisionBehavior;
        UIDynamicAnimator *animator;
        UIGravityBehavior *gravityBehavior;
        UIImpactFeedbackGenerator *impactFeedbackGenerator;
        ViewController *activeController;
        BOOL didAuthorizeLocation;
        BOOL isHighlightingItemDeletionZone;
        BOOL isHighlightingItemEditZone;
        BOOL isShowingItemDeletionZone;
        BOOL isShowingItemEditZone;
        BOOL shouldShowItems;
        NetworkStatus networkStatus;
        NSOperatingSystemVersion iOSVersionCheck;
}

- (void)didEnterBackground;
- (void)didEnterForeground;
- (void)showCamera;
- (void)showLibrary;
- (void)showLocationPickerAndMark:(BOOL)markLocation;
- (void)showTextEditorAndFocus:(BOOL)focus;

@end

