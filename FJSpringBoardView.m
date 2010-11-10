
#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import "NSObject+Proxy.h"
#import <QuartzCore/QuartzCore.h>
#import "NSObject+Proxy.h"

#define DELETE_ANIMATION_DURATION 1.23
#define INSERT_ANIMATION_DURATION 1.25
#define RELOAD_ANIMATION_DURATION 0.75
#define LAYOUT_ANIMATION_DURATION 0.25

#define CREATE_GROUP_ANIMATION_DURATION 0.3
#define REMOVE_GROUP_ANIMATION_DURATION 0.3

#define EDGE_CUSHION 20.0

typedef enum  {
    FJSpringBoardViewEdgeNone,
    FJSpringBoardViewEdgeTop,
    FJSpringBoardViewEdgeRight,
    FJSpringBoardViewEdgeBottom,
    FJSpringBoardViewEdgeLeft
} FJSpringBoardViewEdge;

typedef enum  {
    FJSpringBoardDropActionNone,
    FJSpringBoardDropActionMove,
    FJSpringBoardDropActionAddToFolder
}FJSpringBoardDropAction; 


float nanosecondsWithSeconds(float seconds){
    
    return (seconds * 1000000000);
    
}

@interface FJSpringBoardCell(Internal)

@property(nonatomic, assign) FJSpringBoardView* springBoardView;


@end


@interface FJSpringBoardView()

@property(nonatomic, retain) UIScrollView *scrollView;
@property(nonatomic, retain) UIView *contentView;

@property(nonatomic, retain) FJSpringBoardIndexLoader *indexLoader;
@property(nonatomic, retain) FJSpringBoardLayout *layout;

@property(nonatomic, retain, readwrite) NSMutableArray *cells; 
@property(nonatomic, retain) NSMutableSet *reusableCells;

@property(nonatomic, retain) NSMutableIndexSet *allIndexes;
@property(nonatomic, retain) NSMutableIndexSet *onScreenCellIndexes; 

//used to process changes due to movement
@property(nonatomic, retain) NSMutableIndexSet *indexesScrollingInView; 
@property(nonatomic, retain) NSMutableIndexSet *indexesScrollingOutOfView; 

//used to process changes due to insertion/deletion
@property(nonatomic, retain) NSMutableIndexSet *indexesToInsert;
@property(nonatomic, retain) NSMutableIndexSet *indexesToDelete;

//indexes of cells with modified indexes due to insertion/deletion and need frame recallculations
@property(nonatomic, retain) NSMutableIndexSet *indexesNeedingLayout; 

@property(nonatomic) BOOL layoutIsDirty; //flag to indicate layout has changed requiring visible indexes and their frames to be recalculated

@property(nonatomic) FJSpringBoardCellAnimation layoutAnimation; //determines if changes should be animated

@property(nonatomic) BOOL doubleTapped; //flag to handle double tap irregularities
@property(nonatomic) BOOL longTapped; //flag to handle long tap irregularities

@property(nonatomic, retain) FJReorderingIndexMap* indexMap;
@property(nonatomic, retain) UIView *draggableCellView;
@property(nonatomic) BOOL animatingReorder; //flag to indicate a reordering animation is occuring


@property(nonatomic) BOOL animatingContentOffset; //flag to indicate a scrolling animation is occuring (due to calling setContentOffset:animated:)

@property(nonatomic) CGPoint lastTouchPoint;

@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;

@property(nonatomic, retain) FJSpringBoardGroupCell *floatingGroupCell;
@property(nonatomic) NSUInteger indexOfHighlightedCell;



- (void)_configureLayout;
- (void)_updateLayout;
- (void)_updateIndexes;


- (void)_setContentSize:(CGSize)size;
- (void)_resetAnimatingContentOffset;
//- (void)_setContentOffset:(CGPoint)offset animated:(BOOL)animate;
//- (void)_setContentOffset:(CGPoint)offset;

- (void)_loadCellsScrollingIntoViewAtIndexes:(NSIndexSet*)indexes;
- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_unloadCellsScrollingOutOfViewAtIndexes:(NSIndexSet*)indexes;
- (void)_removeCellsFromSpringBoardViewAtIndexes:(NSIndexSet*)indexes;
- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes withCompletionBlock:(dispatch_block_t)block;
- (void)_preLayoutIndexesComingIntoViewWhenAddingIndexes:(NSIndexSet*)indexes;
- (void)_removeIndexesGoingOutOfViewWhenAddingIndexes:(NSIndexSet*)indexes;

- (void)_deleteCellsAtIndexes:(NSIndexSet*)indexes withCompletionBlock:(dispatch_block_t)block;
- (void)_preLayoutIndexesComingIntoViewWhenRemovingIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes;

- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point checkOffScreenCells:(BOOL)flag;
- (CGRect)_frameForCellAtIndex:(NSUInteger)index checkOffScreenIndexes:(BOOL)flag;

//dragging and dropping
- (UIImage*)_createDraggableImageFromCell:(FJSpringBoardCell*)cell;
- (void)_makeCellDraggableAtTouchPoint:(CGPoint)point;
- (void)_handleDraggableCellWithTouchPoint:(CGPoint)point;
- (void)_completeDragAction;
- (NSUInteger)_coveredCellIndexWithObscuredContentFrame:(CGRect)contentFrame;
- (FJSpringBoardDropAction)_actionForCoveredCellIndex:(NSUInteger)index obscuredContentFrame:(CGRect)contentFrame;
- (void)_animateDraggableViewToCellIndex:(NSUInteger)index completionBlock:(dispatch_block_t)block;

//reordering
- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index;
- (void)_completeReorder;

//scrolling during reordering
- (BOOL)_scrollSpringBoardInDirectionOfEdge:(FJSpringBoardViewEdge)edge;
- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch;

//groups
- (void)_highlightGroupAtIndex:(NSUInteger)index;
- (void)_addCellsAtIndexes:(NSIndexSet*)cellIndexes toGroupAtIndex:(NSUInteger)groupIndex;
- (void)_createGroupCellFromCellAtIndex:(NSUInteger)index;
- (void)_completeGrouping;
- (void)_removeHighlight;

@end

@implementation FJSpringBoardView

@synthesize scrollView;
@synthesize contentView;

@synthesize dataSource;
@synthesize delegate;

@synthesize springBoardInsets;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;

@synthesize indexLoader;
@synthesize layout;

@synthesize cells;
@synthesize reusableCells;

@synthesize allIndexes;
@synthesize indexesScrollingInView;
@synthesize indexesNeedingLayout;
@synthesize indexesToDelete;
@synthesize indexesScrollingOutOfView;
@synthesize selectedIndexes;
@synthesize indexesToInsert;

@synthesize layoutIsDirty;
@synthesize layoutAnimation;

@synthesize doubleTapped;
@synthesize longTapped;

@synthesize indexMap;
@synthesize animatingReorder;
@synthesize draggableCellView;

@synthesize animatingContentOffset;

@synthesize lastTouchPoint;

@synthesize floatingGroupCell;
@synthesize indexOfHighlightedCell;




#pragma mark -
#pragma mark NSObject


- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [scrollView release];
    scrollView = nil;
    [contentView release];
    contentView = nil;    
    [floatingGroupCell release];
    floatingGroupCell = nil;    
    [indexMap release];
    indexMap = nil;    
    [draggableCellView release];
    draggableCellView = nil;    
    [allIndexes release];
    allIndexes = nil; 
    [indexesToInsert release];
    indexesToInsert = nil;
    [indexesScrollingOutOfView release];
    indexesScrollingOutOfView = nil;    
    [indexesScrollingInView release];
    indexesScrollingInView = nil;
    [indexesToDelete release];
    indexesToDelete = nil;
    [indexesNeedingLayout release];
    indexesNeedingLayout = nil;
    [selectedIndexes release];
    selectedIndexes = nil;    
    [cells release];
    cells = nil;
    [reusableCells release];
    reusableCells = nil;
    [layout release];
    layout = nil;
    [indexLoader release];
    indexLoader = nil;
    [super dealloc];
    
}

#pragma mark -
#pragma mark UIView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

        self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];
        
        self.contentView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
        [self.scrollView addSubview:self.contentView];
        
        self.indexLoader = [[[FJSpringBoardIndexLoader alloc] init] autorelease];
        
        self.allIndexes = [NSMutableIndexSet indexSet];
        self.indexesScrollingInView = [NSMutableIndexSet indexSet];
        self.indexesNeedingLayout = [NSMutableIndexSet indexSet];
        self.selectedIndexes = [NSMutableIndexSet indexSet];
        self.indexesToInsert = [NSMutableIndexSet indexSet];
        self.indexesToDelete = [NSMutableIndexSet indexSet];
        self.indexesScrollingOutOfView = [NSMutableIndexSet indexSet];
        self.cells = [NSMutableArray array];
        self.reusableCells = [NSMutableSet set];

        self.indexOfHighlightedCell = NSNotFound;
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
        
        UITapGestureRecognizer* d = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
        d.numberOfTapsRequired = 2;
        [self addGestureRecognizer:d];
        
        UITapGestureRecognizer* t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
        [t requireGestureRecognizerToFail:d];
        [self addGestureRecognizer:t];
        
        UILongPressGestureRecognizer* l = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTap:)];
        l.minimumPressDuration = 0.1;
        [self addGestureRecognizer:l];
        
       
        
    }
    return self;
}


#pragma mark -
#pragma mark External Info Methods

- (NSUInteger)numberOfCells{
    
    return [self.allIndexes count];
    
}


- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([[NSNull null] isEqual:(NSNull*)cell])
        return nil;
    
    return cell;
}


- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell{
    
    NSUInteger i = [self.cells indexOfObject:cell];
    
    return i;
    
}

- (CGRect)frameForCellAtIndex:(NSUInteger)index{
    
    return [self _frameForCellAtIndex:index checkOffScreenIndexes:NO];
    
}

- (CGRect)_frameForCellAtIndex:(NSUInteger)index checkOffScreenIndexes:(BOOL)flag{
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([[NSNull null] isEqual:(NSNull*)cell]){
        
        if(flag)
            return [self.layout frameForCellAtIndex:index];
        else
            return CGRectZero; 
        
    }
    
    return cell.frame;
    
}


- (NSUInteger)indexOfCellAtPoint:(CGPoint)point{
    
    return [self _indexOfCellAtPoint:point checkOffScreenCells:YES];
    
}


- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point checkOffScreenCells:(BOOL)flag{
    
    NSIndexSet* a = [self.cells indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* c = (FJSpringBoardCell*)obj;
        
        if([c isEqual:[NSNull null]]){
            
            if(flag){
                
                CGRect f = [self.layout frameForCellAtIndex:idx];
                if(CGRectContainsPoint(f, point))
                    return YES;
                
            }
            
            return NO;
            
        }
        
        if(CGRectContainsPoint(c.frame, point)){
            *stop = YES;
            return YES;
            
        }
        
        return NO;
        
    }];
    
    if([a count] == 0)
        return NSNotFound;
    
    return [a firstIndex];
    
}


- (NSIndexSet*)visibleCellIndexes{
    
    return [[self.indexLoader.currentIndexes copy] autorelease];

}

- (NSMutableIndexSet*)onScreenCellIndexes{
    
    return self.indexLoader.currentIndexes;
}

- (void)setOnScreenCellIndexes:(NSMutableIndexSet *)indexes{
    
    self.indexLoader.currentIndexes = indexes;
}


#pragma mark -
#pragma mark Scroll Support

- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated{
    
    CGRect f =  [self _frameForCellAtIndex:index checkOffScreenIndexes:YES];
    
    //TODO: support scroll positions?
    [self.scrollView scrollRectToVisible:f animated:animated];
    
}

#pragma mark -
#pragma mark Reuse Dequeued Cell

- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier{
    
    if([self.reusableCells count] == 0)
        return nil;
    
    NSSet* c = [self.reusableCells objectsWithOptions:NSEnumerationConcurrent passingTest:^(id obj, BOOL *stop) {
        
        FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
        if([cell.reuseIdentifier isEqualToString:identifier]){
            *stop = YES;
            return YES;
        }
        
        return NO;
        
    }];
    
    FJSpringBoardCell* cell = [[[c anyObject] retain] autorelease];
    
    if(cell == nil)
        return nil;
    
    [self.reusableCells removeObject:cell];
    
    return cell;
    
}


#pragma mark -
#pragma mark Reload

- (void)reloadData{
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _unloadCellsScrollingOutOfViewAtIndexes:self.onScreenCellIndexes];
    self.cells = nullArrayOfSize([self.allIndexes count]);
    self.indexMap = [[FJReorderingIndexMap alloc] initWithArray:self.cells];
    
    [self _configureLayout]; //triggers _updateCells and _updateIndexes
}



#pragma mark -
#pragma mark configure layout

//only called on reload
- (void)_configureLayout{
      
    if(scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        self.layout = [[[FJSpringBoardHorizontalLayout alloc] init] autorelease];
        self.scrollView.pagingEnabled = YES;
    }else{
        self.layout = [[[FJSpringBoardVerticalLayout alloc] init] autorelease];
        self.scrollView.pagingEnabled = NO;
    }
    
    self.indexLoader.layout = self.layout;
        
    [self _updateLayout];
}

//called when changes occur affecting layout
- (void)_updateLayout{
    
    self.layoutIsDirty = YES;

    self.layout.springBoardbounds = self.bounds;
    self.layout.insets = self.springBoardInsets;
    self.layout.cellSize = self.cellSize;
    
    self.layout.cellCount = [self.allIndexes count];
    
    [self.layout updateLayout];
    
    if(self.layoutAnimation != FJSpringBoardCellAnimationNone){
        
        [UIView animateWithDuration:0.25 animations:^(void) {
                
            [self _setContentSize:self.layout.contentSize];

        }];
        
        
    }else{
        
        [self _setContentSize:self.layout.contentSize];

    }
    
    if(self.layoutIsDirty)
        [self _updateIndexes];
    
}


#pragma mark -
#pragma mark UIScrollView

/*
- (void)_setContentOffset:(CGPoint)offset{
    
    [self.scrollView setContentOffset:offset];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];

    });
}

- (void)_setContentOffset:(CGPoint)offset animated:(BOOL)animate{
    
    self.animatingContentOffset = YES;
    self.lastContentOffset = self.scrollView.contentOffset;
    
	[self.scrollView setContentOffset: offset animated: animate];  
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_contentOffsetAnimationCheck:) userInfo:nil repeats:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];
        
    });    
}

*/


- (void)_setContentSize:(CGSize)size{
    
    if(!CGSizeEqualToSize(size, self.scrollView.contentSize)){
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self.scrollView flashScrollIndicators];

        });
    }
    
    self.scrollView.contentSize = size;
    CGRect f = CGRectMake(0, 0, size.width, size.height);
    self.contentView.frame = f;
    [self.scrollView setContentSize:size];
    
}


- (void)_resetAnimatingContentOffset{
    
    self.animatingContentOffset = NO;
    
}

#pragma mark -
#pragma mark UIScrollViewDelegate



- (void)scrollViewDidScroll:(UIScrollView *)sView{
    
    self.animatingContentOffset = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_resetAnimatingContentOffset) object:nil];
    [self performSelector:@selector(_resetAnimatingContentOffset) withObject:nil afterDelay:0.1];

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];
        
    });
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewDidScroll:sView];
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sView{
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewDidEndScrollingAnimation:sView];
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)sView{
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewWillBeginDragging:scrollView];
    
}
- (void)scrollViewDidEndDragging:(UIScrollView *)sView willDecelerate:(BOOL)decelerate{
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewDidEndDragging:scrollView willDecelerate:decelerate];

}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)sView{
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewWillBeginDecelerating:sView];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sView{
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewDidEndDecelerating:sView];
}


- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)sView{
    
    return [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewShouldScrollToTop:sView];
    
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)sView{
    
    [[(NSObject*)self.delegate performIfRespondsToSelectorProxy] scrollViewDidScrollToTop:sView];

}




#pragma mark -
#pragma mark Update Indexes

- (void)_updateIndexes{
    
    if(indexLoader == nil)
        return;
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.scrollView.contentOffset];
    
    NSRange rangeToRemove = changes.indexRangeToRemove;
    
    NSRange rangeToLoad = changes.indexRangeToAdd;
    
    if([self.onScreenCellIndexes count] > 0 && !indexesAreContinuous(self.onScreenCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    //check maths, newI == oldI - removed + added    
    [self.indexesScrollingOutOfView addIndexesInRange:rangeToRemove];
    
    [self.indexesScrollingInView addIndexesInRange:rangeToLoad];
    
    //unload cells that are no longer "visible"
    [self _unloadCellsScrollingOutOfViewAtIndexes:[self.indexesScrollingOutOfView copy]];
    
    //load cells that are now visible
    [self _loadCellsScrollingIntoViewAtIndexes:[self.indexesScrollingInView copy]];
    
    if([self.cells count] != [self.allIndexes count]){
        
        ALWAYS_ASSERT;
    }
    
    [self.cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
        
        if(![cell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        cell.alpha = 1;
        
    }];
         
    self.layoutIsDirty = NO;

}

#pragma mark -
#pragma mark Load / Unload Cells


- (void)_loadAllCellsScrollingIntoView{
    
    [self _loadCellsScrollingIntoViewAtIndexes:[[self.indexesScrollingInView copy] autorelease]];
    [self.indexesScrollingInView removeAllIndexes];
    
}


- (void)_loadCellsScrollingIntoViewAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    //remove existing cells from view
    [self _removeCellsFromSpringBoardViewAtIndexes:indexes];
    
    //unload them (placed in reusable pool)
    [self _unloadCellsAtIndexes:indexes];
    
    //create and insert in array
    [self _loadCellsAtIndexes:indexes];
    
    //set frame and add to view
    [self _layoutCellsAtIndexes:indexes];
    
    [self.indexesScrollingInView removeIndexes:indexes];
    
}


- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSIndexSet* actualIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
    
        if([self.allIndexes containsIndex:idx])
            return YES;
        return NO;
    
    }];
    
    [actualIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
       
        NSUInteger realIndex = [self.indexMap oldIndexForNewIndex:index];
        
        FJSpringBoardCell* cell = [self.dataSource springBoardView:self cellAtIndex:realIndex];
        [cell retain];
        
        cell.springBoardView = self;
        
        [self.cells replaceObjectAtIndex:index withObject:cell];
        [cell release];
        
    }];

}


- (void)_loadAllCellsScrollingOutOfView{
    
    [self _unloadCellsScrollingOutOfViewAtIndexes:[[self.indexesScrollingOutOfView copy] autorelease]];
    [self.indexesScrollingOutOfView removeAllIndexes];
    
}


- (void)_unloadCellsScrollingOutOfViewAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    [self _removeCellsFromSpringBoardViewAtIndexes:indexes];
    
    [self _unloadCellsAtIndexes:indexes];
    
    [self.indexesScrollingOutOfView removeIndexes:indexes];        
    
    if([self.indexesScrollingOutOfView count] > 0){
        
        ALWAYS_ASSERT;
    }
}


- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.allIndexes containsIndex:index]){
            
            return;
        }
        
        //don't unload the index we are reordering
        FJReorderingIndexMap* im = (FJReorderingIndexMap*)self.indexMap;
        if([im isKindOfClass:[FJReorderingIndexMap class]]){
            
            if(index == im.currentReorderingIndex)
                return;
        }
        
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        [self.reusableCells addObject:eachCell];
        [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
        
        
    }];
    
}

#pragma mark -
#pragma mark layout / remove cells from view


- (void)_layoutAllCellsNeedingLayout{
    
    [self _layoutCellsAtIndexes:[[self.indexesNeedingLayout copy] autorelease]];
    [self.indexesNeedingLayout removeAllIndexes];
    
}

- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSIndexSet* actualIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if([self.allIndexes containsIndex:idx])
            return YES;
        return NO;
        
    }];

    [actualIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
    
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            return;
        }
        
        eachCell.mode = self.mode;

        //NSLog(@"Laying Out Cell %i", index);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        [self.contentView addSubview:eachCell];
        
    }];
}


- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes{
    
    __block NSUInteger positionIndex = [positionIndexes firstIndex];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.allIndexes containsIndex:index])
            return;
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        eachCell.mode = self.mode;
        
        //NSLog(@"Laying Out Cell At Index %i in Old Index Position %i", index, positionIndex);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:positionIndex];
        eachCell.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        [self.contentView addSubview:eachCell];
        
        positionIndex = [positionIndexes indexGreaterThanIndex:positionIndex];
        
    }];
}


- (void)_removeCellsFromSpringBoardViewAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.allIndexes containsIndex:index]){
        
            return;
        }
        
        //don't remove the index we are reordering
        FJReorderingIndexMap* im = (FJReorderingIndexMap*)self.indexMap;
        if([im isKindOfClass:[FJReorderingIndexMap class]]){
            
            if(index == im.currentReorderingIndex)
                return;
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        //NSLog(@"Removing Cell From View %i", index);
        //RECTLOG(eachCell.frame);
        
        [eachCell removeFromSuperview];
        [eachCell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
        eachCell.mode = FJSpringBoardCellModeNormal;
        //RECTLOG(eachCell.frame);
        
    }];
    
}

#pragma mark -
#pragma mark Reload Specific Indexes


- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self _unloadCellsScrollingOutOfViewAtIndexes:indexSet];
    
    //load: create and insert in array
    [self _loadCellsAtIndexes:indexSet];
    
    //set frame and add to view
    [self _layoutCellsAtIndexes:indexSet];
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.onScreenCellIndexes containsIndex:index]){
            
            return;
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        eachCell.alpha = 0;
        
        [UIView animateWithDuration:RELOAD_ANIMATION_DURATION 
                              delay:DELETE_ANIMATION_DURATION 
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^(void) {
                             
                             eachCell.alpha = 1;
                             
                         } completion:^(BOOL finished) {
                             
                             
                             
                             
                         }];
        
        
    }];
    
}




#pragma mark -
#pragma mark Insert Cells
//3 situations, indexset in vis range, indexset > vis range, indexset < vis range

- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    if([indexSet count] == 0)
        return;
    
    
    NSUInteger firstIndex = [indexSet firstIndex];
    
    //TODO: check all indexes
    if(firstIndex > [self.allIndexes lastIndex] + 1){
        
        ALWAYS_ASSERT;
    }
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    if(numOfCells != [allIndexes count] + [indexSet count]){
        
        ALWAYS_ASSERT; //num != pervios count + number added 
    } 
    
    [self.indexesToInsert addIndexes:indexSet];

    self.layoutAnimation = animation; //reset on next layout update
    
    [self _insertCellsAtIndexes:indexSet withCompletionBlock:^{
        
        [self.indexesToInsert removeIndexes:indexSet];
        self.layoutAnimation = FJSpringBoardCellAnimationNone;

        
    }];
            
}



- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes withCompletionBlock:(dispatch_block_t)block{
    
    if([indexes count] == 0)
        return;
    
    [self _preLayoutIndexesComingIntoViewWhenAddingIndexes:indexes];
    
    NSIndexSet* toLayout = [self.indexMap modifiedIndexesByAddingCellsAtIndexes:indexes];
    [self.indexesNeedingLayout addIndexes:toLayout];

    for(int i = 0; i < [indexes count]; i++)
        [self.allIndexes addIndex:([self.allIndexes lastIndex]+1)];

    [self.indexMap commitChanges];

    //load
    [self _loadCellsAtIndexes:indexes];
    
    //add to view
    [self _layoutCellsAtIndexes:indexes];
    
    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){
             
        [self _layoutAllCellsNeedingLayout];
        [self _removeIndexesGoingOutOfViewWhenAddingIndexes:indexes];

        [self _updateLayout];
        block();               
        return;
    }
    
    self.userInteractionEnabled = NO; 

    //fade in
    
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        eachCell.alpha = 0;
        
        
    }];
    
    [UIView animateWithDuration:INSERT_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut  
                     animations:^(void) {
                         
                         [self _layoutAllCellsNeedingLayout];
                         
                         [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
                             
                             FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
                             eachCell.alpha = 1;
                             
                             
                         }];
                                                  
                     } completion:^(BOOL finished) {
                         
                         [self _removeIndexesGoingOutOfViewWhenAddingIndexes:indexes];
                         self.userInteractionEnabled = YES;
                         
                         [self _updateLayout];
                         block();               
                         
                     }];
    
}




- (void)_preLayoutIndexesComingIntoViewWhenAddingIndexes:(NSIndexSet*)indexes{
    
    //indexes we need to bring on screen due to the deletion
    //get indexes that are scrolling on screen if all deleted indexes were already on screen, then we need to scroll on [indexSet count]
    //otherwise we only scroll on x = number of cells in deleted indexes contained in onscreen indexes
    
    NSUInteger firstVisIndex = [self.onScreenCellIndexes firstIndex];
    
    NSIndexSet* releventIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if(idx < firstVisIndex)
            return YES;
        
        return NO;
        
    }];
    
    NSRange newRangeToLoadAndLayout = NSMakeRange([self.onScreenCellIndexes firstIndex] - [releventIndexes count], [releventIndexes count]);
    NSIndexSet* newIndexesToLoadAndLayout = [NSIndexSet indexSetWithIndexesInRange:newRangeToLoadAndLayout]; 
    
    [self _loadCellsAtIndexes:newIndexesToLoadAndLayout];
    [self _layoutCellsAtIndexes:newIndexesToLoadAndLayout];
    
}





- (void)_removeIndexesGoingOutOfViewWhenAddingIndexes:(NSIndexSet*)indexes{
    
    NSUInteger lastVisIndex = [self.onScreenCellIndexes lastIndex];
    
    NSIndexSet* releventIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if(idx > lastVisIndex)
            return NO;
        
        return YES;
        
    }];
    
    NSRange newRangeToPushAndRemove = NSMakeRange([self.onScreenCellIndexes lastIndex] + 1, [releventIndexes count]);
    NSIndexSet* newIndexesToPushAndRemove = [NSIndexSet indexSetWithIndexesInRange:newRangeToPushAndRemove]; 
    
    [self _unloadCellsScrollingOutOfViewAtIndexes:newIndexesToPushAndRemove];
    
}





#pragma mark -
#pragma mark Delete Cells

- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    if([indexSet count] == 0)
        return;
    
    NSIndexSet* idxs = [indexSet indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        return [self.allIndexes containsIndex:idx];
        
    }];
    
    if([idxs count] != [indexSet count]){
        
        ALWAYS_ASSERT;
    }   
    
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    if(numOfCells != [allIndexes count] - [indexSet count]){
        
        ALWAYS_ASSERT; //num != pervios count - number deleted 
    } 

    [self.indexesToDelete addIndexes:indexSet];

    self.layoutAnimation = animation; //reset on next layout update

    [self _deleteCellsAtIndexes:[[self.indexesToDelete copy] autorelease] withCompletionBlock:^{
        
        [self.indexesToDelete removeAllIndexes];
        self.layoutAnimation = FJSpringBoardCellAnimationNone;
        
    }];

       
}


- (void)_deleteCell:(FJSpringBoardCell*)cell{
    
    NSUInteger index = [self.cells indexOfObject:cell];
    
    if(index == NSNotFound){
        ALWAYS_ASSERT;
        return;
    }
    
    
    if(![self.allIndexes containsIndex:index]){
        
        ALWAYS_ASSERT;
        return;
    }
    
    [self.indexesToDelete addIndexes:[NSIndexSet indexSetWithIndex:index]];
    
    self.layoutAnimation = FJSpringBoardCellAnimationFade; //reset on next layout update
    
    [self _deleteCellsAtIndexes:[[self.indexesToDelete copy] autorelease] withCompletionBlock:^{
        
        [self.indexesToDelete removeAllIndexes];
        self.layoutAnimation = FJSpringBoardCellAnimationNone;
        
        NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];

        [[(NSObject*)self.dataSource performIfRespondsToSelectorProxy] springBoardView:self commitDeletionForCellAtIndexes:[NSIndexSet indexSetWithIndex:index]];
        
        NSUInteger newNumOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
        
        if(numOfCells - 1 != newNumOfCells){
            
            ALWAYS_ASSERT; //num != pervios count - number deleted 
        } 
        
    }];
    
}


- (void)_deleteCellsAtIndexes:(NSIndexSet*)indexes withCompletionBlock:(dispatch_block_t)block{
    
    if([indexes count] == 0)
        return;
    
    [self _preLayoutIndexesComingIntoViewWhenRemovingIndexes:indexes];
    
    NSArray* cellsToDelete = [[self.cells objectsAtIndexes:indexes] retain];
    
    NSIndexSet* toLayout = [self.indexMap modifiedIndexesByRemovingCellsAtIndexes:indexes];
    
    [self.indexesNeedingLayout addIndexes:toLayout];
    
    for(int i = 0; i < [indexes count]; i++)
        [self.allIndexes removeIndex:[self.allIndexes lastIndex]];
    
    
    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){
        
        [self _layoutAllCellsNeedingLayout];

        [cellsToDelete enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
            
            if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                
                return;
            }
            
            [cell removeFromSuperview];
            [cell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
            [self.reusableCells addObject:cell];
            cell.alpha = 1;
            
        }];
        
        [self _updateLayout];
        [self.indexMap commitChanges];
        block();                         

        return;
    }
    
    self.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^(void) {
                         
                         [self _layoutAllCellsNeedingLayout];
                         
                         [cellsToDelete enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }                                 
                             cell.alpha = 0;
                             
                         }];
                         
                     } 
                     completion:^(BOOL finished) {
                         
                         [cellsToDelete enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }
                             
                             [cell removeFromSuperview];
                             [cell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
                             [self.reusableCells addObject:cell];
                             cell.alpha = 1;
                             
                         }];
                         
                         //TODO: remove newly offscreen cells
                         
                         [self _updateLayout];
                         self.userInteractionEnabled = YES;
                         [self.indexMap commitChanges];
                         
                         block();                         
                         
                     }];
    
    
}


- (void)_preLayoutIndexesComingIntoViewWhenRemovingIndexes:(NSIndexSet*)indexes{
    
    //indexes we need to bring on screen due to the deletion
    //get indexes that are scrolling on screen if all deleted indexes were already on screen, then we need to scroll on [indexSet count]
    //otherwise we only scroll on x = number of cells in deleted indexes contained in onscreen indexes
    
    NSUInteger lastVisIndex = [self.onScreenCellIndexes lastIndex];
    
    NSIndexSet* releventDeletedIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
    
        if(idx > lastVisIndex)
            return NO;
        
        return YES;
        
    }];
    
    NSRange newRangeToLoadAndLayout = NSMakeRange([self.onScreenCellIndexes lastIndex] + 1, [releventDeletedIndexes count]);
    NSIndexSet* newIndexesToLoadAndLayout = [NSIndexSet indexSetWithIndexesInRange:newRangeToLoadAndLayout]; 
    
    [self _loadCellsAtIndexes:newIndexesToLoadAndLayout];
    [self _layoutCellsAtIndexes:newIndexesToLoadAndLayout];

}


#pragma mark -
#pragma mark Mode


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
    if(mode == aMode)
        return;
        
    mode = aMode;
    
    [self.cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
        FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;

        if(![cell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        cell.mode = mode;
        
    }];
    
}



#pragma mark -
#pragma mark Touches

- (void)didSingleTap:(UITapGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self.contentView];
    self.lastTouchPoint = p;

    if(self.mode != FJSpringBoardCellModeNormal)
        return;
    
    NSUInteger indexOfCell = [self indexOfCellAtPoint:p];
    
    if(indexOfCell == NSNotFound)
        return;
    
    if([delegate respondsToSelector:@selector(springBoardView:cellWasTappedAtIndex:)])
        [delegate springBoardView:self cellWasTappedAtIndex:indexOfCell];
    
}



- (void)didDoubleTap:(UITapGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self.contentView];
    self.lastTouchPoint = p;
    
    if(self.mode != FJSpringBoardCellModeNormal)
        return;
    
    if(doubleTapped){
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_resetDoubleTapped) object:nil];
        
        [self performSelector:@selector(_resetDoubleTapped) withObject:nil afterDelay:0.5];
        
        return;
    }

    NSUInteger indexOfCell = [self indexOfCellAtPoint:p];
    
    if(indexOfCell == NSNotFound)
        return;
    
    self.doubleTapped = YES;
    [self performSelector:@selector(_resetDoubleTapped) withObject:nil afterDelay:0.5];
    
    if([delegate respondsToSelector:@selector(springBoardView:cellWasDoubleTappedAtIndex:)]){
        
        [delegate springBoardView:self cellWasDoubleTappedAtIndex:indexOfCell];
        
        
    }
    
}

- (void)_resetDoubleTapped{
    
    self.doubleTapped = NO;
}


- (void)didLongTap:(UILongPressGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self];
    self.lastTouchPoint = p;
    
    if(self.longTapped){
        
        NSLog(@"still long tapped");

        if(g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled){
            
            self.longTapped = NO;
        }
        
        return;
    }
    
    //don't do anything if we are in the middle of scrolling animation
    if(self.animatingContentOffset)
        return;

    if(self.mode == FJSpringBoardCellModeNormal){
        
        if(g.state == UIGestureRecognizerStateBegan){
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_completeDragAction) object:nil];

            CGPoint contentPoint = [g locationInView:self.contentView];
            
            NSUInteger indexOfCell = [self indexOfCellAtPoint:contentPoint];
            
            if(indexOfCell != NSNotFound)
                self.mode = FJSpringBoardCellModeEditing;
            
            self.longTapped = YES;    
            
            NSLog(@"long tapped");
            
            [self performSelector:@selector(_startDragging) withObject:nil afterDelay:0.25];
            
            [self performSelector:@selector(_completeDragAction) withObject:nil afterDelay:4.0];


        }

        return;
    }
    
    
    if(self.mode == FJSpringBoardCellModeEditing){
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_completeDragAction) object:nil];
        
        if(g.state == UIGestureRecognizerStateBegan){
            
            [self _makeCellDraggableAtTouchPoint:p];
            
            [self performSelector:@selector(_completeDragAction) withObject:nil afterDelay:4.0];
            
            return;
        }
        
        if(g.state == UIGestureRecognizerStateChanged){
                        
            self.draggableCellView.center = p;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(0.25)), dispatch_get_main_queue(), ^{
                           
                if(fabsf(p.x - self.lastTouchPoint.x) < 5 && (fabsf(p.y - self.lastTouchPoint.y) < 5))
                    [self _handleDraggableCellWithTouchPoint:p];       

            });
            
            [self performSelector:@selector(_completeDragAction) withObject:nil afterDelay:4.0];
    
            return;
        }
        
        if(g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled){
            
            [self _completeDragAction];
            
            return;
        }
        
        return;
    }
    
}


#pragma mark -
#pragma mark Touch Point Scrolling

- (BOOL)_scrollSpringBoardInDirectionOfEdge:(FJSpringBoardViewEdge)edge{
        
    NSLog(@"edge!");
    
    if(edge == FJSpringBoardViewEdgeNone)
        return NO;
    
    if(self.scrollDirection == FJSpringBoardViewScrollDirectionVertical){
        
        if(edge == FJSpringBoardViewEdgeTop){
            
            return NO;
            
            
        }else if(edge == FJSpringBoardViewEdgeBottom){
         
            return NO;
            
        }
        
    }else{
        
        
        if(edge == FJSpringBoardViewEdgeLeft){
            
            NSUInteger prevPage = [self previousPage];
            
            if(prevPage == NSNotFound)
                return NO;
           
            [self scrollToPage:prevPage animated:YES];
                        
            
        }else if(edge == FJSpringBoardViewEdgeRight){
            
            NSUInteger nextPage = [self nextPage];
            
            if(nextPage == NSNotFound)
                return NO;
            
            [self scrollToPage:nextPage animated:YES];
            
        }
        
    }
    
    
    return YES;
}



- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch{
    
    CGRect f = self.bounds;
    
    CGRect centerFrame = CGRectInset(f, EDGE_CUSHION, EDGE_CUSHION);
    
    if(CGRectContainsPoint(centerFrame, touch))
        return FJSpringBoardViewEdgeNone;
    
    CGRect top = CGRectMake(f.origin.x+EDGE_CUSHION, f.origin.y, f.size.width-(2*EDGE_CUSHION), EDGE_CUSHION);
    
    if(CGRectContainsPoint(top, touch))
        return FJSpringBoardViewEdgeTop;
    
    CGRect right = CGRectMake(f.origin.x+f.size.width-EDGE_CUSHION, f.origin.y+EDGE_CUSHION, EDGE_CUSHION, f.size.height-(2*EDGE_CUSHION));
    
    if(CGRectContainsPoint(right, touch))
        return FJSpringBoardViewEdgeRight;
    
    CGRect bottom = CGRectMake(f.origin.x + EDGE_CUSHION, f.origin.y+f.size.height-EDGE_CUSHION, f.size.width-(2*EDGE_CUSHION), EDGE_CUSHION);
    
    if(CGRectContainsPoint(bottom, touch))
        return FJSpringBoardViewEdgeBottom;
    
    CGRect left = CGRectMake(f.origin.x, f.origin.y+EDGE_CUSHION, EDGE_CUSHION, f.size.height-(2*EDGE_CUSHION));    
    
    if(CGRectContainsPoint(left, touch))
        return FJSpringBoardViewEdgeLeft;
    
    
    return FJSpringBoardViewEdgeNone;
}


#pragma mark -
#pragma mark Draggable Cell


- (void)_startDragging{
    
    NSLog(@"long tapped = NO");
    
    self.longTapped = NO;
    
    [self _makeCellDraggableAtTouchPoint:self.lastTouchPoint];
    
}

- (void)_makeCellDraggableAtTouchPoint:(CGPoint)point{
    
    if(self.draggableCellView != nil)
        return;
    
    
    CGPoint contentPoint = [self convertPoint:point toView:self.contentView];
    
    NSUInteger index = [self indexOfCellAtPoint:contentPoint];

    if(index == NSNotFound)
        return;
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([cell isEqual:[NSNull null]]){
        
        ALWAYS_ASSERT;
    }
    
    //start reordering
    [self.indexMap beginReorderingIndex:index];
    
    //create imageview to animate
    UIImage* i = [self _createDraggableImageFromCell:cell];
    UIImageView* iv = [[UIImageView alloc] initWithImage:i];
    iv.frame = cell.frame;
    iv.center = [self convertPoint:cell.center fromView:self.contentView];
    self.draggableCellView = iv;
    [self addSubview:iv];
    [iv release];
    
    //notify cell it is being reordered. power of… invisibility!
    cell.reordering = YES;
    
    [UIView animateWithDuration:0.2 
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                     
                         self.draggableCellView.alpha = 0.8;
                         self.draggableCellView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                     
                     } 
                     
                     completion:^(BOOL finished) {
                     
                         
                     
                     }];

}

- (UIImage*)_createDraggableImageFromCell:(FJSpringBoardCell*)cell{
    
    UIView* cellView = cell;
    
    UIGraphicsBeginImageContext(cellView.bounds.size);
    [cellView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
    
}

- (void)_handleDraggableCellWithTouchPoint:(CGPoint)point{
        
    
    //check if we need to scroll the view
    FJSpringBoardViewEdge e = [self _edgeOfViewAtTouchPoint:point];
    
    //CGPoint contentPoint = [self convertPoint:point toView:self.contentView];
    
    if(e == FJSpringBoardViewEdgeNone){
         
        //don't do anything if we are in the middle of a reordering animation
        if(self.animatingReorder)
            return;    
        
        CGRect adjustedFrame = [self convertRect:self.draggableCellView.frame toView:self.contentView];
        
        //if not, lets check to see if we need to reshuffle
        NSUInteger index = [self _coveredCellIndexWithObscuredContentFrame:adjustedFrame];
        
        if(index == NSNotFound){
         
            [self _removeHighlight];
            
            return;

        }
        FJSpringBoardDropAction a = [self _actionForCoveredCellIndex:index obscuredContentFrame:adjustedFrame];
        
        if(a == FJSpringBoardDropActionMove)
            [self _reorderCellsByUpdatingPlaceHolderIndex:index];
        else if(a == FJSpringBoardDropActionAddToFolder)
            [self _highlightGroupAtIndex:index];
        else
            [self _removeHighlight];
        
    }else{
        
        [self _scrollSpringBoardInDirectionOfEdge:e];
        
        CGPoint savedPoint = self.lastTouchPoint;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(0.7)), dispatch_get_main_queue(), ^{
            
            if(CGPointEqualToPoint(savedPoint, self.lastTouchPoint))
                [self _scrollSpringBoardInDirectionOfEdge:e];
            
        });

    }
    
}


- (FJSpringBoardDropAction)_actionForCoveredCellIndex:(NSUInteger)index obscuredContentFrame:(CGRect)contentFrame{
    
    if(index == self.indexMap.currentReorderingIndex)
        return FJSpringBoardDropActionNone;
    
    if(![self.dataSource respondsToSelector:@selector(emptyGroupCellForSpringBoardView:)])
        return FJSpringBoardDropActionMove;
    
    CGRect insetRect = CGRectInset(contentFrame, 
                                   0.15*contentFrame.size.width, 
                                   0.15*contentFrame.size.height);
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    CGRect rect = CGRectIntersection(insetRect, cell.frame);
    float area = rect.size.width * rect.size.height;
    float totalArea = cell.contentView.frame.size.width * cell.contentView.frame.size.height;
    
    
    if(area/totalArea > .65){
        return FJSpringBoardDropActionAddToFolder;
    }
    
    return FJSpringBoardDropActionMove;
    
}

- (NSUInteger)_coveredCellIndexWithObscuredContentFrame:(CGRect)contentFrame{
    
    CGRect insetRect = CGRectInset(contentFrame, 
                                   0.15*contentFrame.size.width, 
                                   0.15*contentFrame.size.height);
    
    NSMutableIndexSet* coveredIndexes = [NSMutableIndexSet indexSet];
    
    [self.cells enumerateObjectsAtIndexes:self.onScreenCellIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
        FJSpringBoardCell* c = (FJSpringBoardCell*)obj;
        
        if([c isEqual:[NSNull null]]){
            
            //ALWAYS_ASSERT;
            return;
        }        
        
        CGRect f = c.frame;
        if(CGRectIntersectsRect(insetRect, f)){
            [coveredIndexes addIndex:idx];
        }
        
    }];
    
    if ([coveredIndexes firstIndex] == NSNotFound) {
        return NSNotFound;
    }
    
    //NSLog(@"potential places to move: %@", [coveredIndexes description]);
    
    
    __block NSUInteger bestMatch = NSNotFound;
    __block float coveredArea = 0;
    
    [coveredIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        FJSpringBoardCell* cell = [self.cells objectAtIndex:idx];
        CGRect rect = CGRectIntersection(insetRect, cell.frame);
        float area = rect.size.width * rect.size.height;
        
        if(area > coveredArea){
            coveredArea = area;
            bestMatch = idx;
        }
        
    }];
    
    if(bestMatch == NSNotFound){
        
        ALWAYS_ASSERT;
    }
    
    return bestMatch;
}


- (void)_completeDragAction{
    
    if(self.animatingReorder)
        return;
    
    if(self.indexOfHighlightedCell == NSNotFound){
        
        [self _completeReorder];
        
    }else{
        
        [self _completeGrouping];
        
    }
}


- (void)_animateDraggableViewToCellIndex:(NSUInteger)index completionBlock:(dispatch_block_t)block{
    
    UIView* v = [self.draggableCellView retain];
    self.draggableCellView = nil;
    
    [UIView animateWithDuration:0.3 
                          delay:0.1 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^(void) {
                         
                         v.alpha = 1.0;
                         v.transform = CGAffineTransformIdentity;
                         CGRect f = [self _frameForCellAtIndex:index checkOffScreenIndexes:NO];
                         f = [self convertRect:f fromView:self.contentView];
                         v.frame = f;
                         
                     } 
     
                     completion:^(BOOL finished) {
                         
                         [v removeFromSuperview];
                         [v release];
                         
                         block();
                         
                     }];
    
}


#pragma mark -
#pragma mark Reorder

- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index{
    
    if(index == NSNotFound)
        return;
    
    [self _removeHighlight];

    self.animatingReorder = YES;
    FJReorderingIndexMap* im = (FJReorderingIndexMap*)self.indexMap;

    NSIndexSet* affectedIndexes = [im modifiedIndexesByMovingReorderingCellToCellAtIndex:index];
    
    [UIView animateWithDuration:LAYOUT_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut  
                     animations:^(void) {
                         
                         [self _layoutCellsAtIndexes:affectedIndexes];                        
                                                                                                   
                     } completion:^(BOOL finished) {
                         
                         self.animatingReorder = NO;
                         //update layout, cell count, content size, index loader, etc
                         //[self _updateLayout];
                         
                     }];
    
}

- (void)_completeReorder{
    
    [self _removeHighlight];

    FJReorderingIndexMap* im = (FJReorderingIndexMap*)self.indexMap;

    NSLog(@"completing reorder...");
    NSUInteger current = im.currentReorderingIndex;
    NSUInteger original = im.originalReorderingIndex;
    
    FJSpringBoardHorizontalLayout* l = (FJSpringBoardHorizontalLayout*)self.layout;
    NSUInteger page = [l pageForContentOffset:self.scrollView.contentOffset];
    NSIndexSet* visIndexes = [l cellIndexesForPage:page];
    
    if(![visIndexes containsIndex:current]){
        
        CGRect adjustedFrame = [self convertRect:self.draggableCellView.frame toView:self.contentView];

        NSUInteger newIndex = [self _coveredCellIndexWithObscuredContentFrame:adjustedFrame];
        
        if(newIndex == NSNotFound)
            newIndex = ([visIndexes lastIndex]-1); //compensating for weird foundation bug that does not report the proper last index. sometimes it reports lastIndex+1. wtf???
        
        
        if(newIndex != current){
            
            
            [self _reorderCellsByUpdatingPlaceHolderIndex:newIndex];
            
            //TODO: guard against infinite loop   
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self _completeReorder];
                
            });
            
            return;
            
        }       
    }
    
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:im.currentReorderingIndex];
    [self.indexMap commitChanges];
    
    self.animatingReorder = YES;

    id<FJSpringBoardViewDataSource> d = self.dataSource;
    
    if([self.cells count] == 0){
        
        ALWAYS_ASSERT;
    }
    
    [self _animateDraggableViewToCellIndex:current completionBlock:^{
        
        if(![cell isEqual:[NSNull null]])
            cell.reordering = NO;
        
        self.animatingReorder = NO;
        if([d respondsToSelector:@selector(springBoardView:moveCellAtIndex:toIndex:)])
            [d springBoardView:self moveCellAtIndex:original toIndex:current];
        
        
    }];
    
}

#pragma mark -
#pragma mark Grouping


- (void)_highlightGroupAtIndex:(NSUInteger)index{
    
    if(self.animatingReorder)
        return;
    
    if(self.indexOfHighlightedCell == index)
        return;
    
    self.animatingReorder = YES;
    [self _removeHighlight];
        
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    self.indexOfHighlightedCell = index;
    
    FJSpringBoardGroupCell* groupCell = nil;
    
    //if we already have a folder on screen, score!
    if([cell isKindOfClass:[FJSpringBoardGroupCell class]])
        groupCell = (FJSpringBoardGroupCell*)cell;
    
    //if not, lets get one
    if(groupCell == nil){
        
        //well lets ask for one
        groupCell = [self.dataSource emptyGroupCellForSpringBoardView:self];
        
        if(groupCell == nil){
            
            return;
        }
        
        self.floatingGroupCell = groupCell;        

        groupCell.frame = cell.frame;
        groupCell.center = cell.center;
        [self.contentView addSubview:groupCell];
        groupCell.alpha = 0.0;

    }
    groupCell.transform = CGAffineTransformMakeScale(1.3, 1.3);
    groupCell.userInteractionEnabled = NO;
    cell.userInteractionEnabled = NO;
    

    [UIView animateWithDuration:CREATE_GROUP_ANIMATION_DURATION 
                          delay:REMOVE_GROUP_ANIMATION_DURATION
                        options:UIViewAnimationOptionCurveEaseOut  
                     animations:^(void) {
                         
                         groupCell.alpha = 1.0;
                         
                         if(![cell isEqual:groupCell])
                             cell.alpha = 0.0;

                     } completion:^(BOOL finished) {
                         
                         groupCell.userInteractionEnabled = YES;
                         cell.userInteractionEnabled = YES;
                         self.animatingReorder = NO;
                         
                     }];
    
}

- (void)_removeHighlight{
        
    if(self.indexOfHighlightedCell == NSNotFound)
        return;
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:indexOfHighlightedCell];
    self.indexOfHighlightedCell = NSNotFound;
    
    FJSpringBoardGroupCell* group = [self.floatingGroupCell retain];
    self.floatingGroupCell = nil;

    [UIView animateWithDuration:REMOVE_GROUP_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseOut  
                     animations:^(void) {
                         
                         if([cell isKindOfClass:[FJSpringBoardGroupCell class]]){
                             
                             cell.transform = CGAffineTransformIdentity;
                             
                         }else{
                             
                             if(![cell isEqual:[NSNull null]])
                                 cell.alpha = 1.0;
                             
                             group.transform = CGAffineTransformIdentity;
                             group.alpha = 0.0;

                         }
                         
                         
                     } completion:^(BOOL finished) {
                         
                         
                         if([cell isKindOfClass:[FJSpringBoardGroupCell class]]){
                             
                             
                         }else{
                             
                             if(group != nil){
                              
                                 [group removeFromSuperview];
                                 group.alpha = 1.0;
                                 [self.reusableCells addObject:group];
                                 [group release];
                                 
                             }
                         }
                     }];
    
}

- (void)_completeGrouping{
    
    //NSArray* objects = [self.cells objectsAtIndexes:indexes];

    NSUInteger index = self.indexOfHighlightedCell;
    
    [self _removeHighlight];

    FJSpringBoardCell* cell = nil;
    
    cell = [self.cells objectAtIndex:index];
    
    NSMutableIndexSet* cellsToAdd = [NSMutableIndexSet indexSet];
    
    NSUInteger movingIndex = self.indexMap.currentReorderingIndex;

    if(![cell isKindOfClass:[FJSpringBoardGroupCell class]]){
       
        [self _createGroupCellFromCellAtIndex:index];
        
        [cellsToAdd addIndex:index+1];
        
        if(movingIndex >= index)
            movingIndex++;
    }        
    
    
    [cellsToAdd addIndex:movingIndex];

    //change to animation into the group
    [self _animateDraggableViewToCellIndex:index completionBlock:^{
        
              
        
    }];
    
    [self _addCellsAtIndexes:cellsToAdd toGroupAtIndex:index];
        
}

- (void)_createGroupCellFromCellAtIndex:(NSUInteger)index{
    
    //create new group, but we won't animate this asa it is always followed by adding cells 

    if(index == NSNotFound)
        return;
    
    //create and group, use floating cell
    FJSpringBoardGroupCell* groupCell = [self.dataSource emptyGroupCellForSpringBoardView:self];
    groupCell.springBoardView = self;
    if(groupCell == nil){
        
        return;
    }
    
    NSIndexSet* toLayout = [self.indexMap modifiedIndexesByAddingGroupCell:groupCell atIndex:index];
    [self.allIndexes addIndex:([self.allIndexes lastIndex]+1)];
 
    //not necesarily needed if we can figure how to not fuck up double loading these later when we scroll since the indexloader is left in the dark    
    NSMutableIndexSet* toRemove = [toLayout mutableCopy];
    [toRemove removeIndexes:self.onScreenCellIndexes];
    [self.indexesScrollingOutOfView addIndexes:toRemove];
    [self.indexesNeedingLayout addIndexes:toLayout];
    [self _layoutCellsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
    //[self.indexesNeedingLayout removeIndexes:toLayout];
    
    //notify datasource
    if([self.dataSource respondsToSelector:@selector(springBoardView:commitInsertingGroupCellAtIndex:)])
        [self.dataSource springBoardView:self commitInsertingGroupCellAtIndex:index];

}

- (void)_addCellsAtIndexes:(NSIndexSet*)cellIndexes toGroupAtIndex:(NSUInteger)groupIndex{
    
    if([cellIndexes count] == 0)
        return;
    
    if(groupIndex == NSNotFound)
        return;
        
    self.animatingReorder = YES;
    
    
    //from the pre method
    NSUInteger lastVisIndex = [self.onScreenCellIndexes lastIndex];
    
    NSIndexSet* releventDeletedIndexes = [cellIndexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if(idx > lastVisIndex)
            return NO;
        
        return YES;
        
    }];
    
    NSRange newRangeToLoadAndLayout = NSMakeRange([self.onScreenCellIndexes lastIndex] + 1, [releventDeletedIndexes count]);
    
    if([self.cells count] > self.layout.cellCount){
        
        //TODO: hey another hack!
        //compensating for the new group being added and haven't yet commited the changes
        newRangeToLoadAndLayout = NSMakeRange([self.onScreenCellIndexes lastIndex] + 2, [releventDeletedIndexes count]-1);
    }
    
    NSIndexSet* newIndexesToLoadAndLayout = [NSIndexSet indexSetWithIndexesInRange:newRangeToLoadAndLayout]; 
    
    [self _loadCellsAtIndexes:newIndexesToLoadAndLayout];
    [self _layoutCellsAtIndexes:newIndexesToLoadAndLayout];
    
    
    
    
    NSArray* cellsToAdd = [[self.cells objectsAtIndexes:cellIndexes] retain];
    
    //TODO: animate cells here
    //FJSpringBoardGroupCell* group = (FJSpringBoardGroupCell*)[self.cells objectAtIndex:groupIndex];
    
    NSIndexSet* toLayout = [self.indexMap modifiedIndexesByRemovingCellsAtIndexes:cellIndexes];
    
    [self.indexesNeedingLayout addIndexes:toLayout];
    
    for(int i = 0; i < [cellIndexes count]; i++)
        [self.allIndexes removeIndex:[self.allIndexes lastIndex]];
    
    self.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^(void) {
        
                         [self _layoutCellsAtIndexes:[toLayout copy]];
                         [self.indexesNeedingLayout removeAllIndexes];
                         
                         [cellsToAdd enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }                                 
                             cell.alpha = 0;
                             
                         }];
                         
                     } 
                     completion:^(BOOL finished) {
                         
                         [cellsToAdd enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }
                             
                             [cell removeFromSuperview];
                             [cell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
                             [self.reusableCells addObject:cell];
                             cell.alpha = 1;
                             self.animatingReorder = NO;
                             
                         }];
                         
                         [self _updateLayout];
                         self.userInteractionEnabled = YES;
                         [self.indexMap commitChanges];

                         if([self.dataSource respondsToSelector:@selector(springBoardView:commitAddingCellsAtIndexes:toGroupCellAtIndex:)])
                             [self.dataSource springBoardView:self commitAddingCellsAtIndexes:cellIndexes toGroupCellAtIndex:groupIndex];
                         
                         NSUInteger newNumOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
                         
                         if([self.cells count] != newNumOfCells){
                             
                             ALWAYS_ASSERT;
                         }
                         
                         
                     }];
    
}




#pragma mark -
#pragma mark paging


- (NSUInteger)page{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    return floorf(self.scrollView.contentOffset.x/self.scrollView.bounds.size.width);
    
}

- (NSUInteger)nextPage{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    FJSpringBoardHorizontalLayout* l = (FJSpringBoardHorizontalLayout*)self.layout;

    NSUInteger currentPage = [self page];
    
    NSUInteger next = currentPage+1;
    
    if(next < l.pageCount){
        
        return next;
    }
     
    return NSNotFound;
    
}

- (NSUInteger)previousPage{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    NSUInteger currentPage = [self page];
    
    if(currentPage > 0)
        return (currentPage-1);
    
       
    return NSNotFound;
    
}

- (BOOL)scrollToPage:(NSUInteger)page animated:(BOOL)animated{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NO;
    
    FJSpringBoardHorizontalLayout* l = (FJSpringBoardHorizontalLayout*)self.layout;

    if(page >= l.pageCount)
        return NO;    
        
    CGPoint p = [l offsetForPage:page];
    
    [self.scrollView setContentOffset:p animated:animated];
    
    return YES;
    
}


#pragma mark -
#pragma mark Selection

- (NSIndexSet *)indexesForSelectedCells{
    
    return [self.selectedIndexes copy];
}


@end
