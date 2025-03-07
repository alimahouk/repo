//
//  LibraryTableViewCell.m
//  Repo
//
//  Created by Ali Mahouk on 18/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "LibraryTableViewCell.h"

#import "constants.h"

@implementation IndexedCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
        self = [super initWithFrame:frame collectionViewLayout:layout];
        
        if ( self ) {
                _emptyCollectionLabel               = [[UILabel alloc] initWithFrame:self.bounds];
                _emptyCollectionLabel.font          = [UIFont systemFontOfSize:[UIFont systemFontSize]];
                _emptyCollectionLabel.hidden        = YES;
                _emptyCollectionLabel.numberOfLines = 0;
                _emptyCollectionLabel.text          = @"Drag & hold items over this area for a second, then drop them to add them to this collection.";
                _emptyCollectionLabel.textAlignment = NSTextAlignmentCenter;
                _emptyCollectionLabel.textColor     = UIColor.grayColor;
                
                [self addSubview:_emptyCollectionLabel];
        }
        
        return self;
}

@end

@implementation LibraryTableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
        self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
        
        if ( self ) {
                UICollectionViewFlowLayout *layout;
                
                self.backgroundColor = UIColor.blackColor;
                self.backgroundView  = nil;
                self.selectionStyle  = UITableViewCellSelectionStyleNone;
                
                layout                         = [[UICollectionViewFlowLayout alloc] init];
                layout.itemSize                = CGSizeMake(ITEM_PREVIEW_SIZE, ITEM_PREVIEW_SIZE);
                layout.minimumInteritemSpacing = 0.0;
                layout.minimumLineSpacing      = 0.0;
                layout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;
                layout.sectionInset            = UIEdgeInsetsZero;
                
                _collectionView                                = [[IndexedCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
                _collectionView.backgroundColor                = UIColor.clearColor;
                _collectionView.scrollsToTop                   = NO;
                _collectionView.showsHorizontalScrollIndicator = NO;
                
                [self.contentView addSubview:_collectionView];
        }
        
        return self;
}

- (void)layoutSubviews
{
        [super layoutSubviews];
        
        _collectionView.frame                      = self.contentView.bounds;
        _collectionView.emptyCollectionLabel.frame = CGRectMake(20, 0, _collectionView.bounds.size.width - 40, _collectionView.bounds.size.height);
}

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath
{
        _collectionView.dataSource = dataSourceDelegate;
        _collectionView.delegate   = dataSourceDelegate;
        _collectionView.indexPath  = indexPath;
        
        [_collectionView setContentOffset:self.collectionView.contentOffset animated:NO];
        [_collectionView reloadData];
}


@end
