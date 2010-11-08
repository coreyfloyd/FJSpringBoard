

#import <UIKit/UIKit.h>

#import "FJSpringBoardCell.h"
#import "FJIndexMap.h"

@class FJSpringBoardIndexLoader;
@class FJSpringBoardLayout;

@protocol FJSpringBoardViewDelegate;
@protocol FJSpringBoardViewDataSource;

typedef enum  {
    FJSpringBoardViewScrollDirectionVertical,
    FJSpringBoardViewScrollDirectionHorizontal
} FJSpringBoardViewScrollDirection;

@interface FJSpringBoardView : UIView <UIScrollViewDelegate> {

    UIScrollView* scrollView;
    UIView* contentView;
    
    UIEdgeInsets springBoardInsets;
    
    CGSize cellSize;
    
    FJSpringBoardViewScrollDirection scrollDirection;
    
    FJReorderingIndexMap* indexMap;
    FJSpringBoardIndexLoader* indexLoader;
    FJSpringBoardLayout *layout;
    
    NSMutableIndexSet *allIndexes;
        
    NSMutableIndexSet *indexesNeedingLayout;

    NSMutableIndexSet *indexesScrollingInView;
    NSMutableIndexSet *indexesScrollingOutOfView;
    
    NSMutableIndexSet *indexesToInsert;
    NSMutableIndexSet *indexesToDelete;
    
    NSMutableIndexSet *selectedIndexes;
    
    NSMutableArray *cells; 
    NSMutableSet *reusableCells; //reusable cells
    
    BOOL layoutIsDirty;

    BOOL doubleTapped;
    BOOL longTapped;

    FJSpringBoardCellAnimation layoutAnimation;
    
    FJSpringBoardCellMode mode;
    
    CGPoint lastTouchPoint;

    UIView* draggableCellView;
        
    NSUInteger indexOfHighlightedCell;
    FJSpringBoardGroupCell* floatingGroupCell;
}
//delegate and datasource
@property(nonatomic, assign) id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) id<FJSpringBoardViewDelegate, UIScrollViewDelegate> delegate;

//view setup, Call reload after changing to update the layout
@property(nonatomic) UIEdgeInsets springBoardInsets;

@property(nonatomic) CGSize cellSize;

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
- (NSUInteger)indexOfCellAtPoint:(CGPoint)point;

@property(nonatomic, retain, readonly) NSMutableArray *cells; 
@property(nonatomic, retain, readonly) NSIndexSet *visibleCellIndexes; 

//scroll
- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;

//paging, only valid if scrollingDirection == horizontal
- (NSUInteger)page;
- (NSUInteger)nextPage;
- (NSUInteger)previousPage;
- (BOOL)scrollToPage:(NSUInteger)page animated:(BOOL)animated;

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
- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasDoubleTappedAtIndex:(NSUInteger)index; //have some fun!!


@end



@protocol FJSpringBoardViewDataSource <NSObject>

- (NSUInteger)numberOfCellsInSpringBoardView:(FJSpringBoardView *)springBoardView;
- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index;


@optional
- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex;

- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger )index; 


//- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDeleteCellAtIndex:(NSUInteger )index;
//- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canSelectCellAtIndex:(NSUInteger )index; 
//- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canMoveCellAtIndex:(NSUInteger )index;






/*
 The following methods are @required to support groups
*/

- (FJSpringBoardGroupCell *)emptyGroupCellForSpringBoardView:(FJSpringBoardView *)springBoardView;

//called when a new group cell has been created
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitInsertingGroupCellAtIndex:(NSUInteger )index;

//called when adding items to group cells
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitAddingCellsAtIndexes:(NSIndexSet *)indexes toGroupCellAtIndex:(NSUInteger )toIndex;


//called to get the image to be displayed inside the group cell
- (UIImage *)springBoardView:(FJSpringBoardView *)springBoardView imageForCellAtIndex:(NSUInteger )index inGroupAtIndex:(NSUInteger)groupIndex;


//- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index inGroupAtIndex:(NSUInteger)groupIndex;
//- (void)springBoardView:(FJSpringBoardView *)springBoardView canAddCellAtIndex:(NSUInteger )fromIndex toGroupCellAtIndex:(NSUInteger )toIndex;





@end

@protocol FJSpringBoardViewGroupDataSource <NSObject>
@end




