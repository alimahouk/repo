//
//  CollectionExplorerViewController.h
//  Repo
//
//  Created by Ali Mahouk on 22/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVKit;
@import MapKit;
@import UIKit;
@import WebKit;

@class Item;

@interface CollectionExplorerViewController : UIViewController <MKMapViewDelegate,
                                                                UIScrollViewDelegate,
                                                                UITextViewDelegate,
                                                                WKNavigationDelegate>
{
        AVPlayer *moviePlayer;
        AVPlayerViewController *playerViewController;
        CLGeocoder *geocoder;
        MKMapView *map;
        UIImageView *imageView;
        UIImageView *inkLayer;
        UILabel *dateLabel;
        UILabel *linkTitleLabel;
        UILabel *linkURLLabel;
        UILabel *timeLabel;
        UINavigationBar *navigationBar;
        UISegmentedControl *mapTypePicker;
        UITextView *textView;
        UIToolbar *mapToolbar;
        UIToolbar *browserToolbar;
        UIView *browserPageInfoView;
        WKWebView *browserView;
        BOOL shouldShowStatusBar;
}

@property (nonatomic) Item *item;
@property (nonatomic) NSArray *dataSource;

@end
