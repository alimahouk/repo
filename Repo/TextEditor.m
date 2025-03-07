//
//  TextEditor.m
//  Repo
//
//  Created by Ali Mahouk on 7/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import MobileCoreServices;

#import "TextEditor.h"

@implementation TextEditor


- (void)insertImage:(UIImage *)image
{
        if ( image ) {
                NSAttributedString *attachmentString;
                NSMutableAttributedString *currentContents;
                NSTextAttachment *attachment;
                UITextRange *caretPosition;
                CGFloat oldImageWidth;
                CGFloat scaleFactor;
                NSInteger editorStartOffset;
                NSInteger editorEndOffset;
                NSRange caretRange;
                
                attachment       = [NSTextAttachment new];
                attachment.image = image;
                
                caretPosition     = [self selectedTextRange];
                currentContents   = [self.attributedText mutableCopy];
                oldImageWidth     = attachment.image.size.width;
                scaleFactor       = oldImageWidth / (self.textContainer.size.width - 10);
                attachment.image  = [UIImage imageWithCGImage:attachment.image.CGImage scale:scaleFactor orientation:attachment.image.imageOrientation];
                attachmentString  = [NSAttributedString attributedStringWithAttachment:attachment];
                editorStartOffset = [self offsetFromPosition:self.beginningOfDocument toPosition:caretPosition.start];
                editorEndOffset   = [self offsetFromPosition:self.beginningOfDocument toPosition:caretPosition.end];
                caretRange        = NSMakeRange(editorStartOffset, editorEndOffset - editorStartOffset);
                
                [currentContents insertAttributedString:attachmentString atIndex:caretRange.location];
                [currentContents addAttributes:self.typingAttributes range:NSMakeRange(caretRange.location, attachmentString.length)];
                
                self.attributedText = currentContents;
        }
}

- (void)paste:(id)sender
{
        NSData *GIFData;
        NSData *pasteBMPData;
        NSData *pasteGIFData;
        NSData *pasteICOData;
        NSData *pasteJPEGData;
        NSData *pastePNGData;
        NSData *pasteTIFFData;
        NSMutableAttributedString *currentContents;
        UIImage *image;
        UIImage *pasteImage;
        
        GIFData         = [UIPasteboard.generalPasteboard dataForPasteboardType:@"com.compuserve.gif"];
        pasteImage      = UIPasteboard.generalPasteboard.image;
        pasteBMPData    = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeBMP];
        pasteGIFData    = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeGIF];
        pasteICOData    = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeICO];
        pasteJPEGData   = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeJPEG];
        pastePNGData    = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypePNG];
        pasteTIFFData   = [UIPasteboard.generalPasteboard dataForPasteboardType:(NSString*)kUTTypeTIFF];
        
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
                [self insertImage:image];
        } else {
                [super paste:sender];
                
                // We need to remove any random backgrounds that might get pasted with text.
                currentContents = [self.attributedText mutableCopy];
                
                [currentContents beginEditing];
                [currentContents enumerateAttribute:NSBackgroundColorAttributeName
                                        inRange:NSMakeRange(0, currentContents.length)
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL *stop) {
                                             if ( value ) {
                                                     [currentContents removeAttribute:NSBackgroundColorAttributeName range:range];
                                                     
                                                     self.attributedText = currentContents;
                                             }
                                     }];
                [currentContents endEditing];
        }
}


@end
