//
//  CameraViewController.m
//  Repo
//
//  Created by Ali Mahouk on 13/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVKit;
@import MobileCoreServices;

#import "CameraViewController.h"

#import "AppDelegate.h"
#import "InkView.h"
#import "InkWell.h"
#import "MediaItem.h"
#import "Util.h"

@implementation CameraViewController


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                isShowingStrokeColorOptions = NO;
                iOSVersionCheck             = (NSOperatingSystemVersion){10, 0, 0};
                shouldShowStatusBar         = YES;
                
                if ( [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOSVersionCheck] )
                        selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
                
                self.tabBarItem.image = [UIImage imageNamed:@"camera"];
                self.title            = @"Camera";
        }
        
        return self;
}

- (UIImage *)screenshot
{
        UIImage *snapshot;
        
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
        
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
        
        snapshot = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return snapshot;
}

- (BOOL)prefersStatusBarHidden
{
        return !shouldShowStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
        return UIStatusBarAnimationFade;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
        return UIStatusBarStyleLightContent;
}

- (void)beginAnnotating
{
        inkLayer.drawingEnabled         = YES;
        inkLayer.strokeColor            = inkWell.backgroundColor;
        inkLayer.userInteractionEnabled = YES;
        
        [inkWell activate];
        [UIView animateWithDuration:0.3 animations:^{
                doneAnnotatingButton.alpha = 0.0;
        } completion:^(BOOL finished){
                doneAnnotatingButton.hidden = YES;
        }];
}

- (void)cameraDidBeginRecordingVideo
{
        [self hideStatusBar];
        
        if ( [_delegate respondsToSelector:@selector(cameraViewDidBeginAnnotating:)] )
                [_delegate cameraViewDidBeginAnnotating:self];
}

- (void)cameraDidCaptureImage:(UIImage *)image
{
        MediaItem *item;
        
        item          = [[MediaItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
        item.image    = image;
        item.itemType = ItemTypePhoto;
        
        [item redraw];
        
        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                [selectionFeedbackGenerator selectionChanged];
        
        if ( [_delegate respondsToSelector:@selector(cameraView:didHandOverItem:isEdit:)] )
                [_delegate cameraView:self didHandOverItem:item isEdit:NO];
}

- (void)cameraDidFinishRecordingVideoAtURL:(NSURL *)path
{
        MediaItem *item;
        NSError *error;
        
        [self showStatusBar];
        
        if ( [_delegate respondsToSelector:@selector(cameraViewDidEndAnnotating:)] )
                [_delegate cameraViewDidEndAnnotating:self];
        
        item          = [[MediaItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
        item.itemType = ItemTypeMovie;
        
        if ( ![NSFileManager.defaultManager copyItemAtURL:path toURL:[Util pathForMedia:item.identifier extension:@"mov"] error:&error] )
                NSLog(@"%@", error);
        
        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaThumbnail:item];
        [item redraw];
        
        if ( [_delegate respondsToSelector:@selector(cameraView:didHandOverItem:isEdit:)] )
                [_delegate cameraView:self didHandOverItem:item isEdit:NO];
}

- (void)closeViewfinder
{
        [camera closeViewfinder];
}

- (void)didChangeControllerFocus:(BOOL)focused
{
        if ( !focused )
                [self closeViewfinder];
        else
                [self openViewfinder];
}

- (void)didDropItem:(MediaItem *)item
{
        if ( [item isKindOfClass:MediaItem.class] ) {
                for ( UIGestureRecognizer *recognizer in item.gestureRecognizers )
                        [item removeGestureRecognizer:recognizer];
                
                [self done]; // Flush in case something is already being edited.
                
                workingItem = item;
                
                [self presentAnnotationInterfaceForItem:workingItem];
        }
}

- (void)didLongPressCameraView:(UILongPressGestureRecognizer *)gestureRecognizer
{
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ) { // Paste image (if available).
                NSData *GIFData;
                NSData *pasteBMPData;
                NSData *pasteGIFData;
                NSData *pasteICOData;
                NSData *pasteJPEGData;
                NSData *pastePNGData;
                NSData *pasteTIFFData;
                UIImage *image;
                UIImage *pasteImage;
                
                GIFData       = [UIPasteboard.generalPasteboard dataForPasteboardType:@"com.compuserve.gif"];
                pasteImage    = UIPasteboard.generalPasteboard.image;
                pasteBMPData  = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeBMP];
                pasteGIFData  = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeGIF];
                pasteICOData  = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeICO];
                pasteJPEGData = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeJPEG];
                pastePNGData  = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypePNG];
                pasteTIFFData = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeTIFF];
                
                // Paste as a new item at this point.
                if ( GIFData )
                        image = [UIImage imageWithData:GIFData];
                else if ( pasteImage )
                        image = pasteImage;
                else if ( pasteBMPData )
                        image = [UIImage imageWithData:pasteBMPData];
                else if ( pasteGIFData )
                        image = [UIImage imageWithData:pasteGIFData];
                else if ( pasteICOData )
                        image = [UIImage imageWithData:pasteICOData];
                else if ( pasteJPEGData )
                        image = [UIImage imageWithData:pasteJPEGData];
                else if ( pastePNGData )
                        image = [UIImage imageWithData:pastePNGData];
                else if ( pasteTIFFData )
                        image = [UIImage imageWithData:pasteTIFFData];
                
                if ( image ) {
                        MediaItem *item;
                        
                        item          = [[MediaItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                        item.image    = image;
                        item.itemType = ItemTypePhoto;
                        
                        [item redraw];
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createMediaItem:item];
                        
                        workingItem = item;
                        
                        [self presentAnnotationInterfaceForItem:item];
                }
        }
}

- (void)didLongPressInkWell:(UILongPressGestureRecognizer *)gestureRecognizer
{
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan )
                [self presentStrokeColorChoices];
}

- (void)didTapInkChoice:(UITapGestureRecognizer *)gestureRecognizer
{
        InkWell *choice;
        
        choice = (InkWell *)gestureRecognizer.view;
        
        [self dismissStrokeColorOptions];
        [UIView animateWithDuration:0.4 animations:^{
                inkWell.backgroundColor   = choice.backgroundColor;
                inkWell.layer.borderColor = choice.layer.borderColor;
                inkWell.layer.borderWidth = choice.layer.borderWidth;
        } completion:^(BOOL finished){
                [self beginAnnotating];
        }];
}

- (void)didTapInkWell:(UITapGestureRecognizer *)gestureRecognizer
{
        [self dismissStrokeColorOptions];
        
        if ( inkLayer.drawingEnabled )
                [self endAnnotating];
        else
                [self beginAnnotating];
}

- (void)dismissAnnotationInterface
{
        if ( [_delegate respondsToSelector:@selector(cameraViewDidEndAnnotating:)] )
                [_delegate cameraViewDidEndAnnotating:self];
        
        annotationView.hidden = YES;
        imagePreview.image    = nil;
        
        [self showStatusBar];
        [self openViewfinder];
}

- (void)dismissStrokeColorOptions
{
        if ( isShowingStrokeColorOptions ) {
                CGFloat delay;
                
                delay                       = 0;
                isShowingStrokeColorOptions = NO;
                
                [annotationView bringSubviewToFront:inkWell];
                
                for ( UIView *v in annotationView.subviews ) {
                        if ( v.tag == 2 ) {
                                [UIView animateWithDuration:0.2 delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
                                        v.frame = inkWell.frame;
                                } completion:^(BOOL finished){
                                        [UIView animateWithDuration:0.1 animations:^{
                                                v.alpha = 0.0;
                                        } completion:^(BOOL finished){
                                                [v removeFromSuperview];
                                        }];
                                }];
                                
                                delay += 0.1;
                        }
                }
        }
}

- (void)done
{
        if ( workingItem ) {
                workingItem.modified = [NSDate date];
                
                if ( ![Util isClearImage:inkLayer.image] ) // Don't set the ink if the image is empty. Prefer it to be nil.
                        workingItem.ink = inkLayer.image;
                else
                        workingItem.ink = nil;
                
                [workingItem redraw];
                
                if ( workingItem.itemType == ItemTypeMovie ) {
                        [moviePlayer pause];
                        [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:moviePlayer.currentItem];
                        
                        moviePlayer = nil;
                }
                
                if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                        [selectionFeedbackGenerator selectionChanged];
                
                if ( [_delegate respondsToSelector:@selector(cameraView:didHandOverItem:isEdit:)] )
                        [_delegate cameraView:self didHandOverItem:workingItem isEdit:YES];
                
                workingItem = nil;
        }
        
        [self dismissAnnotationInterface];
}

- (void)endAnnotating
{
        [self dismissStrokeColorOptions];
        
        doneAnnotatingButton.hidden = NO;
        
        inkLayer.drawingEnabled         = NO;
        inkLayer.userInteractionEnabled = NO;
        
        [inkWell deactivate];
        [UIView animateWithDuration:0.3 animations:^{
                doneAnnotatingButton.alpha = 1.0;
        }];
}

- (void)hideStatusBar
{
        shouldShowStatusBar = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
        }];
}

- (void)loadView
{
        [super loadView];
        
        annotationView        = [[UIView alloc] initWithFrame:self.view.bounds];
        annotationView.hidden = YES;
        
        camera          = [[CameraView alloc] initWithFrame:self.view.bounds];
        camera.delegate = self;
        
        doneAnnotatingButton                     = [UIButton buttonWithType:UIButtonTypeSystem];
        doneAnnotatingButton.layer.borderColor   = [UIColor whiteColor].CGColor;
        doneAnnotatingButton.layer.borderWidth   = 1.0;
        doneAnnotatingButton.layer.cornerRadius  = 4.0;
        doneAnnotatingButton.layer.shadowColor   = UIColor.grayColor.CGColor;
        doneAnnotatingButton.layer.shadowOffset  = CGSizeMake(0, 1.0);
        doneAnnotatingButton.layer.shadowOpacity = 1.0;
        doneAnnotatingButton.layer.shadowRadius  = 1.0;
        doneAnnotatingButton.titleLabel.font     = [UIFont boldSystemFontOfSize:UIFont.systemFontSize];
        
        [doneAnnotatingButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
        [doneAnnotatingButton setTitle:@"DONE" forState:UIControlStateNormal];
        [doneAnnotatingButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [doneAnnotatingButton sizeToFit];
        
        doneAnnotatingButton.frame = CGRectMake(self.view.bounds.size.width - doneAnnotatingButton.bounds.size.width - 40,
                                                15,
                                                doneAnnotatingButton.bounds.size.width + 25,
                                                doneAnnotatingButton.bounds.size.height);
        
        imagePreview                 = [[UIImageView alloc] initWithFrame:annotationView.bounds];
        imagePreview.backgroundColor = UIColor.blackColor;
        imagePreview.contentMode     = UIViewContentModeScaleAspectFit;
        
        inkLayer                        = [[InkView alloc] initWithFrame:annotationView.bounds];
        inkLayer.userInteractionEnabled = NO;
        
        inkWell                 = [[InkWell alloc] initWithFrame:CGRectMake(8.5, 12.5, 40, 40)];
        inkWell.backgroundColor = DEFAULT_STROKE_COLOR;
        
        playerViewController                             = [AVPlayerViewController new];
        playerViewController.view.frame                  = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        playerViewController.showsPlaybackControls       = NO;
        playerViewController.view.userInteractionEnabled = NO;
        
        [annotationView addSubview:playerViewController.view];
        [annotationView addSubview:imagePreview];
        [annotationView addSubview:inkLayer];
        [annotationView addSubview:doneAnnotatingButton];
        [annotationView addSubview:inkWell];
        [self.view addSubview:camera];
        [self.view addSubview:annotationView];
}

- (void)openViewfinder
{
        if ( !workingItem )
                [camera openViewfinder];
}

- (void)presentAnnotationInterfaceForItem:(MediaItem *)item
{
        if ( item ) {
                if ( [_delegate respondsToSelector:@selector(cameraViewDidBeginAnnotating:)] )
                        [_delegate cameraViewDidBeginAnnotating:self];
                
                [self closeViewfinder];
                [self hideStatusBar];
                
                annotationView.hidden = NO;
                inkLayer.image        = item.ink;
                
                if ( item.itemType == ItemTypePhoto ) {
                        imagePreview.hidden = NO;
                        imagePreview.image  = item.image;
                } else if ( item.itemType == ItemTypeMovie ) {
                        imagePreview.hidden = YES;
                        
                        moviePlayer                 = [AVPlayer playerWithURL:[Util pathForMedia:item.identifier extension:@"mov"]];
                        moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                        
                        playerViewController.player = moviePlayer;
                        
                        [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                        object:moviePlayer.currentItem
                                                                        queue:[NSOperationQueue currentQueue]
                                                                    usingBlock:^(NSNotification *notification){
                                                                            [moviePlayer seekToTime:kCMTimeZero];
                                                                    }];
                        [moviePlayer play];
                }
        }
}

- (void)presentStrokeColorChoices
{
        if ( isShowingStrokeColorOptions ) { // Already showing, hide them.
                [self dismissStrokeColorOptions];
        } else {
                CGFloat delay;
                
                [self endAnnotating];
                
                delay                       = 0;
                isShowingStrokeColorOptions = YES;
                
                for ( int i = 1; i <= 5; i++ ) {
                        InkWell *colorButton;
                        UITapGestureRecognizer *colorButtonTapRecognizer;
                        CGFloat activeBlue;
                        CGFloat activeGreen;
                        CGFloat activeRed;
                        CGFloat blue;
                        CGFloat green;
                        CGFloat red;
                        
                        blue  = 0.0; // All black.
                        green = 0.0;
                        red   = 0.0;
                        
                        colorButton     = [[InkWell alloc] initWithFrame:inkWell.frame];
                        colorButton.tag = 2;
                        
                        colorButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapInkChoice:)];
                        
                        [inkWell.backgroundColor getRed:&activeRed green:&activeGreen blue:&activeBlue alpha:nil];
                        
                        switch ( i ) {
                                case 1: {
                                        if ( !(activeRed == 1.0 &&
                                               activeGreen == 1.0 &&
                                               activeBlue == 0.0) ) {
                                                green = 1.0;
                                                red   = 1.0;
                                        }
                                        
                                        colorButton.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                                        
                                        break;
                                }
                                        
                                case 2: {
                                        if ( !(activeRed == 0.8 &&
                                               activeGreen == 0.8 &&
                                               activeBlue == 0.8) ) {
                                                blue  = 0.8;
                                                green = 0.8;
                                                red   = 0.8;
                                        }
                                        
                                        colorButton.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                                        
                                        break;
                                }
                                        
                                case 3: {
                                        if ( !(activeRed == 1.0 &&
                                               activeGreen == 0.0 &&
                                               activeBlue == 0.0) )
                                                red = 1.0;
                                        
                                        colorButton.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                                        
                                        break;
                                }
                                        
                                case 4: {
                                        if ( !(activeRed == 0.0 &&
                                               activeGreen == 0.0 &&
                                               activeBlue == 1.0) )
                                                blue = 1.0;
                                        
                                        colorButton.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                                        
                                        break;
                                }
                                        
                                case 5: {
                                        if ( ![inkWell.backgroundColor isEqual:UIColor.clearColor] ) {
                                                colorButton.backgroundColor = UIColor.clearColor;
                                                colorButton.borderColor     = inkWell.backgroundColor.CGColor;
                                        } else {
                                                colorButton.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                                        }
                                        
                                        break;
                                }
                                        
                                default:
                                        break;
                        }
                        
                        [colorButton addGestureRecognizer:colorButtonTapRecognizer];
                        [annotationView addSubview:colorButton];
                        [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
                                colorButton.center = CGPointMake(inkWell.center.x + (inkWell.bounds.size.width * i), inkWell.center.y);
                                colorButton.transform = CGAffineTransformScale(colorButton.transform, 1.5, 1.5);
                        } completion:^(BOOL finished){
                                [UIView animateWithDuration:0.15 animations:^{
                                        colorButton.transform = CGAffineTransformIdentity;
                                }];
                        }];
                        
                        delay += 0.1;
                }
                
                [UIView animateWithDuration:0.2 animations:^{
                        inkWell.transform = CGAffineTransformScale(inkWell.transform, 2.5, 2.5);
                } completion:^(BOOL finished){
                        [UIView animateWithDuration:0.1 animations:^{
                                inkWell.transform = CGAffineTransformIdentity;
                        }];
                }];
        }
}

- (void)showStatusBar
{
        shouldShowStatusBar = YES;
        
        [UIView animateWithDuration:0.3 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
        }];
}

- (void)viewDidLoad
{
        UILongPressGestureRecognizer *cameraViewLongPressRecognizer;
        UILongPressGestureRecognizer *inkWellLongPressRecognizer;
        UITapGestureRecognizer *inkWellTapRecognizer;
        
        [super viewDidLoad];
        
        cameraViewLongPressRecognizer                      = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressCameraView:)];
        cameraViewLongPressRecognizer.minimumPressDuration = 0.5;
        
        inkWellLongPressRecognizer    = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressInkWell:)];
        inkWellTapRecognizer          = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapInkWell:)];
        
        [inkWellTapRecognizer requireGestureRecognizerToFail:inkWellLongPressRecognizer];
        [inkWell addGestureRecognizer:inkWellLongPressRecognizer];
        [inkWell addGestureRecognizer:inkWellTapRecognizer];
        [camera.viewfinder addGestureRecognizer:cameraViewLongPressRecognizer];
        [self openViewfinder];
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}


@end
