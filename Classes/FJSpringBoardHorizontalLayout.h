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

- (NSUInteger)pageForContentOffset:(CGPoint)offset; //returns -1 if not a multiple of the page size

- (NSIndexSet*)cellIndexesForPage:(NSUInteger)page;

- (CGRect)frameForPage:(NSUInteger)page;

@end
