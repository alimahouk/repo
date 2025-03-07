//
//  LinkItem.h
//  Repo
//
//  Created by Ali Mahouk on 7/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import WebKit;

#import "Item.h"

@interface LinkItem : Item <WKNavigationDelegate>
{
        UIImageView *thumbnail;
        UITextView *titleLabel;
        UITextView *URLLabel;
        WKWebView *browserView;
}

@property (nonatomic) NSString *title;
@property (nonatomic) NSURL *URL;

- (instancetype)initAtPoint:(CGPoint)point;

@end
