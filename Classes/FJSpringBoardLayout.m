//
//  FJSpringBoardLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardLayout.h"
#import "FJSpringBoardUtilities.h"


@interface FJSpringBoardLayout()

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

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

- (NSUInteger)_indexForPositon:(CellPosition)position;

@end

@implementation FJSpringBoardLayout

@synthesize insets;
@synthesize springBoardbounds;
@synthesize cellSize;
@synthesize centerCellsInView;
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
    self.centerCellsInView = YES;
    
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
    self.numberOfRows = [self _numberOfRows];
    
}


- (CGFloat)_maximumRowWidth{
    
    return (self.springBoardbounds.size.width - self.insets.right - self.insets.right);
    
}

- (NSUInteger)_numberOfCellsPerRow{
    
    float totalWidth = self.maximumRowWidth;
    float cellWidth = self.cellSize.width;
    
    float count = 0;
    float totalCellWidth = 0;
    
    while (totalCellWidth < totalWidth) {
        
        totalCellWidth += cellWidth;
        
        if(totalCellWidth >= totalWidth){
            break;
        }
        
        count++;

        totalCellWidth += self.horizontalCellSpacing;
    }
    
    return (NSUInteger)count;
    
}


- (CGFloat)_minimumRowWidth{
    
    return ((float)self.cellsPerRow * self.cellSize.width) + (((float)self.cellsPerRow-1) * self.horizontalCellSpacing);

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

- (NSUInteger)_indexForPositon:(CellPosition)position{
    
    return position.row * position.column;
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
    NSUInteger index = [rowIndexes firstIndex];
    
    while(index != NSNotFound){
        
        NSIndexSet* cellIndexesForEachRow = [self _cellIndexesInRowAtIndex:index];
        [cellIndexes addIndexes:cellIndexesForEachRow];
        
        index = [rowIndexes indexGreaterThanIndex:index];
    }
    
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
