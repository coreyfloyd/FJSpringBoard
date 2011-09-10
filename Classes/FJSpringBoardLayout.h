//
//  FJSpringBoardLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"

@class FJSpringBoardView;

@interface FJSpringBoardLayout : SMModelObject {

    FJSpringBoardView* springBoard;
    
    NSUInteger cellCount;
    
    NSUInteger cellsPerRow;
    CGFloat rowWidth;
    NSUInteger numberOfRows;
    
    float veritcalCellSpacing;
    float horizontalCellSpacing;
    
}

- (id)initWithSpringBoardView:(FJSpringBoardView*)view;

@property (nonatomic, assign, readonly) FJSpringBoardView *springBoard;

@property(nonatomic) NSUInteger cellCount;

//reset all properties
- (void)reset;

//makes layout calculations based on the current geometry and caches the results
- (void)calculateLayout;

- (NSRange)visibleRangeForContentOffset:(CGPoint)offset;

- (CGRect)frameForCellAtIndex:(NSUInteger)index;

@property(nonatomic, readonly) CGSize contentSize;




@end
