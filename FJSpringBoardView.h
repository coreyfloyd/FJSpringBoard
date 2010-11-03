//
//  FJGridView.h
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FJSpringBoardCell.h"

@class FJSpringBoardIndexLoader;
@class FJSpringBoardLayout;

@protocol FJSpringBoardViewDelegate;
@protocol FJSpringBoardViewDataSource;

typedef enum  {
    FJSpringBoardViewScrollDirectionVertical,
    FJSpringBoardViewScrollDirectionHorizontal
} FJSpringBoardViewScrollDirection;

@interface FJSpringBoardView : UIScrollView {

    UIEdgeInsets springBoardInsets;
    
    CGSize cellSize;

    CGFloat horizontalCellSpacing; 
    CGFloat verticalCellSpacing; 
    
    FJSpringBoardViewScrollDirection scrollDirection;
    
    FJSpringBoardIndexLoader* indexLoader;
    FJSpringBoardLayout *layout;
    
    NSMutableIndexSet *allIndexes;
    
    NSMutableIndexSet *visibleCellIndexes; 
    NSMutableIndexSet *dirtyIndexes;
    NSMutableIndexSet *indexesNeedingLayout;
    NSMutableIndexSet *indexesToDequeue;
    NSMutableIndexSet *indexesToDelete;
    NSMutableIndexSet *selectedIndexes;
    
    NSMutableArray *cells; 
    NSMutableSet *dequeuedCells;
    
    BOOL layoutIsDirty;
    
    FJSpringBoardCellMode mode;
}
//delegate and datasource
@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate> delegate;

//view setup
@property(nonatomic) UIEdgeInsets springBoardInsets;

@property(nonatomic) CGSize cellSize;

@property(nonatomic) CGFloat horizontalCellSpacing; //default = 0
@property(nonatomic) CGFloat verticalCellSpacing; //defult = 0

@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection;


//cell loading
- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

- (void)reloadData;
- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;


//cell info
- (NSUInteger)numberOfCells;
- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index;
- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell;

- (CGRect)frameForCellAtIndex:(NSUInteger)index;

@property(nonatomic, retain, readonly) NSMutableArray *cells; 
@property(nonatomic, retain, readonly) NSMutableIndexSet *visibleCellIndexes; 

//scroll
- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;

//index sets must be continuous
- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;


//mode
@property(nonatomic) FJSpringBoardCellMode mode;


//Selection, these only work in Selection Mode
/*
- (void)selectCellAtIndex:(NSUInteger)index;
- (void)selectCellsAtIndexes:(NSIndexSet*)indexSet;

- (void)deselectCellAtIndex:(NSUInteger)index;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexSet;
*/

- (NSIndexSet *)indexesForSelectedCells;


@end


@protocol FJSpringBoardViewDelegate

@optional
- (void)gridView:(FJSpringBoardView *)gridView cellWasTappedAtIndex:(NSUInteger)index; //use to launch detail
- (void)gridView:(FJSpringBoardView *)gridView cellWasTappedAndHeldAtIndex:(NSUInteger)index; //use to set delete mode
- (void)gridView:(FJSpringBoardView *)gridView cellWasDoubleTappedAtIndex:(NSUInteger)index; //have some fun!


@end



@protocol FJSpringBoardViewDataSource

- (NSUInteger)numberOfCellsInGridView:(FJSpringBoardView *)gridView;
- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView cellAtIndex:(NSUInteger )index;


@optional

- (BOOL)gridView:(FJSpringBoardView *)gridView canSelectCellAtIndex:(NSUInteger )index; 

- (BOOL)gridView:(FJSpringBoardView *)gridView canMoveCellAtIndex:(NSUInteger )index;
- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView movableCellForCell:(FJSpringBoardCell*)cell atIndex:(NSUInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex;


- (NSArray *)gridView:(FJSpringBoardView *)gridView cellsForGroupCell:(FJSpringBoardGroupCell*)cell AtIndex:(NSUInteger )index;

- (void)gridView:(FJSpringBoardView *)gridView canAddCellAtIndex:(NSUInteger )fromIndex toGroupCellAtIndex:(NSUInteger )toIndex;
- (void)gridView:(FJSpringBoardView *)gridView commitAddingCellAtIndex:(NSUInteger )fromIndex toGroupCellAtIndex:(NSUInteger )toIndex;


- (BOOL)gridView:(FJSpringBoardView *)gridView canDeleteCellAtIndex:(NSUInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView commitDeletionForCellAtIndex:(NSUInteger )index; 


@end

