//
//  LinkItem.m
//  Repo
//
//  Created by Ali Mahouk on 7/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "LinkItem.h"

#import "AppDelegate.h"
#import "Util.h"

@implementation LinkItem


- (instancetype)initAtPoint:(CGPoint)point
{
        LinkItem *item;
        
        item        = [LinkItem new];
        item.center = point;
        
        return item;
}

- (void)setBounds:(CGRect)bounds
{
        [super setBounds:bounds];
        
        thumbnail.frame  = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
        titleLabel.frame = CGRectMake(0,
                                      bounds.size.height - URLLabel.bounds.size.height - titleLabel.bounds.size.height,
                                      bounds.size.width,
                                      titleLabel.bounds.size.height);
        URLLabel.frame   = CGRectMake(0,
                                      bounds.size.height - URLLabel.bounds.size.height,
                                      bounds.size.width,
                                      URLLabel.bounds.size.height);
}

- (void)setFrame:(CGRect)frame
{
        [super setFrame:frame];
        
        thumbnail.frame  = CGRectMake(0, 0, frame.size.width, frame.size.height);
        titleLabel.frame = CGRectMake(0,
                                      frame.size.height - URLLabel.bounds.size.height - titleLabel.bounds.size.height,
                                      frame.size.width,
                                      titleLabel.bounds.size.height);
        URLLabel.frame   = CGRectMake(0,
                                      frame.size.height - URLLabel.bounds.size.height,
                                      frame.size.width,
                                      URLLabel.bounds.size.height);
}

- (void)setup
{
        [super setup];
        
        self.itemType = ItemTypeLink;
        
        if ( thumbnail )
                [thumbnail removeFromSuperview];
        
        if ( titleLabel )
                [titleLabel removeFromSuperview];
        
        if ( URLLabel )
                [URLLabel removeFromSuperview];
        
        thumbnail             = [UIImageView new];
        thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        thumbnail.image       = self.snapshot;
        
        titleLabel                                    = [UITextView new];
        titleLabel.alpha                              = 0.0;
        titleLabel.backgroundColor                    = [UIColor colorWithWhite:1.0 alpha:0.7];
        titleLabel.editable                           = NO;
        titleLabel.font                               = [UIFont boldSystemFontOfSize:12];
        titleLabel.hidden                             = YES;
        titleLabel.scrollEnabled                      = NO;
        titleLabel.scrollsToTop                       = NO;
        titleLabel.textContainer.maximumNumberOfLines = 1;
        titleLabel.textContainer.lineBreakMode        = NSLineBreakByTruncatingTail;
        titleLabel.textContainerInset                 = UIEdgeInsetsMake(5, 5, 0, 5);
        titleLabel.userInteractionEnabled             = NO;
        
        URLLabel                                    = [UITextView new];
        URLLabel.backgroundColor                    = [UIColor colorWithWhite:1.0 alpha:0.7];
        URLLabel.editable                           = NO;
        URLLabel.font                               = [UIFont systemFontOfSize:12];
        URLLabel.scrollEnabled                      = NO;
        URLLabel.scrollsToTop                       = NO;
        URLLabel.textColor                          = UIColor.grayColor;
        URLLabel.textContainer.maximumNumberOfLines = 1;
        URLLabel.textContainer.lineBreakMode        = NSLineBreakByTruncatingTail;
        URLLabel.textContainerInset                 = UIEdgeInsetsMake(5, 5, 5, 5);
        URLLabel.userInteractionEnabled             = NO;
        
        [titleLabel sizeToFit];
        [URLLabel sizeToFit];
        
        self.bounds        = CGRectMake(0, 0, ITEM_PREVIEW_SIZE, ITEM_PREVIEW_SIZE);
        self.clipsToBounds = YES;
        
        [self addSubview:thumbnail];
        [self addSubview:titleLabel];
        [self addSubview:URLLabel];
        [self setURLLabelText];
        
        if ( _URL &&
             !self.snapshot ) {
                if ( !browserView ) {
                        browserView                        = [[WKWebView alloc] initWithFrame:CGRectMake(-UIScreen.mainScreen.bounds.size.width,
                                                                                                         -UIScreen.mainScreen.bounds.size.height,
                                                                                                         UIScreen.mainScreen.bounds.size.width,
                                                                                                         UIScreen.mainScreen.bounds.size.height)];
                        browserView.navigationDelegate     = self;
                        browserView.userInteractionEnabled = NO;
                        
                        [self addSubview:browserView];
                } else {
                        [self addSubview:browserView];
                }
                
                [browserView loadRequest:[NSURLRequest requestWithURL:_URL]];
        }
}

- (void)setURLLabelText
{
        if ( _URL ) {
                NSString *wwwPrefix;
                
                if ( _title ) {
                        titleLabel.hidden = NO;
                        titleLabel.text   = [NSString stringWithFormat:@"%@", _title];
                        
                        [UIView animateWithDuration:0.3 animations:^{
                                titleLabel.alpha = 1.0;
                        }];
                }
                
                URLLabel.text = [NSString stringWithFormat:@"%@", _URL.host];
                wwwPrefix     = @"www.";
                
                if ( [_URL.host hasPrefix:wwwPrefix] ) // Get rid of the prefix for presentation purposes.
                        URLLabel.text = [URLLabel.text stringByReplacingCharactersInRange:NSMakeRange(0, wwwPrefix.length) withString:@""];
        }
}

- (void)webView:(WKWebView *)webView didFailLoadWithError:(nonnull NSError *)error
{
        NSLog(@"%@", error);
        
        [browserView removeFromSuperview];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
        NSLog(@"%@", error);
        
        [browserView removeFromSuperview];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIGraphicsBeginImageContextWithOptions(browserView.bounds.size, NO, 0.0);
                
                [browserView drawViewHierarchyInRect:browserView.bounds afterScreenUpdates:YES];
                
                self.snapshot = UIGraphicsGetImageFromCurrentImageContext();
                self.snapshot = [Util imageByCroppingImage:self.snapshot toSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.width)];
                
                UIGraphicsEndImageContext();
                
                thumbnail.image = self.snapshot;
                
                // Get the page's title.
                [webView evaluateJavaScript:@"document.title" completionHandler:^(id result, NSError *error){
                        if ( error ) {
                                NSLog(@"%@", error);
                        } else {
                                _title = result;
                                
                                [self setURLLabelText];
                        }
                        
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLinkItem:self inCollection:nil];
                        [browserView removeFromSuperview];
                }];
        });
}


@end
