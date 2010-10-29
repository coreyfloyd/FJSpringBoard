//
//  FJSpringBoardLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum  {
    FJSpringBoardLayoutDirectionVertical,
    FJSpringBoardLayoutDirectionHorizontal
} FJSpringBoardLayoutDirection;

@interface FJSpringBoardLayout : NSObject {

}
@property(nonatomic) UIEdgeInsets gridViewInsets;
@property(nonatomic) CGRect gridViewBounds;

@property(nonatomic) CGSize cellPadding;
@property(nonatomic) CGSize cellSize;

@property(nonatomic) FJSpringBoardLayoutDirection layoutDirection;

@property(nonatomic) BOOL centerCellsInView;

//reset all properties
- (void)reset;



//indepentent calculations
- (NSInteger)numberOfVisibleCells;
- (CGRect)frameForCellAtIndex:(NSInteger)index;



//cell count dependent calculations
- (CGSize)contentSizeWithCellCount:(NSInteger)count;
- (NSInteger)numberOfPagesWithCellCount:(NSInteger)count; //always returns 1 for vertical layout

- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset;

@end
