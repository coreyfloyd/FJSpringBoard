//
//  FJSpringBoardHorizontalLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardHorizontalLayout.h"



@interface FJSpringBoardLayout()

@property (nonatomic) NSInteger rowsPerPage;
@property (nonatomic) NSInteger cellsPerPage;
@property(nonatomic) CGSize pageSize;
@property(nonatomic) CGSize pageSizeWithInsetsApplied;

- (NSInteger)_numberOfVisibleRows;
- (NSInteger)_numberOfCellsPerRow;
- (NSInteger)_numberOfVisibleRowsWithPartials;

- (CGPoint)_originForCellAtPosition:(CellPosition)position;
- (CGRect)_frameForCellAtPosition:(CellPosition)position;

- (CellPosition)_positionForCellAtIndex:(NSInteger)index;
- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position;

- (CGFloat)_horizontalOffsetForPage:(NSInteger)page;
- (NSInteger)_pageForCellAtPosition:(CellPosition)position;

- (void)_calculateAdjustedValues;
- (CGRect)_boundsWithInsetsApplied;
- (CGSize)_sizeOfCellWithPaddingApplied;


@end


@implementation FJSpringBoardHorizontalLayout

@synthesize rowsPerPage;
@synthesize cellsPerPage;
@synthesize pageSize;
@synthesize pageSizeWithInsetsApplied;

- (void)reset{
    
    [super reset];
    self.cellsPerPage = 0;
    self.rowsPerPage = 0;
    self.pageSize = CGSizeZero;
    self.pageSizeWithInsetsApplied = CGSizeZero;
    
}


- (void)updateLayoutWithCellCount:(NSInteger)count{
    
    [super updateLayoutWithCellCount:count];
       
    self.pageSize = [self _pageSize];
    self.pageSizeWithInsetsApplied = [self _pageSizeWithInsetsApplied]
    
        
}



- (CGRect)_pageSize{
    
    CGSize size = self.springBoardbounds.size;
    
    return size;

    
}


- (CGRect)_pageSizeWithInsetsApplied{
    
    CGRect viewRect = self.springBoardbounds;
    
    viewRect = UIEdgeInsetsInsetRect(viewRect, self.insets);
    
    CGSize size = self.viewRect.size;
    
    return size;
    
}




- (NSInteger)_rowsPerPage{
    
    if(self.layoutDirection = FJSpringBoardLayoutDirectionVertical)
        return self.numberOfRows;
    
}

- (NSInteger)_cellsPerPage{
    
    if(self.layoutDirection = FJSpringBoardLayoutDirectionVertical)
        return self.cellCount;
    
    
}



- (CGSize)_contentSize{
    
    CGFloat pageHeight = (self.numberOfRows * self.cellSize.height) + (self.numberOfRows-1 * self.verticalCellSpacing) + self.insets.top + self.insets.bottom;

    
}


- (CellPosition)_positionForCellAtIndex:(NSInteger)index{
    
    CellPosition pos;
    pos.page = 0;
    
    float row = (float)((float)index / (float)self.cellsPerRow);
    
    row = floorf(row);
    
    pos.row = (NSInteger)row;
    
    int column = index % self.cellsPerRow;
    
    pos.column = (NSInteger)column;
    
    pos = [self _pageAdjustedCellPosition:pos];
    
    return pos;
    
}


- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position{
    
    if(self.layoutDirection == FJSpringBoardLayoutDirectionVertical)
        return position;
    
    NSInteger page = [self _pageForCellAtPosition:position];
    position.page = page;
    
    NSInteger row = position.row;
    
    row = row - (page * [self _numberOfVisibleRows]);
    
    position.row = row;
    
    return position;
    
}


- (NSInteger)_pageForCellAtPosition:(CellPosition)position{
    
    if(self.layoutDirection == FJSpringBoardLayoutDirectionVertical)
        return 0;
    
    NSInteger index  = [self _indexForPositon:position];
    
    float p = floorf((float)((float)index / (float)[self numberOfVisibleCells]));
    
    NSInteger page = (NSInteger)p;
    
    return page;
}



- (CGRect)pageRelativeFrameForCellAtIndex:(NSInteger)index{
    
    
}


@end
