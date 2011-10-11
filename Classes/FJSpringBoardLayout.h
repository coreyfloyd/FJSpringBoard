//
//  FJSpringBoardLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"

@interface FJSpringBoardLayout : SMModelObject {
    
    CGRect springBoardBounds;
    NSUInteger cellCount;
    CGSize cellSize;
    
    NSUInteger cellsPerRow;
    CGFloat rowWidth;
    NSUInteger numberOfRows;
    
    float veritcalCellSpacing;
    float horizontalCellSpacing;
    
}

- (id)initWithSpringBoardBounds:(CGRect)bounds cellSize:(CGSize)size cellCount:(NSUInteger)count;

//use this to set the number of cells in the springboard
@property(nonatomic) NSUInteger cellCount;

@property (nonatomic, readonly) CGRect springBoardBounds;
@property(nonatomic, readonly) CGSize cellSize;

//makes layout calculations based on the current geometry and caches the results
- (void)calculateLayout;

- (NSRange)visibleRangeForContentOffset:(CGPoint)offset;

//returns the "visible" range. Subclasses should return a range with a practical buffer
//note that this is range ignores the cell count. i.e. The NSMaxRange can be > cellCount
- (NSRange)visibleRangeWithPaddingForContentOffset:(CGPoint)offset;


- (CGRect)frameForCellAtIndex:(NSUInteger)index;

//the size of the springboard with the current cellCount
@property(nonatomic, readonly) CGSize contentSize;


@end
