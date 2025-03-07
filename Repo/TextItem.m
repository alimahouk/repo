//
//  TextItem.m
//  Repo
//
//  Created by Ali Mahouk on 15/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import CoreText;

#import "TextItem.h"

#import "constants.h"

@implementation TextItem


- (instancetype)initAtPoint:(CGPoint)point
{
        TextItem *item;
        
        item        = [TextItem new];
        item.center = point;
        
        return item;
}

- (UIImage *)ink
{
        return i_ink;
}

- (NSAttributedString *)string
{
        return i_string;
}

- (void)setBounds:(CGRect)bounds
{
        [super setBounds:bounds];
        
        container.frame = bounds;
}

- (void)setFrame:(CGRect)frame
{
        [super setFrame:frame];
        
        container.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

- (void)setInk:(UIImage *)ink
{
        i_ink = ink;
}

- (void)setString:(NSAttributedString *)string
{
        i_string = string;
}

- (void)setup
{
        [super setup];
        
        self.itemType = ItemTypeText;
        
        if ( container )
                [container removeFromSuperview];
        
        if ( inkLayer )
                [inkLayer removeFromSuperview];
        
        if ( textView )
                [textView removeFromSuperview];
        
        container               = [[UIView alloc] initWithFrame:self.bounds];
        container.clipsToBounds = YES;
        
        inkLayer                 = [UIImageView new];
        inkLayer.backgroundColor = UIColor.clearColor;
        inkLayer.frame           = CGRectMake(-10, -64, i_ink.size.width, i_ink.size.height); // The ink usually includes space under the navi bar.
        inkLayer.opaque          = NO;
        inkLayer.image           = i_ink;
        
        textView                             = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)];
        textView.allowsEditingTextAttributes = YES;
        textView.backgroundColor             = UIColor.clearColor;
        textView.dataDetectorTypes           = UIDataDetectorTypeCalendarEvent | UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        textView.editable                    = NO;
        textView.scrollEnabled               = NO;
        textView.userInteractionEnabled      = NO;
        
        /*
         * After a certain point, the invisible content starts impacting performance.
         * Truncate it to just show the visible part.
         */
        CFRange range;
        CGContextRef currentContext;
        CGMutablePathRef framePath;
        CGRect frameRect;
        CTFramesetterRef framesetter;
        CTFrameRef frame;
        
        currentContext = UIGraphicsGetCurrentContext();
        frameRect      = CGRectMake(0, 0, textView.bounds.size.width, ITEM_PREVIEW_SIZE);
        framePath      = CGPathCreateMutable();
        
        CGPathAddRect(framePath, NULL, frameRect);
        
        framesetter             = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)i_string);
        frame                   = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, i_string.length), framePath, NULL);
        range                   = CTFrameGetVisibleStringRange(frame);
        textView.attributedText = [i_string attributedSubstringFromRange:NSMakeRange(range.location, range.length)];
        
        self.backgroundColor = [UIColor colorWithRed:251/255.0 green:251/255.0 blue:240/255.0 alpha:1.0];
        self.bounds          = CGRectMake(0, 0, ITEM_PREVIEW_SIZE, ITEM_PREVIEW_SIZE);
        
        [container addSubview:inkLayer];
        [container addSubview:textView];
        [self addSubview:container];
}


@end
