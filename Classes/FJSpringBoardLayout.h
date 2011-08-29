//
//  FJSpringBoardLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FJSpringBoardView;

@interface FJSpringBoardLayout : NSObject {

    FJSpringBoardView* springBoard;
    
    CGFloat horizontalCellSpacing;
    CGFloat verticalCellSpacing;

    BOOL distributeCellsEvenly;
    
    NSUInteger cellCount;
    
    NSUInteger cellsPerRow;
    CGFloat minimumRowWidth;
    CGFloat maximumRowWidth;
    NSUInteger numberOfRows;
    
}

- (id)initWithSpringBoardView:(FJSpringBoardView*)view;

@property (nonatomic, assign, readonly) FJSpringBoardView *springBoard;

@property(nonatomic) BOOL distributeCellsEvenly; //default = YES

@property(nonatomic) NSUInteger cellCount;

//reset all properties
- (void)reset;

- (void)updateLayout;

- (CGRect)frameForCellAtIndex:(NSUInteger)index;

@property(nonatomic, readonly) CGFloat horizontalCellSpacing; 
@property(nonatomic, readonly) CGFloat verticalCellSpacing; 

@property(nonatomic, readonly) CGSize contentSize;




@end
