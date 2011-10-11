
#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import <QuartzCore/QuartzCore.h>
#import "FJSpringBoardCell.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardCellUpdate.h"
#import "FJSpringBoardUpdate.h"
#import "FJSpringBoardActionGroup.h"

#define MOVE_ANIMATION_DURATION 0.25
#define DELETE_ANIMATION_DURATION 0.25
#define INSERT_ANIMATION_DURATION 0.75
#define RELOAD_ANIMATION_DURATION 0.75

#define CREATE_GROUP_ANIMATION_DURATION 0.3
#define REMOVE_GROUP_ANIMATION_DURATION 0.1

#define EDGE_CUSHION 20.0

#define DROP_COVERAGE .7

typedef enum  {
    FJSpringBoardViewEdgeNone,
    FJSpringBoardViewEdgeTop,
    FJSpringBoardViewEdgeRight,
    FJSpringBoardViewEdgeBottom,
    FJSpringBoardViewEdgeLeft
} FJSpringBoardViewEdge;

typedef enum  {
    FJSpringBoardDragActionNone,
    FJSpringBoardDragActionMove,
    FJSpringBoardDragActionDrop
}FJSpringBoardDragAction; 



@interface FJSpringBoardCell(Internal)

@property(nonatomic, assign) FJSpringBoardView* springBoardView;

@property(nonatomic, readwrite) BOOL reordering;

@property(nonatomic) BOOL allowsEditing; //this is for use by the sprinboard to control whether we expose editing. Should not be set by subclasses, see beginEditingOnTapAndHold

//these are used to control what the cell will display in editing mode
@property(nonatomic) BOOL draggable;
@property(nonatomic) BOOL showsDeleteButton;

//this is used to signify a touch before going into editing mode (and allowing dragging)
@property(nonatomic) BOOL tappedAndHeld;

@property(nonatomic) NSUInteger index; //cache the index for lookup

@end


@interface FJSpringBoardView()

@property(nonatomic, retain) UIView *contentView;

@property(nonatomic, retain) FJSpringBoardIndexLoader *indexLoader;
@property(nonatomic, retain) FJSpringBoardLayout *layout;

@property(nonatomic, retain) NSMutableArray *cells; //has [NSNull null] for any unloaded cells

//junk pile
@property(nonatomic, retain) NSMutableSet *reusableCells;


//mark the layout for recalculation
- (void)_setNeedsLayoutCalculation;
- (void)_clearLayoutCalculation;
@property(nonatomic) BOOL shouldRecalculateLayout;

@property (nonatomic) BOOL suspendLayoutUpdates;

- (void)_calculateLayout;

@property(nonatomic) BOOL layoutIsDirty;
- (void)_setLayoutIsDirty;
- (void)_clearLayoutIsDirty;
- (void)_fixCellLayout;

- (void)_setupCellsScrollingIntoView;
- (void)_cleanupCellsScrollingOutOfView;


- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_loadCellAtIndex:(NSUInteger )index;

- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCell:(FJSpringBoardCell*)cell atIndex:(NSUInteger)index;

- (void)_removeCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_removeCellAtIndex:(NSUInteger)index;

- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_unloadCellAtIndex:(NSUInteger )index;

- (void)_updateModeForCellsAtIndexes:(NSIndexSet*)indexes;


@property(nonatomic, retain) NSMutableArray *actionGroupQueue;
@property(nonatomic, retain) FJSpringBoardUpdate *updateInProgress;

- (FJSpringBoardActionGroup*)_currentActionGroup;
- (void)_processActionQueue;

- (void)_processActionGroup:(FJSpringBoardActionGroup*)actionGroup;

- (void)_processUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)completion;
- (void)_processDeletionUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block;
- (void)_processInsertionUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block;
- (void)_processMoveUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block;
- (void)_processReloadUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block;

@property(nonatomic) CGPoint lastTouchPoint;

- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point checkOffScreenCells:(BOOL)flag;
- (CGRect)_frameForCellAtIndex:(NSUInteger)index checkOffScreenIndexes:(BOOL)flag;

@property(nonatomic) NSUInteger indexOfHighlightedCell;
- (void)_highlightDropCellAtIndex:(NSUInteger)index;
- (void)_removeHighlight;

@property(nonatomic) NSUInteger reorderingIndex;

@property(nonatomic, retain) UIView *draggableCellView;

//- (void)_processEditingLongTapWithRecognizer:(UIGestureRecognizer*)g;
//dragging and dropping
- (void)_makeCellDraggableAtIndex:(NSUInteger)index;
- (void)_handleDraggableCellAtIndex:(NSUInteger)dragIindex withTouchPoint:(CGPoint)point;
- (void)_completeDragAction;
- (NSUInteger)_coveredCellIndexWithObscuredContentFrame:(CGRect)contentFrame;
- (void)_animateDraggableViewToReorderedCellIndex:(NSUInteger)index completionBlock:(dispatch_block_t)block;
- (void)animateEmbiggeningOfDraggableCell;
- (void)animateEmbiggeningOfDraggableCellQuickly;

//scrolling during reordering
- (BOOL)_scrollSpringBoardInDirectionOfEdge:(FJSpringBoardViewEdge)edge;
- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch;


- (void)_resetAnimatingContentOffset;
@property(nonatomic) BOOL animatingContentOffset; //flag to indicate a scrolling animation is occuring (due to calling setContentOffset:animated:)



- (FJSpringBoardDragAction)_actionForDraggableCellAtIndex:(NSUInteger)dragIndex coveredCellIndex:(NSUInteger)index obscuredContentFrame:(CGRect)contentFrame;
//reordering
- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index;
- (void)_completeReorder;

@property(nonatomic) BOOL animatingReorder; //flag to indicate a reordering animation is occuring

//drops
- (void)_completeDrop;


@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;

- (NSUInteger)nextPage;
- (NSUInteger)previousPage;
- (void)_updatePageControl;

@property (nonatomic, getter=isPaging) BOOL paging;

@end

@implementation FJSpringBoardView

@synthesize contentView;

@synthesize dataSource;
@synthesize delegate;

@synthesize pageInsets;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;

@synthesize shouldRecalculateLayout;

@synthesize indexLoader;
@synthesize layout;

@synthesize cells;

@synthesize reusableCells;

@synthesize selectedIndexes;

@synthesize animatingReorder;
@synthesize draggableCellView;

@synthesize animatingContentOffset;

@synthesize lastTouchPoint;

@synthesize indexOfHighlightedCell;
@synthesize reorderingIndex;

@synthesize suspendLayoutUpdates;

@synthesize updateInProgress;
@synthesize layoutIsDirty;
@synthesize allowsMultipleSelection;
@synthesize pageControl;
@synthesize paging;

@synthesize actionGroupQueue;
@synthesize beginEditingOnTapAndHold;


#pragma mark -
#pragma mark NSObject

- (void)dealloc {  
    [actionGroupQueue release];
    actionGroupQueue = nil;
    pageControl = nil;
    dataSource = nil;
    delegate = nil;
    [cells release];
    cells = nil;
    [contentView release];
    contentView = nil;    
    [draggableCellView release];
    draggableCellView = nil;   
    [selectedIndexes release];
    selectedIndexes = nil;    
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

- (void)setup{
    
    self.contentView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:self.contentView];
    
    self.selectedIndexes = [NSMutableIndexSet indexSet];
    
    self.cells = [NSMutableArray array];
    
    self.reusableCells = [NSMutableSet set];
    
    self.actionGroupQueue = [NSMutableArray array];
    
    self.indexOfHighlightedCell = NSNotFound;
    self.reorderingIndex = NSNotFound;
    self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
    self.mode = FJSpringBoardCellModeNormal;
    self.beginEditingOnTapAndHold = YES;
    
    [self.pageControl addTarget:self action:@selector(handlePageControlChange:) forControlEvents:UIControlEventValueChanged];

}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        [self setup];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {

    self = [super initWithCoder:coder];
    if (self) {
        
        [self setup];

    }
    return self;
}



- (void)setFrame:(CGRect)f{
    
    [super setFrame:f];
    
    [self _setLayoutIsDirty];
    
    [self _setNeedsLayoutCalculation];
    
    [self setNeedsLayout];

}

#pragma mark - Accessors


- (void)setPageInsets:(UIEdgeInsets)insets{
    
    pageInsets = insets;
    
    [self setNeedsLayout];
}

-(void)setCellSize:(CGSize)aSize{
    
    cellSize = aSize;
    
    [self reloadData];
        
} 

- (void)setScrollDirection:(FJSpringBoardViewScrollDirection)direction{
    
    scrollDirection = direction;
    
    [self _setLayoutIsDirty];
            
    [self _setNeedsLayoutCalculation];
        
    [self setNeedsLayout];

}

- (void)setBeginEditingOnTapAndHold:(BOOL)flag{
    
    beginEditingOnTapAndHold = flag;
    
    [self.cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:idx];
        
        if([eachCell isEqual:[NSNull null]]){
            
            return;
        }
        
        eachCell.allowsEditing = beginEditingOnTapAndHold;

    }];
    
    
    
}

#pragma mark -
#pragma mark External Info Methods

- (NSUInteger)numberOfCells{
    
    return [self.cells count];
    
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
        
        CGRect f = CGRectZero;

        if([c isEqual:[NSNull null]]){
            
            if(flag)
                f = [self.layout frameForCellAtIndex:idx];
                           
        }else{
            
             f = c.frame;
        }
        
        if(CGRectEqualToRect(f, CGRectZero))
            return NO;
        
        if(self.mode == FJSpringBoardCellModeEditing){
            
            CGRect bFrame = CGRectMake(f.origin.x, f.origin.y, 44, 44);
            
            if(CGRectContainsPoint(bFrame, point)){
                *stop = YES;
                return NO;
            }
        }

        if(CGRectContainsPoint(f, point)){
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
    
    return [[self.indexLoader.loadedIndexes copy] autorelease];

}


#pragma mark -
#pragma mark Mode


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
    if(mode == aMode)
        return;
    
    mode = aMode;
    
    [self _updateModeForCellsAtIndexes:[self visibleCellIndexes]];
    
}

- (void)_updateModeForCellsAtIndexes:(NSIndexSet*)indexes{
    
    BOOL respondsToDelete = NO;
    BOOL respondsToMove = NO;
    
    if([self.dataSource respondsToSelector:@selector(springBoardView:canMoveCellAtIndex:)]){
        
        respondsToMove = YES;
    }
    
    if([self.dataSource respondsToSelector:@selector(springBoardView:canDeleteCellAtIndex:)]){
        
        respondsToDelete = YES;
    }
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* cell = (FJSpringBoardCell*)[self cellAtIndex:idx];
        
        if(![cell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        BOOL canDelete = YES;
        BOOL canMove = YES;
        
        if(respondsToMove){
            
            canMove = [self.dataSource springBoardView:self canMoveCellAtIndex:idx];
        }
        
        if(respondsToDelete){
            
            canDelete = [self.dataSource springBoardView:self canDeleteCellAtIndex:idx];
        }
        
        cell.showsDeleteButton = canDelete;
        cell.draggable = canMove;
        cell.mode = mode;
        
    }];
    
    
}



#pragma mark -
#pragma mark Scroll Support

- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated{
    
    
    if(self.scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        
        NSUInteger page = [(FJSpringBoardHorizontalLayout*)self.layout pageForCellIndex:index];
        [self scrollToPage:page animated:animated];
        
    }else{
        
        static const float kScrollBuffer = 10.0;
        
        NSUInteger row = [(FJSpringBoardVerticalLayout*)self.layout rowForCellAtIndex:index];
        
        CGRect f = [(FJSpringBoardVerticalLayout*)self.layout frameForRow:row]; 

        CGPoint offset = f.origin;
        
        if(scrollPosition == FJSpringBoardCellScrollPositionMiddle){
            
            offset.y = MAX(kScrollBuffer, offset.y - self.bounds.size.height/2 + self.cellSize.height/2);
            
            
        }else if(scrollPosition == FJSpringBoardCellScrollPositionTop){
            
            offset.y = offset.y - kScrollBuffer;
            
        }else{
            
            offset.y = MAX(self.bounds.size.height - kScrollBuffer, offset.y - self.bounds.size.height + self.cellSize.height + kScrollBuffer);
        }
        
        
        [self setContentOffset:offset animated:animated];    
           
    }
    
    
}




#pragma mark -
#pragma mark UIScrollView

- (void)setContentSize:(CGSize)size{
    
    if(!CGSizeEqualToSize(size, self.contentSize)){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self flashScrollIndicators];
            
        });
    }
    
    [super setContentSize:size];
    
    [self _updatePageControl];    

}

- (void)setContentOffset:(CGPoint)offset{
    
    if(indexLoader){
        
        /*
         if([self.loadedIndexes count] > 0 && !indexesAreContiguous(self.loadedIndexes)){
         
         ALWAYS_ASSERT;
         }
         */
        
        [self.indexLoader updateIndexesWithContentOffest:offset];
        
        //after the content offset is adjusted, layoutsubviews will be called automagically
        
    }
    
    
    CGPoint previousOffset = self.contentOffset;
    
    [super setContentOffset:offset];
    
    self.animatingContentOffset = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_resetAnimatingContentOffset) object:nil];
    [self performSelector:@selector(_resetAnimatingContentOffset) withObject:nil afterDelay:0.1];
    
    
    CGPoint dragCenter = self.draggableCellView.center;
    dragCenter.x += (self.contentOffset.x-previousOffset.x);
    self.draggableCellView.center = dragCenter;
    
    
    CGPoint p = self.contentOffset;
    dispatchOnMainQueueAfterDelayInSeconds(0.1, ^(void) {
        
        if(p.x == self.contentOffset.x){
            
            [self _updatePageControl];    

        }
    });
    

}


- (void)_resetAnimatingContentOffset{
    
    self.animatingContentOffset = NO;
    //self.contentSize = self.layout.contentSize;
    
}



#pragma mark -
#pragma mark Reload

- (void)reloadData{
    
    self.contentOffset = CGPointZero;
    
    //remove pending actions
    [self.actionGroupQueue removeAllObjects];
    self.updateInProgress = nil;
    self.suspendLayoutUpdates = NO;

    //deselect
    [self deselectCellsAtIndexes:self.selectedCellIndexes animated:NO];

    //unload all cells
    [self _removeCellsAtIndexes:self.indexLoader.allIndexes];
    [self _unloadCellsAtIndexes:self.indexLoader.allIndexes];
    
    //remove cache
    [self.reusableCells removeAllObjects];
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    self.cells = nullArrayOfSize(numOfCells);
    
    self.layout = nil;
    
    self.indexLoader = [[[FJSpringBoardIndexLoader alloc] initWithCellCount:numOfCells] autorelease];
    
    [self _setNeedsLayoutCalculation];
    
    [self setNeedsLayout];
    
    [self layoutIfNeeded];
}



#pragma mark -
#pragma mark configure layout

- (void)_setNeedsLayoutCalculation{
    
    self.shouldRecalculateLayout = YES;
    
}
- (void)_clearLayoutCalculation{
    
    self.shouldRecalculateLayout = NO;
}

//only called on reload
- (void)_calculateLayout{
    
    [self _clearLayoutCalculation];
    
    NSRange visibleCellRange = [self.layout visibleRangeForContentOffset:self.contentOffset];
    
    NSUInteger firstCell = visibleCellRange.location;

    if(scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        
        FJSpringBoardLayout* l = [[FJSpringBoardHorizontalLayout alloc] initWithSpringBoardBounds:self.bounds cellSize:self.cellSize cellCount:self.numberOfCells];
        self.layout = l;
        //self.pagingEnabled = YES;
        [l release];
        
    }else{
        
        FJSpringBoardLayout* l = [[FJSpringBoardVerticalLayout alloc] initWithSpringBoardBounds:self.bounds cellSize:self.cellSize cellCount:self.numberOfCells];
        self.layout = l;
        //self.pagingEnabled = NO;
        [l release];
    }
    
    [self.layout calculateLayout];

    self.indexLoader.layout = self.layout;
    
    //if our layout is botched, there is no use upseting the indexLoader. Lets wait until we are good and try again.
    if(!self.layoutIsDirty)
        [self.indexLoader updateIndexesWithContentOffest:self.contentOffset];

    CGRect f = CGRectMake(0, 0, self.layout.contentSize.width, self.layout.contentSize.height);
    self.contentView.frame = f; 
    
    //if(!self.layoutIsDirty)
    [self setContentSize:self.layout.contentSize];
    
    //we only 
    if(self.layoutIsDirty){
        
        dispatchOnMainQueueAfterDelayInSeconds(MOVE_ANIMATION_DURATION, ^(void) {
            
            [self scrollToCellAtIndex:firstCell atScrollPosition:FJSpringBoardCellScrollPositionTop animated:YES];        
            
        });

    }
   

}

#pragma mark -
#pragma mark Fix layout


- (void)_setLayoutIsDirty{
    
    self.layoutIsDirty = YES;
    
}

- (void)_clearLayoutIsDirty{
    
    self.layoutIsDirty = NO;
}

- (void)_fixCellLayout{
    
    if(!self.layoutIsDirty)
        return;
    
    [self _clearLayoutIsDirty];
    
    [self.indexLoader updateIndexesWithContentOffest:self.contentOffset]; //this causes the index loader to recalculate cells to load in case we changed scroll directions.
    
    //[CATransaction setDisableActions:YES];
    [self _layoutCellsAtIndexes:[self.indexLoader loadedIndexes]]; //relayout loaded cells. 
    //[CATransaction setDisableActions:NO];
        
}


#pragma mark -
#pragma mark Layout

//called when changes occur affecting layout
- (void)layoutSubviews{
    
    if(self.suspendLayoutUpdates)
        return;
    
    //recalculate layout
    if(self.shouldRecalculateLayout){
        
        [self _calculateLayout];
        
    }
    
    //fix any loaded cells, with animation
    //[UIView animateWithDuration:MOVE_ANIMATION_DURATION animations:^(void) {
        
        [self _fixCellLayout];
        
    //}];
    
    //unload cells that are no longer visible
    [self _cleanupCellsScrollingOutOfView];
    
    //load cells that are now visible
    [self _setupCellsScrollingIntoView];
    
    
    extendedDebugLog([self.contentView recursiveDescription]);

}


#pragma mark -
#pragma mark Load Indexes Due to scrolling

- (void)_setupCellsScrollingIntoView{
    
    if([[self.indexLoader indexesToLoad] count] > 0){
        
        NSIndexSet* actualIndexes = [[self.indexLoader indexesToLoad] indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
            
            if([self.indexLoader.allIndexes containsIndex:idx])
                return YES;
            return NO;
            
        }];
        
        extendedDebugLog(@"indexes to load: %@", [self.indexLoader indexesToLoad]);
        extendedDebugLog(@"actual indexes to load: %@", actualIndexes);
        
        //remove from view
        [self _removeCellsAtIndexes:actualIndexes];
        
        //unload them (placed in reusable pool)
        [self _unloadCellsAtIndexes:actualIndexes];
        
        //create and insert in array
        [self _loadCellsAtIndexes:actualIndexes];
        
        //layout in grid
        [self _layoutCellsAtIndexes:actualIndexes];
        
        [self.indexLoader clearIndexesToLoad];
        
    }
    
}

- (void)_cleanupCellsScrollingOutOfView{
    
    if([[self.indexLoader indexesToUnload] count] > 0){
        
        NSIndexSet* actualIndexes = [[self.indexLoader indexesToUnload] indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
            
            if([self.indexLoader.allIndexes containsIndex:idx])
                return YES;
            return NO;
            
        }];
        
        [self _removeCellsAtIndexes:actualIndexes];
        
        [self _unloadCellsAtIndexes:actualIndexes];
        
        [self.indexLoader clearIndexesToUnload];
        
    }
}



#pragma mark -
#pragma mark Load Cells


- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
               
        [self _loadCellAtIndex:index];
               
    }];

}

- (void)_loadCellAtIndex:(NSUInteger )index{
    
    FJSpringBoardCell* cell = [self.dataSource springBoardView:self cellAtIndex:index];
    
    if(!cell)
        [NSException raise:NSInvalidArgumentException format:@"Must return a valid cell"];
    
    [cell retain];
    
    cell.index = index;
    cell.springBoardView = self;
    cell.allowsEditing = self.beginEditingOnTapAndHold;
    
    if([self.selectedIndexes containsIndex:index])
        cell.selected = YES;
    
    [self.cells replaceObjectAtIndex:index withObject:cell];
    
    extendedDebugLog(@"loaded cell: %@", [cell description])
    
    [cell release];    
    
}


#pragma mark -
#pragma mark Layout cells

- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSIndexSet* actualIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if([self.indexLoader.allIndexes containsIndex:idx])
            return YES;
        return NO;
        
    }];
    
    [actualIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            return;
        }
        
        eachCell.index = index;
        
        [self _layoutCell:eachCell atIndex:index];
        
    }];
    
    [self _updateModeForCellsAtIndexes:actualIndexes];
}


- (void)_layoutCell:(FJSpringBoardCell*)cell atIndex:(NSUInteger)index{
    
    //NSLog(@"Laying Out Cell %i", index);
    //RECTLOG(cell.contentView.frame);
    
    CGRect cellFrame = [self.layout frameForCellAtIndex:index];
    cell.frame = cellFrame;
    cell.alpha = 1.0;
    
    //RECTLOG(eachCell.contentView.frame);
    
    extendedDebugLog(@"layed out cell: %@", [cell description])
    
    [self.contentView addSubview:cell];
    
}


#pragma mark - Remove Cells From Springboard

- (void)_removeCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSIndexSet* actualIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if([self.indexLoader.allIndexes containsIndex:idx])
            return YES;
        return NO;
        
    }];
    
    [actualIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        [self _removeCellAtIndex:index];
        
        
    }];
    
    [self _updateModeForCellsAtIndexes:actualIndexes];
}



- (void)_removeCellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
    
    if([eachCell isKindOfClass:[NSNull class]])
        return;
    
    [eachCell removeFromSuperview];
    
}




#pragma mark - Unloading Cells

- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.indexLoader.allIndexes containsIndex:index]){
            
            return;
        }
        
        //don't unload the index we are reordering
        if(index == self.reorderingIndex)
            return;

        [self _unloadCellAtIndex:index];
            
            
    }];
    
}

- (void)_unloadCellAtIndex:(NSUInteger )index{
    
    FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
    
    if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
        
        return;
    }
    
    [eachCell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
    eachCell.mode = FJSpringBoardCellModeNormal;

    [self.reusableCells addObject:eachCell];
    [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
    
}


#pragma mark -
#pragma mark Reuse Dequeued Cell

- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier{
    
    if([self.reusableCells count] == 0)
        return nil;
    
    NSSet* c = [self.reusableCells objectsWithOptions:0 passingTest:^(id obj, BOOL *stop) {
        
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
    
    [cell prepareForReuse];
    
    return cell;
    
}


    
#pragma mark -
#pragma mark Selections

- (void)_selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated{
    
    if(!allowsMultipleSelection && [self.selectedCellIndexes count] > 0){
        
        [self deselectCellsAtIndexes:self.selectedCellIndexes animated:YES];
    }
    
    
    [self.selectedIndexes addIndex:index];
    
    FJSpringBoardCell* cell = [self cellAtIndex:index];
    
    if(cell == nil || ![cell isKindOfClass:[FJSpringBoardCell class]])
        return;
    
    [cell setSelected:YES animated:animated];
    
    
}


- (void)selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated scrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition{
    
    [self _selectCellAtIndex:index animated:animated];

    [self scrollToCellAtIndex:index atScrollPosition:FJSpringBoardCellScrollPositionMiddle animated:YES];

}

- (void)selectCellsAAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated scrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        [self _selectCellAtIndex:idx animated:animated];
        
    }];
    
    [self scrollToCellAtIndex:[indexes firstIndex] atScrollPosition:FJSpringBoardCellScrollPositionTop animated:YES];

}


- (void)deselectCellAtIndex:(NSUInteger)index animated:(BOOL)animated{
    
    if(index == NSNotFound)
        return;
    
    [self.selectedIndexes removeIndex:index];
    
    FJSpringBoardCell* cell = [self cellAtIndex:index];
    
    if(cell == nil || ![cell isKindOfClass:[FJSpringBoardCell class]])
        return;
    
    [cell setSelected:NO animated:animated];
    
}

- (void)deselectCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
       
        [self deselectCellAtIndex:idx animated:animated];
        
    }];
    
}

- (NSIndexSet*)selectedCellIndexes{
    
    return [[self.selectedIndexes copy] autorelease];
    
}

- (NSUInteger)selectedCellIndex{
    
    return [self.selectedIndexes firstIndex];
    
}
#pragma mark -
#pragma mark Actions


- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
        
    [[self _currentActionGroup] addActionWithType:FJSpringBoardActionReload indexes:indexSet animation:animation];
    
    [self _processActionQueue];

}


//3 situations, indexset in vis range, indexset > vis range, indexset < vis range
- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    if([indexSet count] == 0)
        return;
        
    //NSArray* nulls = nullArrayOfSize([indexSet count]);
    
    //[self.cells insertObjects:nulls atIndexes:indexSet];
    
    [[self _currentActionGroup] addActionWithType:FJSpringBoardActionInsert indexes:indexSet animation:animation];
    
    [self _processActionQueue];
   
    
}

- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    if([indexSet count] == 0)
        return;
    

    //[self.cells removeObjectsAtIndexes:indexSet];
    
    [[self _currentActionGroup] addActionWithType:FJSpringBoardActionDelete indexes:indexSet animation:animation];
            
    [self _processActionQueue];

}


- (void)_deleteCell:(FJSpringBoardCell*)cell{
    
    //we are not doing internal deletes if you are in the middle of shuffling around other things, this might be ok
    FJSpringBoardActionGroup* actionGroup = [self _currentActionGroup];
    if(!actionGroup.autoLock)
        return;
    
    NSUInteger index = cell.index;
    
    if(index == NSNotFound){
        ALWAYS_ASSERT;
        return;
    }
    
    
    if(![self.indexLoader.allIndexes containsIndex:index]){
        ALWAYS_ASSERT;
        return;
    }
    
    [self.dataSource springBoardView:self commitDeletionForCellAtIndex:index];    
    
    [self deleteCellsAtIndexes:[NSIndexSet indexSetWithIndex:index] withCellAnimation:FJSpringBoardCellAnimationFade];

}

- (void)beginUpdates{
    
    FJSpringBoardActionGroup* actionGroup = [self _currentActionGroup];
    ASSERT_TRUE(actionGroup.autoLock);
    ASSERT_TRUE(!actionGroup.isLocked);
    actionGroup.autoLock = NO;
}


- (void)endUpdates{
    
    FJSpringBoardActionGroup* actionGroup = [self _currentActionGroup];
    ASSERT_TRUE(!actionGroup.autoLock);
    ASSERT_TRUE(!actionGroup.isLocked);
    [actionGroup lock]; //must be explicitely locked since autolock is off
    
    [self _processActionQueue];
    
}

- (FJSpringBoardActionGroup*)_currentActionGroup{
    
    FJSpringBoardActionGroup* group = [self.actionGroupQueue firstObjectSafe];
    

    //no current group, set it up
    //or if current group IS locked, AND no action groups is supposed to be open, we can create a new action group
    if(!group || group.isLocked){
        
        NSArray* oldCells = [self.cells copy];
        group = [[FJSpringBoardActionGroup alloc] init];
        
        [self.actionGroupQueue enqueue:group];
        
        [group release];
        [oldCells release];
        
    }
    
    return group;
}

- (void)validateGroup:(FJSpringBoardActionGroup*)group{
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    __block NSUInteger previousCount = [self.indexLoader.allIndexes count];

    if(self.updateInProgress){
        //ok we have anotehr update going on. This means the cell state prior to the action group might not be what the datasource thinks it shoud be.
        previousCount = [self.updateInProgress.cellStatePriorToAction count];
        
        //lets add in the changes
        NSUInteger cellsInserted = [[self.updateInProgress insertIndexes] count];
        NSUInteger cellsDeleted = [[self.updateInProgress deleteIndexes] count];
        
        previousCount += cellsInserted;
        previousCount -= cellsDeleted;
        
    }
    
    if([self.actionGroupQueue count] > 1){
        
        //ok we have inserted several actions that have not processed yet. we need to take these into account as well
        [self.actionGroupQueue enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if(obj == group)
                return;
            
            FJSpringBoardActionGroup *aGroup = obj;
            
            NSUInteger cellsInserted = [[aGroup indexesToInsert] count];
            NSUInteger cellsDeleted = [[aGroup indexesToDelete] count];
            
            previousCount += cellsInserted;
            previousCount -= cellsDeleted;
            
        }];

    }

    //alrighty, at this point the "previous count" should be what the datsource thinks it is. So lets compare and make sure we are not idiots!
    NSUInteger cellsInserted = [[group indexesToInsert] count];
    NSUInteger cellsDeleted = [[group indexesToDelete] count];
    
    if(previousCount + cellsInserted - cellsDeleted != numOfCells){
        
        [NSException raise:NSInternalInconsistencyException format:@"new cells count %i should be equal to previous cell count %i plus cells inserted %1 minus cells deleted %i", numOfCells, previousCount, cellsInserted, cellsDeleted];
    } 
    
    group.validated = YES;
    
}

- (FJSpringBoardActionGroup*)_actionGroupToProcess{
    
    FJSpringBoardActionGroup* actionGroup = [self.actionGroupQueue lastObject];
    
    if(!actionGroup.isLocked)
        return nil;
    
    return [self.actionGroupQueue dequeue];
}



- (void)_processActionQueue{
        
    FJSpringBoardActionGroup* group = [self.actionGroupQueue firstObjectSafe];
    
    if(!group.isValidated && group.isLocked){
        
        [self validateGroup:group];
        
    }
    
    if(self.updateInProgress)
        return;
    
    FJSpringBoardActionGroup* actionGroup = [self _actionGroupToProcess];

    [self _processActionGroup:actionGroup];
}

- (void)_processActionGroup:(FJSpringBoardActionGroup*)actionGroup{
    
    if([actionGroup.reloadActions count] == 0 && [actionGroup.deleteActions count] == 0 && [actionGroup.insertActions count] == 0){
        
        //no changes
        return;
    }
    
    //self.suspendLayoutUpdates = YES;
    //self.userInteractionEnabled = NO;

    //process any unloaded cells before we update the view
    [self layoutIfNeeded];

    NSIndexSet* visible = self.indexLoader.visibleIndexes;
    
    ASSERT_TRUE(indexesAreContiguous(visible));
    NSRange range = rangeWithContiguousIndexes(visible);
    
    extendedDebugLog(@"visible range: %i - %i", range.location, NSMaxRange(range));
    
    FJSpringBoardUpdate* update = [[FJSpringBoardUpdate alloc] initWithCellState:self.cells visibleIndexRange:range actionGroup:actionGroup];
    self.updateInProgress = update;

    [self _processUpdate:update completionBlock:^(void) {
        
        self.updateInProgress = nil;
        //self.suspendLayoutUpdates = NO;
        //self.userInteractionEnabled = YES;
        
        //technically everything should be good to go, but since we have been ignoring layout upates and jiggled a lot of handles, we may have missed a layout due to user scrolling. lets make sure we get this done now.
        [self layoutIfNeeded];

        //possible that we have been queing actions in the mean time…
        [self _processActionQueue];
        
    }];   
    
    [update release];
}


#pragma mark - Process Updates

- (void)_processUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)completion{
    
       

    extendedDebugLog([self.contentView recursiveDescription]);
    
    
    [self _processDeletionUpdate:update completionBlock:^(void) {
        
        
    }];
    
    
    
    [self _processInsertionUpdate:update completionBlock:^(void) {
        
        
        
    }];
    
    
    [self _processMoveUpdate:update completionBlock:^(void) {
        
        
        
        
    }];
    
    [self _processReloadUpdate:update completionBlock:^(void) {
        
        //doing the completion block here because the reload animation is the longest
        
        extendedDebugLog([self.contentView recursiveDescription]);
                
        //update the index loaders list of loaded cells
        [self.indexLoader adjustLoadedIndexesByDeletingIndexes:update.deleteIndexes insertingIndexes:update.insertIndexes];
        
        //update layout count, get the view resized
        //update the index loaders layout
        [self _calculateLayout];
        //[self _setNeedsLayoutCalculation];
        //[self setNeedsLayout];
       
        if(completion)
            completion();
        
        
        
    }];
    
    extendedDebugLog([self.contentView recursiveDescription]);
}






- (void)_processDeletionUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    //NSArray* deletionUpdates = [update deleteUpdates];    
    NSIndexSet* deletionIndexes = [update deleteIndexes];
    
    NSArray* cellsCopy = [self.cells copy];
    
    debugLog(@"delete indexes: %@", [deletionIndexes description]);

    NSIndexSet* deletionIndexesToAnimate = [self.indexLoader visibleIndexesInIndexSet:deletionIndexes];
    
    debugLog(@"delete indexes to animate: %@", [deletionIndexesToAnimate description]);

    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                     animations:^(void) {
                         
                         [deletionIndexesToAnimate enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = [cellsCopy objectAtIndex:idx];
                             
                             if([[NSNull null] isEqual:(NSNull*)cell])
                                 return;
                             
                             cell.alpha = 0;
                             
                         }];
                         
                         
                     } completion:^(BOOL finished) {
                         
                         [deletionIndexesToAnimate enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = [cellsCopy objectAtIndex:idx];
                             
                             if([[NSNull null] isEqual:(NSNull*)cell])
                                 return;
                             
                             [cell removeFromSuperview];
                             
                             [cell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
                             cell.mode = FJSpringBoardCellModeNormal;
                             
                             [self.reusableCells addObject:cell];
                             
                         }];
                         
                         if(block)
                             block();
                         
                     }];
    
    [cellsCopy release];

    [self.cells removeObjectsAtIndexes:[update deleteIndexes]];

}



- (void)_processInsertionUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    //NSArray* insertionUpdates = [update insertUpdates];    
    NSIndexSet* insertionIndexes = [update insertIndexes];
    
    debugLog(@"insert indexes: %@", [insertionIndexes description]);
    
    [self.cells insertObjects:nullArrayOfSize([insertionIndexes count]) atIndexes:insertionIndexes];
    
    NSIndexSet* insertionIndexesToAnimate = [self.indexLoader visibleIndexesInIndexSet:insertionIndexes];
    
    debugLog(@"insert indexes to animate: %@", [insertionIndexesToAnimate description]);
    
    [insertionIndexesToAnimate enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
#if DEBUG == 2
        
        extendedDebugLog(@"insert action - new location: %i", action.newSpringBoardIndex);
#endif
        
        FJSpringBoardCell* cell = [self cellAtIndex:idx];
        ASSERT_TRUE(cell == (FJSpringBoardCell*)[NSNull null] || cell == nil);
        
        [self _loadCellAtIndex:idx];
        
        cell = [self cellAtIndex:idx];
        
        ASSERT_TRUE(cell != nil);
        
        [self _layoutCell:cell atIndex:idx];
        cell.alpha = 0;
        
    }];
    
    
    float delay = 0;
    if([update.deleteIndexes count] > 0)
        delay += DELETE_ANIMATION_DURATION;
    
    if([update.moveUpdates count] > 0)
        delay += MOVE_ANIMATION_DURATION;
    
    
    [UIView animateWithDuration:INSERT_ANIMATION_DURATION 
                          delay:delay
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                     animations:^(void) {
                         
                         [insertionIndexesToAnimate enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:idx];
                             cell.alpha = 1.0;
                             
                         }];
                         
                         
                     } completion:^(BOOL finished) {
                         
                         if(block)
                             block();
                     }];
    
}


- (void)_processMoveUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    NSArray* moves = [update moveUpdates];
    
    NSMutableArray* movesInVisibleRange = [NSMutableArray array];
    
    [moves enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellUpdate* action = obj;
        
#if DEBUG == 2
        
        extendedDebugLog(@"move action - old location: %i new location: %i", action.oldSpringBoardIndex, action.newSpringBoardIndex);
#endif
        
        if([self.indexLoader.visibleIndexes containsIndex:action.newSpringBoardIndex] || [self.indexLoader.visibleIndexes containsIndex:action.oldSpringBoardIndex]){
            
            [movesInVisibleRange addObject:action];
            
            FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
            
            if(!cell){
                
                [self _loadCellAtIndex:action.newSpringBoardIndex];
                cell = [self cellAtIndex:action.newSpringBoardIndex];
                
                [self _layoutCell:cell atIndex:action.oldSpringBoardIndex];
                
                cell.alpha = 1.0;
                
#if DEBUG == 2
                
                extendedDebugLog(@"original frame");
                extendedDebugLog([cell description]);
#endif
                
            }
            
            cell.index = action.newSpringBoardIndex;

        }
        
        
    }];
    
    float delay = 0;
    if([update.deleteIndexes count] > 0)
        delay += DELETE_ANIMATION_DURATION;
    
    [UIView animateWithDuration:MOVE_ANIMATION_DURATION
                          delay:delay 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                     animations:^(void) {
                         
                         [movesInVisibleRange enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCellUpdate* action = obj;
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
                             
                             [self _layoutCell:cell atIndex:action.newSpringBoardIndex];
                             
                             
                         }];
                         
                         
                         
                     } completion:^(BOOL finished) {
                         
#if DEBUG == 2
                         [movesInVisibleRange enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCellUpdate* action = obj;
                             FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
                             extendedDebugLog(@"new frame");
                             extendedDebugLog([cell description]);
                             
                         }];
#endif        
                         if(block)
                             block();
                         
                     }];
    
    
    
    
    
}



- (void)_processReloadUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    NSArray* reloadUpdates = [update reloadUpdates];

    float delay = 0;
    if([update.deleteIndexes count] > 0)
        delay += DELETE_ANIMATION_DURATION;
    
    if([update.moveUpdates count] > 0)
        delay += MOVE_ANIMATION_DURATION;
    
    if([update.insertIndexes count] > 0)
        delay += INSERT_ANIMATION_DURATION; 
    
    [UIView animateWithDuration:RELOAD_ANIMATION_DURATION/2-0.05
                          delay:delay 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                     animations:^(void) {
                         
                         [reloadUpdates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            
                             FJSpringBoardCellUpdate* cellUpdate = obj;
                             
                             if(![self.indexLoader indexIsVisible:cellUpdate.newSpringBoardIndex])
                                 return;
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:cellUpdate.newSpringBoardIndex];
                             
                             if(cellUpdate.animation == FJSpringBoardCellAnimationFade){
                                 
                                 cell.alpha = 0.0;

                             }
                             
#if DEBUG == 2
                             
                             extendedDebugLog(@"reload action - location: %i", action.newSpringBoardIndex);
#endif

                             
                         }];
                         
                         
                     } completion:^(BOOL finished) {
                         
                         
                         [reloadUpdates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCellUpdate* cellUpdate = obj;
                             
                             if(![self.indexLoader indexIsVisible:cellUpdate.newSpringBoardIndex])
                                 return;
                                                          
                             [self _removeCellAtIndex:cellUpdate.newSpringBoardIndex];
                             [self _unloadCellAtIndex:cellUpdate.newSpringBoardIndex];
                             [self _loadCellAtIndex:cellUpdate.newSpringBoardIndex];
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:cellUpdate.newSpringBoardIndex];
                             [self _layoutCell:cell atIndex:cellUpdate.newSpringBoardIndex];

                             if(cellUpdate.animation == FJSpringBoardCellAnimationFade){
                                 
                                 cell.alpha = 0.0;
                             }
                         }];

                                                  
                         
                         [UIView animateWithDuration:RELOAD_ANIMATION_DURATION/2-0.05
                                               delay:0.1 
                                             options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                                          animations:^(void) {
                                              
                                              [reloadUpdates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                  
                                                  FJSpringBoardCellUpdate* cellUpdate = obj;
                                                  
                                                  if(![self.indexLoader indexIsVisible:cellUpdate.newSpringBoardIndex])
                                                      return;
                                            
                                                  FJSpringBoardCell* cell = [self cellAtIndex:cellUpdate.newSpringBoardIndex];
                                                  
                                                  if(cellUpdate.animation == FJSpringBoardCellAnimationFade){
                                                      
                                                      cell.alpha = 1.0;
                                                  }
                                              }];
                                                                                          
                                          } completion:^(BOOL finished) {
                                              
                                              if(block)
                                                  block();
                                              
                                          }];
                         
                     }];

    
}



#pragma mark -
#pragma mark Touches

/*
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    return YES;

}
*/

/*
- (void)updateTapAndHold:(UIGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self.contentView];
    
    NSUInteger indexOfCell = [self indexOfCellAtPoint:p];
    
    if(indexOfCell == NSNotFound)
        return;

    FJSpringBoardCell* c = [self.indexLoader.cells objectAtIndex:indexOfCell];
    
    if(g.state == UIGestureRecognizerStateBegan){
        
        [c setTappedAndHeld:YES];
        
    }else if(g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || g.state == UIGestureRecognizerStateFailed){
        
        [c setTappedAndHeld:NO];

    }
}
*/

- (void)cellWasTapped:(FJSpringBoardCell*)cell{
    
    if(!allowsMultipleSelection && [self.selectedCellIndexes count] > 0){

        if([self.delegate respondsToSelector:@selector(springBoardView:willDeselectCellAtIndex:)])
            [self.delegate springBoardView:self willDeselectCellAtIndex:cell.index];

        [self deselectCellsAtIndexes:self.selectedCellIndexes animated:YES];
        
        if([self.delegate respondsToSelector:@selector(springBoardView:didDeselectCellAtIndex:)])
            [self.delegate springBoardView:self didDeselectCellAtIndex:cell.index];

    }
    
    [self.selectedIndexes addIndex:cell.index];
        
    if(cell == nil || ![cell isKindOfClass:[FJSpringBoardCell class]])
        return;
    
    
    if([self.delegate respondsToSelector:@selector(springBoardView:willSelectCellAtIndex:)])
        [self.delegate springBoardView:self willSelectCellAtIndex:cell.index];

    [cell setSelected:YES animated:YES];

    if([self.delegate respondsToSelector:@selector(springBoardView:didSelectCellAtIndex:)])
        [self.delegate springBoardView:self didSelectCellAtIndex:cell.index];

}

/*
- (void)didSingleTap:(UITapGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self.contentView];
    self.lastTouchPoint = p;
    
    NSUInteger indexOfCell = [self indexOfCellAtPoint:p];
        
    if(indexOfCell == NSNotFound)
        return;

    FJSpringBoardCell* c = [self.indexLoader.cells objectAtIndex:indexOfCell];
    [c setSelected:YES];

    if([delegate respondsToSelector:@selector(springBoardView:didSelectCellAtIndex:)])
        [delegate springBoardView:self didSelectCellAtIndex:indexOfCell];
    
}
*/

- (void)cellWasLongTapped:(FJSpringBoardCell*)cell{
    
    self.mode = FJSpringBoardCellModeEditing;

    [self _makeCellDraggableAtIndex:cell.index];


}

/*
- (void)editingLongTapRecieved:(UILongPressGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self];
    self.lastTouchPoint = p;
    
    CGPoint contentPoint = [g locationInView:self.contentView];
    NSUInteger indexOfCell = [self indexOfCellAtPoint:contentPoint];

    if(self.mode == FJSpringBoardCellModeNormal){
        
        if(indexOfCell != NSNotFound){
            
            self.mode = FJSpringBoardCellModeEditing;

            FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:indexOfCell];
            
            [cell setSelected:NO];
            [cell setTappedAndHeld:NO];
            
            [self _makeCellDraggableAtIndex:indexOfCell];
            
            //[self _handleDraggableCellAtIndex:indexOfCell withTouchPoint:p];       
        }
    
        return;
    }
    
    [self _processEditingLongTapWithRecognizer:g];

}
*/

- (void)cell:(FJSpringBoardCell*)cell longTapMovedToLocation:(CGPoint)newLocation{
    
    if(self.animatingContentOffset || self.animatingReorder){
        
        debugLog(@"still animating");
        //[self performSelector:@selector(_processEditingLongTapWithRecognizer:) withObject:g afterDelay:0.1];
        return;
    }
    debugLog(@"made it!");
    
    CGPoint p = [self convertPoint:newLocation fromView:cell];
    self.lastTouchPoint = p;
    
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_completeDragAction) object:nil];
    
    NSUInteger indexOfCell = cell.index;

    self.draggableCellView.center = p;
    
    //lets pause a second to see 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(0.25)), dispatch_get_main_queue(), ^{
        
        if(fabsf(p.x - self.lastTouchPoint.x) < 5 && (fabsf(p.y - self.lastTouchPoint.y) < 5)){
            
            FJSpringBoardViewEdge e = [self _edgeOfViewAtTouchPoint:p];
            
            if(e == FJSpringBoardViewEdgeNone){
                
                [self _handleDraggableCellAtIndex:indexOfCell withTouchPoint:p];       
                
            }else{
                
                //hit edge, scroll
                if([self _scrollSpringBoardInDirectionOfEdge:e]){
                    
                    /*
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(0.7)), dispatch_get_main_queue(), ^{
                     
                     //are we still on an edge? then scroll again!
                     if(fabsf(p.x - self.lastTouchPoint.x) < 5 && (fabsf(p.y - self.lastTouchPoint.y) < 5))
                     [self _scrollSpringBoardInDirectionOfEdge:e];
                     
                     });
                     
                     */
                }
            }
        }
        
    });
    
    [self performSelector:@selector(_completeDragAction) withObject:nil afterDelay:4.0];

}

- (void)cellLongTapEnded:(FJSpringBoardCell*)cell{
    
    [self _completeDragAction];

}    

/*

- (void)draggingSelectionLongTapReceived:(UILongPressGestureRecognizer*)g{
    
    [self _processEditingLongTapWithRecognizer:g];
}



- (void)dragPanningGestureReceived:(UIPanGestureRecognizer*)g{
    
    [self _processEditingLongTapWithRecognizer:g];
}


- (void)_processEditingLongTapWithRecognizer:(UIGestureRecognizer*)g{
    
    if(self.animatingContentOffset || self.animatingReorder){
        
        debugLog(@"still animating");
        [self performSelector:@selector(_processEditingLongTapWithRecognizer:) withObject:g afterDelay:0.1];
        return;
    }
    debugLog(@"made it!");
    
    CGPoint p = [g locationInView:self];
    self.lastTouchPoint = p;
    
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_completeDragAction) object:nil];
    
    CGPoint contentPoint = [g locationInView:self.contentView];
    NSUInteger indexOfCell = [self indexOfCellAtPoint:contentPoint];
    
    if(indexOfCell == NSNotFound){
        
        [self _completeDragAction];
        
        return;

    }
    
    if(g.state == UIGestureRecognizerStateBegan){
        
        if(indexOfCell != NSNotFound){
            
            FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:indexOfCell];
            
            [cell setSelected:NO];
            [cell setTappedAndHeld:NO];
                        
            [self _handleDraggableCellAtIndex:indexOfCell withTouchPoint:p];       
            
            [self performSelector:@selector(_completeDragAction) withObject:nil afterDelay:4.0];
            
        }
    }
    
    //ok, we are still moving, update the drag cell and then check if we should reorder or animate a folder
    if(g.state == UIGestureRecognizerStateChanged){
        
        self.draggableCellView.center = p;
        
        //lets pause a second to see 
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(0.25)), dispatch_get_main_queue(), ^{
            
            if(fabsf(p.x - self.lastTouchPoint.x) < 5 && (fabsf(p.y - self.lastTouchPoint.y) < 5)){
                
                FJSpringBoardViewEdge e = [self _edgeOfViewAtTouchPoint:p];
                
                if(e == FJSpringBoardViewEdgeNone){
                    
                    [self _handleDraggableCellAtIndex:indexOfCell withTouchPoint:p];       
                    
                }else{
                    
                    //hit edge, scroll
                    if([self _scrollSpringBoardInDirectionOfEdge:e]){
                        
                        /*
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(0.7)), dispatch_get_main_queue(), ^{
                            
                            //are we still on an edge? then scroll again!
                            if(fabsf(p.x - self.lastTouchPoint.x) < 5 && (fabsf(p.y - self.lastTouchPoint.y) < 5))
                                [self _scrollSpringBoardInDirectionOfEdge:e];
                            
                        });
                         
                         
                    }
                }
            }
            
        });
        
        [self performSelector:@selector(_completeDragAction) withObject:nil afterDelay:4.0];
        
        return;
    }
    
    
    //we are done lets reorder or add to folder
    if(g.state == UIGestureRecognizerStateEnded){
        
        [self _completeDragAction];
        
        return;
    }
    
    //we failed to start panning, lets clean up
    if(g.state == UIGestureRecognizerStateFailed || g.state == UIGestureRecognizerStateCancelled){
        
        
        [self _completeDragAction];
        
        return;
    }
    
    if(g.state == UIGestureRecognizerStatePossible){
        
        [self _completeDragAction];
        
        return;
    }
    
}
*/

#pragma mark -
#pragma mark Animating Draggable Cell


- (void)animateEmbiggeningOfDraggableCell{
    
    [UIView animateWithDuration:0.3 
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                         
                         //self.draggableCellView.alpha = 0.7;
                         self.draggableCellView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                         
                     } 
     
                     completion:^(BOOL finished) {
                         
                         
                         
                     }];
    
}

- (void)animateEmbiggeningOfDraggableCellQuickly{
    
    
    [UIView animateWithDuration:0.1 
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                         
                         //self.draggableCellView.alpha = 0.7;
                         self.draggableCellView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                         
                     } 
     
                     completion:^(BOOL finished) {
                         
                         
                         
                     }];
    
}

- (void)animateReducingOfDraggableCellWithCompletionBlock:(dispatch_block_t)block{
    
    
    [UIView animateWithDuration:0.3 
                          delay:0.1 
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                         
                         //self.draggableCellView.alpha = 1.0;
                         self.draggableCellView.transform = CGAffineTransformIdentity;
                         

                         
                     } 
     
                     completion:^(BOOL finished) {
                         
                         block();
                         
                     }];
    
    
}


#pragma mark -
#pragma mark Draggable Cell

- (void)_makeCellDraggableAtIndex:(NSUInteger)index{
    
    if(self.draggableCellView != nil){
        //ALWAYS_ASSERT;
        return;
    }

    if(index == NSNotFound){
        ALWAYS_ASSERT;
        return;
    }

    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
        
    if([cell isEqual:[NSNull null]]){
        
        ALWAYS_ASSERT;
    }
    
    if(![cell draggable])
        return;
    
    [cell setSelected:NO];
    
    //start reordering
    self.reorderingIndex = index;
            
    //create imageview to animate    
    UIGraphicsBeginImageContext(cell.bounds.size);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView* iv = [[UIImageView alloc] initWithImage:i];
    iv.frame = cell.frame;
    iv.center = cell.center;
    self.draggableCellView = iv;
    self.draggableCellView.alpha = CELL_DRAGGABLE_ALPHA;
    [self.contentView addSubview:iv];
    [iv release];
    
    //notify cell it is being reordered. power of… invisibility!
    cell.reordering = YES;
    
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [self animateEmbiggeningOfDraggableCell];

    });
}

- (void)_handleDraggableCellAtIndex:(NSUInteger)dragIindex withTouchPoint:(CGPoint)point{
        
    //check if we need to scroll the view
    
    //CGPoint contentPoint = [self convertPoint:point toView:self.contentView];
    
    
    if(self.reorderingIndex == NSNotFound){
        
        [self _makeCellDraggableAtIndex:dragIindex];
        return;
    }
    
    
    
    CGRect adjustedFrame = [self convertRect:self.draggableCellView.frame toView:self.contentView];
    
    //if not, lets check to see if we need to reshuffle
    NSUInteger index = [self _coveredCellIndexWithObscuredContentFrame:adjustedFrame];
    
    if(index == NSNotFound){
        
        [self _removeHighlight];
        
        return;
        
    }
    
    FJSpringBoardDragAction a = [self _actionForDraggableCellAtIndex:dragIindex coveredCellIndex:index obscuredContentFrame:adjustedFrame];
    
    if(a == FJSpringBoardDragActionMove)
        [self _reorderCellsByUpdatingPlaceHolderIndex:index];
    else if(a == FJSpringBoardDragActionDrop)
        [self _highlightDropCellAtIndex:index];
    else
        [self _removeHighlight];
    
        
}


- (FJSpringBoardDragAction)_actionForDraggableCellAtIndex:(NSUInteger)dragIndex coveredCellIndex:(NSUInteger)index obscuredContentFrame:(CGRect)contentFrame{
    
    //TODO: drag index is the same as reorderingIndex. fix this.
    if(index == self.reorderingIndex)
        return FJSpringBoardDragActionNone;
    
    if(![self.dataSource respondsToSelector:@selector(emptyGroupCellForSpringBoardView:)])
        return FJSpringBoardDragActionMove;
    
    NSUInteger idx = self.reorderingIndex;
    
    //if no currently dragging index, 
    if(idx == NSNotFound)
        idx = dragIndex;
    
    if(idx == NSNotFound)
        return FJSpringBoardDragActionNone;

    CGRect insetRect = CGRectInset(contentFrame, 
                                   0.15*contentFrame.size.width, 
                                   0.15*contentFrame.size.height);
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    //if(cell is not droppable)
        return FJSpringBoardDragActionMove;
    
    CGRect rect = CGRectIntersection(insetRect, cell.frame);
    float area = rect.size.width * rect.size.height;
    float totalArea = cell.contentView.frame.size.width * cell.contentView.frame.size.height;
    
    if(area/totalArea > DROP_COVERAGE){
        return FJSpringBoardDragActionDrop;
    }
    
    return FJSpringBoardDragActionMove;
    
}

- (NSUInteger)_coveredCellIndexWithObscuredContentFrame:(CGRect)contentFrame{
    
    CGRect insetRect = CGRectInset(contentFrame, 
                                   0.15*contentFrame.size.width, 
                                   0.15*contentFrame.size.height);
    
    NSMutableIndexSet* coveredIndexes = [NSMutableIndexSet indexSet];
    
    [self.cells enumerateObjectsAtIndexes:[self.indexLoader loadedIndexes] options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
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
    
    debugLog(@"completing drag action...");

    if(self.reorderingIndex == NSNotFound)
        return;
    
    if(self.indexOfHighlightedCell == NSNotFound){
        
        [self _completeReorder];
        
    }else{
        
        [self _completeDrop];
        
    }
}

#pragma mark -
#pragma mark Reorder

- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index{
    
    if(index == NSNotFound)
        return;
    
    /*
    
    [self _removeHighlight];
    
    self.animatingReorder = YES;
    FJSpringBoardIndexLoader* im = (FJSpringBoardIndexLoader*)self.indexLoader;

    NSIndexSet* affectedIndexes = [im modifiedIndexesByMovingReorderingCellToCellAtIndex:index];
    
    FJSpringBoardCell* c = [self.indexLoader.cells objectAtIndex:self.reorderingIndex];
    
    if(![c isEqual:[NSNull null]]){
        
        c.alpha = 0;
    }
    
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
 
     */
}

- (void)_completeReorder{
    
    /*
    [self _removeHighlight];

    FJSpringBoardIndexLoader* im = (FJSpringBoardIndexLoader*)self.indexLoader;

    debugLog(@"completing reorder...");
    NSUInteger current = im.currentReorderingIndex;
    NSUInteger original = im.originalReorderingIndex;
    
    FJSpringBoardHorizontalLayout* l = (FJSpringBoardHorizontalLayout*)self.layout;
    NSUInteger page = [l pageForContentOffset:self.contentOffset];
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
    
    
    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:im.currentReorderingIndex];
    [self.indexLoader commitChanges];
    
    self.animatingReorder = YES;

    id<FJSpringBoardViewDataSource> d = self.dataSource;
    
    if([self.indexLoader.cells count] == 0){
        
        ALWAYS_ASSERT;
    }
    
    [self _animateDraggableViewToReorderedCellIndex:current completionBlock:^{
        
        if(![cell isEqual:[NSNull null]])
            cell.reordering = NO;
        
        self.draggableCellView = nil;

        self.animatingReorder = NO;
        if([d respondsToSelector:@selector(springBoardView:moveCellAtIndex:toIndex:)])
            [d springBoardView:self moveCellAtIndex:original toIndex:current];
        
        
    }];
    
     */
    
}



- (void)_animateDraggableViewToReorderedCellIndex:(NSUInteger)index completionBlock:(dispatch_block_t)block{
    
    UIView* v = [self.draggableCellView retain];
    
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
#pragma mark Droping


- (void)_highlightDropCellAtIndex:(NSUInteger)index{
    
    if(self.indexOfHighlightedCell == index)
        return;
    
    [self _removeHighlight];
    

    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    self.indexOfHighlightedCell = index;
        
    cell.userInteractionEnabled = NO;
    cell.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:CREATE_GROUP_ANIMATION_DURATION 
                          delay:REMOVE_GROUP_ANIMATION_DURATION
                        options:UIViewAnimationOptionCurveEaseOut  
                     animations:^(void) {
                         
                         cell.transform = CGAffineTransformMakeScale(1.3, 1.3);

                     } completion:^(BOOL finished) {
                         
                         cell.userInteractionEnabled = YES;
                         cell.userInteractionEnabled = YES;
                         
                     }];
    
}

- (void)_removeHighlight{
        
    if(self.indexOfHighlightedCell == NSNotFound)
        return;
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:indexOfHighlightedCell];


    [UIView animateWithDuration:REMOVE_GROUP_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseOut  
                     animations:^(void) {
                         
                         cell.transform = CGAffineTransformIdentity;
                         
                     } completion:^(BOOL finished) {
                         
                         self.indexOfHighlightedCell = NSNotFound;

                    }];
    
}

- (void)_completeDrop{
    
    /*
    //NSArray* objects = [self.cells objectsAtIndexes:indexes];
    
    NSUInteger index = self.indexOfHighlightedCell;
    
    [self _removeHighlight];
    
    FJSpringBoardCell* cell = nil;
    
    cell = [self.indexLoader.cells objectAtIndex:index];
    
    NSMutableIndexSet* cellsToAdd = [NSMutableIndexSet indexSet];
    
    NSUInteger movingIndex = self.indexLoader.currentReorderingIndex;
    
    if(![cell isKindOfClass:[FJSpringBoardGroupCell class]]){
        
        [self _createGroupCellFromCellAtIndex:index];
        
        [cellsToAdd addIndex:index+1];
        
        if(movingIndex >= index)
            movingIndex++;
    }        
    
    
    [cellsToAdd addIndex:movingIndex];
    
    [self _addCellsAtIndexes:cellsToAdd toGroupAtIndex:index];
    */
}




#pragma mark -
#pragma mark Touch Point Scrolling

- (BOOL)_scrollSpringBoardInDirectionOfEdge:(FJSpringBoardViewEdge)edge{
    
    debugLog(@"edge!");
    
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
#pragma mark paging

- (void)setPageControl:(id<FJSpringBoardViewPageControl>)aPageControl
{
    if (pageControl != aPageControl) {
        [aPageControl retain];
        [pageControl release];
        pageControl = aPageControl;
        
        [self.pageControl addTarget:self action:@selector(handlePageControlChange:) forControlEvents:UIControlEventValueChanged];
    }
}
- (IBAction)handlePageControlChange:(id<FJSpringBoardViewPageControl>)sender{
    
    BOOL animate = !self.isPaging;
    
    self.paging = YES;
    
    NSUInteger page = [sender currentPage];
    
    [self scrollToPage:page animated:animate];
    [sender updateCurrentPageDisplay];
    
    dispatchOnMainQueueAfterDelayInSeconds(1.0, ^{
        
        self.paging = NO;
        
    });
}

- (void)_updatePageControl{
    
    NSUInteger p = [self currentPage];
    
    if(p == NSNotFound)
        return;
    
    NSUInteger num = [self numberOfPages];
    
    if(num == NSNotFound)
        return;
    
    [self.pageControl setCurrentPage:p];
    [self.pageControl setNumberOfPages:num];
    [self.pageControl updateCurrentPageDisplay];

}



- (NSUInteger)numberOfPages{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    return [(FJSpringBoardHorizontalLayout*)self.layout pageCount];
}

- (NSUInteger)currentPage{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    return floorf(self.contentOffset.x/self.bounds.size.width);
    
}

- (NSUInteger)nextPage{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    FJSpringBoardHorizontalLayout* l = (FJSpringBoardHorizontalLayout*)self.layout;

    NSUInteger currentPage = [self currentPage];
    
    NSUInteger next = currentPage+1;
    
    if(next < l.pageCount){
        
        return next;
    }
     
    return NSNotFound;
    
}

- (NSUInteger)previousPage{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    NSUInteger currentPage = [self currentPage];
    
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
    
    [self setContentOffset:p animated:animated];
    
    
    return YES;
    
}


#pragma mark -
#pragma mark Selection

- (NSIndexSet *)indexesForSelectedCells{
    
    return [[self.selectedIndexes copy] autorelease];
}


@end

