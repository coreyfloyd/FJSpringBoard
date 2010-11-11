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

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property(nonatomic, readwrite) CGFloat horizontalCellSpacing; 
@property(nonatomic, readwrite) CGFloat verticalCellSpacing; 

@property(nonatomic, readwrite) CGSize contentSize;

@property (nonatomic) CGFloat minimumRowWidth;
@property (nonatomic) CGFloat maximumRowWidth;


- (CGSize)_contentSize;

- (NSUInteger)_numberOfCellsPerRow;

- (CGPoint)_originForCellAtPosition:(CellPosition)position;
- (CGRect)_frameForCellAtPosition:(CellPosition)position;

- (CellPosition)_positionForCellAtIndex:(NSUInteger)index;

- (NSIndexSet*)_cellIndexesWithRowIndexes:(NSIndexSet*)rowIndexes;
- (NSIndexSet*)_cellIndexesInRowAtIndex:(NSUInteger)rowIndex;

- (NSUInteger)_numberOfRows;
- (CGFloat)_minimumRowWidth;
- (CGFloat)_maximumRowWidth;

- (CGFloat)_horizontalSpacing;



@end

@implementation FJSpringBoardLayout

@synthesize insets;
@synthesize springBoardbounds;
@synthesize cellSize;
@synthesize distributeCellsEvenly;
@synthesize horizontalCellSpacing;
@synthesize verticalCellSpacing;
@synthesize cellCount;

@synthesize cellsPerRow;
@synthesize numberOfRows;
@synthesize minimumRowWidth;
@synthesize maximumRowWidth;
@synthesize contentSize;


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
    
    self.springBoardbounds = CGRectZero;
    self.insets = UIEdgeInsetsZero;
    self.cellSize = CGSizeZero;
    self.horizontalCellSpacing = 0;
    self.verticalCellSpacing = 0;
    self.distributeCellsEvenly = YES;
    
    self.cellCount = 0;
    
    self.cellsPerRow = 0;
    self.numberOfRows = 0;
    self.maximumRowWidth = 0;
    self.minimumRowWidth = 0;
    self.contentSize = CGSizeZero;

}

- (void)updateLayout{
    
    self.maximumRowWidth = [self _maximumRowWidth];
    self.cellsPerRow = [self _numberOfCellsPerRow];
    self.minimumRowWidth = [self _minimumRowWidth];
    
    if(distributeCellsEvenly)
        self.horizontalCellSpacing = [self _horizontalSpacing];
    
    self.numberOfRows = [self _numberOfRows];
    
}


- (CGFloat)_maximumRowWidth{
    
    return (self.springBoardbounds.size.width - self.insets.right - self.insets.right);
    
}

- (NSUInteger)_numberOfCellsPerRow{
    
    float totalWidth = self.maximumRowWidth;
    float cellWidth = self.cellSize.width;

    float count = floorf(totalWidth / cellWidth);
    
    if((totalWidth - (count * cellWidth)) < (MINIMUM_CELL_SPACING*(count-1)))
       count--;
    
    return (NSUInteger)count;
    
}


- (CGFloat)_minimumRowWidth{
    
    return ((float)self.cellsPerRow * self.cellSize.width);

}

- (CGFloat)_horizontalSpacing{
    
    float space = (self.maximumRowWidth + CELL_INVISIBLE_LEFT_MARGIN - self.minimumRowWidth)/(self.cellsPerRow-1);
    return space;
    
}

- (NSUInteger)_numberOfRows{
    
    return (NSUInteger)ceilf((float)((float)self.cellCount / (float)self.cellsPerRow));    
}




#pragma mark -
#pragma mark Frame/Position Calculation

- (CGRect)frameForCellAtIndex:(NSUInteger)index{
    
    CellPosition position = [self _positionForCellAtIndex:index];
    CGRect frame = [self _frameForCellAtPosition:position];
    
    return frame;
}

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
    frame.size = self.cellSize;
    
    return frame;
    
}

- (CGPoint)_originForCellAtPosition:(CellPosition)position{
        
    return CGPointZero;
    
}


- (CGRect)_frameForRow:(NSUInteger)row{
    
    return CGRectZero;
}


#pragma mark -

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




@end
