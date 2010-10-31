//
//  FJSpringBoardLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct {
    NSInteger page;
    NSInteger row;
    NSInteger column;
} CellPosition;


@interface FJSpringBoardLayout : NSObject {

    CGRect springBoardbounds;
    CGSize cellSize;

    UIEdgeInsets insets;

    CGFloat horizontalCellSpacing;
    CGFloat verticalCellSpacing;

    BOOL centerCellsInView;
    
    NSInteger cellCount;
    
    NSInteger cellsPerRow;
    CGFloat minimumRowWidth;
    NSInteger numberOfRows;
    
       
}
//set these properties to calculate layout
@property(nonatomic) UIEdgeInsets insets; //default = 0,0,0,0
@property(nonatomic) CGRect springBoardbounds;

@property(nonatomic) CGSize cellSize;

@property(nonatomic) CGFloat horizontalCellSpacing; //default = 0
@property(nonatomic) CGFloat verticalCellSpacing; //defult = 0


@property(nonatomic) BOOL centerCellsInView; //default = YES

//reset all properties
- (void)reset;

- (CGRect)frameForCellAtIndex:(NSInteger)index;

- (void)updateLayoutWithCellCount:(NSInteger)count;
@property(nonatomic, readonly) NSInteger cellCount;

@property(nonatomic, readonly) CGSize contentSize;




@end
