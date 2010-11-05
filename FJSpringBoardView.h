

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
        
    NSMutableIndexSet *indexesNeedingLayout;

    NSMutableIndexSet *indexesToQueue;
    NSMutableIndexSet *indexesToDequeue;
    
    NSMutableIndexSet *indexesToInsert;
    NSMutableIndexSet *indexesToDelete;
    
    NSMutableIndexSet *selectedIndexes;
    
    NSMutableArray *cells; 
    NSMutableSet *dequeuedCells; //reusable cells
    
    BOOL layoutIsDirty;

    BOOL doubleTapped;
    BOOL longTapped;

    FJSpringBoardCellAnimation layoutAnimation;
    
    FJSpringBoardCellMode mode;
    
    UIView* reorderingCellView;
    NSUInteger reorderingCellIndex;
    NSUInteger reorderingPlaceholderCellIndex;

}
//delegate and datasource
@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate> delegate;

//view setup, Call reload after changing to update the layout
@property(nonatomic) UIEdgeInsets springBoardInsets;

@property(nonatomic) CGSize cellSize;

@property(nonatomic) CGFloat horizontalCellSpacing; //default = 0
@property(nonatomic) CGFloat verticalCellSpacing; //defult = 0

@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection; 

//reload
- (void)reloadData;
- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;


//yes, like a UITableView
- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;


//cell info
- (NSUInteger)numberOfCells;
- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index;
- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell;
- (CGRect)frameForCellAtIndex:(NSUInteger)index;

@property(nonatomic, retain, readonly) NSMutableArray *cells; 
@property(nonatomic, retain, readonly) NSIndexSet *visibleCellIndexes; 

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


@protocol FJSpringBoardViewDelegate <NSObject>

@optional
- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasTappedAtIndex:(NSUInteger)index; //use to launch detail?
- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasTappedAndHeldAtIndex:(NSUInteger)index; //use to set edit mode?
- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasDoubleTappedAtIndex:(NSUInteger)index; //have some fun!!


@end



@protocol FJSpringBoardViewDataSource <NSObject>

- (NSUInteger)numberOfCellsInSpringBoardView:(FJSpringBoardView *)springBoardView;
- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index;


@optional

- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canSelectCellAtIndex:(NSUInteger )index; 

- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canMoveCellAtIndex:(NSUInteger )index;
- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex;


- (NSArray *)springBoardView:(FJSpringBoardView *)springBoardView cellsForGroupCell:(FJSpringBoardGroupCell*)cell AtIndex:(NSUInteger )index;

- (void)springBoardView:(FJSpringBoardView *)springBoardView canAddCellAtIndex:(NSUInteger )fromIndex toGroupCellAtIndex:(NSUInteger )toIndex;
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitAddingCellAtIndex:(NSUInteger )fromIndex toGroupCellAtIndex:(NSUInteger )toIndex;


- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDeleteCellAtIndex:(NSUInteger )index;
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger )index; 


@end

