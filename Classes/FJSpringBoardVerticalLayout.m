

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

- (CGRect)_frameForRow:(NSUInteger)row;

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
    
    return self.springBoard.bounds.size.width;
}



- (CGRect):(NSUInteger)row{
    
    CGRect f;
    
    //TODO: handle contentInset
    CGFloat x = 0;
    
    CGFloat y = ((float)row * self.springBoard.cellSize.height) + ((float)(row+1) * self.veritcalCellSpacing); 
    
    f.origin = CGPointMake(x, y);
    f.size = CGSizeMake(self.rowWidth, self.springBoard.cellSize.height); 
    
    return f;
}


- (CGSize)_contentSize{
    
    CGFloat pageHeight = ((float)self.numberOfRows * self.springBoard.cellSize.height) + ((float)(self.numberOfRows+1) * self.veritcalCellSpacing);
    CGFloat pageWidth = self.springBoard.bounds.size.width;
    
    return CGSizeMake(pageWidth, pageHeight);
    
}

- (CGPoint)_originForCellAtPosition:(CellPosition)position{
        
    float widthOfCellsInRowBeforeCell = self.springBoard.cellSize.width * position.column;
    
    float widthOfSpacesInRowBeforeCell = self.horizontalCellSpacing * (position.column + 1);
    
    
    CGFloat x = widthOfCellsInRowBeforeCell + widthOfSpacesInRowBeforeCell;
    
    if(x < 0 || x == NAN){
        ALWAYS_ASSERT;
    }

    float heightOfCellsInColumnBeforeCell = self.springBoard.cellSize.height * position.row;
    
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

- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset{
    
    CGRect viewRect;
    viewRect.origin = offset;
    viewRect.size = self.springBoard.bounds.size;
        
    NSMutableIndexSet* rowsInView = [NSMutableIndexSet indexSet];
    
    for(int row = 0; row < self.numberOfRows; row++){
        
        CGRect rowFrame = [self _frameForRow:row];
        
        if(CGRectIntersectsRect
           (viewRect, rowFrame)){
            
            [rowsInView addIndex:row];
        }
    }
    
    NSIndexSet* cellIndexes = [self _cellIndexesWithRowIndexes:rowsInView];
    
    return cellIndexes;
    
    
}

- (NSUInteger)_rowForCellAtIndex:(NSUInteger)index{
        
    float r = floorf((float)((float)index / (float)self.cellsPerRow));
    
    NSUInteger row = (NSUInteger)r;
    
    if(row > self.numberOfRows)
        row = NSNotFound;
    
    return row;
}


- (NSIndexSet*)visibleCellIndexesWithPaddingForContentOffset:(CGPoint)offset{
    
    NSMutableIndexSet* vis = [[[self visibleCellIndexesForContentOffset:offset] mutableCopy] autorelease];
    
    NSIndexSet* prePadding = nil;
    
    NSUInteger first = [vis firstIndex];
    
    NSInteger row = [self _rowForCellAtIndex:first];
    
    if(row < NSNotFound){
                    
        prePadding = [self _cellIndexesInRowAtIndex:((NSUInteger)(row-1))];
        
    }
    
    NSUInteger last = [vis lastIndex];

    row = [self _rowForCellAtIndex:last];
    
    NSIndexSet* postPadding = [self _cellIndexesInRowAtIndex:((NSUInteger)(row+1))];

    [vis addIndexes:prePadding];
    
    [vis addIndexes:postPadding];
    
    return vis;
    
}


@end
