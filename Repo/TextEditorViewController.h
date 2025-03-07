//
//  TextEditorViewController.h
//  Repo
//
//  Created by Ali Mahouk on 13/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "InkView.h"
#import "ViewController.h"

@class InkWell;
@class Item;
@class TextEditor;
@class TextEditorViewController;
@class TextItem;

@protocol TextEditorViewControllerDelegate<NSObject>
@optional

- (void)textEditorViewDidBeginAnnotating:(TextEditorViewController *)editorViewController;
- (void)textEditorViewDidBeginEditing:(TextEditorViewController *)editorViewController;
- (void)textEditorView:(TextEditorViewController *)editorViewController didChangeKeyboardVisibility:(BOOL)visible;
- (void)textEditorViewDidEndAnnotating:(TextEditorViewController *)editorViewController;
- (void)textEditorViewDidEndEditing:(TextEditorViewController *)editorViewController;
- (void)textEditorView:(TextEditorViewController *)editorViewController didHandOverItem:(Item *)item isEdit:(BOOL)isEdit;

@end

@interface TextEditorViewController : ViewController <InkViewDelegate,
                                                UIImagePickerControllerDelegate,
                                                UINavigationControllerDelegate,
                                                UIScrollViewDelegate,
                                                UITextViewDelegate>
{
        InkView *inkLayer;
        InkWell *inkWell;
        NSTimer *timeLabelTimer;
        NSTimer *statusLabelTimer;
        TextEditor *editor;
        TextItem *workingItem;
        UIButton *doneButton;
        UIImagePickerController *mediaPickerController;
        UILabel *dateLabel;
        UILabel *dayLabel;
        UILabel *locationLabel;
        UILabel *statusLabel;
        UILabel *timeLabel;
        UISelectionFeedbackGenerator *selectionFeedbackGenerator;
        UIView *dividerMidLeft;
        UIView *dividerMidRight;
        UIVisualEffectView *navigationBar;
        BOOL isShowingKeyboard;
        BOOL isShowingStrokeColorOptions;
        CGFloat keyboardAnimationDuration;
        CGSize keyboardSize;
        NSOperatingSystemVersion iOSVersionCheck;
        UIViewAnimationOptions keyboardAnimationCurve;
}

@property (nonatomic) NSString *currentLocation;
@property (nonatomic, readonly) BOOL showingKeyboard;
@property (nonatomic, weak) id <TextEditorViewControllerDelegate> delegate;

- (void)blurEditor;
- (void)didDropItem:(TextItem *)item;
- (void)focusEditor;
- (void)getCurrentDate;

@end
