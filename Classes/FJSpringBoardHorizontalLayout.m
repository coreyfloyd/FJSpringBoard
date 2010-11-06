//
//  FJSpringBoardHorizontalLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardUtilities.h"

#define NUMBER_OF_PAGES_TO_PAD 1



@interface FJSpringBoardLayout(horizontalInternal)

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property (nonatomic) CGFloat minimumRowWidth;
@property (nonatomic) CGFloat maximumRowWidth;

@property(nonatomic, readwrite) CGSize contentSize;

- (NSUInteger)_indexForPositon:(CellPosition)position;
- (CellPosition)_positionForCellAtIndex:(NSUInteger)index;

@end

@interface FJSpringBoardHorizontalLayout()

@property (nonatomic) NSUInteger rowsPerPage;
@property (nonatomic) NSUInteger cellsPerPage;
@property(nonatomic) CGSize pageSize;
@property(nonatomic) CGSize pageSizeWithInsetsApplied;


- (CGPoint)_originForCellAtPosition:(CellPosition)position;

- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position;

- (CGFloat)_horizontalOffsetForPage:(NSUInteger)page;
- (NSUInteger)_pageForCellAtPosition:(CellPosition)position;


- (NSUInteger)_rowsPerPage;
- (CGSize)_pageSizeWithInsetsApplied;
- (CGSize)_pageSize;
- (NSUInteger)_numberOfPages;
- (NSUInteger)_cellsPerPage;

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
    self.cellsPerPage = [self _cellsPerPage];
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
        
        if(totalCellHeight >= totalHeight)
            break;

        count ++;
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
    
    //TODO: check insets for each page… hmmm
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
    
    if(index == 0)
        return 0;
    
    float p = (float)((float)(index) / (float)self.cellsPerPage);
    
    p = floorf(p);
    
    NSUInteger page = (NSUInteger)p;
    
    return page;
}



- (NSUInteger)_numberOfPages{
            
    return ceilf((float)((float)self.cellCount / (float)self.cellsPerPage));
    
}


- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position{
    
    NSUInteger index = [self _indexForPositon:position];

    NSUInteger page = [self _pageForCellAtPosition:position];
    
    if(page == 0)
        return position;

    NSUInteger numberOfCellsBeforePage = 0;
    
    if(page > 0){
        numberOfCellsBeforePage = self.cellsPerPage * (page);
    }
    
    NSUInteger adjustedIndex = index - numberOfCellsBeforePage;
    
    CellPosition adjustedPosition = [self _positionForCellAtIndex:adjustedIndex];
    
    return adjustedPosition;
    
}



- (NSUInteger)pageForContentOffset:(CGPoint)offset{
        
    float pageWidth = self.pageSize.width;
    
    float offsetX = offset.x;
    
    float val = offsetX/pageWidth;

    val = roundf(val);
    
    NSUInteger page = (NSUInteger)val;
    
    if(page > self.pageCount){
        ALWAYS_ASSERT;
    }
    
    if(page < 0){
        ALWAYS_ASSERT;
    }
    
    return page;
    
}

- (NSUInteger)nextPageWithPreviousContentOffset:(CGPoint)previousOffset currentContentOffset:(CGPoint)currentOffset{
    
    NSUInteger pageSizeInt = (NSUInteger)self.pageSize.width;
    
    float currentXOffset = currentOffset.x;
    float previousXOffset = previousOffset.x;
    
    if(abs((int)((int)currentXOffset - (int)previousXOffset)) == 0){
        
        return [self pageForContentOffset:currentOffset];
    }
    
    float nextPage;
    if((currentXOffset - previousXOffset) > 0)
        nextPage = ceilf((float)(currentXOffset / (float)pageSizeInt));
    else
        nextPage = floorf((float)(currentXOffset / (float)pageSizeInt));

    NSUInteger pageInt = (NSUInteger)nextPage;
    
    if(pageInt > self.pageCount)
        return pageInt--;
    
    if(pageInt < 0)
        return pageInt++;
    
    return pageInt;
}

- (NSUInteger)previousPageWithPreviousContentOffset:(CGPoint)previousOffset currentContentOffset:(CGPoint)currentOffset{
        
    float currentXOffset = currentOffset.x;
    float previousXOffset = previousOffset.x;
    
    if(abs((int)((int)currentXOffset - (int)previousXOffset)) == 0){
        
        return [self pageForContentOffset:currentOffset];
    }
    
    NSUInteger currentPage = [self pageForContentOffset:currentOffset];
    
    NSUInteger lastPage = 0;
    
    if((currentXOffset - previousXOffset) > 0)
        lastPage = currentPage - 1;
    else
        lastPage = currentPage + 1;
        
    if(lastPage > self.pageCount)
        return lastPage--;
    
    if(lastPage < 0)
        return lastPage++;
    
    return lastPage;
    
}

- (NSUInteger)removalPageWithPreviousContentOffset:(CGPoint)previousOffset currentContentOffset:(CGPoint)currentOffset{
    
        
    float currentXOffset = currentOffset.x;
    float previousXOffset = previousOffset.x;
    
    if(abs((int)((int)currentXOffset - (int)previousXOffset)) == 0){
        
        return NSUIntegerMax;
    }
    
    NSUInteger currentPage = [self pageForContentOffset:currentOffset];
    
    NSUInteger lastPage = 0;
    
    if((currentXOffset - previousXOffset) > 0)
        lastPage = currentPage - NUMBER_OF_PAGES_TO_PAD - 1;
    else
        lastPage = currentPage + NUMBER_OF_PAGES_TO_PAD + 1;
    
    if(lastPage > self.pageCount)
        return NSUIntegerMax;
    
    if(lastPage < 0)
        return NSUIntegerMax;
    
    return lastPage;
    
    
}



- (CGRect)frameForPage:(NSUInteger)page{
    
    if(page >= self.pageCount)
        return CGRectZero;

    CGRect f = CGRectZero;
    f.size = self.pageSize;
    f.origin =  [self offsetForPage:page];
    
    return f;
    
}

- (CGPoint)offsetForPage:(NSUInteger)page{
    
    if(page >= self.pageCount)
        return CGPointZero;

    return CGPointMake([self _horizontalOffsetForPage:page], 0);
}

- (CGFloat)_horizontalOffsetForPage:(NSUInteger)page{
    
    return springBoardbounds.size.width * (float)page;
    
}

- (NSIndexSet*)cellIndexesForPage:(NSUInteger)page{
        
    if(page >= self.pageCount)
        return nil;
    
    NSUInteger numOfCellsOnPage = self.cellsPerPage;

    NSUInteger numberOfCellsBeforePage = 0;
    NSUInteger firstIndex = 0;
    
    if(page > 0){
        numberOfCellsBeforePage = self.cellsPerPage * (page);
        firstIndex += numberOfCellsBeforePage;
    }
    
    if(firstIndex >= self.cellCount)
        return nil;

    if(page == self.pageCount-1){
        
        numOfCellsOnPage = self.cellCount - numberOfCellsBeforePage;
        
    }
    
    NSRange cellRange = NSMakeRange(firstIndex, numOfCellsOnPage);

    NSIndexSet* cellIndexes = [NSIndexSet indexSetWithIndexesInRange:cellRange];
    
    return cellIndexes;
}



@end
