//
//  Collection.h
//  Repo
//
//  Created by Ali Mahouk on 18/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import Foundation;

@class Item;

@interface Collection : NSObject
{
        NSMutableArray *i_items;
}

@property (nonatomic) NSArray<Item *> *items;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSDate *modified;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *title;
@property (nonatomic) NSInteger index;

- (void)addItem:(Item *)item;
- (void)deleteItemAtIndex:(NSInteger)index;

@end
