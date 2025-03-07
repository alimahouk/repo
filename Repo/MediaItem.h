//
//  MediaItem.h
//  Repo
//
//  Created by Ali Mahouk on 15/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "Item.h"

@interface MediaItem : Item
{
        NSAttributedString *i_caption;
        UIImage *i_image;
        UIImage *i_ink;
        UIImageView *imageView;
        UIImageView *inkLayer;
        UIView *container;
        UIVisualEffectView *videoIcon;
}

@property (nonatomic) NSAttributedString *caption;
@property (nonatomic) UIImage *image;
@property (nonatomic) UIImage *ink;
@property (nonatomic) UITextView *captionView;

- (instancetype)initAtPoint:(CGPoint)point;

@end
