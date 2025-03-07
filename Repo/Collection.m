//
//  Collection.m
//  Repo
//
//  Created by Ali Mahouk on 18/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "Collection.h"

@implementation Collection


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                _created    = [NSDate date];
                i_items     = [NSMutableArray array];
                _identifier = [NSUUID UUID].UUIDString;
                _index      = -1;
                _modified   = [NSDate date];
        }
        
        return self;
}

- (BOOL)isEqual:(id)object
{
        Collection *collection;
        
        if ( object &&
             [object isKindOfClass:Collection.class] ) {
                collection = (Collection *)object;
                
                if ( collection.identifier == _identifier )
                        return YES;
        }
        
        return NO;
}

- (NSArray *)items
{
        return i_items;
}

/**
 * This method alters the modified timestamp
 * of the collection. If you're setting the
 * initial items after intializing the
 * collection, set the items array to your list
 * instead of calling this method repeatedly.
 */
- (void)addItem:(Item *)item
{
        _modified = [NSDate date];
        
        [i_items insertObject:item atIndex:0];
}

- (void)deleteItemAtIndex:(NSInteger)index
{
        _modified = [NSDate date];
        
        [i_items removeObjectAtIndex:index];
}

- (void)setItems:(NSArray *)entries
{
        i_items = [entries mutableCopy];
}


@end
