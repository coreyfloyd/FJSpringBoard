
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

#define MOVE_ANIMATION_DURATION 0.25
#define DELETE_ANIMATION_DURATION 0.50
#define INSERT_ANIMATION_DURATION 1.25
#define RELOAD_ANIMATION_DURATION 0.75
#define LAYOUT_ANIMATION_DURATION 0.25

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

@property (nonatomic) BOOL canProcessActions;

//junk pile
@property(nonatomic, retain) NSMutableSet *reusableCells;


//mark the layout for recalculation
- (void)_setNeedsLayoutCalculation;
- (void)_clearLayoutCalculation;
@property(nonatomic) BOOL shouldRecalculateLayout;

@property (nonatomic) BOOL suspendLayoutUpdates;

- (void)_calculateLayout;

@property(nonatomic) BOOL shouldFixLoadedCells;
- (void)_setLoadedCellsDirty;
- (void)_clearLoadedCellsDirty;
- (void)_fixLoadedCells;

//mark a full reload
- (void)_setNeedsReload;
- (void)_clearReload;
@property(nonatomic) BOOL shouldReload;


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


- (void)_setupActionQueue;
- (void)_processActionQueue;
- (void)_processUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)completion;


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



@end

@implementation FJSpringBoardView

@synthesize contentView;

@synthesize dataSource;
@synthesize delegate;

@synthesize pageInsets;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;

@synthesize shouldReload;
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

@synthesize canProcessActions;
@synthesize shouldFixLoadedCells;


#pragma mark -
#pragma mark NSObject


- (void)dealloc {    
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

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        self.contentView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
        [self addSubview:self.contentView];
                
        self.selectedIndexes = [NSMutableIndexSet indexSet];
        
        self.cells = [NSMutableArray array];

        self.reusableCells = [NSMutableSet set];

        self.indexOfHighlightedCell = NSNotFound;
        self.reorderingIndex = NSNotFound;
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
        self.mode = FJSpringBoardCellModeNormal;
        self.canProcessActions = YES;

        
    }
    return self;
}

- (void)setFrame:(CGRect)f{
    
    [super setFrame:f];
    
    [self _setNeedsLayoutCalculation];
}

- (void)setPageInsets:(UIEdgeInsets)insets{
    
    pageInsets = insets;
    
    [self setNeedsLayout];
}

-(void)setCellSize:(CGSize)aSize{
    
    cellSize = aSize;
    
    [self _setNeedsReload];
    
}

- (void)setScrollDirection:(FJSpringBoardViewScrollDirection)direction{
    
    scrollDirection = direction;
    
    [self _setLoadedCellsDirty];
            
    [self _setNeedsLayoutCalculation];
        
    [self setNeedsLayout];

}

#pragma mark -
#pragma mark External Info Methods

- (NSUInteger)numberOfCells{
    
    return [self.indexLoader.allIndexes count];
    
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
}

- (void)_resetAnimatingContentOffset{
    
    self.animatingContentOffset = NO;
    
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
      
    if(scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        self.layout = [[[FJSpringBoardHorizontalLayout alloc] initWithSpringBoardView:self] autorelease];
        self.pagingEnabled = YES;
    }else{
        self.layout = [[[FJSpringBoardVerticalLayout alloc] initWithSpringBoardView:self] autorelease];
        self.pagingEnabled = NO;
    }
    
    self.layout.cellCount = [[self.indexLoader allIndexes] count];

    self.indexLoader.layout = self.layout;
    
    [self.layout calculateLayout];
    
    CGRect f = CGRectMake(0, 0, self.layout.contentSize.width, self.layout.contentSize.height);
    self.contentView.frame = f; 
    [self setContentSize:self.layout.contentSize];

}

#pragma mark -
#pragma mark Fix layout


- (void)_setLoadedCellsDirty{
    
    self.shouldFixLoadedCells = YES;
    
}

- (void)_clearLoadedCellsDirty{
    
    self.shouldFixLoadedCells = NO;
}

//only called on reload
- (void)_fixLoadedCells{
    
    [self _clearLoadedCellsDirty];
    
    [self.indexLoader updateIndexesWithContentOffest:self.contentOffset]; //this causes the index loader to recalculate cells to load in case we changed scroll directions.
    
    [UIView animateWithDuration:MOVE_ANIMATION_DURATION animations:^(void) {
        
        [self _layoutCellsAtIndexes:[self.indexLoader loadedIndexes]]; //relay out loaded cells. 
        
    }];
        
}


#pragma mark -
#pragma mark Layout

//called when changes occur affecting layout
- (void)layoutSubviews{
            
    
    
    //reload entire table if needed
    if(self.shouldReload)
        [self reloadData];
    
    //recalculate layout
    if(self.shouldRecalculateLayout){
        
        NSRange visibleCellRange = [self.layout visibleRangeForContentOffset:self.contentOffset];
        
        NSUInteger firstVisibleCell = visibleCellRange.location; 
        
        [self _calculateLayout];
        
        dispatchOnMainQueueAfterDelayInSeconds(MOVE_ANIMATION_DURATION, ^(void) {
            [self scrollToCellAtIndex:firstVisibleCell atScrollPosition:FJSpringBoardCellScrollPositionMiddle animated:YES];        
        });

    }
    
    //fix any loaded cells
    if(self.shouldFixLoadedCells)
        [self _fixLoadedCells];

   
    //unload cells that are no longer "visible"
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
#pragma mark Reload

- (void)_setNeedsReload{
    
    self.shouldReload = YES;
}

- (void)_clearReload{
    
    self.shouldReload = NO;
}

- (void)reloadData{
    
    [self _clearReload];
    
    //unload all cells
    [self _removeCellsAtIndexes:self.indexLoader.allIndexes];
    [self _unloadCellsAtIndexes:self.indexLoader.allIndexes];
    
    //remove cache
    [self.reusableCells removeAllObjects];
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    self.cells = nullArrayOfSize(numOfCells);
    
    self.indexLoader = [[[FJSpringBoardIndexLoader alloc] initWithCount:numOfCells] autorelease];
    
    [self _setNeedsLayoutCalculation];
    
    [self setNeedsLayout];
    
    [self layoutIfNeeded];
}




#pragma mark -
#pragma mark Load  Cells


- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
               
        [self _loadCellAtIndex:index];
               
    }];

}

- (void)_loadCellAtIndex:(NSUInteger )index{
    
    FJSpringBoardCell* cell = [self.dataSource springBoardView:self cellAtIndex:index];
    [cell retain];
    
    cell.index = index;
    cell.springBoardView = self;
    
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
#pragma mark Actions


- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self _setupActionQueue];
    
    [[self indexLoader] queueActionByReloadingCellsAtIndexes:indexSet withAnimation:animation];
    
    [self _processActionQueue];

    return;

    //remove from springboard
    [self _removeCellsAtIndexes:indexSet];
    
    //unload existing cells (placed in reusable pool)
    [self _unloadCellsAtIndexes:indexSet];
    
    //create and insert in array
    [self _loadCellsAtIndexes:indexSet];
    
    //set frame and add to view
    [self _layoutCellsAtIndexes:indexSet];

    if(animation == FJSpringBoardCellAnimationNone)
        return;
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        //TODO: must update Index Loader, this is an action…
    
        if(![self.indexLoader.loadedIndexes containsIndex:index]){
            
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


//3 situations, indexset in vis range, indexset > vis range, indexset < vis range
- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    if([indexSet count] == 0)
        return;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    if(numOfCells != [indexLoader.allIndexes count] + [indexSet count]){
        
        [NSException raise:NSInternalInconsistencyException format:@"inserted cell count + previous cell count != datasource cell count"];
        
    } 
    
    [self _setupActionQueue];
    
    NSArray* nulls = nullArrayOfSize([indexSet count]);
    
    [self.cells insertObjects:nulls atIndexes:indexSet];
    
    [[self indexLoader] queueActionByInsertingCellsAtIndexes:indexSet withAnimation:animation];
    
    [self _processActionQueue];
   
    
}

- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    if([indexSet count] == 0)
        return;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    if(numOfCells != [indexLoader.allIndexes count] - [indexSet count]){
        
        [NSException raise:NSInternalInconsistencyException format:@"previous cell count - deleted cell count != datasource cell count"];
        
    }
    
    [self _setupActionQueue];

    NSArray* oldCells = [self.cells copy];

    [self.cells removeObjectsAtIndexes:indexSet];
    
    [[self indexLoader] queueActionByDeletingCellsAtIndexes:indexSet currentCellState:oldCells withAnimation:animation];
    
    [oldCells release];
    
    [self _processActionQueue];

}


- (void)_deleteCell:(FJSpringBoardCell*)cell{
    
    //we are not doing internal deletes if you are in the middle of shuffling around other things
    if(!self.canProcessActions)
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
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];

    [self.dataSource springBoardView:self commitDeletionForCellAtIndex:index];    
    
    NSUInteger newNumOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    if(numOfCells - 1 != newNumOfCells){
        
        [NSException raise:NSInternalInconsistencyException format:@"previous cell count - deleted cell count != datasource cell count"];
    } 
    
    [self _setupActionQueue];
    
    [self.cells removeObjectAtIndex:index];
    
    [[self indexLoader] queueActionByDeletingCellsAtIndexes:[NSIndexSet indexSetWithIndex:index] currentCellState:self.cells withAnimation:FJSpringBoardCellAnimationFade];    
    
    [self _processActionQueue];

}

- (void)beginUpdates{
    
    self.canProcessActions = NO;
}


- (void)endUpdates{
    
    self.canProcessActions = YES;
    
    [self _processActionQueue];
    
}


- (void)_setupActionQueue{
    

    
}

- (void)_processActionQueue{
    
    if(canProcessActions == NO)
        return;
    
    FJSpringBoardUpdate* update = [[self indexLoader] processFirstActionInQueue];
    
    if(update == nil)
        return;
    
    [self _processUpdate:update completionBlock:^(void) {
        
        [self _processActionQueue];
        
    }];   
    
}



#pragma mark - Process Updates

- (void)_processMoveActions:(NSArray*)moves completionBlock:(dispatch_block_t)block{
    
    [moves enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellUpdate* action = obj;
        
#if DEBUG == 2
        
        extendedDebugLog(@"move action - old location: %i new location: %i", action.oldSpringBoardIndex, action.newSpringBoardIndex);
#endif
        
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
        
    }];
    
    [UIView animateWithDuration:MOVE_ANIMATION_DURATION 
                     animations:^(void) {
                         
                         [moves enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCellUpdate* action = obj;
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
                             
                             [self _layoutCell:cell atIndex:action.newSpringBoardIndex];
                             cell.index = action.newSpringBoardIndex;
                
                             
                         }];
                         
                         
                         
                     } completion:^(BOOL finished) {
                         
#if DEBUG == 2
                         [moves enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                          
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

- (void)_processInsertionActions:(NSArray*)insertions completionBlock:(dispatch_block_t)block{
    
    NSMutableIndexSet* insetionIndexes = [NSMutableIndexSet indexSet];
    
    [insertions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellUpdate* action = obj;
        
#if DEBUG == 2
        
        extendedDebugLog(@"insert action - new location: %i", action.newSpringBoardIndex);
#endif

        FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
        ASSERT_TRUE(cell == (FJSpringBoardCell*)[NSNull null] || cell == nil);
        
        [self _loadCellAtIndex:action.newSpringBoardIndex];
        
        cell = [self cellAtIndex:action.newSpringBoardIndex];
        
        ASSERT_TRUE(cell != nil);
        
        [self _layoutCell:cell atIndex:action.newSpringBoardIndex];
        cell.alpha = 0;
        
        [insetionIndexes addIndex:action.newSpringBoardIndex];
        
    }];
    
    
    [UIView animateWithDuration:INSERT_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^(void) {
                         
                         [insetionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:idx];
                             cell.alpha = 1.0;
                             
                         }];
                         
                         
                     } completion:^(BOOL finished) {
                         
                         if(block)
                             block();
                     }];
    
    
    
}


- (void)_processInsertionUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    NSArray* insertionActions = [update sortedCellActionUpdates];
    NSArray* moveActions = [update sortedCellMovementUpdates];
    
    [self _processMoveActions:moveActions completionBlock:^(void) {

        [self _processInsertionActions:insertionActions completionBlock:^(void) {
        
            if(block)
                block();
            
        }];
        
    }];
    
        
}

- (void)_processDeletionActions:(NSArray*)deletions priorCellState:(NSArray*)priorCellState completionBlock:(dispatch_block_t)block{
    
    NSMutableIndexSet* deletionIndexes = [NSMutableIndexSet indexSet];
    
    [deletions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellUpdate* action = obj;
        
#if DEBUG == 2
        
        extendedDebugLog(@"delete action - old location: %i", action.oldSpringBoardIndex);
#endif
        
        [deletionIndexes addIndex:action.oldSpringBoardIndex];
        
    }];
    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^(void) {
                          
                         [deletionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = [priorCellState objectAtIndex:idx];
                             
                             if([[NSNull null] isEqual:(NSNull*)cell])
                                 return;
                             
                             cell.alpha = 0;
                             
                         }];
                         
                         
                     } completion:^(BOOL finished) {
                         
                         [deletionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = [priorCellState objectAtIndex:idx];
                             
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

    
}




- (void)_processDeletionUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    NSArray* deletionActions = [update sortedCellActionUpdates];
    NSArray* moveActions = [update sortedCellMovementUpdates];
    
    [self _processDeletionActions:deletionActions priorCellState:update.cellStatePriorToAction completionBlock:^(void) {
        
        [self _processMoveActions:moveActions completionBlock:^(void) {
            
            if(block)
                block();
            
        }];
     
    }];
   
}

- (void)_processReloadActions:(NSArray*)reloads completionBlock:(dispatch_block_t)block{
    
    [UIView animateWithDuration:RELOAD_ANIMATION_DURATION/2 
                     animations:^(void) {
                         
                         [reloads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             
                             FJSpringBoardCellUpdate* action = obj;
                             FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
                             cell.alpha = 0.0;
                             
#if DEBUG == 2
                             
                             extendedDebugLog(@"reload action - location: %i", action.newSpringBoardIndex);
#endif
                         }];
                         
                         
                     } completion:^(BOOL finished) {
                         
                         [reloads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCellUpdate* action = obj;
                             [self _removeCellAtIndex:action.newSpringBoardIndex];
                             [self _unloadCellAtIndex:action.newSpringBoardIndex]
                             ;
                             [self _loadCellAtIndex:action.newSpringBoardIndex];
                             
                             FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
                             [self _layoutCell:cell atIndex:action.newSpringBoardIndex];
                             cell.alpha = 0.0;

                         }];
                         
                         
                         [UIView animateWithDuration:RELOAD_ANIMATION_DURATION/2 
                                          animations:^(void) {
                                              
                                              [reloads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                  
                                                  FJSpringBoardCellUpdate* action = obj;
                                                  FJSpringBoardCell* cell = [self cellAtIndex:action.newSpringBoardIndex];
                                                  cell.alpha = 1.0;

                                              }];
                                              
                                              
                                              
                                          } completion:^(BOOL finished) {
                                              
                                              if(block)
                                                  block();
                                              
                                          }];
                         
                     }];
    
    
    
}



- (void)_processReloadUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)block{
    
    NSArray* reloadActions = [update sortedCellActionUpdates];
    
    [self _processReloadActions:reloadActions completionBlock:^(void) {
        
        if(block)
            block();
        
    }];
    
    
}

- (void)_processUpdate:(FJSpringBoardUpdate*)update completionBlock:(dispatch_block_t)completion{
    
    self.suspendLayoutUpdates = YES;
    self.userInteractionEnabled = NO;

    extendedDebugLog([self.contentView recursiveDescription]);
    
    dispatch_block_t block = ^{
        
        extendedDebugLog([self.contentView recursiveDescription]);
        
        self.suspendLayoutUpdates = NO;
        self.userInteractionEnabled = YES;
        [self setNeedsLayout];
        
        if(completion)
            completion();
        
    };
    
    
    FJSpringBoardActionType type = update.actionType;
    
    switch (type) {
        case FJSpringBoardActionReload:
            [self _processReloadUpdate:update completionBlock:block];
            break;
        case FJSpringBoardActionInsert:
            [self _processInsertionUpdate:update completionBlock:block];
            break;
        case FJSpringBoardActionDelete:
            [self _processDeletionUpdate:update completionBlock:block];
            break;
        default:
            break;
    }
           
    
    extendedDebugLog([self.contentView recursiveDescription]);
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

- (NSUInteger)numberOfPages{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    return [(FJSpringBoardHorizontalLayout*)self.layout pageCount];
}

- (NSUInteger)page{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return NSNotFound;
    
    return floorf(self.contentOffset.x/self.bounds.size.width);
    
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
    
    [self setContentOffset:p animated:animated];
    
    return YES;
    
}


#pragma mark -
#pragma mark Selection

- (NSIndexSet *)indexesForSelectedCells{
    
    return [[self.selectedIndexes copy] autorelease];
}


@end


/*
 - (void)didDoubleTap:(UITapGestureRecognizer*)g{
 
 CGPoint p = [g locationInView:self.contentView];
 self.lastTouchPoint = p;
 
 NSUInteger indexOfCell = [self indexOfCellAtPoint:p];
 
 if(indexOfCell == NSNotFound)
 return;
 
 //FJSpringBoardCell* c = [self.indexLoader.cells objectAtIndex:indexOfCell];
 
 if(doubleTapped){
 
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_resetDoubleTapped) object:nil];
 
 [self performSelector:@selector(_resetDoubleTapped) withObject:nil afterDelay:0.5];
 
 return;
 }
 
 self.doubleTapped = YES;
 [self performSelector:@selector(_resetDoubleTapped) withObject:nil afterDelay:0.5];
 
 if([delegate respondsToSelector:@selector(springBoardView:cellWasDoubleTappedAtIndex:)]){
 
 [delegate springBoardView:self cellWasDoubleTappedAtIndex:indexOfCell];
 
 
 }
 
 }
 */

/*
 - (void)_resetDoubleTapped{
 
 self.doubleTapped = NO;
 }
 */

