//
//  FJSpringBoardLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardLayout.h"


typedef struct {
    NSInteger page;
    NSInteger row;
    NSInteger column;
} CellPosition;





@interface FJSpringBoardLayout()

@property(nonatomic) CGRect usableBounds;
@property(nonatomic) CGSize cellSizeWithPadding;

- (NSInteger)_numberOfVisibleRows;
- (NSInteger)_numberOfCellsPerRow;


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

@implementation FJSpringBoardLayout

@synthesize gridViewInsets;
@synthesize gridViewBounds;
@synthesize cellPadding;
@synthesize cellSize;
@synthesize layoutDirection;

@synthesize usableBounds;
@synthesize cellSizeWithPadding;


#pragma mark -
#pragma mark Initialization

- (id) init
{
    self = [super init];
    if (self != nil) {
    
        [self reset];
    }
    return self;
}

- (void)reset{
    
    self.gridViewBounds = CGRectZero;
    self.gridViewInsets = UIEdgeInsetsZero;
    self.cellSize = CGSizeZero;
    self.cellPadding = CGSizeZero;
    
    self.usableBounds = CGRectZero;
    self.cellSizeWithPadding = CGSizeZero;
    self.layoutDirection = FJSpringBoardLayoutDirectionVertical;
    
}

#pragma mark -
#pragma mark Cell Count

- (NSInteger)numberOfVisibleCells{ // == number of cells per page
    
    [self _calculateAdjustedValues];
    
    NSInteger cellsPerRow = [self _numberOfCellsPerRow];
    NSInteger visibleRows = [self _numberOfVisibleRows];
    
    NSInteger count = cellsPerRow * visibleRows;
    
    return count;
    
}

- (NSInteger)_numberOfCellsPerRow{
    
    float totalWidth = self.usableBounds.size.width;
    float cellWidth = self.cellSizeWithPadding.width;
    
    float cellCount = floorf(totalWidth/cellWidth);
    
    return (NSInteger)cellCount;
    
}


- (NSInteger)_numberOfVisibleRows{
    
    float totalHeight = self.usableBounds.size.height;
    float cellHeight = self.cellSizeWithPadding.height;
    
    float cellCount = floorf(totalHeight/cellHeight);
    
    return (NSInteger)cellCount;
    
    
}


#pragma mark -
#pragma mark Adjusted Geometry

- (void)_calculateAdjustedValues{
    
    self.usableBounds = [self _boundsWithInsetsApplied];
    self.cellSizeWithPadding = [self _sizeOfCellWithPaddingApplied];
}

- (CGRect)_boundsWithInsetsApplied{
    
    return UIEdgeInsetsInsetRect(self.gridViewBounds, self.gridViewInsets);
    
}

- (CGSize)_sizeOfCellWithPaddingApplied{
    
    CGSize combinedSize = CGSizeZero;
    
    combinedSize.height = self.cellSize.height + (self.cellPadding.height * 2);
    combinedSize.width = self.cellSize.width + (self.cellPadding.width * 2);
    
    return combinedSize;
    
}

#pragma mark -
#pragma mark Frame Calculation

- (CGRect)frameForCellAtIndex:(NSInteger)index{
    
    [self _calculateAdjustedValues];
    
    CellPosition position = [self _positionForCellAtIndex:index];
    CGRect frame = [self _frameForCellAtPosition:position];
    
    return frame;
}

- (CGRect)_frameForCellAtPosition:(CellPosition)position{
    
    CGRect frame = CGRectZero;
    frame.origin = [self _originForCellAtPosition:position];
    frame.size = self.cellSize;
    
    return frame;
    
}

- (CGPoint)_originForCellAtPosition:(CellPosition)position{
    
    CGPoint origin = CGPointZero;
    
    int column = position.column;
    int row = position.row;

    CGFloat x = ([self _horizontalOffsetForPage:position.page]) + self.gridViewInsets.left + (column * self.cellSizeWithPadding.width) + self.cellPadding.width;
    CGFloat y = self.gridViewInsets.top + (row * self.cellSizeWithPadding.height) + self.cellPadding.height; 
    
    origin.x = x;
    origin.y = y;
    
    return origin;
    
}

#pragma mark -
#pragma mark Position Calculation

- (CellPosition)_positionForCellAtIndex:(NSInteger)index{
    
    CellPosition pos;
    
    NSInteger cellsPerRow = [self _numberOfCellsPerRow];
    
    float row = (float)((float)index / (float)cellsPerRow);
    
    row = floorf(row);
        
    pos.row = (NSInteger)row;
    
    int column = index % cellsPerRow;
    
    pos.column = (NSInteger)column;
    
    pos = [self _pageAdjustedCellPosition:pos];

    return pos;
    
}


- (NSInteger)_indexForPositon:(CellPosition)position{
    
    return position.row * position.column;
}


- (CellPosition)_pageAdjustedCellPosition:(CellPosition)position{
    
    if(self.layoutDirection = FJSpringBoardLayoutDirectionVertical)
        return position;
    
    NSInteger page = [self _pageForCellAtPosition:position];
    position.page = page;
    
    NSInteger row = position.row;
    
    row = row - (page * [self _numberOfVisibleRows]);
    
    position.row = row;
    
    return position;
    
}

- (NSInteger)_pageForCellAtPosition:(CellPosition)position{
    
    if(self.layoutDirection = FJSpringBoardLayoutDirectionVertical)
        return 0;
    
    NSInteger index  = [self _indexForPositon:position];
    
    float p = floorf((float)((float)index / (float)[self numberOfVisibleCells]));
    
    NSInteger page = (NSInteger)p;
    
    return page;
}

- (CGFloat)_horizontalOffsetForPage:(NSInteger)page{
    
    return gridViewBounds.size.width * page;
    
}


#pragma mark -
#pragma mark Page Releative Geometry

- (CGRect)frameForPage:(NSInteger)page{
    
    return CGRectZero;
    
}

- (CGRect)pageRelativeFrameForCellAtIndex:(NSInteger)index{
        
    return CGRectZero;

}


\

@end
