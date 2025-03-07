//
//  Model.m
//  Repo
//
//  Created by Ali Mahouk on 20/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import AVFoundation;
@import CloudKit;

#import "Model.h"

#import "Collection.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "LinkItem.h"
#import "LocationItem.h"
#import "MediaItem.h"
#import "TextItem.h"
#import "Util.h"

@implementation Model

// http://newyankeecodeshop.tumblr.com/post/97617794988/full-text-search-on-ios-with-fmdb

- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                NSArray *paths;
                NSError *error;
                NSFileManager *fileManager;
                NSString *documentsDirectory;
                NSString *templateDBPath;
                
                didRestoreCollections   = NO;
                didRestoreLinkItems     = NO;
                didRestoreLocationItems = NO;
                didRestoreMediaItems    = NO;
                didRestoreTextItems     = NO;
                paths                   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); // Get the documents directory.
                documentsDirectory      = [paths firstObject];
                fetchedCollections      = [NSMutableArray array];
                fetchedItems            = [NSMutableArray array];
                fetchedLinkItems        = [NSMutableArray array];
                fetchedLocationItems    = [NSMutableArray array];
                fetchedMediaItems       = [NSMutableArray array];
                fetchedTextItems        = [NSMutableArray array];
                fileManager             = [NSFileManager defaultManager];
                templateDBPath          = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_TEMPLATE_NAME];
                databaseLocalPath       = [documentsDirectory stringByAppendingPathComponent:DB_TEMPLATE_NAME];
                ubiquityStatus          = -1;
                
                if ( ![fileManager fileExistsAtPath:databaseLocalPath] ) {
                        if ( [fileManager copyItemAtPath:templateDBPath toPath:databaseLocalPath error:&error] )
                                NSLog(@"Fresh database created!");
                        else
                                NSLog(@"Failed to copy the database file: %@", error);
                }
                
                queue = [FMDatabaseQueue databaseQueueWithPath:databaseLocalPath];
        }
        
        return self;
}

- (BOOL)doneRestoring
{
        if ( !didRestoreCollections ||
             !didRestoreLinkItems ||
             !didRestoreLocationItems ||
             !didRestoreMediaItems ||
             !didRestoreTextItems ) {
                return NO;
        }
        
        [fetchedItems addObjectsFromArray:fetchedLinkItems];
        [fetchedItems addObjectsFromArray:fetchedLocationItems];
        [fetchedItems addObjectsFromArray:fetchedMediaItems];
        [fetchedItems addObjectsFromArray:fetchedTextItems];
        
        dispatch_async(dispatch_get_main_queue(), ^{
                if ( restoreError )
                        restoreCompletionHandler(NO, nil, nil);
                else
                        restoreCompletionHandler(YES, fetchedCollections, fetchedItems);
        });
        
        return YES;
}

- (void)createCollection:(Collection *)collection
{
        if ( collection ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                [db executeUpdate:@"INSERT INTO COLLECTION(ID, POSITION, TITLE, CREATED, MODIFIED) VALUES(?, ?, ?, ?, ?)",
                                 collection.identifier,
                                 [NSNumber numberWithInteger:collection.index],
                                 collection.title,
                                 collection.created,
                                 collection.modified];
                                
                                if ( ubiquityStatus == 1 ) {
                                        CKModifyRecordsOperation *op;
                                        CKRecord *record;
                                        CKRecordID *recordID;
                                        
                                        recordID = [[CKRecordID alloc] initWithRecordName:collection.identifier];
                                        
                                        record              = [[CKRecord alloc] initWithRecordType:@"Collection" recordID:recordID];
                                        record[@"created"]  = collection.created;
                                        record[@"modified"] = collection.modified;
                                        record[@"position"] = [NSNumber numberWithInteger:collection.index];
                                        record[@"title"]    = collection.title;
                                        
                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                if ( operationError ) {
                                                        NSLog(@"%@", operationError);
                                                        
                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                
                                                        }
                                                } else {
                                                        [db executeUpdate:@"UPDATE COLLECTION SET BACKED_UP = 1 WHERE ID = ?",
                                                         collection.identifier];
                                                }
                                        };
                                        op.qualityOfService = NSQualityOfServiceUserInitiated;
                                        op.savePolicy       = CKRecordSaveAllKeys;
                                        
                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                }
                        }];
                });
        }
}

- (void)createLinkItem:(LinkItem *)item
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                NSString *coordinates;
                                
                                coordinates  = @"";
                                
                                [self updateLinkSnapshot:item];
                                
                                if ( item.coordinates )
                                        coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                
                                [db executeUpdate:@"INSERT INTO LINK_ITEM(ID, TITLE, URL, COORDINATES, LOCATION, CREATED, MOVED) VALUES(?, ?, ?, ?, ?, ?, ?)",
                                 item.identifier,
                                 item.title,
                                 item.URL.absoluteString,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.moved];
                                
                                if ( ubiquityStatus == 1 ) {
                                        CKModifyRecordsOperation *op;
                                        CKRecord *record;
                                        CKRecordID *recordID;
                                        
                                        
                                        recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                        
                                        record                          = [[CKRecord alloc] initWithRecordType:@"LinkItem" recordID:recordID];
                                        record[@"collectionIdentifier"] = item.collectionIdentifier;
                                        record[@"coordinates"]          = item.coordinates;
                                        record[@"created"]              = item.created;
                                        record[@"location"]             = item.location;
                                        record[@"moved"]                = item.moved;
                                        record[@"title"]                = item.title;
                                        record[@"URL"]                  = item.URL.absoluteString;
                                        
                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                if ( operationError ) {
                                                        NSLog(@"%@", operationError);
                                                        
                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                
                                                        }
                                                } else {
                                                        [db executeUpdate:@"UPDATE LINK_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                         item.identifier];
                                                }
                                        };
                                        op.qualityOfService = NSQualityOfServiceUserInitiated;
                                        op.savePolicy       = CKRecordSaveAllKeys;
                                        
                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                }
                        }];
                });
        }
}

- (void)createLocationItem:(LocationItem *)item
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                NSString *coordinates;
                                
                                coordinates  = @"";
                                
                                if ( item.coordinates )
                                        coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                
                                [db executeUpdate:@"INSERT INTO LOCATION_ITEM(ID, COORDINATES, LOCATION, CREATED, MOVED) VALUES(?, ?, ?, ?, ?)",
                                 item.identifier,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.moved];
                                
                                if ( ubiquityStatus == 1 ) {
                                        CKModifyRecordsOperation *op;
                                        CKRecord *record;
                                        CKRecordID *recordID;
                                        
                                        recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                        
                                        record                          = [[CKRecord alloc] initWithRecordType:@"LocationItem" recordID:recordID];
                                        record[@"collectionIdentifier"] = item.collectionIdentifier;
                                        record[@"coordinates"]          = item.coordinates;
                                        record[@"created"]              = item.created;
                                        record[@"location"]             = item.location;
                                        record[@"moved"]                = item.moved;
                                        
                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                if ( operationError ) {
                                                        NSLog(@"%@", operationError);
                                                        
                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                
                                                        }
                                                } else {
                                                        [db executeUpdate:@"UPDATE LOCATION_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                         item.identifier];
                                                }
                                        };
                                        op.qualityOfService = NSQualityOfServiceUserInitiated;
                                        op.savePolicy       = CKRecordSaveAllKeys;
                                        
                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                }
                        }];
                });
        }
}

- (void)createMediaItem:(MediaItem *)item
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                NSData *dataCaption;
                                NSData *dataInk;
                                NSData *dataMedia;
                                NSError *error;
                                NSString *captionAnchorPoint;
                                NSString *captionBounds;
                                NSString *captionCenter;
                                NSString *captionTransform;
                                NSString *coordinates;
                                NSURL *pathCaption;
                                NSURL *pathInk;
                                NSURL *pathMedia;
                                
                                captionAnchorPoint = NSStringFromCGPoint(item.captionView.layer.anchorPoint);
                                captionBounds      = NSStringFromCGRect(item.captionView.bounds);
                                captionCenter      = NSStringFromCGPoint(item.captionView.center);
                                captionTransform   = NSStringFromCGAffineTransform(item.captionView.transform);
                                coordinates        = @"";
                                dataCaption        = [NSKeyedArchiver archivedDataWithRootObject:(item.captionView.attributedText)];
                                dataInk            = UIImagePNGRepresentation(item.ink);
                                
                                pathCaption        = [Util pathForText:item.identifier];
                                pathInk            = [Util pathForInk:item.identifier];
                                
                                if ( item.itemType == ItemTypePhoto ) {
                                        dataMedia = UIImageJPEGRepresentation(item.image, 1.0);
                                        pathMedia = [Util pathForMedia:item.identifier extension:@"jpg"];
                                } else if ( item.itemType == ItemTypeMovie ) {
                                        pathMedia = [Util pathForMedia:item.identifier extension:@"mov"];
                                }
                                
                                if ( item.coordinates )
                                        coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                
                                if ( dataCaption )
                                        if ( ![dataCaption writeToURL:pathCaption options:NSDataWritingAtomic error:&error] )
                                                NSLog(@"%@", error);
                                
                                if ( dataInk )
                                        if ( ![dataInk writeToURL:pathInk options:NSDataWritingAtomic error:&error] )
                                                NSLog(@"%@", error);
                                
                                if ( dataMedia )
                                        if ( ![dataMedia writeToURL:pathMedia options:NSDataWritingAtomic error:&error] )
                                                NSLog(@"%@", error);
                                
                                if ( !error ) {
                                        [db executeUpdate:@"INSERT INTO MEDIA_ITEM(ID, TYPE, CAPTION_ANCHOR_POINT, CAPTION_BOUNDS, CAPTION_CENTER, CAPTION_TRANSFORM, COORDINATES, LOCATION, CREATED, MODIFIED, MOVED) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                         item.identifier,
                                         [NSNumber numberWithInt:item.itemType],
                                         captionAnchorPoint,
                                         captionBounds,
                                         captionCenter,
                                         captionTransform,
                                         coordinates,
                                         item.location,
                                         item.created,
                                         item.modified,
                                         item.moved];
                                        
                                        if ( ubiquityStatus == 1 ) {
                                                CKAsset *assetCaption;
                                                CKAsset *assetInk;
                                                CKAsset *assetMedia;
                                                CKModifyRecordsOperation *op;
                                                CKRecord *record;
                                                CKRecordID *recordID;
                                                
                                                if ( !error ) {
                                                        recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                                        
                                                        record                          = [[CKRecord alloc] initWithRecordType:@"MediaItem" recordID:recordID];
                                                        record[@"captionAnchorPoint"]   = captionAnchorPoint;
                                                        record[@"captionBounds"]        = captionBounds;
                                                        record[@"captionCenter"]        = captionCenter;
                                                        record[@"captionTransform"]     = captionTransform;
                                                        record[@"collectionIdentifier"] = item.collectionIdentifier;
                                                        record[@"coordinates"]          = item.coordinates;
                                                        record[@"created"]              = item.created;
                                                        record[@"location"]             = item.location;
                                                        record[@"modified"]             = item.modified;
                                                        record[@"moved"]                = item.moved;
                                                        record[@"type"]                 = [NSNumber numberWithInt:item.itemType];
                                                        
                                                        if ( dataCaption ) {
                                                                assetCaption       = [[CKAsset alloc] initWithFileURL:pathCaption];
                                                                record[@"caption"] = assetCaption;
                                                        }
                                                        
                                                        if ( dataInk ) {
                                                                assetInk       = [[CKAsset alloc] initWithFileURL:pathInk];
                                                                record[@"ink"] = assetInk;
                                                        }
                                                        
                                                        assetMedia      = [[CKAsset alloc] initWithFileURL:pathMedia];
                                                        record[@"data"] = assetMedia;
                                                        
                                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                                if ( operationError ) {
                                                                        NSLog(@"%@", operationError);
                                                                        
                                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                                
                                                                        }
                                                                } else {
                                                                        [db executeUpdate:@"UPDATE MEDIA_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                                         item.identifier];
                                                                }
                                                        };
                                                        op.qualityOfService = NSQualityOfServiceUserInitiated;
                                                        op.savePolicy       = CKRecordSaveAllKeys;
                                                        
                                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                                }
                                        }
                                }
                        }];
                });
        }
}

- (void)createTextItem:(TextItem *)item
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                NSData *dataInk;
                                NSData *dataText;
                                NSError *error;
                                NSString *coordinates;
                                NSURL *pathInk;
                                NSURL *pathText;
                                
                                coordinates = @"";
                                dataInk     = UIImagePNGRepresentation(item.ink);
                                dataText    = [NSKeyedArchiver archivedDataWithRootObject:item.string];
                                pathInk     = [Util pathForInk:item.identifier];
                                pathText    = [Util pathForText:item.identifier];
                                
                                if ( item.coordinates )
                                        coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                
                                if ( dataInk )
                                        if ( ![dataInk writeToURL:pathInk options:NSDataWritingAtomic error:&error] )
                                                NSLog(@"%@", error);
                                
                                if ( dataText )
                                        if ( ![dataText writeToURL:pathText options:NSDataWritingAtomic error:&error] )
                                                NSLog(@"%@", error);
                                
                                if ( !error ) {
                                        [db executeUpdate:@"INSERT INTO TEXT_ITEM(ID, COORDINATES, LOCATION, CREATED, MODIFIED, MOVED) VALUES(?, ?, ?, ?, ?, ?)",
                                         item.identifier,
                                         coordinates,
                                         item.location,
                                         item.created,
                                         item.modified,
                                         item.moved];
                                        
                                        if ( ubiquityStatus == 1 ) {
                                                CKAsset *assetInk;
                                                CKAsset *assetText;
                                                CKModifyRecordsOperation *op;
                                                CKRecord *record;
                                                CKRecordID *recordID;
                                                
                                                if ( !error ) {
                                                        recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                                        
                                                        record                          = [[CKRecord alloc] initWithRecordType:@"TextItem" recordID:recordID];
                                                        record[@"collectionIdentifier"] = item.collectionIdentifier;
                                                        record[@"coordinates"]          = item.coordinates;
                                                        record[@"created"]              = item.created;
                                                        record[@"location"]             = item.location;
                                                        record[@"modified"]             = item.modified;
                                                        record[@"moved"]                = item.moved;
                                                        
                                                        if ( dataInk ) {
                                                                assetInk       = [[CKAsset alloc] initWithFileURL:pathInk];
                                                                record[@"ink"] = assetInk;
                                                        }
                                                        
                                                        if ( dataText ) {
                                                                assetText       = [[CKAsset alloc] initWithFileURL:pathText];
                                                                record[@"data"] = assetText;
                                                        }
                                                        
                                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                                if ( operationError ) {
                                                                        NSLog(@"%@", operationError);
                                                                        
                                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                                
                                                                        }
                                                                } else {
                                                                        [db executeUpdate:@"UPDATE TEXT_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                                         item.identifier];
                                                                }
                                                        };
                                                        op.qualityOfService = NSQualityOfServiceUserInitiated;
                                                        op.savePolicy       = CKRecordSaveAllKeys;
                                                        
                                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                                }
                                        }
                                }
                        }];
                });
        }
}

- (uint32_t)schemaVersion
{
        FMDatabase *db;
        uint32_t version;
        
        db = [FMDatabase databaseWithPath:databaseLocalPath];
        
        [db open];
        
        version = [db userVersion];
        
        [db close];
        
        return version;
}

- (void)deleteCollection:(Collection *)collection
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [queue inDatabase:^(FMDatabase *db) {
                        CKRecordID *collectionRecordID;
                        FMResultSet *resultSet;
                        NSFileManager *fileManager;
                        NSMutableArray *deletionList;
                        
                        collectionRecordID = [[CKRecordID alloc] initWithRecordName:collection.identifier];
                        fileManager        = [NSFileManager defaultManager];
                        
                        [db executeUpdate:@"VACUUM;"]; // Enable vacuuming.
                        
                        // Before deleting the collection, we have to delete all its children from the cloud.
                        deletionList = [NSMutableArray array];
                        resultSet    = [db executeQuery:@"SELECT ID FROM LINK_ITEM WHERE COLLECTION = ?",
                                        collection.identifier];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                NSString *identifier;
                                
                                identifier = [resultSet stringForColumnIndex:0];
                                recordID   = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                                [fileManager removeItemAtURL:[Util pathForSnapshot:identifier] error:nil];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM LOCATION_ITEM WHERE COLLECTION = ?",
                                     collection.identifier];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                
                                recordID = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM MEDIA_ITEM WHERE COLLECTION = ?",
                                     collection.identifier];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                NSString *identifier;
                                
                                identifier = [resultSet stringForColumnIndex:0];
                                recordID   = [[CKRecordID alloc] initWithRecordName:identifier];
                                
                                [deletionList addObject:recordID];
                                [fileManager removeItemAtURL:[Util pathForInk:identifier] error:nil];
                                [fileManager removeItemAtURL:[Util pathForMedia:identifier extension:@"jpg"] error:nil];
                                [fileManager removeItemAtURL:[Util pathForMedia:identifier extension:@"mov"] error:nil];
                                [fileManager removeItemAtURL:[Util pathForText:identifier] error:nil];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM TEXT_ITEM WHERE COLLECTION = ?",
                                     collection.identifier];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                NSString *identifier;
                                
                                identifier = [resultSet stringForColumnIndex:0];
                                recordID   = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                                [fileManager removeItemAtURL:[Util pathForInk:identifier] error:nil];
                                [fileManager removeItemAtURL:[Util pathForText:identifier] error:nil];
                        }
                        
                        if ( ubiquityStatus == 1 ) {
                                CKModifyRecordsOperation *op;
                                
                                [db executeUpdate:@"UPDATE COLLECTION SET DELETED = 1 WHERE ID = ?",
                                 collection.identifier];
                                [db executeUpdate:@"UPDATE LINK_ITEM SET DELETED = 1 WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"UPDATE LOCATION_ITEM SET DELETED = 1 WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"UPDATE MEDIA_ITEM SET DELETED = 1 WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"UPDATE TEXT_ITEM SET DELETED = 1 WHERE COLLECTION = ?",
                                 collection.identifier];
                                
                                op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:deletionList];
                                op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                        if ( operationError ) {
                                                NSLog(@"%@", operationError);
                                        } else { // Children deleted; delete the collection.
                                                [[[CKContainer defaultContainer] privateCloudDatabase] deleteRecordWithID:collectionRecordID completionHandler:^(CKRecordID *recordID, NSError *error){
                                                        if ( error ) {
                                                                NSLog(@"%@", error);
                                                        } else {
                                                                [db executeUpdate:@"DELETE FROM LINK_ITEM WHERE COLLECTION = ?",
                                                                 collection.identifier];
                                                                [db executeUpdate:@"DELETE FROM LOCATION_ITEM WHERE COLLECTION = ?",
                                                                 collection.identifier];
                                                                [db executeUpdate:@"DELETE FROM MEDIA_ITEM WHERE COLLECTION = ?",
                                                                 collection.identifier];
                                                                [db executeUpdate:@"DELETE FROM TEXT_ITEM WHERE COLLECTION = ?",
                                                                 collection.identifier];
                                                                [db executeUpdate:@"DELETE FROM COLLECTION WHERE ID = ?",
                                                                 collection.identifier];
                                                        }
                                                }];
                                        }
                                };
                                
                                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                        } else { // No iCloud; delete directly.
                                [db executeUpdate:@"DELETE FROM LINK_ITEM WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"DELETE FROM LOCATION_ITEM WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"DELETE FROM MEDIA_ITEM WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"DELETE FROM TEXT_ITEM WHERE COLLECTION = ?",
                                 collection.identifier];
                                [db executeUpdate:@"DELETE FROM COLLECTION WHERE ID = ?",
                                 collection.identifier];
                        }
                }];
        });
}

- (void)deleteItem:(Item *)item fromCollection:(Collection *)collection
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [queue inDatabase:^(FMDatabase *db) {
                        NSFileManager *fileManager;
                        
                        fileManager = [NSFileManager defaultManager];
                        
                        [db executeUpdate:@"VACUUM;"]; // Enable vacuuming.
                        [fileManager removeItemAtURL:[Util pathForInk:item.identifier] error:nil];
                        [fileManager removeItemAtURL:[Util pathForMedia:item.identifier extension:@"jpg"] error:nil];
                        [fileManager removeItemAtURL:[Util pathForMedia:item.identifier extension:@"mov"] error:nil];
                        [fileManager removeItemAtURL:[Util pathForSnapshot:item.identifier] error:nil];
                        [fileManager removeItemAtURL:[Util pathForText:item.identifier] error:nil];
                        
                        if ( ubiquityStatus == 1 ) {
                                CKModifyRecordsOperation *op;
                                CKRecordID *recordID;
                                
                                recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                
                                if ( [item isKindOfClass:LinkItem.class] ) {
                                        [db executeUpdate:@"UPDATE LINK_ITEM SET DELETED = 1 WHERE ID = ?",
                                         item.identifier];
                                } else if ( [item isKindOfClass:LocationItem.class] ) {
                                        [db executeUpdate:@"UPDATE LOCATION_ITEM SET DELETED = 1 WHERE ID = ?",
                                         item.identifier];
                                } else if ( [item isKindOfClass:MediaItem.class] ) {
                                        [db executeUpdate:@"UPDATE media_ITEM SET DELETED = 1 WHERE ID = ?",
                                         item.identifier];
                                } else if ( [item isKindOfClass:TextItem.class] ) {
                                        [db executeUpdate:@"UPDATE text_ITEM SET DELETED = 1 WHERE ID = ?",
                                         item.identifier];
                                }
                                
                                op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:@[recordID]];
                                op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                        if ( operationError ) {
                                                NSLog(@"%@", operationError);
                                        } else {
                                                if ( [item isKindOfClass:LinkItem.class] ) {
                                                        [db executeUpdate:@"DELETE FROM LINK_ITEM WHERE ID = ?",
                                                         item.identifier];
                                                } else if ( [item isKindOfClass:LocationItem.class] ) {
                                                        [db executeUpdate:@"DELETE FROM LOCATION_ITEM WHERE ID = ?",
                                                         item.identifier];
                                                } else if ( [item isKindOfClass:MediaItem.class] ) {
                                                        [db executeUpdate:@"DELETE FROM MEDIA_ITEM WHERE ID = ?",
                                                         item.identifier];
                                                } else if ( [item isKindOfClass:TextItem.class] ) {
                                                        [db executeUpdate:@"DELETE FROM TEXT_ITEM WHERE ID = ?",
                                                         item.identifier];
                                                }
                                                
                                                if ( collection )
                                                        [self updateCollection:collection];
                                        }
                                };
                                
                                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                        } else { // No iCloud; delete directly.
                                if ( [item isKindOfClass:LinkItem.class] ) {
                                        [db executeUpdate:@"DELETE FROM LINK_ITEM WHERE ID = ?",
                                         item.identifier];
                                } else if ( [item isKindOfClass:LocationItem.class] ) {
                                        [db executeUpdate:@"DELETE FROM LOCATION_ITEM WHERE ID = ?",
                                         item.identifier];
                                } else if ( [item isKindOfClass:MediaItem.class] ) {
                                        [db executeUpdate:@"DELETE FROM MEDIA_ITEM WHERE ID = ?",
                                         item.identifier];
                                } else if ( [item isKindOfClass:TextItem.class] ) {
                                        [db executeUpdate:@"DELETE FROM TEXT_ITEM WHERE ID = ?",
                                         item.identifier];
                                }
                                
                                if ( collection )
                                        [self updateCollection:collection];
                        }
                }];
        });
}

- (void)fetchAllCollectionsWithCursor:(CKQueryCursor *)cursor
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                CKQueryOperation *queryOp;
                NSMutableArray *collections;
                
                collections = [NSMutableArray array];
                
                if ( cursor ) {
                        queryOp = [[CKQueryOperation alloc] initWithCursor:cursor];
                } else {
                        CKQuery *query;
                        NSDate *lastSyncDate;
                        NSPredicate *predicate;
                        
                        lastSyncDate = [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE];
                        
                        if ( lastSyncDate )
                                predicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate];
                        else
                                predicate = [NSPredicate predicateWithValue:YES];
                        
                        query   = [[CKQuery alloc] initWithRecordType:@"Collection" predicate:predicate];
                        queryOp = [[CKQueryOperation alloc] initWithQuery:query];
                }
                
                queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
                        if ( operationError ) {
                                didRestoreCollections = YES;
                                
                                if ( operationError.code == CKErrorUnknownItem ) {
                                        // Fetch everything else after the collections are done to ensure foreign key integrity.
                                        [self fetchAllLinkItemsWithCursor:nil];
                                        [self fetchAllLocationItemsWithCursor:nil];
                                        [self fetchAllMediaItemsWithCursor:nil];
                                        [self fetchAllTextItemsWithCursor:nil];
                                } else {
                                        restoreError = operationError;
                                        
                                        NSLog(@"%@", operationError);
                                }
                        } else {
                                if ( cursor )
                                        [self fetchAllCollectionsWithCursor:cursor];
                                else
                                        [self processCollections:collections];
                        }
                };
                queryOp.recordFetchedBlock = ^(CKRecord *record) {
                        [collections addObject:record];
                };
                
                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:queryOp];
        });
}

- (void)fetchAllLinkItemsWithCursor:(CKQueryCursor *)cursor
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                CKQueryOperation *queryOp;
                NSMutableArray *linkItems;
                
                linkItems = [NSMutableArray array];
                
                if ( cursor ) {
                        queryOp = [[CKQueryOperation alloc] initWithCursor:cursor];
                } else {
                        CKQuery *query;
                        NSDate *lastSyncDate;
                        NSPredicate *predicate;
                        
                        lastSyncDate = [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE];
                        
                        if ( lastSyncDate )
                                predicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate];
                        else
                                predicate = [NSPredicate predicateWithValue:YES];
                        
                        query   = [[CKQuery alloc] initWithRecordType:@"LinkItem" predicate:predicate];
                        queryOp = [[CKQueryOperation alloc] initWithQuery:query];
                }
                
                queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
                        if ( operationError ) {
                                didRestoreLinkItems = YES;
                                
                                if ( operationError.code != CKErrorUnknownItem ) {
                                        restoreError = operationError;
                                        
                                        NSLog(@"%@", operationError);
                                }
                                
                                [self doneRestoring];
                        } else {
                                if ( cursor )
                                        [self fetchAllLinkItemsWithCursor:cursor];
                                else
                                        [self processLinkItems:linkItems];
                        }
                };
                queryOp.recordFetchedBlock = ^(CKRecord *record) {
                        [linkItems addObject:record];
                };
                
                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:queryOp];
        });
}

- (void)fetchAllLocationItemsWithCursor:(CKQueryCursor *)cursor
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                CKQueryOperation *queryOp;
                NSMutableArray *locationItems;
                
                locationItems = [NSMutableArray array];
                
                if ( cursor ) {
                        queryOp = [[CKQueryOperation alloc] initWithCursor:cursor];
                } else {
                        CKQuery *query;
                        NSDate *lastSyncDate;
                        NSPredicate *predicate;
                        
                        lastSyncDate = [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE];
                        
                        if ( lastSyncDate )
                                predicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate];
                        else
                                predicate = [NSPredicate predicateWithValue:YES];
                        
                        query   = [[CKQuery alloc] initWithRecordType:@"LocationItem" predicate:predicate];
                        queryOp = [[CKQueryOperation alloc] initWithQuery:query];
                }
                
                queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
                        if ( operationError ) {
                                didRestoreLocationItems = YES;
                                
                                if ( operationError.code != CKErrorUnknownItem ) {
                                        restoreError = operationError;
                                        
                                        NSLog(@"%@", operationError);
                                }
                                
                                [self doneRestoring];
                        } else {
                                if ( cursor )
                                        [self fetchAllLocationItemsWithCursor:cursor];
                                else
                                        [self processLocationItems:locationItems];
                        }
                };
                queryOp.recordFetchedBlock = ^(CKRecord *record) {
                        [locationItems addObject:record];
                };
                
                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:queryOp];
        });
}

- (void)fetchAllMediaItemsWithCursor:(CKQueryCursor *)cursor
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                CKQueryOperation *queryOp;
                NSMutableArray *mediaItems;
                
                mediaItems = [NSMutableArray array];
                
                if ( cursor ) {
                        queryOp = [[CKQueryOperation alloc] initWithCursor:cursor];
                } else {
                        CKQuery *query;
                        NSDate *lastSyncDate;
                        NSPredicate *predicate;
                        
                        lastSyncDate = [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE];
                        
                        if ( lastSyncDate )
                                predicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate];
                        else
                                predicate = [NSPredicate predicateWithValue:YES];
                        
                        query   = [[CKQuery alloc] initWithRecordType:@"MediaItem" predicate:predicate];
                        queryOp = [[CKQueryOperation alloc] initWithQuery:query];
                }
                
                queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
                        if ( operationError ) {
                                didRestoreMediaItems = YES;
                                
                                if ( operationError.code != CKErrorUnknownItem ) {
                                        restoreError = operationError;
                                        
                                        NSLog(@"%@", operationError);
                                }
                                
                                [self doneRestoring];
                        } else {
                                if ( cursor )
                                        [self fetchAllMediaItemsWithCursor:cursor];
                                else
                                        [self processMediaItems:mediaItems];
                        }
                };
                queryOp.recordFetchedBlock = ^(CKRecord *record) {
                        [mediaItems addObject:record];
                };
                
                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:queryOp];
        });
}

- (void)fetchAllTextItemsWithCursor:(CKQueryCursor *)cursor
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                CKQueryOperation *queryOp;
                NSMutableArray *textItems;
                
                textItems = [NSMutableArray array];
                
                if ( cursor ) {
                        queryOp = [[CKQueryOperation alloc] initWithCursor:cursor];
                } else {
                        CKQuery *query;
                        NSDate *lastSyncDate;
                        NSPredicate *predicate;
                        
                        lastSyncDate = [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE];
                        
                        if ( lastSyncDate )
                                predicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate];
                        else
                                predicate = [NSPredicate predicateWithValue:YES];
                        
                        query   = [[CKQuery alloc] initWithRecordType:@"TextItem" predicate:predicate];
                        queryOp = [[CKQueryOperation alloc] initWithQuery:query];
                }
                
                queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
                        if ( operationError ) {
                                didRestoreTextItems = YES;
                                
                                if ( operationError.code != CKErrorUnknownItem ) {
                                        restoreError = operationError;
                                        
                                        NSLog(@"%@", operationError);
                                }
                                
                                [self doneRestoring];
                        } else {
                                if ( cursor )
                                        [self fetchAllTextItemsWithCursor:cursor];
                                else
                                        [self processTextItems:textItems];
                        }
                };
                queryOp.recordFetchedBlock = ^(CKRecord *record) {
                        [textItems addObject:record];
                };
                
                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:queryOp];
        });
}

- (void)flushDeletes
{
        [queue inDatabase:^(FMDatabase *db) {
                [db executeUpdate:@"VACUUM;"];
                
                if ( ubiquityStatus != 0 ) {
                        CKModifyRecordsOperation *op;
                        FMResultSet *resultSet;
                        NSMutableSet *deletionList;
                        
                        deletionList = [NSMutableSet set];
                        resultSet    = [db executeQuery:@"SELECT ID FROM COLLECTION WHERE DELETED = 1"];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                
                                recordID  = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM LINK_ITEM WHERE DELETED = 1"];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                
                                recordID  = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM LOCATION_ITEM WHERE DELETED = 1"];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                
                                recordID  = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM MEDIA_ITEM WHERE DELETED = 1"];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                
                                recordID  = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT ID FROM TEXT_ITEM WHERE DELETED = 1"];
                        
                        while ( [resultSet next] ) {
                                CKRecordID *recordID;
                                
                                recordID  = [[CKRecordID alloc] initWithRecordName:[resultSet stringForColumnIndex:0]];
                                
                                [deletionList addObject:recordID];
                        }
                        
                        if ( deletionList.count > 0 ) {
                                op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:deletionList.allObjects];
                                op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                        if ( operationError ) {
                                                NSLog(@"%@", operationError);
                                        } else {
                                                for ( CKRecordID *recordID in deletedRecordIDs) {
                                                        // Since we have no clue what the ID represents, run a delete on all tables.
                                                        [db executeUpdate:@"DELETE FROM COLLECTION WHERE ID = ?", recordID.recordName];
                                                        [db executeUpdate:@"DELETE FROM LINK_ITEM WHERE ID = ?", recordID.recordName];
                                                        [db executeUpdate:@"DELETE FROM LOCATION_ITEM WHERE ID = ?", recordID.recordName];
                                                        [db executeUpdate:@"DELETE FROM MEDIA_ITEM WHERE ID = ?", recordID.recordName];
                                                        [db executeUpdate:@"DELETE FROM TEXT_ITEM WHERE ID = ?", recordID.recordName];
                                                }
                                        }
                                };
                                op.savePolicy = CKRecordSaveAllKeys;
                                
                                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                        }
                } else { // iCloud disabled; delete everything marked for deletion locally.
                        [db executeUpdate:@"DELETE FROM COLLECTION WHERE DELETED = 1"];
                        [db executeUpdate:@"DELETE FROM LINK_ITEM WHERE DELETED = 1"];
                        [db executeUpdate:@"DELETE FROM LOCATION_ITEM WHERE DELETED = 1"];
                        [db executeUpdate:@"DELETE FROM MEDIA_ITEM WHERE DELETED = 1"];
                        [db executeUpdate:@"DELETE FROM TEXT_ITEM WHERE DELETED = 1"];
                }
        }];
}

- (void)flushPending
{
        [self flushDeletes];
        [self flushUpdates];
}

- (void)flushUpdates
{
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                CKModifyRecordsOperation *op;
                FMResultSet *resultSet;
                NSMutableSet *updates;
                
                updates   = [NSMutableSet set];
                resultSet = [db executeQuery:@"SELECT * FROM COLLECTION WHERE BACKED_UP = 0"];
                
                while ( [resultSet next] ) {
                        CKRecord *record;
                        CKRecordID *recordID;
                        NSString *collectionIdentifier;
                        
                        collectionIdentifier = [resultSet stringForColumn:@"ID"];
                        recordID             = [[CKRecordID alloc] initWithRecordName:collectionIdentifier];
                        
                        record              = [[CKRecord alloc] initWithRecordType:@"Collection" recordID:recordID];
                        record[@"created"]  = [resultSet dateForColumn:@"CREATED"];
                        record[@"modified"] = [resultSet dateForColumn:@"MODIFIED"];
                        record[@"position"] = [NSNumber numberWithInt:[resultSet intForColumn:@"POSITION"]];
                        record[@"title"]    = [resultSet stringForColumn:@"TITLE"];
                        
                        [updates addObject:record];
                }
                
                resultSet = [db executeQuery:@"SELECT * FROM LINK_ITEM WHERE BACKED_UP = 0"];
                
                while ( [resultSet next] ) {
                        CKRecord *record;
                        CKRecordID *recordID;
                        NSString *coordinates;
                        NSString *itemIdentifier;
                        
                        coordinates    = [resultSet stringForColumn:@"COORDINATES"];
                        itemIdentifier = [resultSet stringForColumn:@"ID"];
                        recordID       = [[CKRecordID alloc] initWithRecordName:itemIdentifier];
                        
                        record                          = [[CKRecord alloc] initWithRecordType:@"LinkItem" recordID:recordID];
                        record[@"collectionIdentifier"] = [resultSet stringForColumn:@"COLLECTION"];
                        record[@"created"]              = [resultSet dateForColumn:@"CREATED"];
                        record[@"location"]             = [resultSet stringForColumn:@"LOCATION"];
                        record[@"moved"]                = [resultSet dateForColumn:@"MOVED"];
                        record[@"title"]                = [resultSet stringForColumn:@"TITLE"];
                        record[@"URL"]                  = [resultSet stringForColumn:@"URL"];
                        
                        if ( coordinates &&
                             coordinates.length > 0 ) {
                                NSArray *components;
                                
                                components = [coordinates componentsSeparatedByString:@","];
                                
                                if ( components.count == 2 )
                                        record[@"coordinates"] = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                        }
                        
                        [updates addObject:record];
                }
                
                resultSet = [db executeQuery:@"SELECT * FROM LOCATION_ITEM WHERE BACKED_UP = 0"];
                
                while ( [resultSet next] ) {
                        CKRecord *record;
                        CKRecordID *recordID;
                        NSString *coordinates;
                        NSString *itemIdentifier;
                        
                        coordinates    = [resultSet stringForColumn:@"COORDINATES"];
                        itemIdentifier = [resultSet stringForColumn:@"ID"];
                        recordID       = [[CKRecordID alloc] initWithRecordName:itemIdentifier];
                        
                        record                          = [[CKRecord alloc] initWithRecordType:@"LocationItem" recordID:recordID];
                        record[@"collectionIdentifier"] = [resultSet stringForColumn:@"COLLECTION"];
                        record[@"created"]              = [resultSet dateForColumn:@"CREATED"];
                        record[@"location"]             = [resultSet stringForColumn:@"LOCATION"];
                        record[@"moved"]                = [resultSet dateForColumn:@"MOVED"];
                        
                        if ( coordinates &&
                             coordinates.length > 0 ) {
                                NSArray *components;
                                
                                components = [coordinates componentsSeparatedByString:@","];
                                
                                if ( components.count == 2 )
                                        record[@"coordinates"] = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                        }
                        
                        [updates addObject:record];
                }
                
                resultSet = [db executeQuery:@"SELECT * FROM MEDIA_ITEM WHERE BACKED_UP = 0"];
                
                while ( [resultSet next] ) {
                        CKAsset *assetCaption;
                        CKAsset *assetInk;
                        CKAsset *assetMedia;
                        CKRecord *record;
                        CKRecordID *recordID;
                        NSError *error;
                        NSFileManager *fileManager;
                        NSString *captionAnchorPoint;
                        NSString *captionBounds;
                        NSString *captionCenter;
                        NSString *captionTransform;
                        NSString *coordinates;
                        NSString *itemIdentifier;
                        NSURL *pathCaption;
                        NSURL *pathInk;
                        NSURL *pathMedia;
                        ItemType itemType;
                        
                        captionAnchorPoint = [resultSet stringForColumn:@"CAPTION_ANCHOR_POINT"];
                        captionBounds      = [resultSet stringForColumn:@"CAPTION_BOUNDS"];
                        captionCenter      = [resultSet stringForColumn:@"CAPTION_CENTER"];
                        captionTransform   = [resultSet stringForColumn:@"CAPTION_TRANSFORM"];
                        coordinates        = [resultSet stringForColumn:@"COORDINATES"];
                        fileManager        = [NSFileManager defaultManager];
                        itemIdentifier     = [resultSet stringForColumn:@"ID"];
                        itemType           = [resultSet intForColumn:@"TYPE"];
                        recordID           = [[CKRecordID alloc] initWithRecordName:itemIdentifier];
                        pathCaption        = [Util pathForText:itemIdentifier];
                        pathInk            = [Util pathForInk:itemIdentifier];
                        
                        if ( itemType == ItemTypePhoto )
                                pathMedia = [Util pathForMedia:itemIdentifier extension:@"jpg"];
                        else if ( itemType == ItemTypeMovie )
                                pathMedia = [Util pathForMedia:itemIdentifier extension:@"mov"];
                        
                        if ( !error ) {
                                record                          = [[CKRecord alloc] initWithRecordType:@"MediaItem" recordID:recordID];
                                record[@"captionAnchorPoint"]   = captionAnchorPoint;
                                record[@"captionBounds"]        = captionBounds;
                                record[@"captionCenter"]        = captionCenter;
                                record[@"captionTransform"]     = captionTransform;
                                record[@"collectionIdentifier"] = [resultSet stringForColumn:@"COLLECTION"];
                                record[@"created"]              = [resultSet dateForColumn:@"CREATED"];
                                record[@"location"]             = [resultSet stringForColumn:@"LOCATION"];
                                record[@"modified"]             = [resultSet dateForColumn:@"MODIFIED"];
                                record[@"moved"]                = [resultSet dateForColumn:@"MOVED"];
                                record[@"type"]                 = [NSNumber numberWithInt:[resultSet intForColumn:@"TYPE"]];
                                
                                if ( coordinates &&
                                     coordinates.length > 0 ) {
                                        NSArray *components;
                                        
                                        components = [coordinates componentsSeparatedByString:@","];
                                        
                                        if ( components.count == 2 )
                                                record[@"coordinates"] = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                }
                                
                                if ( [fileManager fileExistsAtPath:pathCaption.path] ) {
                                        assetCaption       = [[CKAsset alloc] initWithFileURL:pathCaption];
                                        record[@"caption"] = assetCaption;
                                }
                                
                                if ( [fileManager fileExistsAtPath:pathInk.path] ) {
                                        assetInk       = [[CKAsset alloc] initWithFileURL:pathInk];
                                        record[@"ink"] = assetInk;
                                }
                                
                                if ( [fileManager fileExistsAtPath:pathMedia.path] ) {
                                        assetMedia      = [[CKAsset alloc] initWithFileURL:pathMedia];
                                        record[@"data"] = assetMedia;
                                }
                                
                                [updates addObject:record];
                        }
                }
                
                resultSet  = [db executeQuery:@"SELECT * FROM TEXT_ITEM WHERE BACKED_UP = 0"];
                
                while ( [resultSet next] ) {
                        CKAsset *assetInk;
                        CKAsset *assetText;
                        CKRecord *record;
                        CKRecordID *recordID;
                        NSError *error;
                        NSFileManager *fileManager;
                        NSString *coordinates;
                        NSString *itemIdentifier;
                        NSURL *pathInk;
                        NSURL *pathText;
                        
                        coordinates    = [resultSet stringForColumn:@"COORDINATES"];
                        itemIdentifier = [resultSet stringForColumn:@"ID"];
                        fileManager    = [NSFileManager defaultManager];
                        recordID       = [[CKRecordID alloc] initWithRecordName:itemIdentifier];
                        pathInk        = [Util pathForInk:itemIdentifier];
                        pathText       = [Util pathForText:itemIdentifier];
                        
                        if ( !error ) {
                                record                          = [[CKRecord alloc] initWithRecordType:@"TextItem" recordID:recordID];
                                record[@"collectionIdentifier"] = [resultSet stringForColumn:@"COLLECTION"];
                                record[@"created"]              = [resultSet dateForColumn:@"CREATED"];
                                record[@"location"]             = [resultSet stringForColumn:@"LOCATION"];
                                record[@"modified"]             = [resultSet dateForColumn:@"MODIFIED"];
                                record[@"moved"]                = [resultSet dateForColumn:@"MOVED"];
                                
                                if ( coordinates &&
                                     coordinates.length > 0 ) {
                                        NSArray *components;
                                        
                                        components = [coordinates componentsSeparatedByString:@","];
                                        
                                        if ( components.count == 2 )
                                                record[@"coordinates"] = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                }
                                
                                if ( [fileManager fileExistsAtPath:pathInk.path] ) {
                                        assetInk       = [[CKAsset alloc] initWithFileURL:pathInk];
                                        record[@"ink"] = assetInk;
                                }
                                
                                if ( [fileManager fileExistsAtPath:pathText.path] ) {
                                        assetText       = [[CKAsset alloc] initWithFileURL:pathText];
                                        record[@"data"] = assetText;
                                }
                                
                                [updates addObject:record];
                        }
                }
                
                if ( updates.count > 0 ) {
                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:updates.allObjects recordIDsToDelete:nil];
                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                if ( operationError ) {
                                        NSLog(@"%@", operationError);
                                } else {
                                        for ( CKRecord *record in savedRecords) {
                                                if ( [record.recordType isEqualToString:@"Collection"] )
                                                        [db executeUpdate:@"UPDATE COLLECTION SET BACKED_UP = 1 WHERE ID = ?",
                                                         record.recordID.recordName];
                                                else if ( [record.recordType isEqualToString:@"LinkItem"] )
                                                        [db executeUpdate:@"UPDATE LINK_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                         record.recordID.recordName];
                                                else if ( [record.recordType isEqualToString:@"LocationItem"] )
                                                        [db executeUpdate:@"UPDATE LOCATION_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                         record.recordID.recordName];
                                                else if ( [record.recordType isEqualToString:@"MediaItem"] )
                                                        [db executeUpdate:@"UPDATE MEDIA_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                         record.recordID.recordName];
                                                else if ( [record.recordType isEqualToString:@"TextItem"] )
                                                        [db executeUpdate:@"UPDATE TEXT_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                         record.recordID.recordName];
                                        }
                                }
                        };
                        op.savePolicy = CKRecordSaveAllKeys;
                        
                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                }
        }];
}

- (void)incrementSchemaVersion
{
        FMDatabase *db;
        uint32_t currentVersion;
        
        db = [FMDatabase databaseWithPath:databaseLocalPath];
        
        [db open];
        
        currentVersion = [db userVersion] + 1;
        
        [db setUserVersion:currentVersion];
        [db close];
}

- (void)loadCollectionsCompletion:(void (^)(NSMutableArray *list))completion
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        FMResultSet *s1;
                        NSMutableArray *array;
                        
                        array = [NSMutableArray array];
                        s1    = [db executeQuery:@"SELECT * FROM COLLECTION WHERE DELETED = 0 ORDER BY MODIFIED DESC"];
                        
                        while ( [s1 next] ) {
                                FMResultSet *s2;
                                Collection *collection;
                                NSMutableArray *items;
                                
                                items = [NSMutableArray array];
                                
                                collection            = [Collection new];
                                collection.created    = [s1 dateForColumn:@"CREATED"];
                                collection.index      = [s1 intForColumn:@"POSITION"];
                                collection.identifier = [s1 stringForColumn:@"ID"];
                                collection.modified   = [s1 dateForColumn:@"MODIFIED"];
                                collection.title      = [s1 stringForColumn:@"TITLE"];
                                
                                s2 = [db executeQuery:@"SELECT * FROM LINK_ITEM WHERE DELETED = 0 AND COLLECTION = ?",
                                      collection.identifier];
                                
                                while ( [s2 next] ) {
                                        CLLocation *location;
                                        NSString *coordinates;
                                        LinkItem *item;
                                        
                                        coordinates = [s2 stringForColumn:@"COORDINATES"];
                                        
                                        if ( coordinates &&
                                             coordinates.length > 0 ) {
                                                NSArray *components;
                                                
                                                components = [coordinates componentsSeparatedByString:@","];
                                                
                                                if ( components.count == 2 )
                                                        location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                        }
                                        
                                        item                      = [LinkItem new];
                                        item.identifier           = [s2 stringForColumn:@"ID"];
                                        item.collectionIdentifier = collection.identifier;
                                        item.coordinates          = location;
                                        item.created              = [s2 dateForColumn:@"CREATED"];
                                        item.location             = [s2 stringForColumn:@"LOCATION"];
                                        item.moved                = [s2 dateForColumn:@"MOVED"];
                                        item.snapshot             = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForSnapshot:item.identifier]]];
                                        item.title                = [s2 stringForColumn:@"TITLE"];
                                        item.URL                  = [NSURL URLWithString:[s2 stringForColumn:@"URL"]];
                                        
                                        [items addObject:item];
                                }
                                
                                s2 = [db executeQuery:@"SELECT * FROM LOCATION_ITEM WHERE DELETED = 0 AND COLLECTION = ?",
                                      collection.identifier];
                                
                                while ( [s2 next] ) {
                                        CLLocation *location;
                                        NSString *coordinates;
                                        LocationItem *item;
                                        
                                        coordinates = [s2 stringForColumn:@"COORDINATES"];
                                        
                                        if ( coordinates &&
                                             coordinates.length > 0 ) {
                                                NSArray *components;
                                                
                                                components = [coordinates componentsSeparatedByString:@","];
                                                
                                                if ( components.count == 2 )
                                                        location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                        }
                                        
                                        item                      = [LocationItem new];
                                        item.identifier           = [s2 stringForColumn:@"ID"];
                                        item.collectionIdentifier = collection.identifier;
                                        item.coordinates          = location;
                                        item.created              = [s2 dateForColumn:@"CREATED"];
                                        item.location             = [s2 stringForColumn:@"LOCATION"];
                                        item.moved                = [s2 dateForColumn:@"MOVED"];
                                        
                                        [items addObject:item];
                                }
                                
                                s2 = [db executeQuery:@"SELECT * FROM MEDIA_ITEM WHERE DELETED = 0 AND COLLECTION = ?",
                                      collection.identifier];
                                
                                while ( [s2 next] ) {
                                        CLLocation *location;
                                        NSString *coordinates;
                                        MediaItem *item;
                                        ItemType type;
                                        
                                        coordinates = [s2 stringForColumn:@"COORDINATES"];
                                        type        = [s2 intForColumn:@"TYPE"];
                                        
                                        if ( coordinates &&
                                             coordinates.length > 0 ) {
                                                NSArray *components;
                                                
                                                components = [coordinates componentsSeparatedByString:@","];
                                                
                                                if ( components.count == 2 )
                                                        location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                        }
                                        
                                        item                               = [MediaItem new];
                                        item.identifier                    = [s2 stringForColumn:@"ID"];
                                        item.captionView.bounds            = CGRectFromString([s2 stringForColumn:@"CAPTION_BOUNDS"]);
                                        item.captionView.center            = CGPointFromString([s2 stringForColumn:@"CAPTION_CENTER"]);
                                        item.captionView.layer.anchorPoint = CGPointFromString([s2 stringForColumn:@"CAPTION_ANCHOR_POINT"]);
                                        item.captionView.transform         = CGAffineTransformFromString([s2 stringForColumn:@"CAPTION_TRANSFORM"]);
                                        item.collectionIdentifier          = collection.identifier;
                                        item.coordinates                   = location;
                                        item.created                       = [s2 dateForColumn:@"CREATED"];
                                        item.caption                       = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:[Util pathForText:item.identifier]]];
                                        item.image                         = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForMedia:item.identifier extension:@"jpg"]]];
                                        item.ink                           = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForInk:item.identifier]] scale:UIScreen.mainScreen.scale];
                                        item.itemType                      = type;
                                        item.location                      = [s2 stringForColumn:@"LOCATION"];
                                        item.modified                      = [s2 dateForColumn:@"MODIFIED"];
                                        item.moved                         = [s2 dateForColumn:@"MOVED"];
                                        
                                        [items addObject:item];
                                }
                                
                                s2 = [db executeQuery:@"SELECT * FROM TEXT_ITEM WHERE DELETED = 0 AND COLLECTION = ?",
                                      collection.identifier];
                                
                                while ( [s2 next] ) {
                                        CLLocation *location;
                                        NSString *coordinates;
                                        TextItem *item;
                                        
                                        coordinates = [s2 stringForColumn:@"COORDINATES"];
                                        
                                        if ( coordinates &&
                                             coordinates.length > 0 ) {
                                                NSArray *components;
                                                
                                                components = [coordinates componentsSeparatedByString:@","];
                                                
                                                if ( components.count == 2 )
                                                        location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                        }
                                        
                                        item                      = [TextItem new];
                                        item.identifier           = [s2 stringForColumn:@"ID"];
                                        item.collectionIdentifier = collection.identifier;
                                        item.coordinates          = location;
                                        item.created              = [s2 dateForColumn:@"CREATED"];
                                        item.ink                  = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForInk:item.identifier]] scale:UIScreen.mainScreen.scale];
                                        item.location             = [s2 stringForColumn:@"LOCATION"];
                                        item.modified             = [s2 dateForColumn:@"MODIFIED"];
                                        item.moved                = [s2 dateForColumn:@"MOVED"];
                                        item.string               = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:[Util pathForText:item.identifier]]];
                                        
                                        [items addObject:item];
                                }
                                
                                [items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"moved" ascending:NO]]];
                                
                                collection.items = items;
                                
                                [array addObject:collection];
                        }
                        
                        completion(array);
                }];
        });
}

- (void)loadFreeItemsCompletion:(void (^)(NSMutableArray *list))completion
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        FMResultSet *resultSet;
                        NSMutableArray *array;
                        
                        array     = [NSMutableArray array];
                        resultSet = [db executeQuery:@"SELECT * FROM LINK_ITEM WHERE DELETED = 0 AND (COLLECTION IS NULL OR COLLECTION = '') ORDER BY MOVED ASC"];
                        
                        while ( [resultSet next] ) {
                                CLLocation *location;
                                NSString *coordinates;
                                LinkItem *item;
                                
                                coordinates = [resultSet stringForColumn:@"COORDINATES"];
                                
                                if ( coordinates &&
                                     coordinates.length > 0 ) {
                                        NSArray *components;
                                        
                                        components = [coordinates componentsSeparatedByString:@","];
                                        
                                        if ( components.count == 2 )
                                                location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                }
                                
                                item             = [LinkItem new];
                                item.identifier  = [resultSet stringForColumn:@"ID"];
                                item.coordinates = location;
                                item.created     = [resultSet dateForColumn:@"CREATED"];
                                item.location    = [resultSet stringForColumn:@"LOCATION"];
                                item.moved       = [resultSet dateForColumn:@"MOVED"];
                                item.snapshot    = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForSnapshot:item.identifier]]];
                                item.title       = [resultSet stringForColumn:@"TITLE"];
                                item.URL         = [NSURL URLWithString:[resultSet stringForColumn:@"URL"]];
                                
                                [array addObject:item];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT * FROM LOCATION_ITEM WHERE DELETED = 0 AND (COLLECTION IS NULL OR COLLECTION = '') ORDER BY MOVED ASC"];
                        
                        while ( [resultSet next] ) {
                                CLLocation *location;
                                NSString *coordinates;
                                LocationItem *item;
                                
                                coordinates = [resultSet stringForColumn:@"COORDINATES"];
                                
                                if ( coordinates &&
                                    coordinates.length > 0 ) {
                                        NSArray *components;
                                        
                                        components = [coordinates componentsSeparatedByString:@","];
                                        
                                        if ( components.count == 2 )
                                                location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                }
                                
                                item             = [LocationItem new];
                                item.identifier  = [resultSet stringForColumn:@"ID"];
                                item.coordinates = location;
                                item.created     = [resultSet dateForColumn:@"CREATED"];
                                item.location    = [resultSet stringForColumn:@"LOCATION"];
                                item.moved       = [resultSet dateForColumn:@"MOVED"];
                                
                                [array addObject:item];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT * FROM MEDIA_ITEM WHERE DELETED = 0 AND (COLLECTION IS NULL OR COLLECTION = '') ORDER BY MODIFIED ASC"];
                        
                        while ( [resultSet next] ) {
                                CLLocation *location;
                                NSString *coordinates;
                                MediaItem *item;
                                ItemType type;
                                
                                coordinates = [resultSet stringForColumn:@"COORDINATES"];
                                type        = [resultSet intForColumn:@"TYPE"];
                                
                                if ( coordinates &&
                                     coordinates.length > 0 ) {
                                        NSArray *components;
                                        
                                        components = [coordinates componentsSeparatedByString:@","];
                                        
                                        if ( components.count == 2 )
                                                location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                }
                                
                                item                               = [MediaItem new];
                                item.identifier                    = [resultSet stringForColumn:@"ID"];
                                item.captionView.bounds            = CGRectFromString([resultSet stringForColumn:@"CAPTION_BOUNDS"]);
                                item.captionView.center            = CGPointFromString([resultSet stringForColumn:@"CAPTION_CENTER"]);
                                item.captionView.layer.anchorPoint = CGPointFromString([resultSet stringForColumn:@"CAPTION_ANCHOR_POINT"]);
                                item.captionView.transform         = CGAffineTransformFromString([resultSet stringForColumn:@"CAPTION_TRANSFORM"]);
                                item.coordinates                   = location;
                                item.created                       = [resultSet dateForColumn:@"CREATED"];
                                item.caption                       = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:[Util pathForText:item.identifier]]];
                                item.image                         = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForMedia:item.identifier extension:@"jpg"]]];
                                item.ink                           = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForInk:item.identifier]] scale:UIScreen.mainScreen.scale];
                                item.itemType                      = type;
                                item.location                      = [resultSet stringForColumn:@"LOCATION"];
                                item.modified                      = [resultSet dateForColumn:@"MODIFIED"];
                                item.moved                         = [resultSet dateForColumn:@"MOVED"];
                                
                                [array addObject:item];
                        }
                        
                        resultSet = [db executeQuery:@"SELECT * FROM TEXT_ITEM WHERE DELETED = 0 AND (COLLECTION IS NULL OR COLLECTION = '') ORDER BY MODIFIED ASC"];
                        
                        while ( [resultSet next] ) {
                                CLLocation *location;
                                NSString *coordinates;
                                TextItem *item;
                                
                                coordinates = [resultSet stringForColumn:@"COORDINATES"];
                                
                                if ( coordinates &&
                                     coordinates.length > 0 ) {
                                        NSArray *components;
                                        
                                        components = [coordinates componentsSeparatedByString:@","];
                                        
                                        if ( components.count == 2 )
                                                location = [[CLLocation alloc] initWithLatitude:[components[0] doubleValue] longitude:[components[1] doubleValue]];
                                }
                                
                                item             = [TextItem new];
                                item.identifier  = [resultSet stringForColumn:@"ID"];
                                item.coordinates = location;
                                item.created     = [resultSet dateForColumn:@"CREATED"];
                                item.ink         = [UIImage imageWithData:[NSData dataWithContentsOfURL:[Util pathForInk:item.identifier]] scale:UIScreen.mainScreen.scale];
                                item.location    = [resultSet stringForColumn:@"LOCATION"];
                                item.modified    = [resultSet dateForColumn:@"MODIFIED"];
                                item.moved       = [resultSet dateForColumn:@"MOVED"];
                                item.string      = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:[Util pathForText:item.identifier]]];
                                
                                [array addObject:item];
                        }
                        
                        completion(array);
                }];
        });
}

- (void)processCollections:(NSArray *)collections
{
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for ( CKRecord *record in collections ) {
                        Collection *collection;
                        
                        collection            = [Collection new];
                        collection.created    = record[@"created"];
                        collection.identifier = record.recordID.recordName;
                        collection.index      = [record[@"position"] intValue];
                        collection.modified   = record[@"modified"];
                        collection.title      = record[@"title"];
                        
                        [fetchedCollections addObject:collection];
                }
                
                for ( Collection *collection in fetchedCollections ) {
                        FMResultSet *s;
                        BOOL exists;
                        
                        exists = NO;
                        s      = [db executeQuery:@"SELECT ID FROM COLLECTION WHERE ID = ?", collection.identifier];
                        
                        while ( [s next] ) { // Already exists; update.
                                exists = YES;
                                
                                [db executeUpdate:@"UPDATE COLLECTION SET ID = ?, BACKED_UP = 1, POSITION = ?, TITLE = ?, CREATED = ?, MODIFIED = ? WHERE ID = ? AND DATETIME(MODIFIED) < DATETIME(?)",
                                 collection.identifier,
                                 [NSNumber numberWithInteger:collection.index],
                                 collection.title,
                                 collection.created,
                                 collection.modified,
                                 collection.identifier,
                                 collection.modified];
                        }
                        
                        if ( !exists ) {
                                [db executeUpdate:@"INSERT INTO COLLECTION(ID, BACKED_UP, POSITION, TITLE, CREATED, MODIFIED) VALUES(?, 1, ?, ?, ?, ?)",
                                 collection.identifier,
                                 [NSNumber numberWithInteger:collection.index],
                                 collection.title,
                                 collection.created,
                                 collection.modified];
                        }
                }
                
                didRestoreCollections = YES;
                
                // Fetch everything else after the collections are done to ensure foreign key integrity.
                [self fetchAllLinkItemsWithCursor:nil];
                [self fetchAllLocationItemsWithCursor:nil];
                [self fetchAllMediaItemsWithCursor:nil];
                [self fetchAllTextItemsWithCursor:nil];
        }];
}

- (void)processLinkItems:(NSArray *)items
{
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for ( CKRecord *record in items ) {
                        LinkItem *item;
                        
                        item                      = [LinkItem new];
                        item.collectionIdentifier = record[@"collectionIdentifier"];
                        item.coordinates          = record[@"coordinates"];
                        item.created              = record[@"created"];
                        item.identifier           = record.recordID.recordName;
                        item.location             = record[@"location"];
                        item.moved                = record[@"moved"];
                        item.title                = record[@"title"];
                        item.URL                  = [NSURL URLWithString:record[@"URL"]];
                        
                        [fetchedLinkItems addObject:item];
                }
                
                for ( LinkItem *item in fetchedLinkItems ) {
                        FMResultSet *resultSet;
                        NSString *coordinates;
                        BOOL exists;
                        
                        if ( item.coordinates )
                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                        
                        exists    = NO;
                        resultSet = [db executeQuery:@"SELECT ID FROM LINK_ITEM WHERE ID = ?", item.identifier];
                        
                        while ( [resultSet next] ) { // Already exists; update.
                                exists = YES;
                                
                                [db executeUpdate:@"UPDATE LINK_ITEM SET ID = ?, COLLECTION = ?, BACKED_UP = 1, TITLE = ?, URL = ?, COORDINATES = ?, LOCATION = ?, CREATED = ?, MOVED = ? WHERE ID = ?",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 item.title,
                                 item.URL.absoluteString,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.moved,
                                 item.identifier];
                        }
                        
                        if ( !exists ) {
                                [db executeUpdate:@"INSERT INTO LINK_ITEM(ID, COLLECTION, BACKED_UP, TITLE, URL, COORDINATES, LOCATION, CREATED, MOVED) VALUES(?, ?, 1, ?, ?, ?, ?, ?, ?)",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 item.title,
                                 item.URL.absoluteString,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.moved];
                        }
                }
                
                didRestoreLinkItems = YES;
                
                [self doneRestoring];
        }];
}

- (void)processLocationItems:(NSArray *)items
{
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for ( CKRecord *record in items ) {
                        LocationItem *item;
                        
                        item                      = [LocationItem new];
                        item.collectionIdentifier = record[@"collectionIdentifier"];
                        item.coordinates          = record[@"coordinates"];
                        item.created              = record[@"created"];
                        item.identifier           = record.recordID.recordName;
                        item.location             = record[@"location"];
                        item.moved                = record[@"moved"];
                        
                        [fetchedLocationItems addObject:item];
                }
                
                for ( LocationItem *item in fetchedLocationItems ) {
                        FMResultSet *resultSet;
                        NSString *coordinates;
                        BOOL exists;
                        
                        if ( item.coordinates )
                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                        
                        exists    = NO;
                        resultSet = [db executeQuery:@"SELECT ID FROM LOCATION_ITEM WHERE ID = ?", item.identifier];
                        
                        while ( [resultSet next] ) { // Already exists; update.
                                exists = YES;
                                
                                [db executeUpdate:@"UPDATE LOCATION_ITEM SET ID = ?, COLLECTION = ?, BACKED_UP = 1, COORDINATES = ?, LOCATION = ?, CREATED = ?, MOVED = ? WHERE ID = ?",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.moved,
                                 item.identifier];
                        }
                        
                        if ( !exists ) {
                                [db executeUpdate:@"INSERT INTO LOCATION_ITEM(ID, COLLECTION, BACKED_UP, COORDINATES, LOCATION, CREATED, MOVED) VALUES(?, ?, 1, ?, ?, ?, ?)",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.moved];
                        }
                }
                
                didRestoreLocationItems = YES;
                
                [self doneRestoring];
        }];
}

- (void)processMediaItems:(NSArray *)items
{
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for ( CKRecord *record in items ) {
                        CKAsset *assetCaption;
                        CKAsset *assetInk;
                        CKAsset *assetMedia;
                        MediaItem *item;
                        NSFileManager *fileManager;
                        
                        assetCaption = record[@"caption"];
                        assetInk     = record[@"ink"];
                        assetMedia   = record[@"data"];
                        fileManager  = [NSFileManager defaultManager];
                        
                        item                               = [MediaItem new];
                        item.captionView.bounds            = CGRectFromString(record[@"captionBounds"]);
                        item.captionView.center            = CGPointFromString(record[@"captionCenter"]);
                        item.captionView.layer.anchorPoint = CGPointFromString(record[@"captionAnchorPoint"]);
                        item.captionView.transform         = CGAffineTransformFromString(record[@"captionTransform"]);
                        item.collectionIdentifier          = record[@"collectionIdentifier"];
                        item.coordinates                   = record[@"coordinates"];
                        item.created                       = record[@"created"];
                        item.identifier                    = record.recordID.recordName;
                        item.itemType                      = [record[@"type"] intValue];
                        item.location                      = record[@"location"];
                        item.modified                      = record[@"modified"];
                        item.moved                         = record[@"moved"];
                        
                        if ( assetCaption ) {
                                [fileManager removeItemAtURL:[Util pathForText:item.identifier] error:nil];
                                [fileManager copyItemAtURL:assetCaption.fileURL toURL:[Util pathForText:item.identifier] error:nil];
                                
                                item.caption = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:assetCaption.fileURL]];
                        }
                        
                        if ( assetInk ) {
                                [fileManager removeItemAtURL:[Util pathForInk:item.identifier] error:nil];
                                [fileManager copyItemAtURL:assetCaption.fileURL toURL:[Util pathForInk:item.identifier] error:nil];
                                
                                item.ink = [UIImage imageWithData:[NSData dataWithContentsOfURL:assetInk.fileURL] scale:UIScreen.mainScreen.scale];
                        }
                        
                        if ( assetMedia ) {
                                NSString *extension;
                                
                                if ( item.itemType == ItemTypePhoto )
                                        extension = @"jpg";
                                else if ( item.itemType == ItemTypeMovie )
                                        extension = @"mov";
                                
                                [fileManager removeItemAtURL:[Util pathForMedia:item.identifier extension:extension] error:nil];
                                [fileManager copyItemAtURL:assetMedia.fileURL toURL:[Util pathForMedia:item.identifier extension:extension] error:nil];
                                
                                if ( item.itemType == ItemTypePhoto )
                                        item.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:assetMedia.fileURL]];
                                else if ( item.itemType == ItemTypeMovie )
                                        [self updateMediaThumbnail:item]; // Update the video's thumbnail.
                        }
                        
                        [fetchedMediaItems addObject:item];
                }
                
                for ( MediaItem *item in fetchedMediaItems ) {
                        FMResultSet *resultSet;
                        NSString *coordinates;
                        BOOL exists;
                        
                        if ( item.coordinates )
                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                        
                        exists    = NO;
                        resultSet = [db executeQuery:@"SELECT ID FROM MEDIA_ITEM WHERE ID = ?", item.identifier];
                        
                        while ( [resultSet next] ) { // Already exists; update.
                                exists = YES;
                                
                                [db executeUpdate:@"UPDATE MEDIA_ITEM SET ID = ?, COLLECTION = ?, BACKED_UP = 1, TYPE = ?, CAPTION_ANCHOR_POINT = ?, CAPTION_BOUNDS = ?, CAPTION_CENTER = ?, CAPTION_TRANSFORM = ?, COORDINATES = ?, LOCATION = ?, CREATED = ?, MODIFIED = ?, MOVED = ? WHERE ID = ? AND DATETIME(MODIFIED) < DATETIME(?)",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 [NSNumber numberWithInt:item.itemType],
                                 NSStringFromCGPoint(item.captionView.layer.anchorPoint),
                                 NSStringFromCGRect(item.captionView.bounds),
                                 NSStringFromCGPoint(item.captionView.center),
                                 NSStringFromCGAffineTransform(item.captionView.transform),
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.modified,
                                 item.moved,
                                 item.identifier,
                                 item.modified];
                        }
                        
                        if ( !exists ) {
                                [db executeUpdate:@"INSERT INTO MEDIA_ITEM(ID, COLLECTION, BACKED_UP, TYPE, CAPTION_ANCHOR_POINT, CAPTION_BOUNDS, CAPTION_CENTER, CAPTION_TRANSFORM, COORDINATES, LOCATION, CREATED, MODIFIED, MOVED) VALUES(?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 [NSNumber numberWithInt:item.itemType],
                                 NSStringFromCGPoint(item.captionView.layer.anchorPoint),
                                 NSStringFromCGRect(item.captionView.bounds),
                                 NSStringFromCGPoint(item.captionView.center),
                                 NSStringFromCGAffineTransform(item.captionView.transform),
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.modified,
                                 item.moved];
                        }
                }
                
                didRestoreMediaItems = YES;
                
                [self doneRestoring];
        }];
}

- (void)processTextItems:(NSArray *)items
{
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for ( CKRecord *record in items ) {
                        CKAsset *assetInk;
                        CKAsset *assetText;
                        TextItem *item;
                        NSFileManager *fileManager;
                        
                        assetInk    = record[@"ink"];
                        assetText   = record[@"data"];
                        fileManager = [NSFileManager defaultManager];
                        
                        item                      = [TextItem new];
                        item.collectionIdentifier = record[@"collectionIdentifier"];
                        item.coordinates          = record[@"coordinates"];
                        item.created              = record[@"created"];
                        item.identifier           = record.recordID.recordName;
                        item.location             = record[@"location"];
                        item.modified             = record[@"modified"];
                        item.moved                = record[@"moved"];
                        
                        if ( assetInk ) {
                                [fileManager removeItemAtURL:[Util pathForInk:item.identifier] error:nil];
                                [fileManager copyItemAtURL:assetInk.fileURL toURL:[Util pathForInk:item.identifier] error:nil];
                                
                                item.ink = [UIImage imageWithData:[NSData dataWithContentsOfURL:assetInk.fileURL] scale:UIScreen.mainScreen.scale];
                        }
                        
                        if ( assetText ) {
                                [fileManager removeItemAtURL:[Util pathForText:item.identifier] error:nil];
                                [fileManager copyItemAtURL:assetText.fileURL toURL:[Util pathForText:item.identifier] error:nil];
                                
                                item.string = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:assetText.fileURL]];
                        }
                        
                        [fetchedTextItems addObject:item];
                }
                
                for ( TextItem *item in fetchedTextItems ) {
                        FMResultSet *resultSet;
                        NSString *coordinates;
                        BOOL exists;
                        
                        if ( item.coordinates )
                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                        
                        exists    = NO;
                        resultSet = [db executeQuery:@"SELECT ID FROM TEXT_ITEM WHERE ID = ?", item.identifier];
                        
                        while ( [resultSet next] ) { // Already exists; update.
                                exists = YES;
                                
                                [db executeUpdate:@"UPDATE TEXT_ITEM SET ID = ?, COLLECTION = ?, BACKED_UP = 1, COORDINATES = ?, LOCATION = ?, CREATED = ?, MODIFIED = ?, MOVED = ? WHERE ID = ? AND DATETIME(MODIFIED) < DATETIME(?)",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.modified,
                                 item.moved,
                                 item.identifier,
                                 item.modified];
                        }
                        
                        if ( !exists ) {
                                [db executeUpdate:@"INSERT INTO TEXT_ITEM(ID, COLLECTION, BACKED_UP, COORDINATES, LOCATION, CREATED, MODIFIED, MOVED) VALUES(?, ?, 1, ?, ?, ?, ?, ?)",
                                 item.identifier,
                                 item.collectionIdentifier,
                                 coordinates,
                                 item.location,
                                 item.created,
                                 item.modified,
                                 item.moved];
                        }
                }
                
                didRestoreTextItems = YES;
                
                [self doneRestoring];
        }];
}

/**
 * @attention Callback is on the main thread!
 */
- (void)syncCompletion:(void (^)(BOOL done, NSMutableArray *fetchedCollections, NSMutableArray *fetchedItems))completion
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                didRestoreCollections    = NO;
                didRestoreLinkItems      = NO;
                didRestoreLocationItems  = NO;
                didRestoreMediaItems     = NO;
                didRestoreTextItems      = NO;
                restoreCompletionHandler = completion;
                restoreError             = nil;
                
                [fetchedCollections removeAllObjects];
                [fetchedLinkItems removeAllObjects];
                [fetchedLocationItems removeAllObjects];
                [fetchedMediaItems removeAllObjects];
                [fetchedTextItems removeAllObjects];
                
                if ( ubiquityStatus == -1 ) {
                        [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error){
                                if ( error )
                                        NSLog(@"%@", error);
                                
                                if ( accountStatus == CKAccountStatusAvailable ) {
                                        ubiquityStatus = 1;
                                        
                                        [self ubiquityAvailable];
                                } else {
                                        ubiquityStatus = 0;
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                completion(YES, fetchedCollections, [NSMutableArray array]); // iCloud unavailable.
                                        });
                                }
                                
                                [NSNotificationCenter.defaultCenter addObserverForName:CKAccountChangedNotification
                                                                                object:nil
                                                                                 queue:[NSOperationQueue currentQueue]
                                                                            usingBlock:^(NSNotification *notification){
                                                                                    NSLog(@"Ubiquity status changed!");
                                                                                      
                                                                                    ubiquityStatus = -1;
                                                                            }];
                        }];
                } else {
                        if ( ubiquityStatus == 1 ) {
                                [self ubiquityAvailable];
                        } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                        completion(YES, fetchedCollections, [NSMutableArray array]); // iCloud unavailable.
                                });
                        }
                }
        });
}

- (void)ubiquityAvailable
{
        if ( ubiquityStatus == 1 ) {
                // We pull after 5 minutes or more.
                NSDate *lastSyncDate;
                
                lastSyncDate = [NSUserDefaults.standardUserDefaults objectForKey:NSUDKEY_LAST_SYNC_DATE];
                
                if ( lastSyncDate ) {
                        int seconds = -(int)[lastSyncDate timeIntervalSinceNow];
                        int minutes = seconds / 60;
                        
                        if ( minutes >= 5 ) // Sync after at least 5 minutes.
                                [self fetchAllCollectionsWithCursor:nil];
                } else { // Never synced before; attempt sync.
                        [self fetchAllCollectionsWithCursor:nil];
                }
                
                [self flushPending]; // Updates are pushed immediately.
        }
}

- (void)updateCollection:(Collection *)collection
{
        if ( collection ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                FMResultSet *resultSet;
                                BOOL exists;
                                
                                exists    = NO;
                                resultSet = [db executeQuery:@"SELECT ID FROM COLLECTION WHERE ID = ?", collection.identifier];
                                
                                while ( [resultSet next] ) // Already exists; update.
                                        exists = YES;
                                
                                if ( exists ) {
                                        if ( ubiquityStatus == 1 ) {
                                                CKModifyRecordsOperation *op;
                                                CKRecord *record;
                                                CKRecordID *recordID;
                                                
                                                recordID  = [[CKRecordID alloc] initWithRecordName:collection.identifier];
                                                
                                                record              = [[CKRecord alloc] initWithRecordType:@"Collection" recordID:recordID];
                                                record[@"created"]  = collection.created;
                                                record[@"modified"] = collection.modified;
                                                record[@"position"] = [NSNumber numberWithInteger:collection.index];
                                                record[@"title"]    = collection.title;
                                                
                                                [db executeUpdate:@"UPDATE COLLECTION SET BACKED_UP = 0, POSITION = ?, TITLE = ?, MODIFIED = ? WHERE ID = ?",
                                                 [NSNumber numberWithInteger:collection.index],
                                                 collection.title,
                                                 collection.modified,
                                                 collection.identifier];
                                                
                                                op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                        if ( operationError ) {
                                                                NSLog(@"%@", operationError);
                                                                
                                                                if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                        
                                                                }
                                                        } else {
                                                                [db executeUpdate:@"UPDATE COLLECTION SET BACKED_UP = 1 WHERE ID = ?",
                                                                 collection.identifier];
                                                        }
                                                };
                                                op.savePolicy = CKRecordSaveAllKeys;
                                                
                                                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                        } else { // No iCloud; update directly.
                                                [db executeUpdate:@"UPDATE COLLECTION SET BACKED_UP = 0, POSITION = ?, TITLE = ?, MODIFIED = ? WHERE ID = ?",
                                                 [NSNumber numberWithInteger:collection.index],
                                                 collection.title,
                                                 collection.modified,
                                                 collection.identifier];
                                        }
                                }
                        }];
                });
        }
}

- (void)updateLinkItem:(LinkItem *)item inCollection:(Collection *)collection
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                FMResultSet *resultSet;
                                BOOL exists;
                                
                                exists    = NO;
                                resultSet = [db executeQuery:@"SELECT ID FROM LINK_ITEM WHERE ID = ?", item.identifier];
                                
                                while ( [resultSet next] ) // Already exists; update.
                                        exists = YES;
                                
                                if ( exists ) {
                                        NSString *coordinates;
                                        
                                        [self updateLinkSnapshot:item];
                                        
                                        if ( item.coordinates )
                                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                        
                                        if ( ubiquityStatus == 1 ) {
                                                CKModifyRecordsOperation *op;
                                                CKRecord *record;
                                                CKRecordID *recordID;
                                                
                                                recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                                
                                                record                          = [[CKRecord alloc] initWithRecordType:@"LinkItem" recordID:recordID];
                                                record[@"collectionIdentifier"] = item.collectionIdentifier;
                                                record[@"coordinates"]          = item.coordinates;
                                                record[@"created"]              = item.created;
                                                record[@"location"]             = item.location;
                                                record[@"moved"]                = item.moved;
                                                record[@"title"]                = item.title;
                                                record[@"URL"]                  = item.URL.absoluteString;
                                                
                                                [db executeUpdate:@"UPDATE LINK_ITEM SET COLLECTION = ?, BACKED_UP = 0, TITLE = ?, URL = ?, COORDINATES = ?, LOCATION = ?, MOVED = ? WHERE ID = ?",
                                                 item.collectionIdentifier,
                                                 item.title,
                                                 item.URL.absoluteString,
                                                 coordinates,
                                                 item.location,
                                                 item.moved,
                                                 item.identifier];
                                                
                                                op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                        if ( operationError ) {
                                                                NSLog(@"%@", operationError);
                                                                
                                                                if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                        
                                                                }
                                                        } else {
                                                                [db executeUpdate:@"UPDATE LINK_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                                 item.identifier];
                                                        }
                                                };
                                                op.savePolicy = CKRecordSaveAllKeys;
                                                
                                                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                                
                                                if ( collection )
                                                        [self updateCollection:collection];
                                        } else { // No iCloud; update directly.
                                                [db executeUpdate:@"UPDATE LINK_ITEM SET COLLECTION = ?, BACKED_UP = 0, TITLE = ?, URL = ?, COORDINATES = ?, LOCATION = ?, MOVED = ? WHERE ID = ?",
                                                 item.collectionIdentifier,
                                                 item.title,
                                                 item.URL.absoluteString,
                                                 coordinates,
                                                 item.location,
                                                 item.moved,
                                                 item.identifier];
                                                
                                                if ( collection )
                                                        [self updateCollection:collection];
                                        }
                                }
                        }];
                });
        }
}

- (void)updateLinkSnapshot:(LinkItem *)item
{
        if ( item ) {
                NSData *dataSnapshot;
                NSError *error;
                
                dataSnapshot = UIImageJPEGRepresentation(item.snapshot, 1.0);
                
                if ( dataSnapshot )
                        if ( ![dataSnapshot writeToURL:[Util pathForSnapshot:item.identifier] options:NSDataWritingAtomic error:&error] )
                                NSLog(@"%@", error);
        }
}

- (void)updateLocationItem:(LocationItem *)item inCollection:(Collection *)collection
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                FMResultSet *resultSet;
                                BOOL exists;
                                
                                exists    = NO;
                                resultSet = [db executeQuery:@"SELECT ID FROM LOCATION_ITEM WHERE ID = ?", item.identifier];
                                
                                while ( [resultSet next] ) // Already exists; update.
                                        exists = YES;
                                
                                if ( exists ) {
                                        NSString *coordinates;
                                        
                                        if ( item.coordinates )
                                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                        
                                        if ( ubiquityStatus == 1 ) {
                                                CKModifyRecordsOperation *op;
                                                CKRecord *record;
                                                CKRecordID *recordID;
                                                
                                                recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                                
                                                record                          = [[CKRecord alloc] initWithRecordType:@"LocationItem" recordID:recordID];
                                                record[@"collectionIdentifier"] = item.collectionIdentifier;
                                                record[@"coordinates"]          = item.coordinates;
                                                record[@"created"]              = item.created;
                                                record[@"location"]             = item.location;
                                                record[@"moved"]                = item.moved;
                                                
                                                [db executeUpdate:@"UPDATE LOCATION_ITEM SET COLLECTION = ?, BACKED_UP = 0, COORDINATES = ?, LOCATION = ?, MOVED = ? WHERE ID = ?",
                                                 item.collectionIdentifier,
                                                 coordinates,
                                                 item.location,
                                                 item.moved,
                                                 item.identifier];
                                                
                                                op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                        if ( operationError ) {
                                                                NSLog(@"%@", operationError);
                                                                
                                                                if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                        
                                                                }
                                                        } else {
                                                                [db executeUpdate:@"UPDATE LOCATION_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                                 item.identifier];
                                                        }
                                                };
                                                op.savePolicy = CKRecordSaveAllKeys;
                                                
                                                [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                                
                                                if ( collection )
                                                        [self updateCollection:collection];
                                        } else { // No iCloud; update directly.
                                                [db executeUpdate:@"UPDATE LOCATION_ITEM SET COLLECTION = ?, BACKED_UP = 0, COORDINATES = ?, LOCATION = ?, MOVED = ? WHERE ID = ?",
                                                 item.collectionIdentifier,
                                                 coordinates,
                                                 item.location,
                                                 item.moved,
                                                 item.identifier];
                                                
                                                if ( collection )
                                                        [self updateCollection:collection];
                                        }
                                }
                        }];
                });
        }
}

- (void)updateMediaItem:(MediaItem *)item inCollection:(Collection *)collection
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                FMResultSet *resultSet;
                                BOOL exists;
                                
                                exists    = NO;
                                resultSet = [db executeQuery:@"SELECT ID FROM MEDIA_ITEM WHERE ID = ?", item.identifier];
                                
                                while ( [resultSet next] ) // Already exists; update.
                                        exists = YES;
                                
                                if ( exists ) {
                                        /*
                                         * In the case of media updates, the media attachment
                                         * itself is never edited, so there's no need to
                                         * waste bandwidth re-uploading it every time.
                                         */
                                        NSData *dataCaption;
                                        NSData *dataInk;
                                        NSError *error;
                                        NSString *captionAnchorPoint;
                                        NSString *captionBounds;
                                        NSString *captionCenter;
                                        NSString *captionTransform;
                                        NSString *coordinates;
                                        NSURL *pathCaption;
                                        NSURL *pathInk;
                                        
                                        captionAnchorPoint = NSStringFromCGPoint(item.captionView.layer.anchorPoint);
                                        captionBounds      = NSStringFromCGRect(item.captionView.bounds);
                                        captionCenter      = NSStringFromCGPoint(item.captionView.center);
                                        captionTransform   = NSStringFromCGAffineTransform(item.captionView.transform);
                                        coordinates        = @"";
                                        dataCaption        = [NSKeyedArchiver archivedDataWithRootObject:(item.captionView.attributedText)];
                                        dataInk            = UIImagePNGRepresentation(item.ink);
                                        pathCaption        = [Util pathForText:item.identifier];
                                        pathInk            = [Util pathForInk:item.identifier];
                                        
                                        if ( item.coordinates )
                                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                        
                                        if ( dataCaption )
                                                if ( ![dataCaption writeToURL:pathCaption options:NSDataWritingAtomic error:&error] )
                                                        NSLog(@"%@", error);
                                        
                                        if ( dataInk )
                                                if ( ![dataInk writeToURL:pathInk options:NSDataWritingAtomic error:&error] )
                                                        NSLog(@"%@", error);
                                        
                                        if ( !error ) {
                                                if ( ubiquityStatus == 1 ) {
                                                        CKAsset *assetCaption;
                                                        CKAsset *assetInk;
                                                        CKModifyRecordsOperation *op;
                                                        CKRecord *record;
                                                        CKRecordID *recordID;
                                                        
                                                        recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                                        
                                                        record                          = [[CKRecord alloc] initWithRecordType:@"MediaItem" recordID:recordID];
                                                        record[@"captionAnchorPoint"]   = captionAnchorPoint;
                                                        record[@"captionBounds"]        = captionBounds;
                                                        record[@"captionCenter"]        = captionCenter;
                                                        record[@"captionTransform"]     = captionTransform;
                                                        record[@"collectionIdentifier"] = item.collectionIdentifier;
                                                        record[@"coordinates"]          = item.coordinates;
                                                        record[@"created"]              = item.created;
                                                        record[@"location"]             = item.location;
                                                        record[@"modified"]             = item.modified;
                                                        record[@"moved"]                = item.moved;
                                                        record[@"type"]                 = [NSNumber numberWithInt:item.itemType];
                                                        
                                                        if ( dataCaption ) {
                                                                assetCaption       = [[CKAsset alloc] initWithFileURL:pathCaption];
                                                                record[@"caption"] = assetCaption;
                                                        }
                                                        
                                                        if ( dataInk ) {
                                                                assetInk       = [[CKAsset alloc] initWithFileURL:pathInk];
                                                                record[@"ink"] = assetInk;
                                                        }
                                                        
                                                        [db executeUpdate:@"UPDATE MEDIA_ITEM SET COLLECTION = ?, BACKED_UP = 0, TYPE = ?, CAPTION_ANCHOR_POINT = ?, CAPTION_BOUNDS = ?, CAPTION_CENTER = ?, CAPTION_TRANSFORM = ?, COORDINATES = ?, LOCATION = ?, MODIFIED = ?, MOVED = ? WHERE ID = ?",
                                                         item.collectionIdentifier,
                                                         [NSNumber numberWithInt:item.itemType],
                                                         captionAnchorPoint,
                                                         captionBounds,
                                                         captionCenter,
                                                         captionTransform,
                                                         coordinates,
                                                         item.location,
                                                         item.modified,
                                                         item.moved,
                                                         item.identifier];
                                                        
                                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                                if ( operationError ) {
                                                                        NSLog(@"%@", operationError);
                                                                        
                                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                                
                                                                        }
                                                                } else {
                                                                        [db executeUpdate:@"UPDATE MEDIA_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                                         item.identifier];
                                                                }
                                                        };
                                                        op.savePolicy = CKRecordSaveAllKeys;
                                                        
                                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                                        
                                                        if ( collection )
                                                                [self updateCollection:collection];
                                                } else { // No iCloud; update directly.
                                                        [db executeUpdate:@"UPDATE MEDIA_ITEM SET COLLECTION = ?, BACKED_UP = 0, TYPE = ?, CAPTION_ANCHOR_POINT = ?, CAPTION_BOUNDS = ?, CAPTION_CENTER = ?, CAPTION_TRANSFORM = ?, COORDINATES = ?, LOCATION = ?, MODIFIED = ?, MOVED = ? WHERE ID = ?",
                                                         item.collectionIdentifier,
                                                         [NSNumber numberWithInt:item.itemType],
                                                         captionAnchorPoint,
                                                         captionBounds,
                                                         captionCenter,
                                                         captionTransform,
                                                         coordinates,
                                                         item.location,
                                                         item.modified,
                                                         item.moved,
                                                         item.identifier];
                                                        
                                                        if ( collection )
                                                                [self updateCollection:collection];
                                                }
                                        }
                                }
                        }];
                });
        }
}

/**
 * This method is intended for videos.
 */
- (void)updateMediaThumbnail:(MediaItem *)item
{
        if ( item &&
             item.itemType == ItemTypeMovie ) {
                AVAsset *asset;
                NSData *dataThumbnail;
                NSError *error;
                NSURL *path;
                CMTime time;
                CMTime timeMidFrame;
                NSInteger midFrame;
                
                path  = [Util pathForMedia:item.identifier extension:@"mov"];
                asset = [AVAsset assetWithURL:path];
                time  = asset.duration;
                
                midFrame  = (NSInteger)((time.value / 2) / 1000);
                midFrame *= 1000;
                
                timeMidFrame = CMTimeMake(midFrame, asset.duration.timescale);
                
                item.image = [Util thumbnailForVideo:path atTime:timeMidFrame.value]; // Get a thumbnail from the middle of the video.
                
                dataThumbnail = UIImageJPEGRepresentation(item.image, 1.0);
                
                if ( dataThumbnail )
                        if ( ![dataThumbnail writeToURL:[Util pathForMedia:item.identifier extension:@"jpg"] options:NSDataWritingAtomic error:&error] )
                                NSLog(@"%@", error);
        }
}

- (void)updateTextItem:(TextItem *)item inCollection:(Collection *)collection
{
        if ( item ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                FMResultSet *resultSet;
                                BOOL exists;
                                
                                exists    = NO;
                                resultSet = [db executeQuery:@"SELECT ID FROM TEXT_ITEM WHERE ID = ?", item.identifier];
                                
                                while ( [resultSet next] ) // Already exists; update.
                                        exists = YES;
                                
                                if ( exists ) {
                                        NSData *dataInk;
                                        NSData *dataText;
                                        NSError *error;
                                        NSString *coordinates;
                                        NSURL *pathInk;
                                        NSURL *pathText;
                                        
                                        coordinates = @"";
                                        dataInk     = UIImagePNGRepresentation(item.ink);
                                        dataText    = [NSKeyedArchiver archivedDataWithRootObject:item.string];
                                        pathInk     = [Util pathForInk:item.identifier];
                                        pathText    = [Util pathForText:item.identifier];
                                        
                                        if ( item.coordinates )
                                                coordinates = [NSString stringWithFormat:@"%f,%f", item.coordinates.coordinate.latitude, item.coordinates.coordinate.longitude];
                                        
                                        if ( dataInk )
                                                if ( ![dataInk writeToURL:pathInk options:NSDataWritingAtomic error:&error] )
                                                        NSLog(@"%@", error);
                                        
                                        if ( dataText )
                                                if ( ![dataText writeToURL:pathText options:NSDataWritingAtomic error:&error] )
                                                        NSLog(@"%@", error);
                                        
                                        if ( !error ) {
                                                if ( ubiquityStatus == 1 ) {
                                                        CKAsset *assetInk;
                                                        CKAsset *assetText;
                                                        CKModifyRecordsOperation *op;
                                                        CKRecord *record;
                                                        CKRecordID *recordID;
                                                        
                                                        recordID = [[CKRecordID alloc] initWithRecordName:item.identifier];
                                                        
                                                        record                          = [[CKRecord alloc] initWithRecordType:@"TextItem" recordID:recordID];
                                                        record[@"collectionIdentifier"] = item.collectionIdentifier;
                                                        record[@"coordinates"]          = item.coordinates;
                                                        record[@"created"]              = item.created;
                                                        record[@"location"]             = item.location;
                                                        record[@"modified"]             = item.modified;
                                                        record[@"moved"]                = item.moved;
                                                        
                                                        if ( dataInk ) {
                                                                assetInk       = [[CKAsset alloc] initWithFileURL:pathInk];
                                                                record[@"ink"] = assetInk;
                                                        }
                                                        
                                                        if ( dataText ) {
                                                                assetText       = [[CKAsset alloc] initWithFileURL:pathText];
                                                                record[@"data"] = assetText;
                                                        }
                                                        
                                                        [db executeUpdate:@"UPDATE TEXT_ITEM SET COLLECTION = ?, BACKED_UP = 0, COORDINATES = ?, LOCATION = ?, MODIFIED = ?, MOVED = ? WHERE ID = ?",
                                                         item.collectionIdentifier,
                                                         coordinates,
                                                         item.location,
                                                         item.modified,
                                                         item.moved,
                                                         item.identifier];
                                                        
                                                        op                              = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
                                                        op.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                                                                if ( operationError ) {
                                                                        NSLog(@"%@", operationError);
                                                                        
                                                                        if ( operationError.code == CKErrorNetworkUnavailable ) { // Handle.
                                                                                
                                                                        }
                                                                } else {
                                                                        [db executeUpdate:@"UPDATE TEXT_ITEM SET BACKED_UP = 1 WHERE ID = ?",
                                                                         item.identifier];
                                                                }
                                                        };
                                                        op.savePolicy = CKRecordSaveAllKeys;
                                                        
                                                        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:op];
                                                        
                                                        if ( collection )
                                                                [self updateCollection:collection];
                                                } else { // No iCloud; update directly.
                                                        [db executeUpdate:@"UPDATE TEXT_ITEM SET COLLECTION = ?, BACKED_UP = 0, COORDINATES = ?, LOCATION = ?, MODIFIED = ?, MOVED = ? WHERE ID = ?",
                                                         item.collectionIdentifier,
                                                         coordinates,
                                                         item.location,
                                                         item.modified,
                                                         item.moved,
                                                         item.identifier];
                                                        
                                                        if ( collection )
                                                                [self updateCollection:collection];
                                                }
                                        }
                                }
                        }];
                });
        }
}


@end
