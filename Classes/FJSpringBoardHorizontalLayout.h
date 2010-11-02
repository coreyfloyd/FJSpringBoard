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

- (NSUInteger)nextPageWithPreviousContentOffset:(CGPoint)previousOffset currentContentOffset:(CGPoint)currentOffset; //returns next logical page

- (NSUInteger)previousPageWithPreviousContentOffset:(CGPoint)previousOffset currentContentOffset:(CGPoint)currentOffset; //returns last logical page

- (NSUInteger)removalPageWithPreviousContentOffset:(CGPoint)previousOffset currentContentOffset:(CGPoint)currentOffset; //returns page which should be unloaded. returns NSUIntegerMax if no pages should be removed


- (NSIndexSet*)cellIndexesForPage:(NSUInteger)page;

- (CGRect)frameForPage:(NSUInteger)page;

@end
