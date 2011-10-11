

#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardView.h"

#define NUMBER_OF_ROWS_TO_PAD 1

@interface FJSpringBoardLayout(verticalInternal)

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property(nonatomic) CGFloat minimumRowWidth;
@property(nonatomic) CGFloat rowWidth;

@property (nonatomic) float veritcalCellSpacing;
@property (nonatomic) float horizontalCellSpacing;

@property(nonatomic, readwrite) CGSize contentSize;


- (CGSize)_contentSize;

- (NSIndexSet*)_cellIndexesWithRowIndexes:(NSIndexSet*)rowIndexes;
- (NSIndexSet*)_cellIndexesInRowAtIndex:(NSUInteger)rowIndex;

@end


@implementation FJSpringBoardVerticalLayout


- (void)calculateLayout{
    
    [super calculateLayout];
    
    self.veritcalCellSpacing = self.horizontalCellSpacing;

    self.contentSize = [self _contentSize];

    
}

- (float)_rowWidth{
    
    return self.springBoardBounds.size.width;
}



- (CGRect)frameForRow:(NSUInteger)row{
    
    CGRect f;
    
    //TODO: handle contentInset
    CGFloat x = 0;
    
    CGFloat y = ((float)row * self.cellSize.height) + ((float)(row+1) * self.veritcalCellSpacing); 
    
    f.origin = CGPointMake(x, y);
    f.size = CGSizeMake(self.rowWidth, self.cellSize.height); 
    
    return f;
}


- (CGSize)_contentSize{
    
    CGFloat pageHeight = ((float)self.numberOfRows * self.cellSize.height) + ((float)(self.numberOfRows+1) * self.veritcalCellSpacing);
    CGFloat pageWidth = self.springBoardBounds.size.width;
    
    return CGSizeMake(pageWidth, pageHeight);
    
}

- (CGPoint)_originForCellAtPosition:(CellPosition)position{
        
    float widthOfCellsInRowBeforeCell = self.cellSize.width * position.column;
    
    float widthOfSpacesInRowBeforeCell = self.horizontalCellSpacing * (position.column + 1);
    
    
    CGFloat x = widthOfCellsInRowBeforeCell + widthOfSpacesInRowBeforeCell;
    
    if(x < 0 || x == NAN){
        ALWAYS_ASSERT;
    }

    float heightOfCellsInColumnBeforeCell = self.cellSize.height * position.row;
    
    float heightOfSpacesInColumnBeforeCell = self.veritcalCellSpacing * (position.row + 1);
    
    float heighInColumnBeforeCell = heightOfCellsInColumnBeforeCell + heightOfSpacesInColumnBeforeCell;
    
    CGFloat y = heighInColumnBeforeCell; 
    
    if(y < 0 || y == NAN){
        ALWAYS_ASSERT;
    }   
    
    CGPoint origin;
    origin.x = x;
    origin.y = y;
    
    return origin;
}

- (NSIndexSet*)visibleCellIndexesWithPaddingForContentOffset:(CGPoint)offset{
    
    CGRect viewRect;
    viewRect.origin = offset;
    viewRect.size = self.springBoardBounds.size;
        
    NSMutableIndexSet* rowsInView = [NSMutableIndexSet indexSet];
    
    for(int row = 0; row < self.numberOfRows; row++){
        
        CGRect rowFrame = [self frameForRow:row];
        
        if(CGRectIntersectsRect
           (viewRect, rowFrame)){
            
            [rowsInView addIndex:row];
        }
    }
    
    if([rowsInView count] == 0)
        return nil;
    
    NSUInteger lowest = [rowsInView firstIndex];
    
    if(lowest > 0)
        lowest--;
    
    [rowsInView addIndex:lowest];
    
    NSUInteger highest = [rowsInView lastIndex];
    highest++;
    
    [rowsInView addIndex:highest];
    
    NSIndexSet* cellIndexes = [self _cellIndexesWithRowIndexes:rowsInView];
    
    return cellIndexes;
    
    
}

- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset{
    
    CGRect viewRect;
    viewRect.origin = offset;
    viewRect.size = self.springBoardBounds.size;
    
    NSMutableIndexSet* rowsInView = [NSMutableIndexSet indexSet];
    
    for(int row = 0; row < self.numberOfRows; row++){
        
        CGRect rowFrame = [self frameForRow:row];
        
        if(CGRectIntersectsRect
           (viewRect, rowFrame)){
            
            [rowsInView addIndex:row];
        }
    }
    
    if([rowsInView count] == 0)
        return nil;
    
    NSIndexSet* cellIndexes = [self _cellIndexesWithRowIndexes:rowsInView];
    
    return cellIndexes;
    
    
}

- (NSRange)visibleRangeWithPaddingForContentOffset:(CGPoint)offset{
    
    NSIndexSet* cellIndexes = [self visibleCellIndexesWithPaddingForContentOffset:offset];
    
    ASSERT_TRUE(indexesAreContiguous(cellIndexes));
    
    NSRange r = rangeWithContiguousIndexes(cellIndexes);
    
    return r;
    
}

- (NSRange)visibleRangeForContentOffset:(CGPoint)offset{
    
    NSIndexSet* cellIndexes = [self visibleCellIndexesForContentOffset:offset];
    
    ASSERT_TRUE(indexesAreContiguous(cellIndexes));
    
    NSRange r = rangeWithContiguousIndexes(cellIndexes);
    
    return r;
}

- (NSUInteger)rowForCellAtIndex:(NSUInteger)index{
        
    float r = floorf((float)((float)index / (float)self.cellsPerRow));
    
    NSUInteger row = (NSUInteger)r;
    
    if(row > self.numberOfRows)
        row = NSNotFound;
    
    return row;
}

@end
