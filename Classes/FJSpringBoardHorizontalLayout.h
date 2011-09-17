//
//  FJSpringBoardHorizontalLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FJSpringBoardLayout.h"

@interface FJSpringBoardHorizontalLayout : FJSpringBoardLayout {

    NSUInteger pageCount;

    NSUInteger rowsPerPage;
    NSUInteger cellsPerPage;
    
    CGSize pageSize;
    CGSize pageSizeWithInsetsApplied;
}
@property (nonatomic) NSUInteger pageCount;

- (NSUInteger)pageForContentOffset:(CGPoint)offset; //rounds

- (NSIndexSet*)cellIndexesForPage:(NSUInteger)page;

- (NSUInteger)pageForCellIndex:(NSUInteger)index;

- (CGRect)frameForPage:(NSUInteger)page;
- (CGPoint)offsetForPage:(NSUInteger)page;

@end
