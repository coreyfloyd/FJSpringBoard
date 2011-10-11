//
//  FJSpringBoardLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardLayout.h"
#import "FJSpringBoardUtilities.h"

#define MINIMUM_CELL_SPACING 2

@interface FJSpringBoardLayout()

@property (nonatomic, readwrite) CGSize cellSize;
@property (nonatomic, readwrite) CGRect springBoardBounds;
@property(nonatomic, readwrite) CGSize cellSizeWithAccesories;

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property (nonatomic) float veritcalCellSpacing;
@property (nonatomic) float horizontalCellSpacing;

@property(nonatomic, readwrite) CGSize contentSize;

@property (nonatomic) CGFloat rowWidth;

- (float)_rowWidth;

- (CGSize)_contentSize;

- (CGPoint)_originForCellAtPosition:(CellPosition)position;
- (CGRect)_frameForCellAtPosition:(CellPosition)position;

- (CellPosition)_positionForCellAtIndex:(NSUInteger)index;

- (NSIndexSet*)_cellIndexesWithRowIndexes:(NSIndexSet*)rowIndexes;
- (NSIndexSet*)_cellIndexesInRowAtIndex:(NSUInteger)rowIndex;


@end

@implementation FJSpringBoardLayout

@synthesize cellCount;
@synthesize cellsPerRow;
@synthesize numberOfRows;
@synthesize rowWidth;
@synthesize contentSize;
@synthesize cellSizeWithAccesories;
@synthesize veritcalCellSpacing;
@synthesize horizontalCellSpacing;
@synthesize cellSize;
@synthesize springBoardBounds;


#pragma mark -
#pragma mark Initialization

- (id)initWithSpringBoardBounds:(CGRect)bounds cellSize:(CGSize)size cellCount:(NSUInteger)count{
    self = [super init];
    if (self != nil) {
    
        self.springBoardBounds = bounds;
        self.cellSize = size;
        self.cellCount = count;
    }
    return self;
}

- (void)calculateLayout{
    
    self.rowWidth = [self _rowWidth];
    
    CGSize s = self.cellSize;
    s.width += CELL_INVISIBLE_LEFT_MARGIN;
    s.height += CELL_INVISIBLE_TOP_MARGIN;
    self.cellSizeWithAccesories = s;
    
    float minimumCellWidth = self.cellSizeWithAccesories.width;
    float cellsInOneRow = floorf(self.rowWidth / minimumCellWidth);
    self.cellsPerRow = (NSUInteger)cellsInOneRow;
    
    self.horizontalCellSpacing = (self.rowWidth - (self.cellsPerRow * self.cellSize.width))/(self.cellsPerRow+1);

    self.numberOfRows = (NSUInteger)ceilf((float)((float)self.cellCount / (float)self.cellsPerRow));
    

}

- (float)_rowWidth{
    
    return 0.0;
}

#pragma mark -
#pragma mark Frame/Position Calculation

- (CGRect)frameForCellAtIndex:(NSUInteger)index{
    
    CellPosition position = [self _positionForCellAtIndex:index];
    CGRect frame = [self _frameForCellAtPosition:position];
    
    return frame;
}

//this calculation is independant of the layout
- (CellPosition)_positionForCellAtIndex:(NSUInteger)index{
    
    CellPosition pos;
    pos.index = index;
    
    float row = (float)((float)index / (float)self.cellsPerRow);
    row = floorf(row);
    pos.row = (NSUInteger)row;
    
    int column = index % self.cellsPerRow;
    pos.column = (NSUInteger)column;
    
    return pos;
}


- (CGRect)_frameForCellAtPosition:(CellPosition)position{
    
    CGRect frame = CGRectZero;
    frame.origin = [self _originForCellAtPosition:position];
    frame.origin.x = roundf(frame.origin.x);
    frame.origin.y = roundf(frame.origin.y);
    frame.size = self.cellSize;
    
    return frame;
    
}

//overidden by subclasses
- (CGPoint)_originForCellAtPosition:(CellPosition)position{
        
    return CGPointZero;
    
}


#pragma mark -

//overidden by subclasses
- (CGSize)_contentSize{
    
    return CGSizeZero;    
}


- (NSIndexSet*)_cellIndexesWithRowIndexes:(NSIndexSet*)rowIndexes{
    
    NSMutableIndexSet* cellIndexes = [NSMutableIndexSet indexSet];
    
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
    
        NSIndexSet* cellIndexesForEachRow = [self _cellIndexesInRowAtIndex:index];
        [cellIndexes addIndexes:cellIndexesForEachRow];

    
    }];
        
    return cellIndexes;
}

- (NSIndexSet*)_cellIndexesInRowAtIndex:(NSUInteger)rowIndex{
    
    NSUInteger numOfCellsInRow = (NSUInteger)self.cellsPerRow;
        
    NSUInteger numberOfCellsBeforeRow = 0;
    NSUInteger firstIndex = 0;
    
    if(rowIndex > 0){
        numberOfCellsBeforeRow = numOfCellsInRow * rowIndex;
        firstIndex += numberOfCellsBeforeRow;
    }
    
    if(firstIndex >= self.cellCount)
        return nil;
    
    if(rowIndex == self.numberOfRows-1){
        
        numOfCellsInRow = self.cellCount - numberOfCellsBeforeRow;
        
    }
    
    NSRange cellRange = NSMakeRange(firstIndex, numOfCellsInRow);
    
    NSIndexSet* cellIndexes = [NSIndexSet indexSetWithIndexesInRange:cellRange];
    
    return cellIndexes;
    
}

- (NSRange)visibleRangeWithPaddingForContentOffset:(CGPoint)offset{
    
    return NSMakeRange(0, 0);
    
}
- (NSRange)visibleRangeForContentOffset:(CGPoint)offset{
    
    return NSMakeRange(0, 0);
   
}


@end
