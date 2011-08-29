

#import <UIKit/UIKit.h>
#import "FJSpringBoardUtilities.h"

@class FJSpringBoardCell;
@class FJReorderingIndexMap;

@class FJSpringBoardIndexLoader;
@class FJSpringBoardLayout;

@protocol FJSpringBoardViewDelegate;
@protocol FJSpringBoardViewDataSource;

typedef enum  {
    FJSpringBoardCellModeNormal,
    FJSpringBoardCellModeSelection,
    FJSpringBoardCellModeEditing //delete + move
} FJSpringBoardCellMode;

typedef enum  {
    FJSpringBoardCellAnimationNone,
    FJSpringBoardCellAnimationFade
} FJSpringBoardCellAnimation;

typedef enum  {
    FJSpringBoardCellScrollPositionMiddle
} FJSpringBoardCellScrollPosition;

typedef enum  {
    FJSpringBoardViewScrollDirectionVertical,
    FJSpringBoardViewScrollDirectionHorizontal
} FJSpringBoardViewScrollDirection;

@interface FJSpringBoardView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate> {

    UIView* contentView;
    
    UIEdgeInsets springBoardInsets;
    
    CGSize cellSize;
    
    FJSpringBoardViewScrollDirection scrollDirection;
    
    FJSpringBoardIndexLoader* indexLoader;
    FJSpringBoardLayout *layout;
            
    NSMutableIndexSet *indexesNeedingLayout;

    NSMutableIndexSet *indexesScrollingInView;
    NSMutableIndexSet *indexesScrollingOutOfView;
    
    NSMutableIndexSet *indexesToInsert;
    NSMutableIndexSet *indexesToDelete;
    
    NSMutableIndexSet *selectedIndexes;
    
    NSMutableSet *reusableCells; //reusable cells
    
    BOOL layoutIsDirty;

    BOOL doubleTapped;
    BOOL longTapped;

    FJSpringBoardCellAnimation layoutAnimation;
    
    FJSpringBoardCellMode mode;
    
    CGPoint lastTouchPoint;

    UIView* draggableCellView;
        
    NSUInteger indexOfHighlightedCell;
    
    UITapGestureRecognizer* singleTapRecognizer;
    UITapGestureRecognizer* doubleTapRecognizer;
    
    UILongPressGestureRecognizer* editingModeRecognizer;
    
    UILongPressGestureRecognizer* draggingSelectionRecognizer;
    UIPanGestureRecognizer* draggingRecognizer;
}
//delegate and datasource
@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate, UIScrollViewDelegate> delegate;

@property(nonatomic) UIEdgeInsets springBoardInsets;
@property(nonatomic, readonly) CGRect insetBounds;

@property(nonatomic) CGSize cellSize; //causes reload

@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection; //causes reload

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
- (NSUInteger)indexOfCellAtPoint:(CGPoint)point;

@property(nonatomic, retain, readonly) NSIndexSet *visibleCellIndexes; 

//scroll
- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;

//paging, only valid if scrollingDirection == horizontal
- (NSUInteger)numberOfPages;
- (NSUInteger)page;
- (NSUInteger)nextPage;
- (NSUInteger)previousPage;

- (BOOL)scrollToPage:(NSUInteger)page animated:(BOOL)animated;

//index sets must be continuous
- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;


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


@end



@protocol FJSpringBoardViewDelegate <NSObject>

@optional
- (void)springBoardView:(FJSpringBoardView *)springBoardView didSelectCellAtIndex:(NSUInteger)index; //use to launch detail?

//- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasDoubleTappedAtIndex:(NSUInteger)index; //have some fun!!


@end



@protocol FJSpringBoardViewDataSource <NSObject>

- (NSUInteger)numberOfCellsInSpringBoardView:(FJSpringBoardView *)springBoardView;
- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index;


@optional
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canMoveCellAtIndex:(NSUInteger )index;
- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex;

- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDeleteCellAtIndex:(NSUInteger )index;
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger )index; 


//- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canSelectCellAtIndex:(NSUInteger )index; 
//- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canMoveCellAtIndex:(NSUInteger )index;






/*
 The following methods are @required to support groups
*/
/*
- (void)springBoardView:(FJSpringBoardView *)springBoardView canDropCellFromIndex:(NSUInteger )formIndex onCellAtIndex:(NSUInteger )dropIndex; 
 
- (FJSpringBoardGroupCell *)emptyGroupCellForSpringBoardView:(FJSpringBoardView *)springBoardView;

//called when a new group cell has been created
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitInsertingGroupCellAtIndex:(NSUInteger )index;

//called when adding items to group cells
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitAddingCellsAtIndexes:(NSIndexSet *)indexes toGroupCellAtIndex:(NSUInteger )toIndex;

//called to get the image to be displayed inside the group cell
- (NSArray *)springBoardView:(FJSpringBoardView *)springBoardView imagesForGroupAtIndex:(NSUInteger)groupIndex;
- (UIImage *)springBoardView:(FJSpringBoardView *)springBoardView imageForCellAtIndex:(NSUInteger )index inGroupAtIndex:(NSUInteger)groupIndex;


- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index inGroupAtIndex:(NSUInteger)groupIndex;
- (void)springBoardView:(FJSpringBoardView *)springBoardView canAddCellAtIndex:(NSUInteger )fromIndex toGroupCellAtIndex:(NSUInteger )toIndex;
*/



@end



