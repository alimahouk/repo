//
//  LibraryViewController.h
//  Repo
//
//  Created by Ali Mahouk on 14/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "ViewController.h"

@class Item;
@class LibraryViewController;

@protocol LibraryViewControllerDelegate<NSObject>
@optional

- (void)libraryView:(LibraryViewController *)libraryViewController didHandOverItem:(Item *)item atPoint:(CGPoint)point imported:(BOOL)imported;
- (void)libraryView:(LibraryViewController *)libraryViewController didReceiveItem:(Item *)item;

@end

@interface LibraryViewController : ViewController <UICollectionViewDataSource,
                                                UICollectionViewDelegate,
                                                UIImagePickerControllerDelegate,
                                                UINavigationControllerDelegate,
                                                UITableViewDataSource,
                                                UITableViewDelegate,
                                                UITextFieldDelegate>
{
        NSMutableArray *collections;
        NSMutableDictionary *contentOffsetDictionary;
        NSTimer *hoverTimer;
        UIAlertAction *newCollectionCancel;
        UIAlertAction *newCollectionCreate;
        UIImagePickerController *mediaPickerController;
        UILabel *emptyLibraryLabel;
        UISelectionFeedbackGenerator *selectionFeedbackGenerator;
        UITextField *activeTextField;
        BOOL shouldReceiveItem;
        NSInteger hoveringRow;
        NSOperatingSystemVersion iOSVersionCheck;
}

@property (nonatomic) UITableView *tableView;
@property (nonatomic, weak) id <LibraryViewControllerDelegate> delegate;

- (void)didDropItem:(Item *)item atPoint:(CGPoint)point;
- (void)didMoveItemToPoint:(CGPoint)point;
- (void)reloadDataSource;

@end
