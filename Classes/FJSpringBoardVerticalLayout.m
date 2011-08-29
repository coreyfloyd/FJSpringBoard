

#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardView.h"

#define NUMBER_OF_ROWS_TO_PAD 1

@interface FJSpringBoardLayout(verticalInternal)

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property(nonatomic) CGFloat minimumRowWidth;
@property(nonatomic) CGFloat maximumRowWidth;

@property(nonatomic, readwrite) CGSize contentSize;

- (CGSize)_contentSize;

- (NSIndexSet*)_cellIndexesWithRowIndexes:(NSIndexSet*)rowIndexes;
- (NSIndexSet*)_cellIndexesInRowAtIndex:(NSUInteger)rowIndex;

@end


@implementation FJSpringBoardVerticalLayout


- (void)updateLayout{
    
    [super updateLayout];
    self.contentSize = [self _contentSize];

    
}

- (CGRect)_frameForRow:(NSUInteger)row{
    
    CGRect f;
    
    CGFloat x = self.springBoard.springBoardInsets.left;
    
    CGFloat y = self.springBoard.springBoardInsets.top + ((float)row * self.verticalCellSpacing) + ((float)row * self.springBoard.cellSize.height); 
    
    f.origin = CGPointMake(x, y);
    f.size = CGSizeMake(self.maximumRowWidth, self.springBoard.cellSize.height); 
    
    return f;
}


- (CGSize)_contentSize{
    
    CGFloat cellHeight = (float)self.numberOfRows * self.springBoard.cellSize.height;
    CGFloat spacingHeight = (float)(self.numberOfRows-1) * self.verticalCellSpacing;
    CGFloat insetHeight = self.springBoard.springBoardInsets.top + self.springBoard.springBoardInsets.bottom;
    
    CGFloat pageHeight = (cellHeight + spacingHeight + insetHeight);
    
    CGFloat pageWidth = self.maximumRowWidth;

    return CGSizeMake(pageWidth, pageHeight);
    
}

- (CGPoint)_originForCellAtPosition:(CellPosition)position{
    
    CGPoint origin = CGPointZero;
    
    int column = position.column;
    int row = position.row;
    
    CGFloat x = self.springBoard.springBoardInsets.left + ((float)column * self.horizontalCellSpacing) + ((float)column * self.springBoard.cellSize.width) - CELL_INVISIBLE_LEFT_MARGIN;
    CGFloat y = self.springBoard.springBoardInsets.top + ((float)row * self.verticalCellSpacing) + ((float)row * self.springBoard.cellSize.height) - CELL_INVISIBLE_TOP_MARGIN; 
    
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
