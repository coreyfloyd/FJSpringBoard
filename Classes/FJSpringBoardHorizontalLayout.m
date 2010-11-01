//
//  FJSpringBoardHorizontalLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardUtilities.h"



@interface FJSpringBoardLayout(horizontalInternal)

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property (nonatomic) CGFloat minimumRowWidth;
@property (nonatomic) CGFloat maximumRowWidth;

@property(nonatomic, readwrite) CGSize contentSize;

- (NSUInteger)_indexForPositon:(CellPosition)position;

@end

@interface FJSpringBoardLayout()

@property (nonatomic) NSUInteger rowsPerPage;
@property (nonatomic) NSUInteger cellsPerPage;
@property(nonatomic) CGSize pageSize;
@property(nonatomic) CGSize pageSizeWithInsetsApplied;


- (CGPoint)_originForCellAtPosition:(CellPosition)position;

- (CellPosition)_positionForCellAtIndex:(NSUInteger)index;
- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position;

- (CGFloat)_horizontalOffsetForPage:(NSUInteger)page;
- (NSUInteger)_pageForCellAtPosition:(CellPosition)position;

- (void)_calculateAdjustedValues;
- (CGRect)_boundsWithInsetsApplied;
- (CGSize)_sizeOfCellWithPaddingApplied;

- (NSUInteger)_rowsPerPage;
- (CGSize)_pageSizeWithInsetsApplied;
- (CGSize)_pageSize;
- (NSUInteger)_numberOfPages;

- (CGSize)_contentSize;
@end


@implementation FJSpringBoardHorizontalLayout

@synthesize rowsPerPage;
@synthesize cellsPerPage;
@synthesize pageSize;
@synthesize pageSizeWithInsetsApplied;
@synthesize pageCount;


- (void)reset{
    
    [super reset];
    self.cellsPerPage = 0;
    self.rowsPerPage = 0;
    self.pageSize = CGSizeZero;
    self.pageSizeWithInsetsApplied = CGSizeZero;
    
}


- (void)updateLayout{
     
    [super updateLayout];

    self.pageSize = [self _pageSize];
    self.pageSizeWithInsetsApplied = [self _pageSizeWithInsetsApplied];
    
    self.rowsPerPage = [self _rowsPerPage];
    self.pageCount = [self _numberOfPages];
        
    self.contentSize = [self _contentSize];

}



- (CGSize)_pageSize{
    
    CGSize size = self.springBoardbounds.size;
    
    return size;

    
}


- (CGSize)_pageSizeWithInsetsApplied{
    
    CGRect viewRect = self.springBoardbounds;
    
    viewRect = UIEdgeInsetsInsetRect(viewRect, self.insets);
    
    CGSize size = viewRect.size;
    
    return size;
    
}


- (NSUInteger)_rowsPerPage{
    
    float totalHeight = self.pageSizeWithInsetsApplied.height;
    float cellHeight = self.cellSize.height;
    
    float count = 0;
    float totalCellHeight = 0;
    
    while (totalCellHeight < totalHeight) {
        
        totalCellHeight += cellHeight;
        count ++;
        
        if(totalCellHeight >= totalHeight)
            break;
        
        totalCellHeight += self.verticalCellSpacing;
    }
    
    return (NSUInteger)count;
    
}

- (NSUInteger)_cellsPerPage{
    
    return (self.rowsPerPage * self.cellsPerRow);
        
}



- (CGSize)_contentSize{
    
    CGFloat pageHeight = self.springBoardbounds.size.height;
    
    CGFloat width = self.pageCount * self.springBoardbounds.size.width;
    CGSize s = CGSizeMake(width, pageHeight);
    return s;
    
}



- (CGPoint)_originForCellAtPosition:(CellPosition)position{
    
    CGPoint origin = CGPointZero;
    
    NSUInteger page = [self _pageForCellAtPosition:position];
    
    CellPosition adjustedPosition = [self _pageAdjustedCellPosition:position];
    
    NSUInteger column = adjustedPosition.column;
    NSUInteger row = adjustedPosition.row;
    
    CGFloat x = self.insets.left + ((float)column * self.horizontalCellSpacing) + ((float)column * self.cellSize.width) + ((float)page * self.pageSize.width);
    CGFloat y = self.insets.top + ((float)row * self.verticalCellSpacing) + ((float)row * self.cellSize.height); 
    
    if(self.centerCellsInView){
        
        float leftover = self.maximumRowWidth - self.minimumRowWidth;
        float leftOffset = leftover / 2; 
        x += leftOffset;
    }
    
    origin.x = x;
    origin.y = y;
    
    return origin;
}


- (NSUInteger)_pageForCellAtPosition:(CellPosition)position{
    
    NSUInteger index = [self _indexForPositon:position];
    
    float p = floorf((float)((float)index / (float)self.cellsPerPage));
    
    NSUInteger page = (NSUInteger)p;
    
    return page;
}



- (NSUInteger)_numberOfPages{
            
    return ceilf((float)((float)self.cellCount / (float)self.cellsPerPage));
    
}


- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position{
    
    NSUInteger index = [self _indexForPositon:position];

    NSUInteger page = [self _pageForCellAtPosition:position];

    NSUInteger numberOfCellsBeforePage = 0;
    
    if(page > 0){
        numberOfCellsBeforePage = self.cellsPerPage * (page);
    }
    
    NSUInteger adjustedIndex = index - numberOfCellsBeforePage;
    
    CellPosition adjustedPosition = [self _positionForCellAtIndex:adjustedIndex];
    
    return adjustedPosition;
    
}



- (NSUInteger)pageForContentOffset:(CGPoint)offset{
        
    NSUInteger pageSizeInt = (NSUInteger)self.pageSize.width;
    
    NSUInteger offsetInt = (NSUInteger)offset.x;

    if(offsetInt % pageSizeInt != 0)
        return -1;
    
    return (offsetInt / pageSizeInt);
    
}



- (CGRect)frameForPage:(NSUInteger)page{
    
    CGRect f = CGRectZero;
    f.size = self.pageSize;
    f.origin = CGPointMake([self _horizontalOffsetForPage:page], 0); 
    
    return f;
    
}


- (CGFloat)_horizontalOffsetForPage:(NSUInteger)page{
    
    return springBoardbounds.size.width * (float)page;
    
}

- (NSIndexSet*)cellIndexesForPage:(NSUInteger)page{
        
    NSUInteger numberOfCellsBeforePage = 0;
    NSUInteger firstIndex = 0;
    
    if(page > 0){
        numberOfCellsBeforePage = self.cellsPerPage * (page);
        firstIndex += numberOfCellsBeforePage;
    }
    
    NSRange cellRange = NSMakeRange(firstIndex, self.cellsPerPage);

    NSIndexSet* cellIndexes = [NSIndexSet indexSetWithIndexesInRange:cellRange];
    
    return cellIndexes;
}



@end
