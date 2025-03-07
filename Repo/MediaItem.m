//
//  MediaItem.m
//  Repo
//
//  Created by Ali Mahouk on 15/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import ImageIO;

#import "MediaItem.h"

#import "Util.h"

@implementation MediaItem


- (instancetype)initAtPoint:(CGPoint)point
{
        MediaItem *item;
        
        item        = [MediaItem new];
        item.center = point;
        
        return item;
}

- (NSAttributedString *)caption
{
        return i_caption;
}

- (UIImage *)image
{
        return i_image;
}

- (UIImage *)ink
{
        return i_ink;
}

- (void)setBounds:(CGRect)bounds
{
        [super setBounds:bounds];
        
        container.frame = bounds;
        imageView.frame = bounds;
        inkLayer.frame  = imageView.bounds;
        
        if ( self.itemType == ItemTypeMovie )
                videoIcon.frame = CGRectMake((bounds.size.width / 2) - (videoIcon.bounds.size.width / 2),
                                             (bounds.size.height / 2) - (videoIcon.bounds.size.height / 2),
                                             videoIcon.bounds.size.width,
                                             videoIcon.bounds.size.height);
}

- (void)setCaption:(NSAttributedString *)caption
{
        i_caption = caption;   
}

- (void)setFrame:(CGRect)frame
{
        [super setFrame:frame];
        
        container.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        imageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        inkLayer.frame  = imageView.frame;
        
        if ( self.itemType == ItemTypeMovie )
                videoIcon.frame = CGRectMake((frame.size.width / 2) - (videoIcon.bounds.size.width / 2),
                                             (frame.size.height / 2) - (videoIcon.bounds.size.height / 2),
                                             videoIcon.bounds.size.width,
                                             videoIcon.bounds.size.height);
}

- (void)setImage:(UIImage *)image
{
        i_image = image;
}

- (void)setInk:(UIImage *)ink
{
        i_ink = ink;
}

- (void)setup
{
        [super setup];
        
        if ( container )
                [container removeFromSuperview];
        
        if ( imageView )
                [imageView removeFromSuperview];
        
        if ( inkLayer )
                [inkLayer removeFromSuperview];
        
        if ( _captionView )
                [_captionView removeFromSuperview];
        
        if ( videoIcon )
                [videoIcon removeFromSuperview];
        
        container               = [[UIView alloc] initWithFrame:self.bounds];
        container.clipsToBounds = YES;
        
        imageView               = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode   = UIViewContentModeScaleAspectFill;
        imageView.image         = [Util thumbnailForImage:i_image];
        
        inkLayer                 = [UIImageView new];
        inkLayer.backgroundColor = UIColor.clearColor;
        inkLayer.contentMode     = UIViewContentModeScaleAspectFill;
        inkLayer.image           = i_ink;
        inkLayer.opaque          = NO;
        
        _captionView                             = [UITextView new];
        _captionView.allowsEditingTextAttributes = YES;
        _captionView.scrollEnabled               = NO;
        _captionView.userInteractionEnabled      = NO;
        _captionView.attributedText              = i_caption;
        
        if ( self.itemType == ItemTypeMovie ) {
                UIBlurEffect *blurEffect;
                UILabel *label;
                
                blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
                
                videoIcon               = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                videoIcon.clipsToBounds = YES;
                videoIcon.frame         = CGRectMake((self.bounds.size.width / 2) - (videoIcon.bounds.size.width / 2),
                                                     (self.bounds.size.height / 2) - (videoIcon.bounds.size.height / 2),
                                                     40,
                                                     40);
                videoIcon.layer.cornerRadius = videoIcon.bounds.size.width / 2;
                
                label      = [UILabel new];
                label.font = [UIFont boldSystemFontOfSize:UIFont.buttonFontSize];
                label.text = @"▶";
                
                [label sizeToFit];
                
                label.frame = CGRectMake((videoIcon.bounds.size.width / 2) - (label.bounds.size.width / 2),
                                         (videoIcon.bounds.size.height / 2) - (label.bounds.size.height / 2),
                                         label.bounds.size.width,
                                         label.bounds.size.height);
                
                [videoIcon.contentView addSubview:label];
        }
        
        self.bounds = CGRectMake(0, 0, ITEM_PREVIEW_SIZE, ITEM_PREVIEW_SIZE);
        
        [container addSubview:imageView];
        [container addSubview:inkLayer];
        [container addSubview:_captionView];
        [self addSubview:container];
        
        if ( self.itemType == ItemTypeMovie )
                [self addSubview:videoIcon];
}


@end
