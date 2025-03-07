//
//  CollectionExplorerViewController.m
//  Repo
//
//  Created by Ali Mahouk on 22/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVFoundation;
@import CoreText;

#import "CollectionExplorerViewController.h"

#import "AppDelegate.h"
#import "LinkItem.h"
#import "LocationItem.h"
#import "MediaItem.h"
#import "TextItem.h"
#import "Util.h"

@implementation CollectionExplorerViewController


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                geocoder            = [CLGeocoder new];
                shouldShowStatusBar = YES;
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

- (NSData *)exportPDF
{
        NSMutableData *PDFData;
        TextItem *item;
        CTFramesetterRef framesetter;
        
        item        = (TextItem *)_item;
        framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)item.string);
        
        if ( framesetter ) {
                CFRange currentRange;
                CGRect pageRect;
                NSInteger currentPage;
                BOOL done;
                
                PDFData = [NSMutableData data];
                
                // Create the PDF context using the default page size of 612 x 792.
                UIGraphicsBeginPDFContextToData(PDFData, CGRectZero, nil);
                
                currentRange = CFRangeMake(0, 0);
                currentPage  = 0;
                done         = NO;
                pageRect     = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height + 90);
                
                do {
                        CGContextRef currentContext;
                        
                        // Mark the beginning of a new page.
                        UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
                        
                        // Draw a page number at the bottom of each page.
                        currentPage++;
                        
                        currentContext = UIGraphicsGetCurrentContext();
                        
                        // Color the page.
                        CGContextSetFillColorWithColor(currentContext, [UIColor colorWithRed:251/255.0 green:251/255.0 blue:240/255.0 alpha:1.0].CGColor);
                        CGContextFillRect(currentContext, pageRect);
                        
                        if ( currentPage == 1 )
                                [self drawPDFDate];
                        
                        [self drawPDFPageNumber:currentPage];
                        
                        // Render the current page and update the current range to
                        // point to the beginning of the next page.
                        currentRange = [self renderPage:currentPage withTextRange:currentRange andFramesetter:framesetter];
                        
                        // If we're at the end of the text, exit the loop.
                        if ( currentRange.location == CFAttributedStringGetLength((CFAttributedStringRef)item.string) )
                                done = YES;
                } while ( !done );
                
                // Close the PDF context and write the contents out.
                UIGraphicsEndPDFContext();
                
                // Release the framewetter.
                CFRelease(framesetter);
                
        } else {
                NSLog(@"Could not create the framesetter needed to lay out the atrributed string.");
        }
        
        return PDFData;
}

- (BOOL)prefersStatusBarHidden
{
        return !shouldShowStatusBar;
}

- (CFRange)renderPage:(NSInteger)pageNumber withTextRange:(CFRange)currentRange andFramesetter:(CTFramesetterRef)framesetter
{
        // Get the graphics context.
        CGContextRef currentContext;
        CGMutablePathRef framePath;
        CGRect frameRect;
        NSInteger textHeight;
        TextItem *item;
        __block BOOL containsImages;
        
        containsImages = NO;
        currentContext = UIGraphicsGetCurrentContext();
        item           = (TextItem *)_item;
        textHeight     = UIScreen.mainScreen.bounds.size.height;
        
        if ( pageNumber == 1 ) {
                textHeight -= 90;
        }
        /*
         * Put the text matrix into a known state. This ensures
         * that no old scaling factors are left in place.
         */
        CGContextSetTextMatrix(currentContext, CGAffineTransformIdentity);
        
        /* Create a path object to enclose the text. Use 40 point
         * margins to the right & left of the text, & bigger margins
         * at the top & bottom.
         */
        frameRect = CGRectMake(35, -35, UIScreen.mainScreen.bounds.size.width - 80, textHeight);
        framePath = CGPathCreateMutable();
        
        CGPathAddRect(framePath, NULL, frameRect);
        
        /*
         * Get the frame that will do the rendering.
         * The currentRange variable specifies only the starting point. The framesetter
         * lays out as much text as will fit into the frame.
         */
        CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, NULL);
        
        CGPathRelease(framePath);
        
        /*[item.string enumerateAttribute:NSAttachmentAttributeName
                                inRange:NSMakeRange(0, item.string.length)
                                options:0
                             usingBlock:^(id value, NSRange range, BOOL *stop){
                                     if ( [value isKindOfClass:NSTextAttachment.class] ) {
                                             NSTextAttachment *attachment;
                                             UIImage *image;
                                             
                                             attachment = (NSTextAttachment *)value;
                                             
                                             if ( attachment.image )
                                                     image = attachment.image;
                                             else
                                                     image = [attachment imageForBounds:attachment.bounds textContainer:nil characterIndex:range.location];
                                             
                                             if ( image )
                                                     containsImages = YES;
                                     }
        }];
        
        if ( !containsImages ) {
                if ( [(TextItem *)_item ink] ) {
                        UIImage *ink;
                        CGImageRef imageRef;
                        CGRect inkRect;
                        
                        if ( pageNumber == 1 )
                                inkRect = CGRectMake(0 * inkLayer.image.scale,
                                                     (inkLayer.image.size.height * (pageNumber - 1)) * inkLayer.image.scale,
                                                     inkLayer.image.size.width * inkLayer.image.scale,
                                                     UIScreen.mainScreen.bounds.size.height * inkLayer.image.scale);
                        else
                                inkRect = CGRectMake(0 * inkLayer.image.scale,
                                                     (inkLayer.image.size.height * (pageNumber - 1)) * inkLayer.image.scale,
                                                     inkLayer.image.size.width * inkLayer.image.scale,
                                                     UIScreen.mainScreen.bounds.size.height * inkLayer.image.scale);
                        
                        imageRef = CGImageCreateWithImageInRect(inkLayer.image.CGImage, inkRect);
                        ink   = [UIImage imageWithCGImage:imageRef scale:inkLayer.image.scale orientation:inkLayer.image.imageOrientation];
                        
                        CGImageRelease(imageRef);
                        
                        if ( pageNumber == 1 ) {
                                [ink drawAtPoint:CGPointMake(0, 25 * inkLayer.image.scale)];
                        } else {
                                [ink drawAtPoint:CGPointMake(0, 15 * inkLayer.image.scale)];
                        }
                        
                        
                }
        }*/
        
        /*
         * Core Text draws from the bottom-left corner up, so flip
         * the current transform prior to drawing.
         */
        CGContextTranslateCTM(currentContext, 0, UIScreen.mainScreen.bounds.size.height);
        CGContextScaleCTM(currentContext, 1.0, -1.0);
        
        // Draw the frame.
        CTFrameDraw(frameRef, currentContext);
        
        // Update the current range based on what was drawn.
        currentRange           = CTFrameGetVisibleStringRange(frameRef);
        currentRange.location += currentRange.length;
        currentRange.length    = 0;
        
        CFRelease(frameRef);
        
        return currentRange;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
        return UIStatusBarStyleLightContent;
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ) {
                UIView *view;
                CGPoint locationInSuperview;
                CGPoint locationInView;
                
                view                   = gestureRecognizer.view;
                locationInSuperview    = [gestureRecognizer locationInView:view.superview];
                locationInView         = [gestureRecognizer locationInView:view];
                view.layer.anchorPoint = CGPointMake(locationInView.x / view.bounds.size.width, locationInView.y / view.bounds.size.height);
                view.center            = locationInSuperview;
        }
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (void)didPinchView:(UIPinchGestureRecognizer *)gestureRecognizer
{
        [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
        
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ||
             gestureRecognizer.state == UIGestureRecognizerStateChanged ) {
                if ( gestureRecognizer.state == UIGestureRecognizerStateBegan )
                        [self hideNavigationBar];
                
                gestureRecognizer.view.transform = CGAffineTransformScale(gestureRecognizer.view.transform, gestureRecognizer.scale, gestureRecognizer.scale);
                gestureRecognizer.scale          = 1;
        } else {
                [UIView animateWithDuration:0.3 animations:^{
                        gestureRecognizer.view.transform = CGAffineTransformIdentity;
                }];
        }
}

- (void)didTapView:(UITapGestureRecognizer *)gestureRecognizer
{
        if ( navigationBar.hidden )
                [self showNavigationBar];
        else
                [self hideNavigationBar];
}

- (void)dismissView
{
        if ( moviePlayer ) {
                [moviePlayer pause];
                [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:moviePlayer.currentItem];
                
                moviePlayer = nil;
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)drawPDFDate
{
        NSDateFormatter *dateFormatter;
        NSDictionary *dateAttributes;
        NSDictionary *timeAttributes;
        NSMutableParagraphStyle *paragraphStyle;
        NSString *dateString;
        NSString *timeString;
        CGRect finalRectDate;
        CGRect finalRectTime;
        CGRect stringRectDate;
        CGRect stringRectTime;
        CGSize maxSize;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"d MMM yyyy"];
        
        dateString = [[dateFormatter stringFromDate:_item.created] uppercaseString];
        
        [dateFormatter setDateFormat:@"hh:mm a"];
        
        maxSize    = UIScreen.mainScreen.bounds.size;
        timeString = [[dateFormatter stringFromDate:_item.created] uppercaseString];
        
        paragraphStyle               = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        
        dateAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:22],
                           NSParagraphStyleAttributeName:paragraphStyle};
        timeAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Georgia-Italic" size:UIFont.systemFontSize],
                           NSParagraphStyleAttributeName:paragraphStyle};
        stringRectDate = [dateString boundingRectWithSize:maxSize
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:dateAttributes
                                                  context:nil];
        stringRectTime = [timeString boundingRectWithSize:maxSize
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:timeAttributes
                                                  context:nil];
        finalRectDate  = CGRectMake(((UIScreen.mainScreen.bounds.size.width - stringRectDate.size.width) / 2.0),
                                    50,
                                    stringRectDate.size.width,
                                    stringRectDate.size.height);
        finalRectTime  = CGRectMake(((UIScreen.mainScreen.bounds.size.width - stringRectTime.size.width) / 2.0),
                                    finalRectDate.origin.y + finalRectDate.size.height,
                                    stringRectTime.size.width,
                                    stringRectTime.size.height);
        
        [dateString drawInRect:finalRectDate withAttributes:dateAttributes];
        [timeString drawInRect:finalRectTime withAttributes:timeAttributes];
}

- (void)drawPDFPageNumber:(NSInteger)pageNum
{
        NSDictionary *attributes;
        NSMutableParagraphStyle *paragraphStyle;
        NSString *pageString;
        CGRect finalRect;
        CGRect pageStringRect;
        CGSize maxSize;
        
        maxSize    = UIScreen.mainScreen.bounds.size;
        pageString = [NSString stringWithFormat:@"%ld", (long)pageNum];
        
        paragraphStyle               = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        
        attributes     = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                           NSParagraphStyleAttributeName:paragraphStyle};
        pageStringRect = [pageString boundingRectWithSize:maxSize
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil];
        finalRect      = CGRectMake(((UIScreen.mainScreen.bounds.size.width - pageStringRect.size.width) / 2.0),
                                    UIScreen.mainScreen.bounds.size.height + 35,
                                    pageStringRect.size.width,
                                    pageStringRect.size.height);
        
        [pageString drawInRect:finalRect withAttributes:attributes];
}

- (void)getCurrentDate
{
        NSDateFormatter *dateFormatter;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"d MMM yyyy"];
        
        dateLabel.text = [[dateFormatter stringFromDate:_item.created] uppercaseString];
        
        [dateFormatter setDateFormat:@"hh:mm a"];
        
        timeLabel.text      = [[dateFormatter stringFromDate:_item.created] uppercaseString];
        
        [dateLabel sizeToFit];
        [timeLabel sizeToFit];
        
        dateLabel.frame = CGRectMake((self.view.bounds.size.width / 2) - (dateLabel.bounds.size.width / 2),
                                     27,
                                     dateLabel.bounds.size.width,
                                     dateLabel.bounds.size.height);
        timeLabel.frame = CGRectMake((self.view.bounds.size.width / 2) - (timeLabel.bounds.size.width / 2),
                                     dateLabel.frame.origin.y + dateLabel.bounds.size.height,
                                     timeLabel.bounds.size.width,
                                     timeLabel.bounds.size.height);
}

- (void)hideNavigationBar
{
        shouldShowStatusBar = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
                navigationBar.alpha = 0.0;
                
                [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished){
                navigationBar.hidden = YES;
        }];
}

- (void)loadInterfaceForLinkItem:(LinkItem *)item
{
        UIBarButtonItem *flexibleSpaceLeft;
        UIBarButtonItem *flexibleSpaceRight;
        UIBarButtonItem *pageInfoButtonItem;
        UIRefreshControl *refreshControl = [UIRefreshControl new];
        
        self.view.backgroundColor = UIColor.blackColor;
        
        browserView                                     = [[WKWebView alloc] initWithFrame:self.view.bounds];
        browserView.allowsBackForwardNavigationGestures = YES;
        browserView.scrollView.contentInset             = UIEdgeInsetsMake(64, 0, 44, 0);
        browserView.scrollView.scrollIndicatorInsets    = UIEdgeInsetsMake(browserView.scrollView.contentInset.top, 0, browserView.scrollView.contentInset.bottom, 0);
        browserView.navigationDelegate                  = self;
        
        flexibleSpaceLeft  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        flexibleSpaceRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        linkTitleLabel               = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, browserView.bounds.size.width - 40, UIFont.systemFontSize + 2)];
        linkTitleLabel.font          = [UIFont systemFontOfSize:UIFont.systemFontSize];
        linkTitleLabel.text          = [[(LinkItem *)_item title] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        linkTitleLabel.textAlignment = NSTextAlignmentCenter;
        linkTitleLabel.textColor     = UIColor.whiteColor;
        
        linkURLLabel               = [[UILabel alloc] initWithFrame:CGRectMake(20, linkTitleLabel.frame.origin.y + linkTitleLabel.bounds.size.height + 5, browserView.bounds.size.width - 40, 14)];
        linkURLLabel.font          = [UIFont systemFontOfSize:12];
        linkURLLabel.text          = [[(LinkItem *)_item URL] absoluteString];
        linkURLLabel.textAlignment = NSTextAlignmentCenter;
        linkURLLabel.textColor     = UIColor.grayColor;
        
        refreshControl       = [UIRefreshControl new];
        refreshControl.frame = CGRectMake((browserView.bounds.size.width / 2) - (refreshControl.bounds.size.width / 2),
                                          -refreshControl.bounds.size.height,
                                          refreshControl.bounds.size.width,
                                          refreshControl.bounds.size.height);
        
        [refreshControl addTarget:self action:@selector(refreshBrowser:) forControlEvents:UIControlEventValueChanged];
        
        browserPageInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, browserView.bounds.size.width, 44)];
        pageInfoButtonItem  = [[UIBarButtonItem alloc] initWithCustomView:browserPageInfoView];
        
        browserToolbar              = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44)];
        browserToolbar.barTintColor = UIColor.blackColor;
        browserToolbar.items        = @[flexibleSpaceLeft, pageInfoButtonItem, flexibleSpaceRight];
        
        linkTitleLabel.frame = CGRectMake((browserToolbar.bounds.size.width / 2) - (linkTitleLabel.bounds.size.width / 2),
                                          5,
                                          linkTitleLabel.bounds.size.width,
                                          linkTitleLabel.bounds.size.height);
        linkURLLabel.frame = CGRectMake((browserToolbar.bounds.size.width / 2) - (linkURLLabel.bounds.size.width / 2),
                                        linkTitleLabel.bounds.size.height + 10,
                                        linkURLLabel.bounds.size.width,
                                        linkURLLabel.bounds.size.height);
        
        [browserPageInfoView addSubview:linkTitleLabel];
        [browserPageInfoView addSubview:linkURLLabel];
        [browserView.scrollView addSubview:refreshControl];
        [self.view addSubview:browserView];
        [self.view sendSubviewToBack:browserView];
        [self.view addSubview:browserToolbar];
        [browserView loadRequest:[NSURLRequest requestWithURL:[(LinkItem *)_item URL]]];
}

- (void)loadInterfaceForLocationItem:(LocationItem *)item
{
        NSNumber *preferredMapType;
        UIBarButtonItem *flexibleSpaceLeft;
        UIBarButtonItem *flexibleSpaceRight;
        UIBarButtonItem *mapPickerButtonItem;
        
        self.view.backgroundColor = UIColor.blackColor;
        flexibleSpaceLeft         = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        flexibleSpaceRight        = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        map.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64);
        
        mapTypePicker           = [[UISegmentedControl alloc] initWithItems:@[@"Standard", @"Hybrid", @"Satellite"]];
        mapTypePicker.tintColor = UIColor.whiteColor;
        
        mapPickerButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mapTypePicker];
        
        mapToolbar              = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44)];
        mapToolbar.barTintColor = UIColor.blackColor;
        mapToolbar.items        = @[flexibleSpaceLeft, mapPickerButtonItem, flexibleSpaceRight];
        
        [mapTypePicker addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
        [mapTypePicker sizeToFit];
        
        preferredMapType = [NSUserDefaults.standardUserDefaults objectForKey:@"PreferredMapType"];
        
        if ( preferredMapType )
                mapTypePicker.selectedSegmentIndex = preferredMapType.longValue;
        else
                mapTypePicker.selectedSegmentIndex = 0;
        
        [self setMapTypeForSegmentIndex:mapTypePicker.selectedSegmentIndex];
        
        map.hidden = NO;
        
        [self.view addSubview:mapToolbar];
        [self loadLocation];
}

- (void)loadInterfaceForMediaItem:(MediaItem *)item
{
        UITapGestureRecognizer *tapRecognizer;
        
        self.view.backgroundColor = UIColor.blackColor;
        tapRecognizer             = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
        
        inkLayer        = [[UIImageView alloc] initWithFrame:self.view.bounds];
        inkLayer.frame  = CGRectMake(0, 0, item.ink.size.width, item.ink.size.height);
        inkLayer.image  = item.ink;
        inkLayer.opaque = NO;
        
        if ( item.itemType == ItemTypePhoto ) {
                UIPinchGestureRecognizer *pinchRecognizer;
                
                pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinchView:)];
                
                imageView                        = [[UIImageView alloc] initWithFrame:self.view.bounds];
                imageView.contentMode            = UIViewContentModeScaleAspectFit;
                imageView.image                  = item.image;
                imageView.userInteractionEnabled = YES;
                
                [imageView addGestureRecognizer:pinchRecognizer];
                [imageView addSubview:inkLayer];
                [self.view addSubview:imageView];
                [self.view sendSubviewToBack:imageView];
        } else if ( item.itemType == ItemTypeMovie ) {
                moviePlayer                 = [AVPlayer playerWithURL:[Util pathForMedia:item.identifier extension:@"mov"]];
                moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
                playerViewController                             = [AVPlayerViewController new];
                playerViewController.player                      = moviePlayer;
                playerViewController.view.frame                  = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
                playerViewController.showsPlaybackControls       = NO;
                playerViewController.view.userInteractionEnabled = NO;
                
                [self.view addSubview:playerViewController.view];
                [self.view addSubview:inkLayer];
                [self.view bringSubviewToFront:navigationBar];
                [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                object:moviePlayer.currentItem
                                                                 queue:[NSOperationQueue currentQueue]
                                                            usingBlock:^(NSNotification *notification){
                                                                    [moviePlayer seekToTime:kCMTimeZero];
                                                            }];
                [moviePlayer play];
        }
        
        [self.view addGestureRecognizer:tapRecognizer];
}

- (void)loadInterfaceForTextItem:(TextItem *)item
{
        self.view.backgroundColor = [UIColor colorWithRed:251/255.0 green:251/255.0 blue:240/255.0 alpha:1.0];
        
        inkLayer        = [[UIImageView alloc] initWithFrame:self.view.bounds];
        inkLayer.frame  = CGRectMake(0, 0, item.ink.size.width, item.ink.size.height);
        inkLayer.image  = item.ink;
        inkLayer.opaque = NO;
        
        textView                       = [[UITextView alloc] initWithFrame:self.view.bounds];
        textView.attributedText        = item.string;
        textView.backgroundColor       = UIColor.clearColor;
        textView.dataDetectorTypes     = UIDataDetectorTypeCalendarEvent | UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        textView.delegate              = self;
        textView.editable              = NO;
        textView.textContainerInset    = UIEdgeInsetsMake(99, 35, 35, 35);
        textView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
        
        [self.view addSubview:textView];
        [self.view sendSubviewToBack:textView];
        [inkLayer removeFromSuperview];
        [textView addSubview:inkLayer];
        [textView sendSubviewToBack:inkLayer];
}

- (void)loadLocation
{
        if ( _item.coordinates ) {
                MKPointAnnotation *annotation;
                MKCoordinateRegion region;
                MKCoordinateSpan span;
                
                span.latitudeDelta  = 0.01;
                span.longitudeDelta = 0.01;
                
                region.center = _item.coordinates.coordinate;
                region.span   = span;
                
                annotation            = [MKPointAnnotation new];
                annotation.coordinate = _item.coordinates.coordinate;
                
                for ( MKPointAnnotation *a in map.annotations )
                        [map removeAnnotation:a];
                
                [map setRegion:region animated:YES];
                [map regionThatFits:region];
                
                if ( !_item.location ) {
                        [geocoder reverseGeocodeLocation:_item.coordinates completionHandler:^(NSArray *placemarks, NSError *error){
                                if ( placemarks.count > 0) {
                                        MKPlacemark *placemark;
                                        
                                        placemark = placemarks[0];
                                        
                                        if ( placemark.areasOfInterest.count > 0 ) {
                                                annotation.title    = [NSString stringWithFormat:@"Near %@", placemark.areasOfInterest[0]];
                                                annotation.subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.thoroughfare ) {
                                                annotation.title    = [NSString stringWithFormat:@"%@", placemark.thoroughfare];
                                                annotation.subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else if ( placemark.subLocality ) {
                                                annotation.title    = [NSString stringWithFormat:@"%@", placemark.subLocality];
                                                annotation.subtitle = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                                        } else {
                                                annotation.title    = [NSString stringWithFormat:@"%@", placemark.locality];
                                                annotation.subtitle = [NSString stringWithFormat:@"%@", placemark.country];
                                        }
                                        
                                        _item.location = [NSString stringWithFormat:@"%@\n%@", annotation.title, annotation.subtitle];
                                        
                                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLocationItem:(LocationItem *)_item inCollection:nil];
                                        [map addAnnotation:annotation];
                                        [map selectAnnotation:annotation animated:YES];
                                } else if ( _item.location ) { // Fall back.
                                        NSArray *components;
                                        
                                        components = [_item.location componentsSeparatedByString:@"\n"];
                                        
                                        if ( components.count == 2 ) {
                                                annotation.title    = components[0];
                                                annotation.subtitle = components[1];
                                                
                                                [map addAnnotation:annotation];
                                                [map selectAnnotation:annotation animated:YES];
                                        }
                                }
                        }];
                } else {
                        NSArray *components;
                        
                        components = [_item.location componentsSeparatedByString:@"\n"];
                        
                        if ( components.count == 2 ) {
                                annotation.title    = components[0];
                                annotation.subtitle = components[1];
                                
                                [map addAnnotation:annotation];
                                [map selectAnnotation:annotation animated:YES];
                        }
                }
        }
}

- (void)loadView
{
        UIBarButtonItem *doneButtonItem;
        UIBarButtonItem *exportButtonItem;
        UINavigationItem *navigationItem;
        
        [super loadView];
        
        dateLabel               = [UILabel new];
        dateLabel.font          = [UIFont systemFontOfSize:UIFont.systemFontSize];
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.textColor     = UIColor.whiteColor;
        
        doneButtonItem   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView)];
        exportButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(presentExportOptions)];
        
        map                       = [MKMapView new];
        map.delegate              = self;
        map.hidden                = YES;
        map.showsBuildings        = YES;
        map.showsCompass          = YES;
        map.showsPointsOfInterest = YES;
        map.showsScale            = YES;
        map.showsUserLocation     = YES;
        
        navigationBar              = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
        navigationBar.barTintColor = UIColor.blackColor;
        
        navigationItem                    = [[UINavigationItem alloc] initWithTitle:@""];
        navigationItem.hidesBackButton    = YES;
        navigationItem.leftBarButtonItem  = exportButtonItem;
        navigationItem.rightBarButtonItem = doneButtonItem;
        
        timeLabel               = [UILabel new];
        timeLabel.font          = [UIFont systemFontOfSize:12];
        timeLabel.textAlignment = NSTextAlignmentCenter;
        timeLabel.textColor     = UIColor.grayColor;
        
        [navigationBar pushNavigationItem:navigationItem animated:NO];
        [navigationBar addSubview:dateLabel];
        [navigationBar addSubview:timeLabel];
        [self.view addSubview:map];
        [self.view addSubview:navigationBar];
}

- (void)mapTypeChanged:(UISegmentedControl *)segmentedControl
{
        [self setMapTypeForSegmentIndex:segmentedControl.selectedSegmentIndex];
        [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithLong:segmentedControl.selectedSegmentIndex] forKey:@"PreferredMapType"];
}

- (void)presentExportOptions
{
        __block UIActivityViewController *activityController;
        
        if ( [_item isKindOfClass:LinkItem.class] ) {
                activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[(LinkItem *)_item URL]] applicationActivities:nil];
                
                [self presentViewController:activityController animated:YES completion:nil];
        } else if ( [_item isKindOfClass:LocationItem.class] ) {
                NSString *locationAppleMaps;
                UIAlertAction *apple;
                UIAlertAction *cancel;
                UIAlertAction *google;
                UIAlertAction *other;
                UIAlertController *prompt;
                
                locationAppleMaps = [NSString stringWithFormat:@"http://maps.apple.com/?q=%f,%f", _item.coordinates.coordinate.latitude, _item.coordinates.coordinate.longitude];
                
                apple  = [UIAlertAction actionWithTitle:@"Apple Maps" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:locationAppleMaps]];
                }];
                cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                other  = [UIAlertAction actionWithTitle:@"Other…" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        NSString *location;
                        
                        if ( _item.location )
                                location = [NSString stringWithFormat:@"%@\n%f,%f", _item.location, _item.coordinates.coordinate.latitude, _item.coordinates.coordinate.longitude];
                        else
                                location = [NSString stringWithFormat:@"%f,%f", _item.coordinates.coordinate.latitude, _item.coordinates.coordinate.longitude];
                        
                        activityController = [[UIActivityViewController alloc] initWithActivityItems:@[location] applicationActivities:nil];
                        
                        [self presentViewController:activityController animated:YES completion:nil];
                }];
                prompt = [UIAlertController alertControllerWithTitle:@"Open in…" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                [prompt addAction:cancel];
                
                if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]] ) {
                        NSString *locationGoogleMaps;
                        
                        locationGoogleMaps = [NSString stringWithFormat:@"comgooglemaps://?q=%f,%f", _item.coordinates.coordinate.latitude, _item.coordinates.coordinate.longitude];
                        
                        google = [UIAlertAction actionWithTitle:@"Google Maps" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:locationGoogleMaps]];
                        }];
                        
                        [prompt addAction:google];
                }
                
                [prompt addAction:apple];
                [prompt addAction:other];
                [self presentViewController:prompt animated:YES completion:nil];
        } else if ( [_item isKindOfClass:MediaItem.class] ) {
                if ( _item.itemType == ItemTypePhoto ) {
                        UIImage *export;
                        
                        // Exporting with ink reduces the res of the photo.
                        if ( inkLayer.image ) {
                                UIImageView *buffer;
                                UIImageView *bufferInk;
                                
                                buffer = [[UIImageView alloc] initWithFrame:imageView.bounds];
                                buffer.image = imageView.image;
                                
                                bufferInk = [[UIImageView alloc] initWithFrame:inkLayer.bounds];
                                bufferInk.contentMode = UIViewContentModeTop;
                                bufferInk.image = inkLayer.image;
                                
                                [buffer addSubview:bufferInk];
                                
                                UIGraphicsBeginImageContextWithOptions(buffer.bounds.size, NO, 0.0);
                                
                                [buffer drawViewHierarchyInRect:imageView.bounds afterScreenUpdates:YES];
                                
                                export = UIGraphicsGetImageFromCurrentImageContext();
                                
                                UIGraphicsEndImageContext();
                        } else {
                                export = imageView.image;
                        }
                        
                        activityController = [[UIActivityViewController alloc] initWithActivityItems:@[export] applicationActivities:nil];
                } else if ( [(MediaItem *)_item itemType] == ItemTypeMovie ) {
                        activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[Util pathForMedia:_item.identifier extension:@"mov"]] applicationActivities:nil];
                }
                
                [self presentViewController:activityController animated:YES completion:nil];
        } else if ( [_item isKindOfClass:TextItem.class] ) {
                NSData *PDF;
                
                PDF = [self exportPDF];
                
                if ( PDF ) {
                        activityController = [[UIActivityViewController alloc] initWithActivityItems:@[PDF] applicationActivities:nil];
                        
                        [self presentViewController:activityController animated:YES completion:nil];
                }
        }
}

- (void)refreshBrowser:(UIRefreshControl *)refreshControl
{
        [browserView reload];
        [refreshControl endRefreshing];
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

- (void)showNavigationBar
{
        navigationBar.hidden = NO;
        shouldShowStatusBar  = YES;
        
        [UIView animateWithDuration:0.3 animations:^{
                navigationBar.alpha = 1.0;
                
                [self setNeedsStatusBarAppearanceUpdate];
        }];
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        
        if ( _item ) {
                if ( [_item isKindOfClass:LinkItem.class] )
                        [self loadInterfaceForLinkItem:(LinkItem *)_item];
                else if ( [_item isKindOfClass:LocationItem.class] )
                        [self loadInterfaceForLocationItem:(LocationItem *)_item];
                else if ( [_item isKindOfClass:MediaItem.class] )
                        [self loadInterfaceForMediaItem:(MediaItem *)_item];
                else if ( [_item isKindOfClass:TextItem.class] )
                        [self loadInterfaceForTextItem:(TextItem *)_item];
                
                [self getCurrentDate];
        }
}

- (void)webView:(WKWebView *)webView didFailLoadWithError:(nonnull NSError *)error
{
        NSLog(@"%@", error);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
        NSLog(@"%@", error);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
        linkURLLabel.text = webView.URL.absoluteString;
        
        [webView evaluateJavaScript:@"document.title" completionHandler:^(id result, NSError *error){
                if ( error ) {
                        NSLog(@"%@", error);
                } else {
                        linkTitleLabel.text = result;
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        UIGraphicsBeginImageContextWithOptions(browserView.bounds.size, NO, 0.0);
                        
                        [browserView drawViewHierarchyInRect:browserView.bounds afterScreenUpdates:YES];
                        
                        _item.snapshot = UIGraphicsGetImageFromCurrentImageContext();
                        _item.snapshot = [Util imageByCroppingImage:_item.snapshot toSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.width)];
                        
                        UIGraphicsEndImageContext();
                        
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLinkSnapshot:(LinkItem *)_item];
                });
        }];
}


@end
