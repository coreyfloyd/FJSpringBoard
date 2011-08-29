
#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import <QuartzCore/QuartzCore.h>
#import "FJSpringBoardCell.h"

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

@property(nonatomic, retain) NSMutableSet *reusableCells;

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

@property(nonatomic) BOOL shouldReload;

@property(nonatomic) FJSpringBoardCellAnimation layoutAnimation; //determines if changes should be animated

//@property(nonatomic) BOOL doubleTapped; //flag to handle double tap irregularities
@property(nonatomic) BOOL longTapped; //flag to handle long tap irregularities

@property(nonatomic, retain) UIView *draggableCellView;
@property(nonatomic) BOOL animatingReorder; //flag to indicate a reordering animation is occuring


@property(nonatomic) BOOL animatingContentOffset; //flag to indicate a scrolling animation is occuring (due to calling setContentOffset:animated:)

@property(nonatomic) CGPoint lastTouchPoint;

@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;

@property(nonatomic) NSUInteger indexOfHighlightedCell;

@property(nonatomic, retain) UILongPressGestureRecognizer *tapAndHoldRecognizer;
@property(nonatomic, retain) UITapGestureRecognizer *singleTapRecognizer;
//@property(nonatomic, retain) UITapGestureRecognizer *doubleTapRecognizer;
@property(nonatomic, retain) UILongPressGestureRecognizer *editingModeRecognizer;
@property(nonatomic, retain) UILongPressGestureRecognizer *draggingSelectionRecognizer;
@property(nonatomic, retain) UIPanGestureRecognizer *draggingRecognizer;


- (void)_configureLayout;
- (void)_updateIndexes;

- (void)_setNeedsReload;
- (void)_clearReload;

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

- (void)_updateModeForCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_deleteCellsAtIndexes:(NSIndexSet*)indexes withCompletionBlock:(dispatch_block_t)block;
- (void)_preLayoutIndexesComingIntoViewWhenRemovingIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes;

- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point checkOffScreenCells:(BOOL)flag;
- (CGRect)_frameForCellAtIndex:(NSUInteger)index checkOffScreenIndexes:(BOOL)flag;

- (void)_processEditingLongTapWithRecognizer:(UIGestureRecognizer*)g;
//dragging and dropping
- (void)_makeCellDraggableAtIndex:(NSUInteger)index;
- (void)_handleDraggableCellAtIndex:(NSUInteger)dragIindex withTouchPoint:(CGPoint)point;
- (FJSpringBoardDragAction)_actionForDraggableCellAtIndex:(NSUInteger)dragIndex coveredCellIndex:(NSUInteger)index obscuredContentFrame:(CGRect)contentFrame;
- (void)_completeDragAction;
- (NSUInteger)_coveredCellIndexWithObscuredContentFrame:(CGRect)contentFrame;
- (void)_animateDraggableViewToReorderedCellIndex:(NSUInteger)index completionBlock:(dispatch_block_t)block;
- (void)animateEmbiggeningOfDraggableCell;
- (void)animateEmbiggeningOfDraggableCellQuickly;

//reordering
- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index;
- (void)_completeReorder;

//scrolling during reordering
- (BOOL)_scrollSpringBoardInDirectionOfEdge:(FJSpringBoardViewEdge)edge;
- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch;

//drops
- (void)_highlightDropCellAtIndex:(NSUInteger)index;
- (void)_removeHighlight;
- (void)_completeDrop;

@end

@implementation FJSpringBoardView

@synthesize contentView;

@synthesize dataSource;
@synthesize delegate;

@synthesize springBoardInsets;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;

@synthesize shouldReload;

@synthesize indexLoader;
@synthesize layout;

@synthesize reusableCells;

@synthesize indexesScrollingInView;
@synthesize indexesNeedingLayout;
@synthesize indexesToDelete;
@synthesize indexesScrollingOutOfView;
@synthesize selectedIndexes;
@synthesize indexesToInsert;

@synthesize layoutIsDirty;
@synthesize layoutAnimation;

//@synthesize doubleTapped;
@synthesize longTapped;

@synthesize animatingReorder;
@synthesize draggableCellView;

@synthesize animatingContentOffset;

@synthesize lastTouchPoint;

@synthesize indexOfHighlightedCell;

@synthesize tapAndHoldRecognizer;
@synthesize singleTapRecognizer;
//@synthesize doubleTapRecognizer;
@synthesize editingModeRecognizer;
@synthesize draggingSelectionRecognizer;
@synthesize draggingRecognizer;



#pragma mark -
#pragma mark NSObject


- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [tapAndHoldRecognizer release];
    tapAndHoldRecognizer = nil;
    [singleTapRecognizer release];
    singleTapRecognizer = nil;
    //[doubleTapRecognizer release];
    //doubleTapRecognizer = nil;
    [editingModeRecognizer release];
    editingModeRecognizer = nil;
    [draggingSelectionRecognizer release];
    draggingSelectionRecognizer = nil;
    [draggingRecognizer release];
    draggingRecognizer = nil;    
    [contentView release];
    contentView = nil;    
    [draggableCellView release];
    draggableCellView = nil;   
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
                
        self.indexesScrollingInView = [NSMutableIndexSet indexSet];
        self.indexesNeedingLayout = [NSMutableIndexSet indexSet];
        self.selectedIndexes = [NSMutableIndexSet indexSet];
        self.indexesToInsert = [NSMutableIndexSet indexSet];
        self.indexesToDelete = [NSMutableIndexSet indexSet];
        self.indexesScrollingOutOfView = [NSMutableIndexSet indexSet];
        self.reusableCells = [NSMutableSet set];

        self.indexOfHighlightedCell = NSNotFound;
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
        
        
        /*
        UILongPressGestureRecognizer* g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(updateTapAndHold:)];
        g.minimumPressDuration = 0.1;
        g.delegate = self;
        g.cancelsTouchesInView = NO;
        [self addGestureRecognizer:g];
        self.tapAndHoldRecognizer = g;
        [g release];
    
         
        /*
        UITapGestureRecognizer* d = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
        d.numberOfTapsRequired = 2;
        [self addGestureRecognizer:d];
        self.doubleTapRecognizer = d;
        [d release];
        
        
        UITapGestureRecognizer* t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
        //[t requireGestureRecognizerToFail:d];
        [self addGestureRecognizer:t];
        self.singleTapRecognizer = t;
        [t release];
        
        UILongPressGestureRecognizer* l = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editingLongTapRecieved:)];
        l.minimumPressDuration = 0.75;
        [self addGestureRecognizer:l];
        self.editingModeRecognizer = l;
        [l release];
        

        l = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingSelectionLongTapReceived:)];
        l.minimumPressDuration = 0.1;
        l.cancelsTouchesInView = NO;
        [self addGestureRecognizer:l];
        self.draggingSelectionRecognizer = l;
        [l release];
        
        
        UIPanGestureRecognizer* p = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanningGestureReceived:)];
        p.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:p];
        self.draggingRecognizer = p;
        [p release]; 
       
         */
        
        self.mode = FJSpringBoardCellModeNormal;
        
    }
    return self;
}

/*
- (void)setFrame:(CGRect)aFrame{
    
    [super setFrame:aFrame];
    
    [self _updateLayout];
    
}

- (void)setBounds:(CGRect)aFrame{
    
    [super setBounds:aFrame];
    
    [self _updateLayout];
}
*/

- (CGRect)insetBounds{
    
    CGRect viewRect = self.bounds;
    viewRect = UIEdgeInsetsInsetRect(viewRect, self.springBoardInsets);
    return viewRect;
    
}

- (void)setSpringBoardInsets:(UIEdgeInsets)insets{
    
    springBoardInsets = insets;
    
    [self setNeedsLayout];
    //[self _updateLayout];
}

-(void)setCellSize:(CGSize)aSize{
    
    cellSize = aSize;
    
    [self _setNeedsReload];
    
}

- (void)setScrollDirection:(FJSpringBoardViewScrollDirection)direction{
    
    scrollDirection = direction;
    
    [self _configureLayout];

}

#pragma mark -
#pragma mark External Info Methods

- (NSUInteger)numberOfCells{
    
    return [self.indexLoader.allIndexes count];
    
}


- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:index];
    
    if([[NSNull null] isEqual:(NSNull*)cell])
        return nil;
    
    return cell;
}


- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell{
    
    NSUInteger i = [self.indexLoader.cells indexOfObject:cell];
    
    return i;
    
}

- (CGRect)frameForCellAtIndex:(NSUInteger)index{
    
    return [self _frameForCellAtIndex:index checkOffScreenIndexes:NO];
    
}

- (CGRect)_frameForCellAtIndex:(NSUInteger)index checkOffScreenIndexes:(BOOL)flag{
    
    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:index];
    
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
    
    NSIndexSet* a = [self.indexLoader.cells indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        
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
    [self scrollRectToVisible:f animated:animated];
    
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

- (void)_setNeedsReload{
    
    self.shouldReload = YES;
}

- (void)_clearReload{
    
    self.shouldReload = NO;
}

- (void)reloadData{
    
    [self _clearReload];
    
    //remove existing cells from view
    [self _removeCellsFromSpringBoardViewAtIndexes:self.indexLoader.allIndexes];
    
    //unload them (placed in reusable pool)
    [self _unloadCellsAtIndexes:self.indexLoader.allIndexes];
    
    [self _configureLayout]; //triggers _updateCells and _updateIndexes
}



#pragma mark -
#pragma mark configure layout

//only called on reload
- (void)_configureLayout{
      
    if(scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        self.layout = [[[FJSpringBoardHorizontalLayout alloc] initWithSpringBoardView:self] autorelease];
        self.pagingEnabled = YES;
    }else{
        self.layout = [[[FJSpringBoardVerticalLayout alloc] initWithSpringBoardView:self] autorelease];
        self.pagingEnabled = NO;
    }
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.layout.cellCount = numOfCells;

    self.indexLoader = [[[FJSpringBoardIndexLoader alloc] initWithCount:numOfCells] autorelease];
    self.indexLoader.layout = self.layout;
        
    [self setNeedsLayout];
}

//called when changes occur affecting layout

- (void)layoutSubviews{
    
    //self.layoutIsDirty = YES;
    
    if(self.shouldReload)
        [self reloadData];
    
    [self.layout updateLayout];
    
    if(self.layoutAnimation != FJSpringBoardCellAnimationNone){
    
        [UIView animateWithDuration:0.25 animations:^(void) {
                
            [self setContentSize:self.layout.contentSize];

        }];
        
        
    }else{
        
        [self setContentSize:self.layout.contentSize];

    }
    
    [self _layoutCellsAtIndexes:[[self.indexesNeedingLayout copy] autorelease]];
    [self.indexesNeedingLayout removeAllIndexes];
    
    /*
    if(self.layoutIsDirty)
        [self _updateIndexes];
    */
    
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
    CGRect f = CGRectMake(0, 0, size.width, size.height);
    self.contentView.frame = f;

}

- (void)setContentOffset:(CGPoint)offset{
    
    self.animatingContentOffset = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_resetAnimatingContentOffset) object:nil];
    [self performSelector:@selector(_resetAnimatingContentOffset) withObject:nil afterDelay:0.1];
    
    [self _updateIndexes];

    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];
        
    });
     */
    
    CGPoint previousOffset = self.contentOffset;
    
    [super setContentOffset:offset];
    
    CGPoint dragCenter = self.draggableCellView.center;
    dragCenter.x += (self.contentOffset.x-previousOffset.x);
    self.draggableCellView.center = dragCenter;
}

- (void)_resetAnimatingContentOffset{
    
    self.animatingContentOffset = NO;
    
}


#pragma mark -
#pragma mark Update Indexes

- (void)_updateIndexes{
    
    if(indexLoader == nil)
        return;
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
    NSRange rangeToRemove = changes.indexRangeToRemove;
    
    NSRange rangeToLoad = changes.indexRangeToAdd;
    
    if([self.onScreenCellIndexes count] > 0 && !indexesAreContiguous(self.onScreenCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    //check maths, newI == oldI - removed + added    
    [self.indexesScrollingOutOfView addIndexesInRange:rangeToRemove];
    
    //TODO: recheck to see if cells comming into view are already loaded and laid out, remove those that are
    [self.indexesScrollingInView addIndexesInRange:rangeToLoad];
    
    //unload cells that are no longer "visible"
    [self _unloadCellsScrollingOutOfViewAtIndexes:[self.indexesScrollingOutOfView copy]];
    
    //load cells that are now visible
    [self _loadCellsScrollingIntoViewAtIndexes:[self.indexesScrollingInView copy]];
    
    [self.indexLoader.cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
        
        if(![cell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        cell.alpha = 1;
        
    }];
         
    //self.layoutIsDirty = NO;

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
    
        if([self.indexLoader.allIndexes containsIndex:idx])
            return YES;
        return NO;
    
    }];
    
    [actualIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
       
        NSUInteger realIndex = [self.indexLoader oldIndexForNewIndex:index];
        
        FJSpringBoardCell* cell = [self.dataSource springBoardView:self cellAtIndex:realIndex];
        [cell retain];
        
        cell.index = index;
        cell.springBoardView = self;
        
        [self.indexLoader.cells replaceObjectAtIndex:index withObject:cell];
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
        
        if(![self.indexLoader.allIndexes containsIndex:index]){
            
            return;
        }
        
        //don't unload the index we are reordering
        FJSpringBoardIndexLoader* im = (FJSpringBoardIndexLoader*)self.indexLoader;
        if([im isKindOfClass:[FJSpringBoardIndexLoader class]]){
            
            if(index == im.currentReorderingIndex)
                return;
        }
        
        
        FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
        
        if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        [self.reusableCells addObject:eachCell];
        [self.indexLoader.cells replaceObjectAtIndex:index withObject:[NSNull null]];
        
        
    }];
    
}

#pragma mark -
#pragma mark layout / remove cells from view


- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSIndexSet* actualIndexes = [indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        if([self.indexLoader.allIndexes containsIndex:idx])
            return YES;
        return NO;
        
    }];

    [actualIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
    
        FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            return;
        }
        
        eachCell.index = index;
        //eachCell.mode = self.mode;

        //NSLog(@"Laying Out Cell %i", index);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        [self.contentView addSubview:eachCell];
        
    }];
    
    [self _updateModeForCellsAtIndexes:actualIndexes];
}


- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes{
    
    __block NSUInteger positionIndex = [positionIndexes firstIndex];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.indexLoader.allIndexes containsIndex:index])
            return;
        
        FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
        //eachCell.mode = self.mode;
        
        //NSLog(@"Laying Out Cell At Index %i in Old Index Position %i", index, positionIndex);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:positionIndex];
        eachCell.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        [self.contentView addSubview:eachCell];
        
        positionIndex = [positionIndexes indexGreaterThanIndex:positionIndex];
        
    }];
    
    [self _updateModeForCellsAtIndexes:indexes];

}


- (void)_removeCellsFromSpringBoardViewAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.indexLoader.allIndexes containsIndex:index]){
        
            return;
        }
        
        //don't remove the index we are reordering
        FJSpringBoardIndexLoader* im = (FJSpringBoardIndexLoader*)self.indexLoader;
        if([im isKindOfClass:[FJSpringBoardIndexLoader class]]){
            
            if(index == im.currentReorderingIndex)
                return;
        }
        
        FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
        
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
        
    
    //remove existing cells from view
    [self _removeCellsFromSpringBoardViewAtIndexes:indexSet];
    
    //unload them (placed in reusable pool)
    [self _unloadCellsAtIndexes:indexSet];
    
    //create and insert in array
    [self _loadCellsAtIndexes:indexSet];
    
    //set frame and add to view
    [self _layoutCellsAtIndexes:indexSet];

    if(animation == FJSpringBoardCellAnimationNone)
        return;
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.onScreenCellIndexes containsIndex:index]){
            
            return;
        }
        
        FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
        
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
    if(firstIndex > [self.indexLoader.allIndexes lastIndex] + 1){
        
        ALWAYS_ASSERT;
    }
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    
    if(numOfCells != [indexLoader.allIndexes count] + [indexSet count]){
        
        [NSException raise:NSInternalInconsistencyException format:@"inserted cell count + previous cell count != datasource cell count"];
        
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
    
    NSIndexSet* toLayout = [self.indexLoader modifiedIndexesByAddingCellsAtIndexes:indexes];
    [self.indexesNeedingLayout addIndexes:toLayout];

    [self.indexLoader commitChanges];

    //load
    [self _loadCellsAtIndexes:indexes];
    
    //add to view
    [self _layoutCellsAtIndexes:indexes];

    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){
             
        [self _layoutCellsAtIndexes:toLayout];
        [self _removeIndexesGoingOutOfViewWhenAddingIndexes:indexes];
        [self setNeedsLayout];
        block();               
        return;
    }
    
    self.userInteractionEnabled = NO; 

    //fade in
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
        eachCell.alpha = 0;
        
    }];
    
    [UIView animateWithDuration:MOVE_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut  
                     animations:^(void) {
                         
                         [self _layoutCellsAtIndexes:toLayout];
                         
                     } completion:^(BOOL finished) {
                         
                         
                     }];

    
    
    [UIView animateWithDuration:INSERT_ANIMATION_DURATION 
                          delay:MOVE_ANIMATION_DURATION 
                        options:UIViewAnimationOptionCurveEaseInOut  
                     animations:^(void) {
                                                  
                         [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
                             
                             FJSpringBoardCell* eachCell = [self.indexLoader.cells objectAtIndex:index];
                             eachCell.alpha = 1;
                             
                             
                         }];
                                                  
                     } completion:^(BOOL finished) {
                         
                         [self _removeIndexesGoingOutOfViewWhenAddingIndexes:indexes];
                         self.userInteractionEnabled = YES;
                         
                         [self setNeedsLayout];
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
        
        return [self.indexLoader.allIndexes containsIndex:idx];
        
    }];
    
    if([idxs count] != [indexSet count]){
        
        ALWAYS_ASSERT;
    }   
       
    [self.indexesToDelete addIndexes:indexSet];

    self.layoutAnimation = animation; //reset on next layout update

    [self _deleteCellsAtIndexes:[[self.indexesToDelete copy] autorelease] withCompletionBlock:^{
        
        [self.indexesToDelete removeAllIndexes];
        self.layoutAnimation = FJSpringBoardCellAnimationNone;
                
        NSUInteger newNumOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
        
        if(newNumOfCells != [indexLoader.allIndexes count]){
            
            ALWAYS_ASSERT; //num != pervious count - number deleted 
        } 
        
    }];

       
}


- (void)_deleteCell:(FJSpringBoardCell*)cell{
    
    NSUInteger index = [self.indexLoader.cells indexOfObject:cell];
    
    if(index == NSNotFound){
        ALWAYS_ASSERT;
        return;
    }
    
    
    if(![self.indexLoader.allIndexes containsIndex:index]){
        
        ALWAYS_ASSERT;
        return;
    }
    
    //[self.indexesToDelete addIndexes:shouldDelete];
    
    self.layoutAnimation = FJSpringBoardCellAnimationFade; //reset on next layout update
    
    [self _deleteCellsAtIndexes:[NSIndexSet indexSetWithIndex:index] withCompletionBlock:^{
        
        //[self.indexesToDelete removeAllIndexes];
        self.layoutAnimation = FJSpringBoardCellAnimationNone;
        
        NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
        
        [self.dataSource springBoardView:self commitDeletionForCellAtIndex:index];

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
    
    NSArray* cellsToDelete = [[[self.indexLoader.cells objectsAtIndexes:indexes] retain] autorelease];
    
    NSIndexSet* toLayout = [self.indexLoader modifiedIndexesByRemovingCellsAtIndexes:indexes];
    
    [self.indexesNeedingLayout addIndexes:toLayout];
    
    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){
        
        [self _layoutCellsAtIndexes:toLayout];

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
        
        [self setNeedsLayout];
        [self.indexLoader commitChanges];
        block();                         

        return;
    }
    
    self.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^(void) {
                                                  
                         [cellsToDelete enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }                                 
                             cell.alpha = 0;
                             
                         }];
                         
                     } 
                     completion:^(BOOL finished) {
                         
                         [self setNeedsLayout];

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
                         
                     }];
    
    [UIView animateWithDuration:MOVE_ANIMATION_DURATION 
                          delay:DELETE_ANIMATION_DURATION 
                        options:UIViewAnimationOptionCurveEaseInOut  
                     animations:^(void) {
                         
                         [self _layoutCellsAtIndexes:toLayout];
                         
                     } completion:^(BOOL finished) {
                         
                         //TODO: remove newly offscreen cells
                         
                         [self setNeedsLayout];
                         self.userInteractionEnabled = YES;
                         [self.indexLoader commitChanges];
                         
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
    
    /*
    if(aMode == FJSpringBoardCellModeNormal){
        
        self.singleTapRecognizer.enabled = YES;
        //self.doubleTapRecognizer.enabled = YES;
        self.editingModeRecognizer.enabled = YES;
        
        self.draggingRecognizer.enabled = NO;
        self.draggingSelectionRecognizer.enabled = NO;
        
        
    }else{
        
        self.singleTapRecognizer.enabled = NO;
        //self.doubleTapRecognizer.enabled = NO;
        self.editingModeRecognizer.enabled = YES; //to get the first drag
        
        self.draggingRecognizer.enabled = YES;
        self.draggingSelectionRecognizer.enabled = YES;
    }
    */
    
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

    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:index];
        
    if([cell isEqual:[NSNull null]]){
        
        ALWAYS_ASSERT;
    }
    
    if(![cell draggable])
        return;
    
    //start reordering
    [self.indexLoader beginReorderingIndex:index];
            
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
    
    
    if(self.indexLoader.originalReorderingIndex == NSNotFound){
        
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
    
    if(index == self.indexLoader.currentReorderingIndex)
        return FJSpringBoardDragActionNone;
    
    if(![self.dataSource respondsToSelector:@selector(emptyGroupCellForSpringBoardView:)])
        return FJSpringBoardDragActionMove;
    
    NSUInteger idx = self.indexLoader.currentReorderingIndex;
    
    //if no currently dragging index, 
    if(idx == NSNotFound)
        idx = dragIndex;
    
    if(idx == NSNotFound)
        return FJSpringBoardDragActionNone;

    CGRect insetRect = CGRectInset(contentFrame, 
                                   0.15*contentFrame.size.width, 
                                   0.15*contentFrame.size.height);
    
    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:index];
    
    if(!cell.draggable)
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
    
    [self.indexLoader.cells enumerateObjectsAtIndexes:self.onScreenCellIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
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
    
        FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:idx];
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

    if(self.indexLoader.originalReorderingIndex == NSNotFound)
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
    
    [self _removeHighlight];
    
    self.animatingReorder = YES;
    FJSpringBoardIndexLoader* im = (FJSpringBoardIndexLoader*)self.indexLoader;

    NSIndexSet* affectedIndexes = [im modifiedIndexesByMovingReorderingCellToCellAtIndex:index];
    
    FJSpringBoardCell* c = [self.indexLoader.cells objectAtIndex:im.currentReorderingIndex];
    
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
    
}

- (void)_completeReorder{
    
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
    

    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:index];
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
    
    FJSpringBoardCell* cell = [self.indexLoader.cells objectAtIndex:indexOfHighlightedCell];


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

