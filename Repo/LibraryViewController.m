//
//  LibraryViewController.m
//  Repo
//
//  Created by Ali Mahouk on 14/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVFoundation;
@import MobileCoreServices;

#import "LibraryViewController.h"

#import "AppDelegate.h"
#import "Collection.h"
#import "CollectionExplorerViewController.h"
#import "constants.h"
#import "MediaItem.h"
#import "LibraryTableViewCell.h"
#import "LibraryTableViewHeader.h"
#import "LinkItem.h"
#import "LocationItem.h"
#import "TextItem.h"
#import "Util.h"

@implementation LibraryViewController


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                collections                = [NSMutableArray array];
                contentOffsetDictionary    = [NSMutableDictionary dictionary];
                hoveringRow                = -1;
                iOSVersionCheck            = (NSOperatingSystemVersion){10, 0, 0};
                
                mediaPickerController          = [UIImagePickerController new];
                mediaPickerController.delegate = self;
                
                if ( [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOSVersionCheck] )
                        selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
                        
                shouldReceiveItem = NO;
                
                self.tabBarItem.image         = [UIImage imageNamed:@"library"];
                self.tabBarItem.selectedImage = [UIImage imageNamed:@"library_selected"];
                self.title                    = @"Library";
        }
        
        return self;
}

- (UICollectionViewCell *)collectionView:(IndexedCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
        Collection *collection;
        Item *item;
        static NSString *identifier;
        UICollectionViewCell *cell;
        UILongPressGestureRecognizer *longPressRecognizer;
        
        identifier          = @"LibraryCell";
        cell                = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        collection          = collections[collectionView.indexPath.section];
        item                = collection.items[indexPath.row];
        longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressItem:)];
        
        item.center = CGPointMake(cell.bounds.size.width / 2, cell.bounds.size.height / 2);
        item.userInteractionEnabled = NO;
        
        [cell.contentView addSubview:item];
        [cell.contentView addGestureRecognizer:longPressRecognizer];
                
        return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        LibraryTableViewCell *cell;
        static NSString *identifier;
        
        identifier = [NSString stringWithFormat:@"LibraryCell"];
        cell       = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if ( !cell ) {
                cell = [[LibraryTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                [cell.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:identifier];
        }
        
        return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
        Collection *collection;
        LibraryTableViewHeader *header;
        static NSString *identifier;
        
        collection = collections[section];
        identifier = [NSString stringWithFormat:@"LibraryTableViewHeaderIdentifier"];
        header     = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        
        if ( !header )
                header = [[LibraryTableViewHeader alloc] initWithReuseIdentifier:identifier];
        
        header.textField.delegate = self;
        header.textField.tag      = section;
        header.textField.text     = collection.title;
        
        return header;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
        [textField resignFirstResponder];
        
        return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
        return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return ITEM_PREVIEW_SIZE;
}

- (NSInteger)collectionView:(IndexedCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
        Collection *collection;
        
        collection = collections[collectionView.indexPath.section];
        
        if ( collection.items.count == 0 )
                collectionView.emptyCollectionLabel.hidden = NO;
        else
                collectionView.emptyCollectionLabel.hidden = YES;
        
        return collection.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
        if ( collections.count == 0 )
                emptyLibraryLabel.hidden = NO;
        else
                emptyLibraryLabel.hidden = YES;
        
        return collections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return 1;
}

- (void)alertForExists:(NSString *)title
{
        UIAlertAction *cancel;
        UIAlertAction *chooseNew;
        UIAlertController *alert;
        
        alert     = [UIAlertController alertControllerWithTitle:@"Wait…"
                                                    message:@"That name is already being used for another collection. Pick a different name."
                                             preferredStyle:UIAlertControllerStyleAlert];
        cancel    = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
        }];
        chooseNew = [UIAlertAction actionWithTitle:@"Retype" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
                [self newCollection];
        }];
        
        [alert addAction:cancel];
        [alert addAction:chooseNew];
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)collectionView:(IndexedCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
        Collection *collection;
        CollectionExplorerViewController *explorerView;
        
        collection = collections[collectionView.indexPath.section];
        
        explorerView                      = [CollectionExplorerViewController new];
        explorerView.item                 = collection.items[indexPath.row];
        explorerView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:explorerView animated:YES completion:nil];
}

- (void)confirmCollectionDeletion:(Collection *)collection
{
        UIAlertAction *cancel;
        UIAlertAction *delete;
        UIAlertController *alert;
        
        alert     = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Deleting \"%@\"", collection.title]
                                                        message:@"Leaving the title blank will delete this collection along with everything in it. Are you sure you want to continue?"
                                                 preferredStyle:UIAlertControllerStyleAlert];
        cancel    = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        // Reset the title of the collection.
                        for ( int i = 0; i < collections.count; i++ ) {
                                Collection *c;
                                
                                c = collections[i];
                                
                                if ( [c isEqual:collection] ) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                LibraryTableViewHeader *header;
                                                
                                                header                = (LibraryTableViewHeader *)[self.tableView headerViewForSection:i];
                                                header.textField.text = c.title;
                                        });
                                        
                                        break;
                                }
                        }
                });
        }];
        delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                [self.tableView beginUpdates];
                
                for ( int i = 0; i < collections.count; i++ ) {
                        Collection *c;
                        
                        c = collections[i];
                        
                        if ( [c isEqual:collection] ) {
                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] deleteCollection:c];
                                [self.tableView beginUpdates];
                                [collections removeObjectAtIndex:i];
                                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationAutomatic];
                                [self.tableView endUpdates];
                                
                                break;
                        }
                }
                
                [self.tableView endUpdates];
        }];
        
        [alert addAction:cancel];
        [alert addAction:delete];
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)createNewCollectionWithTitle:(NSString *)title
{
        if ( title.length > 0 ) {
                Collection *newCollection;
                
                for ( Collection *c in collections ) {
                        if ( [c.title compare:title options:NSCaseInsensitiveSearch] == NSOrderedSame ) {
                                [self alertForExists:title];
                                
                                return;
                        }
                }
                
                newCollection       = [Collection new];
                newCollection.index = 0;
                newCollection.title = title;
                
                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createCollection:newCollection];
                [self.tableView beginUpdates];
                [collections insertObject:newCollection atIndex:0];
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
        }
}

- (void)didChangeControllerFocus:(BOOL)focused
{
        if ( !focused )
                [activeTextField resignFirstResponder];
        
        [super didChangeControllerFocus:focused];
}

- (void)didDropItem:(Item *)item atPoint:(CGPoint)point
{
        NSIndexPath *indexPath;
        
        point     = [self.tableView convertPoint:point fromView:self.tableView.superview];
        indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if ( hoverTimer ) {
                [hoverTimer invalidate];
                
                hoverTimer = nil;
        }
        
        if ( indexPath &&
             indexPath.section == hoveringRow &&
             shouldReceiveItem ) {
                Collection *collection;
                LibraryTableViewCell *cell;
                
                if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                        [selectionFeedbackGenerator selectionChanged];
                
                if ( ![NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_TUTORIAL_COLLECTION_POP] )
                        [self playCollectionPopTutorial];
                
                if ( [_delegate respondsToSelector:@selector(libraryView:didReceiveItem:)] )
                        [_delegate libraryView:self didReceiveItem:item];
                
                cell = (LibraryTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                
                collection = collections[hoveringRow];
                
                item.collectionIdentifier = collection.identifier;
                item.free                 = NO;
                item.moved                = [NSDate date];
                
                [item redraw];
                [collection addItem:item];
                
                if ( [item isKindOfClass:LinkItem.class] )
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLinkItem:(LinkItem *)item inCollection:collection];
                else if ( [item isKindOfClass:LocationItem.class] )
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLocationItem:(LocationItem *)item inCollection:collection];
                else if ( [item isKindOfClass:MediaItem.class] )
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaItem:(MediaItem *)item inCollection:collection];
                else if ( [item isKindOfClass:TextItem.class] )
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateTextItem:(TextItem *)item inCollection:collection];
                
                for ( UIGestureRecognizer *recognizer in item.gestureRecognizers )
                        [item removeGestureRecognizer:recognizer];
                
                [cell.collectionView performBatchUpdates:^{
                        [cell.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
                } completion:^(BOOL finished){
                        [cell.collectionView setContentOffset:CGPointMake(0, 0) animated:YES];
                }];
                
                hoveringRow       = -1;
                shouldReceiveItem = NO;
        }
}

- (void)didLongPressItem:(UILongPressGestureRecognizer *)gestureRecognizer
{
        Collection *collection;
        Item *item;
        NSIndexPath *indexPath;
        CGPoint location;
        
        location = [gestureRecognizer locationInView:self.tableView];
        
        if ( gestureRecognizer.state == UIGestureRecognizerStateBegan ) {
                if ( [_delegate respondsToSelector:@selector(libraryView:didHandOverItem:atPoint:imported:)] ) {
                        indexPath = [self.tableView indexPathForRowAtPoint:location];
                        
                        if ( indexPath ) {
                                LibraryTableViewCell *cell;
                                
                                cell = (LibraryTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                                
                                collection          = collections[indexPath.section];
                                collection.modified = [NSDate date];
                                
                                location  = [cell.collectionView convertPoint:location fromView:self.tableView];
                                indexPath = [cell.collectionView indexPathForItemAtPoint:location];
                                
                                if ( indexPath ) {
                                        item                        = collection.items[indexPath.row];
                                        item.collectionIdentifier   = nil;
                                        item.free                   = YES;
                                        item.moved                  = [NSDate date];
                                        item.userInteractionEnabled = YES;
                                        
                                        location = [gestureRecognizer locationInView:self.tableView];
                                        
                                        [item redraw];
                                        
                                        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                                                [selectionFeedbackGenerator selectionChanged];
                                        
                                        if ( [_delegate respondsToSelector:@selector(libraryView:didHandOverItem:atPoint:imported:)] )
                                                [_delegate libraryView:self didHandOverItem:item atPoint:location imported:NO];
                                        
                                        [collection deleteItemAtIndex:indexPath.row];
                                        
                                        if ( [item isKindOfClass:LinkItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLinkItem:(LinkItem *)item inCollection:collection];
                                        else if ( [item isKindOfClass:LocationItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateLocationItem:(LocationItem *)item inCollection:collection];
                                        else if ( [item isKindOfClass:MediaItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaItem:(MediaItem *)item inCollection:collection];
                                        else if ( [item isKindOfClass:TextItem.class] )
                                                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateTextItem:(TextItem *)item inCollection:collection];
                                        
                                        [cell.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                                }
                        }
                }
        }
}

- (void)didMoveItemToPoint:(CGPoint)point
{
        NSIndexPath *indexPath;
        
        if ( point.x < 0 &&
             point.y < 0 ) {
                if ( hoverTimer ) {
                        [hoverTimer invalidate];
                        
                        hoverTimer = nil;
                }
                
                hoveringRow       = -1;
                shouldReceiveItem = NO;
                
                return;
        }
        
        point     = [self.tableView convertPoint:point fromView:self.tableView.superview];
        indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if ( indexPath ) {
                if ( indexPath.section != hoveringRow ) {
                        hoveringRow       = indexPath.section;
                        shouldReceiveItem = NO;
                        
                        if ( hoverTimer )
                                [hoverTimer invalidate];
                        
                        hoverTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 repeats:NO block:^(NSTimer *timer) {
                                LibraryTableViewHeader *header;
                                
                                shouldReceiveItem = YES;
                                header            = (LibraryTableViewHeader *)[self.tableView headerViewForSection:hoveringRow];
                                
                                [header flash];
                        }];
                }
        } else {
                if ( hoverTimer ) {
                        [hoverTimer invalidate];
                        
                        hoverTimer = nil;
                }
                
                hoveringRow       = -1;
                shouldReceiveItem = NO;
        }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
        [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
        [picker dismissViewControllerAnimated:YES completion:^{
                MediaItem *newItem;
                NSDictionary *imageData;
                NSString *mediaType;
                NSURL *imagePath;
                
                mediaType = [info objectForKey:UIImagePickerControllerMediaType];
                
                if ( [mediaType isEqualToString:(NSString *)kUTTypeVideo] ||
                     [mediaType isEqualToString:(NSString *)kUTTypeMovie] ) {
                        AVAsset *asset;
                        NSError *error;
                        NSFileManager *fileManager;
                        NSURL *videoURL;
                        
                        fileManager = [NSFileManager defaultManager];
                        videoURL    = [info objectForKey:UIImagePickerControllerMediaURL];
                        asset       = [AVAsset assetWithURL:videoURL];
                        
                        newItem          = [MediaItem new];
                        newItem.itemType = ItemTypeMovie;
                        
                        if ( ![fileManager copyItemAtURL:videoURL toURL:[Util pathForMedia:newItem.identifier extension:@"mov"] error:&error] )
                                NSLog(@"%@", error);
                        
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateMediaThumbnail:newItem];
                        [newItem redraw];
                        
                        if ( ![fileManager removeItemAtURL:videoURL error:&error] )
                                NSLog(@"Error deleting temp video file: %@", error);
                        
                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createMediaItem:newItem];
                        
                        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                                [selectionFeedbackGenerator selectionChanged];
                        
                        if ( [_delegate respondsToSelector:@selector(libraryView:didHandOverItem:atPoint:imported:)] )
                                [_delegate libraryView:self didHandOverItem:newItem atPoint:CGPointMake(ITEM_PREVIEW_SIZE / 2, 44) imported:YES];
                } else if ( [mediaType isEqualToString:(NSString *)kUTTypeImage] ){
                        /*
                         *  In order to support GIFs, we can't just use the image
                         *  returned by the controller. We have to fetch the
                         *  image ourselves so as not to lose its data.
                         */
                        imagePath = [info objectForKey:UIImagePickerControllerReferenceURL];
                        
                        if ( imagePath ) {
                                imageData = [Util imageDataFromReferenceURL:imagePath];
                                
                                if ( imageData ) {
                                        newItem             = [MediaItem new];
                                        newItem.coordinates = [imageData objectForKey:@"coordinates"];
                                        newItem.created     = [imageData objectForKey:@"date"];
                                        newItem.image       = [UIImage imageWithData:[imageData objectForKey:@"data"]];
                                        newItem.itemType    = ItemTypePhoto;
                                        
                                        [newItem redraw];
                                        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] createMediaItem:newItem];
                                        
                                        if ( selectionFeedbackGenerator ) // Play some haptic feedback.
                                                [selectionFeedbackGenerator selectionChanged];
                                        
                                        if ( [_delegate respondsToSelector:@selector(libraryView:didHandOverItem:atPoint:imported:)] )
                                                [_delegate libraryView:self didHandOverItem:newItem atPoint:CGPointMake(ITEM_PREVIEW_SIZE / 2, 44) imported:YES];
                                }
                        }
                }
        }];
}

- (void)playCollectionPopTutorial
{
        __block UILabel *explanationLabel;
        __block UIView *overlay;
        
        explanationLabel               = [[UILabel alloc] initWithFrame:CGRectMake(35, 35, self.view.bounds.size.width - 70, self.view.bounds.size.height - 70)];
        explanationLabel.font          = [UIFont systemFontOfSize:UIFont.buttonFontSize];
        explanationLabel.numberOfLines = 0;
        explanationLabel.text          = @"To pop an item back out of a collection, long press that item.";
        explanationLabel.textAlignment = NSTextAlignmentCenter;
        explanationLabel.textColor     = UIColor.whiteColor;
        
        overlay                 = [[UIView alloc] initWithFrame:self.view.bounds];
        overlay.alpha           = 0;
        overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        
        [overlay addSubview:explanationLabel];
        [self.view addSubview:overlay];
        [UIView animateWithDuration:0.2 animations:^{
                overlay.alpha = 1.0;
        } completion:^(BOOL finished){
                [UIView animateWithDuration:0.2 delay:3.0 options:UIViewAnimationOptionCurveLinear animations:^{
                        overlay.alpha = 0.0;
                } completion:^(BOOL finished){
                        [NSUserDefaults.standardUserDefaults setObject:@"1" forKey:NSUDKEY_TUTORIAL_COLLECTION_POP];
                        [overlay removeFromSuperview];
                        
                        explanationLabel = nil;
                        overlay          = nil;
                }];
        }];
}

- (void)presentMediaPicker
{
        UIAlertAction *cancel;
        UIAlertAction *photo;
        UIAlertAction *video;
        UIAlertController *prompt;
        
        cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        photo  = [UIAlertAction actionWithTitle:@"Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                mediaPickerController.allowsEditing        = NO;
                mediaPickerController.mediaTypes           = @[(NSString *)kUTTypeImage];
                
                [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:mediaPickerController animated:YES completion:nil];
        }];
        video  = [UIAlertAction actionWithTitle:@"Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                mediaPickerController.allowsEditing        = YES;
                mediaPickerController.mediaTypes           = @[(NSString *)kUTTypeMovie];
                mediaPickerController.videoMaximumDuration = 10;
                
                [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:mediaPickerController animated:YES completion:nil];
        }];
        prompt = [UIAlertController alertControllerWithTitle:@"Import Media" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [prompt addAction:cancel];
        [prompt addAction:photo];
        [prompt addAction:video];
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:prompt animated:YES completion:nil];
}

- (void)loadView
{
        UIBarButtonItem *importButton;
        UIBarButtonItem *newCollectionButton;
        CGSize emptyLibraryLabelSize;
        
        [super loadView];
        
        _tableView                 = [[UITableView alloc] initWithFrame:UIScreen.mainScreen.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        _tableView.backgroundView  = nil;
        _tableView.dataSource      = self;
        _tableView.delegate        = self;
        _tableView.indicatorStyle  = UIScrollViewIndicatorStyleWhite;
        _tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
        
        emptyLibraryLabel               = [UILabel new];
        emptyLibraryLabel.font          = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        emptyLibraryLabel.hidden        = YES;
        emptyLibraryLabel.numberOfLines = 0;
        emptyLibraryLabel.text          = @"Organize everything in collections. Tap the \"+\" above to create a new collection.";
        emptyLibraryLabel.textAlignment = NSTextAlignmentCenter;
        emptyLibraryLabel.textColor     = UIColor.grayColor;
        
        emptyLibraryLabelSize = [emptyLibraryLabel sizeThatFits:CGSizeMake(self.tableView.bounds.size.width - 80, self.tableView.bounds.size.height)];
        
        emptyLibraryLabel.frame = CGRectMake((self.tableView.bounds.size.width / 2) - (emptyLibraryLabelSize.width / 2),
                                             (self.tableView.bounds.size.height / 2) - (emptyLibraryLabelSize.height / 2),
                                             emptyLibraryLabelSize.width,
                                             emptyLibraryLabelSize.height);
        
        importButton                          = [[UIBarButtonItem alloc] initWithTitle:@"Import" style:UIBarButtonItemStylePlain target:self action:@selector(presentMediaPicker)];
        self.navigationItem.leftBarButtonItem = importButton;
        
        newCollectionButton                    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newCollection)];
        self.navigationItem.rightBarButtonItem = newCollectionButton;
        
        [_tableView addSubview:emptyLibraryLabel];
        
        self.view = _tableView;
}

- (void)namingBoxDidChange:(UITextField *)sender
{
        if ( sender.text.length > 0 )
                newCollectionCreate.enabled = YES;
        else
                newCollectionCreate.enabled = NO;
}

- (void)newCollection
{
        UIAlertController *namingBox;
        
        namingBox           = [UIAlertController alertControllerWithTitle:@"New Collection" message:@"Enter a name for this collection." preferredStyle:UIAlertControllerStyleAlert];
        newCollectionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
        }];
        
        newCollectionCreate         = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                UITextField *nameTextField;
                
                nameTextField = namingBox.textFields.firstObject;
                
                [self createNewCollectionWithTitle:nameTextField.text];
        }];
        newCollectionCreate.enabled = NO;
        
        [namingBox addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.autocapitalizationType        = UITextAutocapitalizationTypeWords;
                textField.autocorrectionType            = UITextAutocorrectionTypeDefault;
                textField.enablesReturnKeyAutomatically = YES;
                textField.keyboardAppearance            = UIKeyboardAppearanceDark;
                textField.placeholder                   = @"Title";
                
                [textField addTarget:self action:@selector(namingBoxDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [namingBox addAction:newCollectionCancel];
        [namingBox addAction:newCollectionCreate];
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:namingBox animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (void)reloadDataSource
{
        [[(AppDelegate *)UIApplication.sharedApplication.delegate model] loadCollectionsCompletion:^(NSMutableArray *list){
                collections = list;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                        for ( Collection *collection in collections ) {
                                for (Item *item in collection.items ) {
                                        item.free = NO;
                                        
                                        [item redraw];
                                }
                        }
                        
                        [self.tableView reloadData];
                });
        }];
}

- (void)renameCollection:(Collection *)collection to:(NSString *)newTitle
{
        if ( !newTitle ||
             newTitle.length == 0 ) {
                [self confirmCollectionDeletion:collection];
                
                return;
        }
        
        if ( ![collection.title isEqualToString:newTitle] ) {
                collection.modified = [NSDate date];
                collection.title    = newTitle;
                
                [[(AppDelegate *)UIApplication.sharedApplication.delegate model] updateCollection:collection];
        }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
        if ( [scrollView isKindOfClass:UICollectionView.class] ) {
                IndexedCollectionView *collectionView;
                CGFloat horizontalOffset;
                NSInteger index;
                
                horizontalOffset = scrollView.contentOffset.x;
                collectionView   = (IndexedCollectionView *)scrollView;
                index            = collectionView.indexPath.row;
                
                contentOffsetDictionary[[@(index) stringValue]] = @(horizontalOffset);
        }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LibraryTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
        CGFloat horizontalOffset;
        NSInteger index;
        
        [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
        
        index            = cell.collectionView.indexPath.row;
        horizontalOffset = [contentOffsetDictionary[[@(index) stringValue]] floatValue];
        
        [cell.collectionView setContentOffset:CGPointMake(horizontalOffset, 0)];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
        LibraryTableViewHeader *header;
        
        header                = (LibraryTableViewHeader *)view;
        header.backgroundView = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
        activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
        if ( [textField isEqual:activeTextField] ) {
                if ( textField.tag < collections.count ) {
                        Collection *collection;
                        
                        collection = collections[textField.tag];
                        
                        [self renameCollection:collection to:textField.text];
                }
                
                activeTextField = nil;
        }
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        [self reloadDataSource];
        
        self.navigationController.navigationBar.barTintColor        = UIColor.blackColor;
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
}


@end
