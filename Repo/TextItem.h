//
//  TextItem.h
//  Repo
//
//  Created by Ali Mahouk on 15/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "Item.h"

@interface TextItem : Item
{
        NSAttributedString *i_string;
        UIImage *i_ink;
        UIImageView *inkLayer;
        UITextView *textView;
        UIView *container;
}

@property (nonatomic) UIImage *ink;
@property (nonatomic) NSAttributedString *string;

- (instancetype)initAtPoint:(CGPoint)point;

@end
