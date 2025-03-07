//
//  LibraryTableViewHeader.h
//  Repo
//
//  Created by Ali Mahouk on 18/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

@interface LibraryTableViewHeader : UITableViewHeaderFooterView
{
        UIBlurEffect *blurEffect;
        UIVisualEffectView *background;
}

@property (nonatomic) UITextField *textField;

- (void)flash;

@end
