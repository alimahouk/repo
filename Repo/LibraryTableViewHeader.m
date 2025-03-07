//
//  LibraryTableViewHeader.m
//  Repo
//
//  Created by Ali Mahouk on 18/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "LibraryTableViewHeader.h"

@implementation LibraryTableViewHeader


- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
        self = [super initWithReuseIdentifier:reuseIdentifier];
        
        if ( self ) {
                self.backgroundView              = nil;
                self.contentView.backgroundColor = UIColor.clearColor;
                
                blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                
                background       = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                background.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44);
                
                _textField                        = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, background.bounds.size.width - 20, background.bounds.size.height)];
                _textField.attributedPlaceholder  = [[NSAttributedString alloc] initWithString:@"Title (leave blank to delete)" attributes:@{NSForegroundColorAttributeName: UIColor.grayColor}];
                _textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                _textField.backgroundColor        = UIColor.clearColor;
                _textField.font                   = [UIFont systemFontOfSize:UIFont.systemFontSize];
                _textField.keyboardAppearance     = UIKeyboardAppearanceDark;
                _textField.returnKeyType          = UIReturnKeyDone;
                _textField.textColor              = UIColor.whiteColor;
                
                [self.contentView addSubview:background];
                [self.contentView addSubview:_textField];
        }
        
        return self;
}

- (void)flash
{
        self.contentView.backgroundColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        background.effect                = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.contentView.backgroundColor = [UIColor clearColor];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.contentView.backgroundColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
                        _textField.textColor             = UIColor.whiteColor;
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                self.contentView.backgroundColor = [UIColor clearColor];
                                background.effect                = blurEffect;
                        });
                });
        });
}


@end
