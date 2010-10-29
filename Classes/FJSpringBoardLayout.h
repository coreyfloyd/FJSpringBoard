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


- (NSInteger)numberOfVisibleCells;
- (CGRect)frameForCellAtIndex:(NSInteger)index;

- (CGRect)frameForPage:(NSInteger)page;
- (CGRect)pageRelativeFrameForCellAtIndex:(NSInteger)index; //


//reset all parameters
- (void)reset;


@end
