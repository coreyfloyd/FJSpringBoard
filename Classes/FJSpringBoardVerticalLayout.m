

#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardUtilities.h"

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
    
    CGFloat x = self.insets.left;
    
    CGFloat y = self.insets.top + ((float)row * self.verticalCellSpacing) + ((float)row * self.cellSize.height); 
    
    f.origin = CGPointMake(x, y);
    f.size = CGSizeMake(self.maximumRowWidth, self.cellSize.height); 
    
    return f;
}


- (CGSize)_contentSize{
    
    CGFloat cellHeight = (float)self.numberOfRows * self.cellSize.height;
    CGFloat spacingHeight = (float)(self.numberOfRows-1) * self.verticalCellSpacing;
    CGFloat insetHeight = self.insets.top + self.insets.bottom;
    
    CGFloat pageHeight = (cellHeight + spacingHeight + insetHeight);
    
    CGFloat pageWidth = self.maximumRowWidth;

    return CGSizeMake(pageWidth, pageHeight);
    
}

- (CGPoint)_originForCellAtPosition:(CellPosition)position{
    
    CGPoint origin = CGPointZero;
    
    int column = position.column;
    int row = position.row;
    
    CGFloat x = self.insets.left + ((float)column * self.horizontalCellSpacing) + ((float)column * self.cellSize.width);
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

- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset{
    
    CGRect viewRect;
    viewRect.origin = offset;
    viewRect.size = self.springBoardbounds.size;
        
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
        row = NSIntegerMax;
    
    return row;
}


- (NSIndexSet*)visibleCellIndexesWithPaddingForContentOffset:(CGPoint)offset{
    
    NSMutableIndexSet* vis = [[self visibleCellIndexesForContentOffset:offset] mutableCopy];
    
    NSIndexSet* prePadding = nil;
    
    NSUInteger first = [vis firstIndex];
    
    NSInteger row = [self _rowForCellAtIndex:first];
    
    if(row < NSIntegerMax){
                    
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
