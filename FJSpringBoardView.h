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

    FJSpringBoardIndexLoader* indexLoader;
    FJSpringBoardLayout *layout;

    NSMutableArray *cellItems; //by index
    
    NSMutableIndexSet *visibleCellIndexes; 
    NSMutableArray *cells; 
    NSMutableSet *dequeuedCells;
    
    BOOL reloading;
}

@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate> delegate;

//view setup
@property(nonatomic) UIEdgeInsets gridViewInsets;

@property(nonatomic) CGSize cellSize;

@property(nonatomic) CGFloat horizontalCellSpacing; //default = 0
@property(nonatomic) CGFloat verticalCellSpacing; //defult = 0

@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection;

//mode
@property(nonatomic) FJSpringBoardCellMode mode;

//allows deletion (tap and hold)
@property(nonatomic) BOOL allowsDeleteMode;


//selection
- (void)selectCellAtIndex:(NSUInteger)index;
- (void)selectCellsAtIndexes:(NSIndexSet*)indexSet;

- (void)deselectCellAtIndex:(NSUInteger)index;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexSet;

- (NSIndexSet *)indexesForSelectedCells;


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


- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;




- (void)beginUpdates;

- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;

- (void)endUpdates;

@end


@protocol FJSpringBoardViewDelegate

@optional
- (void)gridView:(FJSpringBoardView *)gridView cellWasTappedAtIndex:(NSUInteger)index;
- (void)gridView:(FJSpringBoardView *)gridView cellWasTappedAndHeldAtIndex:(NSUInteger)index;
- (void)gridView:(FJSpringBoardView *)gridView cellWasDoubleTappedAtIndex:(NSUInteger)index;


- (void)gridViewWillBeginEditing:(FJSpringBoardView *)gridView;
- (void)gridViewDidEndEditing:(FJSpringBoardView *)gridView;

/*
- (void)gridViewWillBeginMultiSelection:(FJSpringBoardView *)gridView;
- (void)gridViewDidEndMultiSelection:(FJSpringBoardView *)gridView;
*/

@end



@protocol FJSpringBoardViewDataSource

- (NSUInteger)numberOfCellsInGridView:(FJSpringBoardView *)gridView;
- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView cellAtIndex:(NSUInteger )index;


@optional
- (NSArray *)gridView:(FJSpringBoardView *)gridView cellsForGroupCell:(FJSpringBoardGroupCell*)cell AtIndex:(NSUInteger )index;

- (BOOL)gridView:(FJSpringBoardView *)gridView canSelectCellAtIndex:(NSUInteger )index;

- (BOOL)gridView:(FJSpringBoardView *)gridView canMoveCellAtIndex:(NSUInteger )index;
- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView movableCellForCell:(FJSpringBoardCell*)cell atIndex:(NSUInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex;

- (BOOL)gridView:(FJSpringBoardView *)gridView canDeleteCellAtIndex:(NSUInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView commitDeletionForCellAtIndex:(NSUInteger )index; 

/*
- (BOOL)gridView:(FJSpringBoardView *)gridView canMultiSelectCellAtIndex:(NSUInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView commitMultiSelectActionForCellsAtIndexes:(NSIndexSet *)indexSet; 
*/

@end

