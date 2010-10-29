//
//  FJGridView.h
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FJSpringBoardCell.h"

@class FJSpringBoardLayout;

@protocol FJSpringBoardViewDelegate;
@protocol FJSpringBoardViewDataSource;

typedef enum  {
    FJSpringBoardViewScrollDirectionVertical,
    FJSpringBoardViewScrollDirectionHorizontal
} FJSpringBoardViewScrollDirection;

@interface FJSpringBoardView : UIScrollView {

    
    FJSpringBoardLayout *layout;
    
    NSMutableArray *cellItems; //by index
    
    NSMutableIndexSet *visibleIndexes; 
    NSMutableArray *visibleCells; 
    NSMutableSet *dequeuedCells;
    
}

@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate> delegate;

//view setup
@property(nonatomic) UIEdgeInsets gridViewInsets;

@property(nonatomic) CGSize cellPadding;
@property(nonatomic) CGSize cellSize;

@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection;

//mode
@property(nonatomic) FJSpringBoardCellMode mode;

//allows deletion (tap and hold)
@property(nonatomic) BOOL allowsDeleteMode;


//selection
- (void)selectCellAtIndex:(NSInteger)index;
- (void)selectCellsAtIndexes:(NSIndexSet*)indexSet;

- (void)deselectCellAtIndex:(NSInteger)index;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexSet;

- (NSIndexSet *)indexesForSelectedCells;


//cell loading
- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

- (void)reloadData;
- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;


//cell info
- (NSInteger)numberOfCells;
- (FJSpringBoardCell *)cellAtIndex:(NSInteger *)index;
- (NSInteger *)indexForCell:(FJSpringBoardCell *)cell;

- (CGRect)frameForCellAtIndex:(NSInteger)index;

@property(nonatomic, retain, readonly) NSMutableArray *visibleCells; 
@property(nonatomic, retain, readonly) NSMutableIndexSet *visibleIndexes; 


- (void)scrollToCellAtIndex:(NSInteger *)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;




- (void)beginUpdates;

- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;

- (void)endUpdates;

@end


@protocol FJSpringBoardViewDelegate

@optional
- (void)gridView:(FJSpringBoardView *)gridView cellWasTappedAtIndex:(NSInteger *)index;
- (void)gridView:(FJSpringBoardView *)gridView cellWasTappedAndHeldAtIndex:(NSInteger *)index;
- (void)gridView:(FJSpringBoardView *)gridView cellWasDoubleTappedAtIndex:(NSInteger *)index;


- (void)gridViewWillBeginEditing:(FJSpringBoardView *)gridView;
- (void)gridViewDidEndEditing:(FJSpringBoardView *)gridView;

/*
- (void)gridViewWillBeginMultiSelection:(FJSpringBoardView *)gridView;
- (void)gridViewDidEndMultiSelection:(FJSpringBoardView *)gridView;
*/

@end



@protocol FJSpringBoardViewDataSource

- (NSInteger)numberOfCellsInGridView:(FJSpringBoardView *)gridView;
- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView cellAtIndex:(NSInteger )index;


@optional
- (NSArray *)gridView:(FJSpringBoardView *)gridView cellsForGroupCell:(FJSpringBoardGroupCell*)cell AtIndex:(NSInteger )index;

- (BOOL)gridView:(FJSpringBoardView *)gridView canSelectCellAtIndex:(NSInteger )index;

- (BOOL)gridView:(FJSpringBoardView *)gridView canMoveCellAtIndex:(NSInteger )index;
- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView movableCellForCell:(FJSpringBoardCell*)cell atIndex:(NSInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView moveCellAtIndex:(NSInteger )fromIndex toIndex:(NSInteger )toIndex;

- (BOOL)gridView:(FJSpringBoardView *)gridView canDeleteCellAtIndex:(NSInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView commitDeletionForCellAtIndex:(NSInteger )index; 

/*
- (BOOL)gridView:(FJSpringBoardView *)gridView canMultiSelectCellAtIndex:(NSInteger )index;
- (void)gridView:(FJSpringBoardView *)gridView commitMultiSelectActionForCellsAtIndexes:(NSIndexSet *)indexSet; 
*/

@end

