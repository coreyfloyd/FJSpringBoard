//
//  FJSpringBoardVerticalLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardVerticalLayout.h"


@implementation FJSpringBoardVerticalLayout




- (CGSize)_contentSize{
    
    CGFloat pageHeight = (self.numberOfRows * self.cellSize.height) + (self.numberOfRows-1 * self.verticalCellSpacing) + self.insets.top + self.insets.bottom;
    
}



- (CellPosition)_positionForCellAtIndex:(NSInteger)index{
    
    CellPosition pos;
    pos.page = 0;
    
    float row = (float)((float)index / (float)self.cellsPerRow);
    
    row = floorf(row);
    
    pos.row = (NSInteger)row;
    
    int column = index % self.cellsPerRow;
    
    pos.column = (NSInteger)column;
        
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
    
    CGFloat x = (self.insets.left + (column * self.horizontalCellSpacing) + (column * self.cellSize.width);
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



@end
