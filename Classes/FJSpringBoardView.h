

#import <UIKit/UIKit.h>
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardCell.h"

@class FJReorderingIndexMap;

@class FJSpringBoardIndexLoader;
@class FJSpringBoardLayout;

@class FJSpringBoardView;

@protocol FJSpringBoardViewDataSource;

typedef enum  {
    FJSpringBoardCellAnimationNone,
    FJSpringBoardCellAnimationFade
} FJSpringBoardCellAnimation;

typedef enum  {
    FJSpringBoardCellScrollPositionTop,
    FJSpringBoardCellScrollPositionMiddle,
    FJSpringBoardCellScrollPositionBottom
} FJSpringBoardCellScrollPosition;

typedef enum  {
    FJSpringBoardViewScrollDirectionVertical,
    FJSpringBoardViewScrollDirectionHorizontal
} FJSpringBoardViewScrollDirection;


@protocol FJSpringBoardViewDelegate <NSObject, UIScrollViewDelegate>

@optional
- (void)springBoardView:(FJSpringBoardView *)springBoardView didSelectCellAtIndex:(NSUInteger)index; //use to launch detail?


@end

@protocol FJSpringBoardViewDataSource <NSObject>

- (NSUInteger)numberOfCellsInSpringBoardView:(FJSpringBoardView *)springBoardView;
- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index;


@optional

//simple drag and drop
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canMoveCellAtIndex:(NSUInteger)index; //you must implement the following method as well
- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex; //update your model

//deletion
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDeleteCellAtIndex:(NSUInteger)index; //you must implement the following method as well
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger)index; //update your model

//NOT IMPLEMENTED
//drag and drop ONTO another cell
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDropCellFromIndex:(NSUInteger)formIndex onCellAtIndex:(NSUInteger)dropIndex; 
- (FJSpringBoardCell*)springBoardView:(FJSpringBoardView *)springBoardView willDropCellOntoCell:(FJSpringBoardCell*)dropCell atIndex:(NSUInteger)dropIndex; //chance to customize a cell before another cell is dropped onto it
- (void)springBoardView:(FJSpringBoardView *)springBoardView dropCellAtIndex:(NSUInteger)fromIndex onCellAtIndex:(NSUInteger)toIndex; //update your model. the cell at the drop index will be reloaded after this call



@end


@interface FJSpringBoardView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate> {

    UIView* contentView;
    
    UIEdgeInsets pageInsets;
    
    CGSize cellSize;
    
    FJSpringBoardViewScrollDirection scrollDirection;

    FJSpringBoardIndexLoader* indexLoader;
    FJSpringBoardLayout *layout;
      
    NSMutableArray *cells;
    
    BOOL canProcessActions;
    
    NSMutableSet *reusableCells; //reusable cells
    
    BOOL suspendLayoutUpdates;

    BOOL doubleTapped;
    BOOL longTapped;

    FJSpringBoardCellAnimation layoutAnimation;
    
    FJSpringBoardCellMode mode;
    
    NSMutableIndexSet *selectedIndexes;

    CGPoint lastTouchPoint;

    UIView* draggableCellView;
        
    NSUInteger indexOfHighlightedCell;
    
}
//delegate and datasource
@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate> delegate;

@property(nonatomic) CGSize cellSize; //be sure your cells are the size you specify here. careful! setting this causes a full reload

@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection;



//reload
- (void)reloadData;


//yes, like a UITableView
- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;


//cell info
- (NSUInteger)numberOfCells;
- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index;
- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell;
- (CGRect)frameForCellAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfCellAtPoint:(CGPoint)point;

@property(nonatomic, retain, readonly) NSIndexSet *visibleCellIndexes; 

//scroll, position is ignored in horizontal layout
- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;


@property(nonatomic) BOOL allowsMultipleSelection; 

- (void)selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated scrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition;
- (void)deselectCellAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated;


- (NSUInteger)selectedCellIndex;
- (NSIndexSet*)selectedCellIndexes;



//the following methods are used to animate changes without a full reload
- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;

//use these to perform multiple updates at once
- (void)beginUpdates;
- (void)endUpdates;



//mode
@property(nonatomic) FJSpringBoardCellMode mode; //KVO to be notified about mode changes


//Selection, these only work in Selection Mode
/*
- (void)selectCellAtIndex:(NSUInteger)index;
- (void)selectCellsAtIndexes:(NSIndexSet*)indexSet;

- (void)deselectCellAtIndex:(NSUInteger)index;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexSet;
*/

- (NSIndexSet *)indexesForSelectedCells;



//paging, only valid if scrollingDirection == horizontal

@property(nonatomic) UIEdgeInsets pageInsets;

- (NSUInteger)numberOfPages;
- (NSUInteger)page;
- (NSUInteger)nextPage;
- (NSUInteger)previousPage;

- (BOOL)scrollToPage:(NSUInteger)page animated:(BOOL)animated;


@end


