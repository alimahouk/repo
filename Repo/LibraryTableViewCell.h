//
//  LibraryTableViewCell.h
//  Repo
//
//  Created by Ali Mahouk on 18/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

@interface IndexedCollectionView : UICollectionView

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) UILabel *emptyCollectionLabel;

@end

@interface LibraryTableViewCell : UITableViewCell

@property (nonatomic, strong) IndexedCollectionView *collectionView;

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath;

@end
