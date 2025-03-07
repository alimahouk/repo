//
//  TextEditorViewController.m
//  Repo
//
//  Created by Ali Mahouk on 13/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import MobileCoreServices;

#import "TextEditorViewController.h"

#import "constants.h"
#import "InkWell.h"
#import "LinkItem.h"
#import "LocationItem.h"
#import "MediaItem.h"
#import "TextEditor.h"
#import "TextItem.h"
#import "Util.h"

@implementation TextEditorViewController


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                iOSVersionCheck             = (NSOperatingSystemVersion){10, 0, 0};
                isShowingKeyboard           = NO;
                isShowingStrokeColorOptions = NO;
                
                mediaPickerController            = [UIImagePickerController new];
                mediaPickerController.delegate   = self;
                mediaPickerController.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
                
                if ( [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOSVersionCheck] )
                        selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
                
                self.tabBarItem.image = [UIImage imageNamed:@"notepad"];
                self.title            = @"Notepad";
        }
        
        return self;
}

- (UIImage *)screenshot
{
        UIImage *snapshot;
        
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
        
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
        
        snapshot = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return snapshot;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
        if ( action == @selector(insertPhoto) &&
             [sender isEqual:editor] )
                return YES;
        else
                return [super canPerformAction:action withSender:sender];
}

- (BOOL)downloadImageAtURL:(NSURL *)URL
{
        NSSet *imageExtensions;
        
        // We support everything UIImage supports.
        imageExtensions = [NSSet setWithObjects:@"bmp", @"BMPf", @"gif", @"ico", @"jpeg", @"jpg", @"png", @"tif", @"tiff", @"xbm", nil];
        
        [self blurEditor];
        
        if ( [imageExtensions containsObject:URL.pathExtension] ) {
                [[NSURLSession.sharedSession dataTaskWithURL:URL
                                           completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                           if ( !error &&
                                                                data ) {
                                                                   UIImage *image;
                                                                   
                                                                   image = [[UIImage alloc] initWithData:data];
                                                                   
                                                                   if ( image ) {
                                                                           MediaItem *item;
                                                                           BOOL isEdit;
                                                                           
                                                                           item          = [[MediaItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                                                                           item.image    = [[UIImage alloc] initWithData:data];
                                                                           item.itemType = ItemTypePhoto;
                                                                           
                                                                           [item redraw];
                                                                           
                                                                           if ( workingItem )
                                                                                   isEdit = YES;
                                                                           else
                                                                                   isEdit = NO;
                                                                           
                                                                           if ( [_delegate respondsToSelector:@selector(textEditorView:didHandOverItem:isEdit:)] )
                                                                                   [_delegate textEditorView:self didHandOverItem:item isEdit:isEdit];
                                                                           
                                                                           workingItem = nil;
                                                                   } else {
                                                                           [self handOverLink:URL];
                                                                   }
                                                           } else {
                                                                   [self handOverLink:URL];
                                                           }
                                                   });
                                           }] resume];
                return YES;
        }
        
        return NO;
}

- (BOOL)parseMapLink:(NSURL *)URL
{
        /*
         * Check if it's a Google Maps link.
         * If so, extract the coordinates.
         */
        NSString *URLString;
        
        URLString = URL.absoluteString;
        
        if ( [URLString containsString:@"www.google.com/maps"] ||
             [URLString containsString:@"maps.google.com"] ) {
                NSString *latitude;
                NSString *longitude;
                
                if ( [URLString containsString:@"www.google.com/maps"] ) {
                        NSArray *split;
                        
                        /*
                         * The first case happens when you choose
                         * a random location on the map (not a
                         * specific venue).
                         */
                        split = [URLString componentsSeparatedByString:@","];
                        
                        if ( split.count == 2 ) {
                                NSScanner *scanner;
                                NSURL *temp;
                                
                                temp     = [NSURL URLWithString:split[0]];
                                latitude = [temp lastPathComponent];
                                scanner  = [NSScanner scannerWithString:split[1]];
                                
                                [scanner scanUpToString:@"/" intoString:&longitude];
                        } else {
                                /*
                                 * Handling map links where the coordinates are
                                 * preceded by an @ char. This happens when you
                                 * choose a specific venue on the map.
                                 */
                                split = [URLString componentsSeparatedByString:@"@"];
                                
                                if ( split.count == 2 ) {
                                        NSString *extract;
                                        NSRange endRange;
                                        
                                        endRange = [split[1] rangeOfString:@"/"];
                                        extract  = [split[1] substringToIndex:endRange.location];
                                        split    = [extract componentsSeparatedByString:@","];
                                        
                                        if ( split.count >= 2 ) {
                                                latitude  = split[0];
                                                longitude = split[1];
                                        }
                                }
                        }
                } else if ( [URLString containsString:@"maps.google.com"] ) { // WhatsApp shares these kinds of basic map links.
                        NSArray *split;
                        NSString *extract;
                        NSRange endRange;
                        NSRange startRange;
                        
                        if ( [URLString containsString:@"?q="] )
                                startRange = [URLString rangeOfString:@"?q="];
                        else if ( [URLString containsString:@"&q="] )
                                startRange = [URLString rangeOfString:@"&q="];
                        
                        extract  = [URLString substringFromIndex:startRange.location];
                        endRange = [extract rangeOfString:@"&"];
                        
                        // If endRange is NSNotFound then we've reached the end of the URL.
                        if ( endRange.location != NSNotFound )
                                extract = [extract substringToIndex:endRange.location];
                        
                        split = [extract componentsSeparatedByString:@","];
                        
                        if ( split.count == 2 ) {
                                latitude  = split[0];
                                longitude = split[1];
                        }
                }
                
                if ( latitude &&
                     longitude ) {
                        LocationItem *item;
                        BOOL isEdit;
                        
                        item             = [[LocationItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                        item.coordinates = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
                        item.snapshot    = [self screenshot];
                        
                        if ( workingItem )
                                isEdit = YES;
                        else
                                isEdit = NO;
                        
                        [item redraw];
                        
                        if ( [_delegate respondsToSelector:@selector(textEditorView:didHandOverItem:isEdit:)] )
                                [_delegate textEditorView:self didHandOverItem:item isEdit:isEdit];
                        
                        workingItem = nil;
                } else {
                        [self handOverLink:URL];
                }
                
                return YES;
        }
        
        return NO;
}

- (BOOL)prefersStatusBarHidden
{
        return YES;
}

- (BOOL)showingKeyboard
{
        return isShowingKeyboard;
}

- (void)beginAnnotating
{
        if ( [_delegate respondsToSelector:@selector(textEditorViewDidBeginAnnotating:)] )
                [_delegate textEditorViewDidBeginAnnotating:self];
        
        [self blurEditor];
        [self dismissStrokeColorOptions];
        
        editor.userInteractionEnabled = NO;
        
        inkLayer.drawingEnabled = YES;
        inkLayer.strokeColor    = inkWell.backgroundColor;
        
        [inkWell activate];
        
        if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_INK] )
                [self playInkTutorial];
}

- (void)blurEditor
{
        [editor resignFirstResponder];
}

- (void)clearEditor
{
        [inkLayer clear];
        [self getCurrentDate]; // In case we were editing & it was from a different date.
        
        editor.attributedText = [[NSAttributedString alloc] initWithString:@""];
}

- (void)deregisterForKeyboard
{
        if ( self.isFocusedController ) {
                [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
                [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
                [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
        }
}

- (void)didChangeControllerFocus:(BOOL)focused
{
        if ( focused ) {
                [self registerForKeyboard]; // Register for keyboard notifications.
                [self startMonitoringTime];
        } else {
                [self deregisterForKeyboard];
                [self stopMonitoringTime];
        }
        
        [super didChangeControllerFocus:focused];
}

- (void)didDropItem:(TextItem *)item
{
        if ( [item isKindOfClass:TextItem.class] ) {
                CGSize textSize;
                
                for ( UIGestureRecognizer *recognizer in item.gestureRecognizers )
                        [item removeGestureRecognizer:recognizer];
                
                /*
                 * Flush in case something is already being edited.
                 * Don't call done directly otherwise an empty location
                 * item will be created every time.
                 */
                if ( workingItem ||
                     editor.attributedText.length > 0 ||
                     ![Util isClearImage:inkLayer.image] )
                        [self done];
                
                
                workingItem           = item;
                editor.attributedText = item.string;
                
                textSize = [editor sizeThatFits:CGSizeMake(editor.bounds.size.width, CGFLOAT_MAX)];
                
                inkLayer.frame = CGRectMake(0, 0, editor.bounds.size.width, MAX(editor.bounds.size.height, textSize.height));
                inkLayer.image = item.ink;
                
                [self getCurrentDate]; // Update the displayed date to use the one from this item.
        }
}

- (void)didLongPressInkWell:(UILongPressGestureRecognizer *)gestureRecognizer
{
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan )
                [self presentStrokeColorChoices];
}

- (void)didPinchEditor:(UIPinchGestureRecognizer *)gestureRecognizer
{
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ||
             gestureRecognizer.state == UIGestureRecognizerStateChanged ) {
                [self scaleFontSize:gestureRecognizer.scale];
                
                gestureRecognizer.scale = 1;
        }
}

- (void)didTapInkChoice:(UITapGestureRecognizer *)gestureRecognizer
{
        InkWell *choice;
        
        choice = (InkWell *)gestureRecognizer.view;
        
        [self dismissStrokeColorOptions];
        [UIView animateWithDuration:0.4 animations:^{
                inkWell.backgroundColor = choice.backgroundColor;
        } completion:^(BOOL finished){
                [self beginAnnotating];
        }];
}

- (void)didTapInkWell:(UITapGestureRecognizer *)gestureRecognizer
{
        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                [selectionFeedbackGenerator selectionChanged];
        
        if ( inkLayer.drawingEnabled )
                [self endAnnotating];
        else
                [self beginAnnotating];
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (void)dismissStrokeColorOptions
{
        if ( isShowingStrokeColorOptions ) {
                CGFloat delay;
                
                delay                       = 0;
                isShowingStrokeColorOptions = NO;
                
                [navigationBar.contentView bringSubviewToFront:inkWell];
                
                for ( UIView *v in navigationBar.contentView.subviews ) {
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
                
                [UIView animateWithDuration:0.2 delay:delay options:UIViewAnimationOptionCurveLinear animations:^{
                        dateLabel.alpha = 1.0;
                } completion:^(BOOL finished){
                        
                }];
        }
}

- (void)done
{
        NSURL *URL;
        
        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                [selectionFeedbackGenerator selectionChanged];
        
        if ( [Util isValidURL:editor.text] ) {
                NSString *escapedString;
                
                escapedString = [editor.text stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet];
                URL           = [NSURL URLWithString:escapedString];
        }
        
        if ( URL &&
             [Util isClearImage:inkLayer.image] ) {
                [self handOverResourceAtURL:URL];
        } else {
                [self handOverText];
        }
        
        [self endAnnotating];
        [self clearEditor];
}

- (void)endAnnotating
{
        if ( [_delegate respondsToSelector:@selector(textEditorViewDidEndAnnotating:)] )
                [_delegate textEditorViewDidEndAnnotating:self];
        
        [self.view sendSubviewToBack:inkLayer];
        [self dismissStrokeColorOptions];
        
        editor.userInteractionEnabled = YES;
        inkLayer.drawingEnabled       = NO;
        
        [inkWell deactivate];
}

- (void)focusEditor
{
        [self getCurrentDate];
        [self registerForKeyboard];
        [editor becomeFirstResponder];
}

- (void)getCurrentDate
{
        NSDateFormatter *dateFormatter;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"d MMM yyyy"];
        
        if ( workingItem )
                dateLabel.text = [[dateFormatter stringFromDate:workingItem.created] uppercaseString];
        else
                dateLabel.text = [[dateFormatter stringFromDate:[NSDate date]] uppercaseString];
        
        [dateLabel sizeToFit];
        [dateFormatter setDateFormat:@"EEEE"];
        
        if ( workingItem )
                dayLabel.text = [dateFormatter stringFromDate:workingItem.created];
        else
                dayLabel.text = [dateFormatter stringFromDate:[NSDate date]];
        
        [dayLabel sizeToFit];
        
        dateLabel.frame       = CGRectMake((navigationBar.bounds.size.width / 2) - (dateLabel.bounds.size.width / 2),
                                           32,
                                           dateLabel.bounds.size.width,
                                           dateLabel.bounds.size.height);
        dayLabel.frame        = CGRectMake(15,
                                           69,
                                           dayLabel.bounds.size.width,
                                           dayLabel.bounds.size.height);
        dividerMidLeft.frame  = CGRectMake(15,
                                           64,
                                           (navigationBar.bounds.size.width / 2) - (dateLabel.bounds.size.width / 2) - 25,
                                           1);
        dividerMidRight.frame = CGRectMake((navigationBar.bounds.size.width / 2) + (dateLabel.bounds.size.width / 2) + 10,
                                           64,
                                           (navigationBar.bounds.size.width / 2) - (dateLabel.bounds.size.width / 2) - 25,
                                           1);
}

- (void)getCurrentTime
{
        NSDateFormatter *dateFormatter;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"hh:mm a"];
        
        if ( workingItem )
                timeLabel.text = [[dateFormatter stringFromDate:workingItem.created] uppercaseString];
        else
                timeLabel.text = [[dateFormatter stringFromDate:[NSDate date]] uppercaseString];
        
        [timeLabel sizeToFit];
        
        timeLabel.frame = CGRectMake(navigationBar.bounds.size.width - timeLabel.bounds.size.width - 15,
                                     69,
                                     timeLabel.bounds.size.width,
                                     timeLabel.bounds.size.height);
}

- (void)handOverLink:(NSURL *)URL
{
        LinkItem *item;
        BOOL isEdit;
        
        item     = [[LinkItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
        item.URL = URL;
        
        [item redraw];
        
        if ( workingItem )
                isEdit = YES;
        else
                isEdit = NO;
        
        if ( [_delegate respondsToSelector:@selector(textEditorView:didHandOverItem:isEdit:)] )
                [_delegate textEditorView:self didHandOverItem:item isEdit:isEdit];
        
        workingItem = nil;
}

- (void)handOverResourceAtURL:(NSURL *)URL
{
        [self blurEditor];
        
        if ( !URL.scheme ) // Prepend a default scheme.
                URL = [NSURL URLWithString:[@"http://" stringByAppendingString:URL.absoluteString]];
        
        if ( ![self downloadImageAtURL:URL] ) {
                if ( ![self parseMapLink:URL] ) {
                        // Resolve the URL (it might be a shortened one that leads to an image).
                        NSMutableURLRequest *request;
                        NSURLSession *session;
                        
                        request            = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                        request.HTTPMethod = @"HEAD";
                        
                        session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                                                delegate:nil
                                                           delegateQueue:NSOperationQueue.currentQueue];
                        [[session dataTaskWithRequest:request
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
                                            NSHTTPURLResponse *HTTPResponse;
                                            
                                            HTTPResponse = (NSHTTPURLResponse *)response;
                                            
                                            if ( !HTTPResponse ||
                                                 error ||
                                                 HTTPResponse.statusCode != 200 ) {
                                                    [self handOverLink:URL];
                                            } else {
                                                    if ( ![self downloadImageAtURL:response.URL] ) {
                                                            if ( ![self parseMapLink:response.URL] )
                                                                    [self handOverLink:URL];
                                                    }
                                            }
                                    }] resume];
                }
        }
}

- (void)handOverText
{
        TextItem *item;
        BOOL isEdit;
        
        if ( editor.attributedText.length > 0 ||
             ![Util isClearImage:inkLayer.image] ) {
                [self blurEditor];
                
                item          = [[TextItem alloc] initAtPoint:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                item.string   = editor.attributedText;
                item.snapshot = [self screenshot];
                
                if ( ![Util isClearImage:inkLayer.image] ) // Don't set the ink if the image is empty. Prefer it to be nil.
                        item.ink = inkLayer.image;
                
                if ( workingItem ) {
                        isEdit = YES;
                        
                        item.created     = workingItem.created;
                        item.identifier  = workingItem.identifier;
                        item.coordinates = workingItem.coordinates;
                } else {
                        isEdit = NO;
                }
                
                [item redraw];
                
                if ( [_delegate respondsToSelector:@selector(textEditorView:didHandOverItem:isEdit:)] )
                        [_delegate textEditorView:self didHandOverItem:item isEdit:isEdit];
        } else {
                if ( isShowingKeyboard )
                        [self blurEditor];
                else
                        [self focusEditor];
        }
        
        workingItem = nil;
}

- (void)hideStatusLabel
{
        statusLabelTimer = nil;
        
        [UIView animateWithDuration:0.2 animations:^{
                dateLabel.alpha   = 1.0;
                statusLabel.alpha = 0.0;
        } completion:^(BOOL finished){
                statusLabel.hidden = YES;
        }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
        [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
        [picker dismissViewControllerAnimated:YES completion:^{
                NSDictionary *imageData;
                NSURL *imagePath;
                UIImage *image;
                
                /*
                 *  In order to support GIFs, we can't just use the image
                 *  returned by the controller. We have to fetch the
                 *  image ourselves so as not to lose its data.
                 */
                imagePath = [info objectForKey:UIImagePickerControllerReferenceURL];
                
                if ( imagePath ) {
                        imageData = [Util imageDataFromReferenceURL:imagePath];
                        
                        if ( imageData ) {
                                image = [UIImage imageWithData:[imageData objectForKey:@"data"]];
                                
                                [editor insertImage:image];
                        }
                }
        }];
}

- (void)insertPhoto
{
        [self presentMediaPicker];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
        if ( isShowingKeyboard ) {
                [self moveUIDown];
                
                isShowingKeyboard = NO;
                
                if ( [_delegate respondsToSelector:@selector(textEditorView:didChangeKeyboardVisibility:)] )
                        [_delegate textEditorView:self didChangeKeyboardVisibility:isShowingKeyboard];
        }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
        if ( !isShowingKeyboard ) {
                NSDictionary *info;
                
                info                      = [notification userInfo];
                keyboardAnimationCurve    = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
                keyboardAnimationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
                keyboardSize              = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
                
                [self dismissStrokeColorOptions];
                [self moveUIUp];
                
                isShowingKeyboard = YES;
                
                if ( [_delegate respondsToSelector:@selector(textEditorView:didChangeKeyboardVisibility:)] )
                        [_delegate textEditorView:self didChangeKeyboardVisibility:isShowingKeyboard];
                
                if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_TEXT_SIZE] )
                        [self playTextSizeTutorial];
        }
}

- (void)loadView
{
        UIBlurEffect *blurEffect;
        UIView *dividerLower;
        UIView *dividerUpperBottom;
        UIView *dividerUpperTop;
        
        [super loadView];
        
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        dateLabel               = [UILabel new];
        dateLabel.font          = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:29];
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.textColor     = UIColor.blackColor;
        
        dayLabel      = [UILabel new];
        dayLabel.font = [UIFont fontWithName:@"Georgia-Italic" size:9];
        
        dividerLower                 = [[UIView alloc] initWithFrame:CGRectMake(15, 84, self.view.bounds.size.width - 30, 1)];
        dividerLower.backgroundColor = UIColor.blackColor;
        
        dividerMidLeft                 = [[UIView alloc] initWithFrame:CGRectMake(15, 32, self.view.bounds.size.width / 2, 1)];
        dividerMidLeft.backgroundColor = UIColor.blackColor;
        
        dividerMidRight                 = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2, 32, self.view.bounds.size.width / 2, 1)];
        dividerMidRight.backgroundColor = UIColor.blackColor;
        
        dividerUpperBottom                 = [[UIView alloc] initWithFrame:CGRectMake(15, 15, self.view.bounds.size.width - 30, 1)];
        dividerUpperBottom.backgroundColor = UIColor.blackColor;
        
        dividerUpperTop                 = [[UIView alloc] initWithFrame:CGRectMake(15, 17, self.view.bounds.size.width - 30, 1)];
        dividerUpperTop.backgroundColor = UIColor.blackColor;
        
        doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        doneButton.titleLabel.font = [UIFont fontWithName:@"Georgia" size:UIFont.buttonFontSize];
        
        [doneButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
        [doneButton setTitle:@"DONE" forState:UIControlStateNormal];
        [doneButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [doneButton sizeToFit];
        
        doneButton.frame = CGRectMake(self.view.bounds.size.width - doneButton.bounds.size.width - 15, 17, doneButton.bounds.size.width, 51);
        
        editor                             = [[TextEditor alloc] initWithFrame:self.view.bounds];
        editor.allowsEditingTextAttributes = YES;
        editor.backgroundColor             = UIColor.clearColor;
        editor.delegate                    = self;
        editor.keyboardDismissMode         = UIScrollViewKeyboardDismissModeInteractive;
        editor.textContainerInset          = UIEdgeInsetsMake(100, 35, 84, 35);
        editor.scrollIndicatorInsets       = UIEdgeInsetsMake(85, 10, 49, 10);
        
        [self resetEditorAttributes];
        
        inkLayer          = [[InkView alloc] initWithFrame:editor.bounds];
        inkLayer.delegate = self;
        
        inkWell                 = [[InkWell alloc] initWithFrame:CGRectMake(8, 20, 40, 40)];
        inkWell.backgroundColor = DEFAULT_STROKE_COLOR;
        
        locationLabel      = [UILabel new];
        locationLabel.font = [UIFont fontWithName:@"Georgia" size:9];
        
        navigationBar       = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        navigationBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 85);
        
        statusLabel               = [UILabel new];
        statusLabel.font          = [UIFont fontWithName:@"Georgia-Italic" size:UIFont.buttonFontSize];
        statusLabel.hidden        = YES;
        statusLabel.textAlignment = NSTextAlignmentCenter;
        statusLabel.textColor     = UIColor.blackColor;
        
        timeLabel      = [UILabel new];
        timeLabel.font = [UIFont fontWithName:@"Georgia" size:9];
        
        self.view.backgroundColor = [UIColor colorWithRed:251/255.0 green:251/255.0 blue:240/255.0 alpha:1.0];
        
        [navigationBar.contentView addSubview:dividerLower];
        [navigationBar.contentView addSubview:dividerMidLeft];
        [navigationBar.contentView addSubview:dividerMidRight];
        [navigationBar.contentView addSubview:dividerUpperBottom];
        [navigationBar.contentView addSubview:dividerUpperTop];
        [navigationBar.contentView addSubview:dateLabel];
        [navigationBar.contentView addSubview:dayLabel];
        [navigationBar.contentView addSubview:locationLabel];
        [navigationBar.contentView addSubview:statusLabel];
        [navigationBar.contentView addSubview:timeLabel];
        [navigationBar.contentView addSubview:inkWell];
        [navigationBar.contentView addSubview:doneButton];
        [self.view addSubview:inkLayer];
        [self.view addSubview:editor];
        [self.view addSubview:navigationBar];
}

- (void)moveUIDown
{
        if ( isShowingKeyboard ) {
                if ( [_delegate respondsToSelector:@selector(textEditorViewDidEndEditing:)] )
                        [_delegate textEditorViewDidEndEditing:self];
                
                [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:keyboardAnimationCurve animations:^{
                        editor.textContainerInset    = UIEdgeInsetsMake(editor.textContainerInset.top, editor.textContainerInset.left, 84, editor.textContainerInset.right);
                        editor.scrollIndicatorInsets = UIEdgeInsetsMake(editor.scrollIndicatorInsets.top,
                                                                        editor.scrollIndicatorInsets.left,
                                                                        49,
                                                                        editor.scrollIndicatorInsets.right);
                } completion:^(BOOL finished){
                        
                }];
        }
}

- (void)moveUIUp
{
        if ( !isShowingKeyboard ) {
                if ( [_delegate respondsToSelector:@selector(textEditorViewDidBeginEditing:)] )
                        [_delegate textEditorViewDidBeginEditing:self];
                
                [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:keyboardAnimationCurve animations:^{
                        editor.textContainerInset    = UIEdgeInsetsMake(editor.textContainerInset.top, editor.textContainerInset.left, keyboardSize.height + 35, editor.textContainerInset.right);
                        editor.scrollIndicatorInsets = UIEdgeInsetsMake(editor.scrollIndicatorInsets.top,
                                                                        editor.scrollIndicatorInsets.left,
                                                                        keyboardSize.height,
                                                                        editor.scrollIndicatorInsets.right);
                } completion:^(BOOL finished){
                        UITextRange *caretPosition;
                        CGRect caretRect;
                        
                        caretPosition = [editor selectedTextRange];
                        caretRect     = [editor caretRectForPosition:caretPosition.end];
                        caretRect.size.height += editor.textContainerInset.bottom;
                        
                        [editor scrollRectToVisible:caretRect animated:YES];
                }];
        }
}

- (void)playInkTutorial
{
        __block UILabel *explanationLabel;
        __block UIView *overlay;
        
        explanationLabel               = [[UILabel alloc] initWithFrame:CGRectMake(35, 35, self.view.bounds.size.width - 70, self.view.bounds.size.height - keyboardSize.height - 35)];
        explanationLabel.font          = [UIFont systemFontOfSize:UIFont.buttonFontSize];
        explanationLabel.numberOfLines = 0;
        explanationLabel.text          = @"You can now start drawing highlights. Tap the ink button again to exit drawing mode.";
        explanationLabel.textAlignment = NSTextAlignmentCenter;
        explanationLabel.textColor     = UIColor.whiteColor;
        
        overlay                 = [[UIView alloc] initWithFrame:self.view.bounds];
        overlay.alpha           = 0;
        overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        
        [overlay addSubview:explanationLabel];
        [self.view addSubview:overlay];
        [UIView animateWithDuration:0.2 animations:^{
                overlay.alpha = 1.0;
        } completion:^(BOOL finished){
                [UIView animateWithDuration:0.2 delay:4.0 options:UIViewAnimationOptionCurveLinear animations:^{
                        explanationLabel.alpha = 0.0;
                } completion:^(BOOL finished){
                        explanationLabel.text = @"Long press the ink button for more colors.";
                        
                        [UIView animateWithDuration:0.2 animations:^{
                                explanationLabel.alpha = 1.0;
                        } completion:^(BOOL finished){
                                [UIView animateWithDuration:0.2 delay:3.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                        overlay.alpha = 0.0;
                                } completion:^(BOOL finished){
                                        [NSUserDefaults.standardUserDefaults setObject:@"1" forKey:NSUDKEY_TUTORIAL_INK];
                                        [overlay removeFromSuperview];
                                        
                                        explanationLabel = nil;
                                        overlay          = nil;
                                }];
                        }];
                }];
        }];
}

- (void)playTextSizeTutorial
{
        __block UILabel *explanationLabel;
        __block UIView *overlay;
        
        explanationLabel               = [[UILabel alloc] initWithFrame:CGRectMake(35, 35, self.view.bounds.size.width - 70, self.view.bounds.size.height - keyboardSize.height - 35)];
        explanationLabel.font          = [UIFont systemFontOfSize:UIFont.buttonFontSize];
        explanationLabel.numberOfLines = 0;
        explanationLabel.text          = @"After typing something, pinch the screen to change the overall text size, or select some text & pinch to resize that selection only.";
        explanationLabel.textAlignment = NSTextAlignmentCenter;
        explanationLabel.textColor     = UIColor.whiteColor;
        
        overlay                 = [[UIView alloc] initWithFrame:self.view.bounds];
        overlay.alpha           = 0;
        overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        
        [overlay addSubview:explanationLabel];
        [self.view addSubview:overlay];
        [UIView animateWithDuration:0.2 animations:^{
                overlay.alpha = 1.0;
        } completion:^(BOOL finished){
                [UIView animateWithDuration:0.2 delay:4.0 options:UIViewAnimationOptionCurveLinear animations:^{
                        overlay.alpha = 0.0;
                } completion:^(BOOL finished){
                        [NSUserDefaults.standardUserDefaults setObject:@"1" forKey:NSUDKEY_TUTORIAL_TEXT_SIZE];
                        [overlay removeFromSuperview];
                        
                        explanationLabel = nil;
                        overlay          = nil;
                }];
        }];
}

- (void)presentMediaPicker
{
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:mediaPickerController animated:YES completion:nil];
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
                                        if ( ![inkWell.backgroundColor isEqual:UIColor.clearColor] )
                                                colorButton.backgroundColor = UIColor.clearColor;
                                        else
                                                colorButton.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                                        
                                        break;
                                }
                                        
                                default:
                                        break;
                        }
                        
                        [colorButton addGestureRecognizer:colorButtonTapRecognizer];
                        [navigationBar.contentView addSubview:colorButton];
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
                        dateLabel.alpha = 0.0;
                        inkWell.transform = CGAffineTransformScale(inkWell.transform, 2.5, 2.5);
                } completion:^(BOOL finished){
                        [UIView animateWithDuration:0.1 animations:^{
                                inkWell.transform = CGAffineTransformIdentity;
                        }];
                }];
        }
}

- (void)registerForKeyboard
{
        if ( !self.isFocusedController ) {
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(keyboardWillShow:)
                                                           name:UIKeyboardWillShowNotification
                                                         object:nil];
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(keyboardWillHide:)
                                                           name:UIKeyboardWillHideNotification
                                                         object:nil];
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(keyboardWillShow:)
                                                           name:UIKeyboardWillChangeFrameNotification
                                                         object:nil];
        }
}

- (void)resetEditorAttributes
{
        NSMutableParagraphStyle *editorParagraphStyle;
        
        editorParagraphStyle             = [NSMutableParagraphStyle new];
        editorParagraphStyle.lineSpacing = 8;
        
        editor.attributedText = [[NSAttributedString alloc] initWithString:@" "
                                                                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Georgia" size:16],
                                                                             NSParagraphStyleAttributeName: editorParagraphStyle}];
        editor.text           = @"";
}

- (void)scaleFontSize:(CGFloat)scale
{
        /*
         * If no text is selected, we resize all the
         * text, otherwise we resize the text that the
         * user selected.
         */
        NSMutableAttributedString *mutableCopy;
        UITextPosition *beginning;
        UITextPosition *selectionEnd;
        UITextPosition *selectionStart;
        UITextRange *selectedRange;
        NSInteger location;
        NSInteger length;
        NSRange textRange;
        
        mutableCopy    = [editor.attributedText mutableCopy];
        beginning      = editor.beginningOfDocument;
        selectedRange  = editor.selectedTextRange;
        selectionStart = selectedRange.start;
        selectionEnd   = selectedRange.end;
        location       = [editor offsetFromPosition:beginning toPosition:selectionStart];
        length         = [editor offsetFromPosition:selectionStart toPosition:selectionEnd];
        textRange      = NSMakeRange(location, length);
        
        if ( textRange.length == 0 )
                textRange = NSMakeRange(0, mutableCopy.length);
        
        [mutableCopy beginEditing];
        [mutableCopy enumerateAttribute:NSFontAttributeName
                                inRange:textRange
                                options:0
                             usingBlock:^(id value, NSRange range, BOOL *stop) {
                                     if ( value ) {
                                             UIFont *newFont;
                                             UIFont *oldFont;
                                             CGSize textSize;
                                             
                                             oldFont = (UIFont *)value;
                                             newFont = [oldFont fontWithSize:oldFont.pointSize * scale];
                                             
                                             [mutableCopy removeAttribute:NSFontAttributeName range:range];
                                             [mutableCopy addAttribute:NSFontAttributeName value:newFont range:range];
                                             
                                             editor.attributedText    = mutableCopy;
                                             editor.selectedTextRange = selectedRange; // Selection gets lost when we edit the text, set it again.
                                             statusLabel.text         = [NSString stringWithFormat:@"%.f pt%@",
                                                                        truncf(newFont.pointSize),
                                                                        (truncf(newFont.pointSize) == 1) ? @"" : @"s"]; // Display size with only the tenths.
                                             
                                             textSize       = [editor sizeThatFits:CGSizeMake(editor.bounds.size.width, CGFLOAT_MAX)];
                                             inkLayer.frame = CGRectMake(0, 0, editor.bounds.size.width, MAX(editor.bounds.size.height, textSize.height));
                                             
                                             [self showStatusLabel];
                                     }
                             }];
        [mutableCopy endEditing];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
        if ( [scrollView isEqual:editor] ) {
                inkLayer.frame   = CGRectMake(0, -scrollView.contentOffset.y, inkLayer.bounds.size.width, inkLayer.bounds.size.height);
        }
}

- (void)setCurrentLocation:(NSString *)currentLocation
{
        if ( currentLocation ) {
                locationLabel.text = [currentLocation uppercaseString];
                
                [locationLabel sizeToFit];
                
                locationLabel.frame = CGRectMake((navigationBar.bounds.size.width / 2) - (locationLabel.bounds.size.width / 2),
                                                 69,
                                                 locationLabel.bounds.size.width,
                                                 locationLabel.bounds.size.height);
        }
}

- (void)showStatusLabel
{
        if ( statusLabelTimer )
                [statusLabelTimer invalidate];
        
        statusLabelTimer = [NSTimer scheduledTimerWithTimeInterval:0.7
                                                            target:self
                                                          selector:@selector(hideStatusLabel)
                                                          userInfo:nil
                                                           repeats:NO];
        [statusLabel sizeToFit];
        
        statusLabel.frame = CGRectMake((self.view.bounds.size.width / 2) - (statusLabel.bounds.size.width / 2),
                                       (navigationBar.bounds.size.height / 2) - (statusLabel.bounds.size.height / 2) + 8,
                                       statusLabel.bounds.size.width,
                                       statusLabel.bounds.size.height);
        
        if ( statusLabel.hidden ) {
                statusLabel.hidden = NO;
                
                [UIView animateWithDuration:0.2 animations:^{
                        dateLabel.alpha   = 0.0;
                        statusLabel.alpha = 1.0;
                }];
        }
}

- (void)startMonitoringTime
{
        if ( !timeLabelTimer ) {
                [self getCurrentTime];
                
                timeLabelTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(getCurrentTime) userInfo:nil repeats:YES];
        }
}

- (void)stopMonitoringTime
{
        if ( timeLabelTimer ) {
                [timeLabelTimer invalidate];
                
                timeLabelTimer = nil;
        }
}

- (void)textViewDidChange:(UITextView *)textView
{
        if ( [textView isEqual:editor] ) {
                UITextRange *caretPosition;
                CGRect caretRect;
                CGSize textSize;
                
                caretPosition          = [editor selectedTextRange];
                caretRect              = [editor caretRectForPosition:caretPosition.end];
                caretRect.size.height += editor.textContainerInset.bottom;
                
                textSize       = [editor sizeThatFits:CGSizeMake(editor.bounds.size.width, CGFLOAT_MAX)];
                inkLayer.frame = CGRectMake(0, 0, editor.bounds.size.width, MAX(editor.bounds.size.height, textSize.height));
                
                [editor scrollRectToVisible:caretRect animated:YES];
                
                if ( editor.attributedText.length == 0 ) // Clear out stale attributes.
                        [self resetEditorAttributes];
        }
}

- (void)viewDidLoad
{
        UILongPressGestureRecognizer *inkWellLongPressRecognizer;
        UIMenuItem *insertPhotoMenuItem;
        UIPinchGestureRecognizer *editorPinchRecognizer;
        UITapGestureRecognizer *inkWellTapRecognizer;
        
        [super viewDidLoad];
        [self getCurrentDate];
        
        insertPhotoMenuItem                             = [[UIMenuItem alloc] initWithTitle:@"Insert Photo" action:@selector(insertPhoto)];
        UIMenuController.sharedMenuController.menuItems = @[insertPhotoMenuItem];
        
        editorPinchRecognizer      = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinchEditor:)];
        inkWellLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressInkWell:)];
        inkWellTapRecognizer       = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapInkWell:)];
        
        [inkWellTapRecognizer requireGestureRecognizerToFail:inkWellLongPressRecognizer];
        [editor addGestureRecognizer:editorPinchRecognizer];
        [inkWell addGestureRecognizer:inkWellLongPressRecognizer];
        [inkWell addGestureRecognizer:inkWellTapRecognizer];
}


@end
