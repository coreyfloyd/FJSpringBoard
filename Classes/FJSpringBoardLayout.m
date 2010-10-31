//
//  FJSpringBoardLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardLayout.h"


@interface FJSpringBoardLayout()

@property(nonatomic, readwrite) NSInteger cellCount;
@property(nonatomic, readwrite) NSInteger numberOfRows;
@property (nonatomic) NSInteger cellsPerRow;

@property (nonatomic) CGFloat minimumRowWidth;


- (CGSize)_contentSize;

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

@implementation FJSpringBoardLayout

@synthesize insets;
@synthesize springBoardbounds;
@synthesize cellSize;
@synthesize layoutDirection;
@synthesize centerCellsInView;
@synthesize horizontalCellSpacing;
@synthesize verticalCellSpacing;
@synthesize cellCount;

@synthesize cellsPerRow;
@synthesize numberOfRows;
@synthesize minimumRowWidth;


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

    
}

- (void)updateLayoutWithCellCount:(NSInteger)count{
    
    self.cellCount = count;
    self.minimumRowWidth = [self _rowWidth];
    self.cellsPerRow = [self _numberOfCellsPerRow];
    self.numberOfRows = [self _numberOfRows];
    self.contentSize = [self _contentSize];
    
    
    //TODO: run maths
    
}


- (NSInteger)_numberOfCellsPerRow{
    
    float viewWidth = self.springBoardbounds.size.width;
    
    float totalWidth = viewWidth - self.insets.left - self.insets.right;
    
    float cellWidth = self.cellSize.width;
    
    float count = 0;
    float totalCellWidth = 0;
    
    while (totalCellWidth < totalWidth) {
        
        totalCellWidth += cellWidth;
        count ++;
        
        if(totalCellWidth >= totalWidth)
            break;
        
        totalCellWidth += self.horizontalCellSpacing;
    }
    
    
    return (NSInteger)count;
    
}

- (NSInteger)_numberOfRows{
    
    float rows = ceilf((float)((float)self.cellCount / (float)self.cellsPerRow));
    
    return rows;
    
}

- (CGFloat)_rowWidth{
    
    return ([self _numberOfCellsPerRow] * self.cellSize.width) + (([self _numberOfCellsPerRow]-1) * self.horizontalCellSpacing);
    
}



#pragma mark -
#pragma mark Cell Count

- (NSInteger)numberOfVisibleCells{ // == number of cells per page
    
    [self _calculateAdjustedValues];
    
    self.cellsPerRow = [self _numberOfCellsPerRow];
    
    NSInteger visibleRows = [self _numberOfVisibleRows];
    
    NSInteger count = cellsPerRow * visibleRows;
    
    return count;
    
}


- (NSInteger)_numberOfVisibleRows{
    
    float totalHeight = self.pageSizeWithInsetsApplied.size.height;
    float cellHeight = self.cellSizeWithPadding.height;
    
    float count = floorf(totalHeight/cellHeight);
    
    return (NSInteger)count;
    
    
}

- (NSInteger)numberOfVisibleCellsIncludingPartials{
    
    [self _calculateAdjustedValues];
    
    self.cellsPerRow = [self _numberOfCellsPerRow];

    NSInteger visibleRows = [self _numberOfVisibleRows];
    
    NSInteger count = cellsPerRow * visibleRows;
    
    return count;
        
}

- (NSInteger)_numberOfVisibleRowsWithPartials{
    
    float totalHeight = self.pageSizeWithInsetsApplied.size.height;
    float cellHeight = self.cellSizeWithPadding.height;
    
    float cellCount = ceilf(totalHeight/cellHeight);
    
    return (NSInteger)cellCount;
    
    
}

#pragma mark -
#pragma mark Frame/Position Calculation

- (CGRect)frameForCellAtIndex:(NSInteger)index{
    
    CellPosition position = [self _positionForCellAtIndex:index];
    CGRect frame = [self _frameForCellAtPosition:position];
    
    return frame;
}


- (CellPosition)_positionForCellAtIndex:(NSInteger)index{
    
    CellPosition pos;
    pos.page = 0;
    NSInteger cellsPerRow = [self _numberOfCellsPerRow];
    
    float row = (float)((float)index / (float)cellsPerRow);
    
    row = floorf(row);
    
    pos.row = (NSInteger)row;
    
    int column = index % cellsPerRow;
    
    pos.column = (NSInteger)column;
    
    pos = [self _pageAdjustedCellPosition:pos];
    
    return pos;
    
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
    
    CGFloat x = ([self _horizontalOffsetForPage:position.page]) + self.insets.left + (column * self.horizontalCellSpacing) + (column * self.cellSize.width);
    CGFloat y = self.gridViewInsets.top + (row * self.verticalCellSpacing) + (row * self.cellSize.height) + self.cellPadding.height; 
    
    if(self.centerCellsInView){
        
        float rowWidth = [self _rowWidth];
        
        float usableWidth = self.pageSizeWithInsetsApplied.size.width;
        float leftover = usableWidth - rowWidth;
        float leftOffset = leftover / 2; 
        x += leftOffset;
        
    }
    
    origin.x = x;
    origin.y = y;
    
    return origin;
    
}

- (NSInteger)_indexForPositon:(CellPosition)position{
    
    return position.row * position.column;
}


- (CGFloat)_horizontalOffsetForPage:(NSInteger)page{
    
    return springBoardbounds.size.width * page;
    
}

- (CGRect)_frameForRow:(NSInteger)row{
    
    CGRect f;
    
    CGFloat x = self.insets.left;
    
    CGFloat y = self.insets.top + (row * self.cellSizeWithPadding.height); 
    
    f.origin = CGPointMake(x, y);
    f.size = CGSizeMake(self.springBoardbounds.size.width, self.cellSizeWithPadding.height) 
    
    return f;
}





#pragma mark -
#pragma mark Page Releative Geometry

- (CGRect)frameForPage:(NSInteger)page{
    
    return CGRectZero;
    
}

- (CGRect)pageRelativeFrameForCellAtIndex:(NSInteger)index{
        
    return CGRectZero;

}

#pragma mark -

- (CGSize)contentSizeWithCellCount:(NSInteger)count{
    
    [self _calculateAdjustedValues];

    CGSize pageSize = self.springBoardbounds.size;

    if(self.layoutDirection == FJSpringBoardLayoutDirectionVertical){
        
        NSInteger cellsPerRow = [self _numberOfCellsPerRow];
        float rows = ceilf((float)((float)count / (float)cellsPerRow));
        CGFloat height = rows * self.cellSizeWithPadding.height;
        CGSize s = CGSizeMake(pageSize.width, height);
        return s;
    }
    
    CGFloat width = [self numberOfPagesWithCellCount:count] * self.springBoardbounds.size.width;
    CGSize s = CGSizeMake(width, pageSize.height);
    return s;
    
}


- (NSInteger)numberOfPagesWithCellCount:(NSInteger)count{
    
    if(self.layoutDirection == FJSpringBoardLayoutDirectionVertical)
        return 1;
    
    NSInteger perPage = [self numberOfVisibleCells];
    
    float pages = ceilf((float)((float)count / (float)perPage));
    
    return pages;
    
}

- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset cellCount:(NSInteger)count{
    
    CGRect viewRect;
    viewRect.origin = offset;
    viewRect.size = self.springBoardbounds.size;
    
    NSInteger numberOfRows = [self _numberOfRowsWithCellCount:count];
    
    NSMutableIndexSet* rowsInView = [NSMutableIndexSet indexSet];
    
    for(int row = 0; row < numberOfRows; row++){
        
        CGRect rowFrame = [self _frameForRow:row];
        
        if(CGRectContainsRect(viewRect, rowFrame)){
            
            [rowsInView addIndex:row];
        }
    }
    
    NSIndexSet* cellIndexes = [self _cellIndexesWithRowIndexes:rowsInView];
    
    return cellIndexes;
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

- (NSIndexSet*)_cellIndexesInRowAtIndex:(NSInteger)rowIndex{
    
    NSInteger numOfCellsInRow = [self _numberOfCellsPerRow];
        
    NSInteger numberOfCellsBeforeRow = 0;
    NSInteger firstIndex = 0;
    
    if(rowIndex > 0){
        numberOfCellsBeforeRow = numOfCellsInRow * (rowIndex - 1);
        firstIndex += numberOfCellsBeforeRow;
    }
    
    NSRange cellRange = NSMakeRange(firstIndex, numOfCellsInRow);
    
    NSIndexSet* cellIndexes = [NSIndexSet indexSetWithIndexesInRange:cellRange];
    
}




@end
