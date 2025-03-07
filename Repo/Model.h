//
//  Model.h
//  Repo
//
//  Created by Ali Mahouk on 20/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@class Collection;
@class FMDatabase;
@class FMDatabaseQueue;
@class Item;
@class LinkItem;
@class LocationItem;
@class MediaItem;
@class TextItem;

@interface Model : NSObject
{
        FMDatabaseQueue *queue;
        NSError *restoreError;
        NSMutableArray<Collection *> *fetchedCollections;
        NSMutableArray *fetchedItems;
        NSMutableArray<LinkItem *> *fetchedLinkItems;
        NSMutableArray<LocationItem *> *fetchedLocationItems;
        NSMutableArray<MediaItem *> *fetchedMediaItems;
        NSMutableArray<TextItem *> *fetchedTextItems;
        NSString *databaseLocalPath;
        BOOL didRestoreCollections;
        BOOL didRestoreLinkItems;
        BOOL didRestoreLocationItems;
        BOOL didRestoreMediaItems;
        BOOL didRestoreTextItems;
        int ubiquityStatus;
        void (^restoreCompletionHandler)(BOOL done, NSMutableArray *fetchedCollections, NSMutableArray *fetchedItems);
}

- (void)createCollection:(Collection *)collection;
- (void)createLinkItem:(LinkItem *)item;
- (void)createLocationItem:(LocationItem *)item;
- (void)createMediaItem:(MediaItem *)item;
- (void)createTextItem:(TextItem *)item;
- (void)deleteCollection:(Collection *)collection;
- (void)deleteItem:(Item *)item fromCollection:(Collection *)collection;
- (void)loadCollectionsCompletion:(void (^)(NSMutableArray *list))completion;
- (void)loadFreeItemsCompletion:(void (^)(NSMutableArray *list))completion;
- (void)syncCompletion:(void (^)(BOOL done, NSMutableArray *fetchedCollections, NSMutableArray *fetchedItems))completion;
- (void)updateCollection:(Collection *)collection;
- (void)updateLinkItem:(LinkItem *)item inCollection:(Collection *)collection;
- (void)updateLinkSnapshot:(LinkItem *)item;
- (void)updateLocationItem:(LocationItem *)item inCollection:(Collection *)collection;
- (void)updateMediaItem:(MediaItem *)item inCollection:(Collection *)collection;
- (void)updateMediaThumbnail:(MediaItem *)item;
- (void)updateTextItem:(TextItem *)item inCollection:(Collection *)collection;

@end
