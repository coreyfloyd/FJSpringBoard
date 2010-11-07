
#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import <QuartzCore/QuartzCore.h>

#define DELETE_ANIMATION_DURATION 1.23
#define INSERT_ANIMATION_DURATION 1.25
#define RELOAD_ANIMATION_DURATION 0.75
#define LAYOUT_ANIMATION_DURATION 0.25

#define EDGE_CUSHION 20.0

typedef enum  {
    FJSpringBoardViewEdgeNone,
    FJSpringBoardViewEdgeTop,
    FJSpringBoardViewEdgeRight,
    FJSpringBoardViewEdgeBottom,
    FJSpringBoardViewEdgeLeft
} FJSpringBoardViewEdge;


float nanosecondsWithSeconds(float seconds){
    
    return (seconds * 1000000000);
    
}

@interface FJSpringBoardCell(Internal)

@property(nonatomic, assign) FJSpringBoardView* springBoardView;


@end


@interface FJSpringBoardView()

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

@property(nonatomic, retain) id<FJIndexMapping> indexMap;
@property(nonatomic, retain) UIView *reorderingCellView;
@property(nonatomic) BOOL animatingReorder; //flag to indicate a reordering animation is occuring


@property(nonatomic) BOOL animatingContentOffset; //flag to indicate a scrolling animation is occuring (due to calling setContentOffset:animated:)
@property(nonatomic) CGPoint lastContentOffset; //used to determine the above flag


@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;


- (void)_configureLayout;
- (void)_updateLayout;
- (void)_updateIndexes;

- (void)_loadCellsScrollingIntoViewAtIndexes:(NSIndexSet*)indexes;
- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_unloadCellsScrollingOutOfViewAtIndexes:(NSIndexSet*)indexes;
- (void)_removeCellsFromSpringBoardViewAtIndexes:(NSIndexSet*)indexes;
- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_deleteCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes;

- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point;

//reordering
- (UIImage*)_createImageFromCell:(FJSpringBoardCell*)cell;
- (void)_makeCellReorderableAtTouchPoint:(CGPoint)point;
- (NSUInteger)_newCellIndexForTouchPoint:(CGPoint)point;
- (void)_handleReorderbleCellWithTouchPoint:(CGPoint)point;
- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index;
- (void)_completeReorder;

//scrolling during reordering
- (BOOL)_scrollSpringBoardInDirectionOfEdge:(FJSpringBoardViewEdge)edge;
- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch;
- (void)_keepReorderingCellUnderTouchPointDuringAnimationWithStartingTouchPoint:(CGPoint)point;

@end

@implementation FJSpringBoardView

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
@synthesize reorderingCellView;

@synthesize animatingContentOffset;
@synthesize lastContentOffset;







#pragma mark -
#pragma mark NSObject


- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [indexMap release];
    indexMap = nil;    
    [reorderingCellView release];
    reorderingCellView = nil;    
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
        
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
        
        UITapGestureRecognizer* d = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
        d.numberOfTapsRequired = 2;
        [self addGestureRecognizer:d];
        
        UITapGestureRecognizer* t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
        [t requireGestureRecognizerToFail:d];
        [self addGestureRecognizer:t];
        
        UILongPressGestureRecognizer* l = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTap:)];
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
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([[NSNull null] isEqual:(NSNull*)cell]){
        
        return [self.layout frameForCellAtIndex:index];
        
    }
    
    return cell.frame;
    
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
    
    CGRect f =  [self frameForCellAtIndex:index];
    
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

- (void)reloadData{
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _unloadCellsScrollingOutOfViewAtIndexes:self.onScreenCellIndexes];
    self.cells = nullArrayOfSize([self.allIndexes count]);
    self.indexMap = [[FJNormalIndexMap alloc] initWithArray:self.cells];
    
    [self _configureLayout]; //triggers _updateCells and _updateIndexes
}



#pragma mark -
#pragma mark configure layout

//only called on reload
- (void)_configureLayout{
      
    if(scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        self.layout = [[[FJSpringBoardHorizontalLayout alloc] init] autorelease];
        self.pagingEnabled = YES;
    }else{
        self.layout = [[[FJSpringBoardVerticalLayout alloc] init] autorelease];
        self.pagingEnabled = NO;
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
                
            self.contentSize = self.layout.contentSize;

        }];
        
        
    }else{
        
        self.contentSize = self.layout.contentSize;

    }
    
    if(self.layoutIsDirty)
        [self _updateIndexes];
    
}


#pragma mark -
#pragma mark UIScrollView

- (void)setContentOffset:(CGPoint)offset{
    
	[super setContentOffset: offset];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];

    });
}

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animate{
    
    self.animatingContentOffset = YES;
    self.lastContentOffset = self.contentOffset;
	[super setContentOffset: offset animated: animate];  
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(contentOffsetAnimationCheck:) userInfo:nil repeats:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];
        
    });    
}

- (void)contentOffsetAnimationCheck:(NSTimer*)timer{
    
    if(CGPointEqualToPoint(self.contentOffset, self.lastContentOffset)){
        
        self.animatingContentOffset = NO;
        
        [timer invalidate];
    }
    
    self.lastContentOffset = self.contentOffset;
}

- (void)setContentSize:(CGSize)size{
    
    if(!CGSizeEqualToSize(size, self.contentSize)){
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self flashScrollIndicators];

        });
    }
    
    [super setContentSize:size];
    
}


#pragma mark -
#pragma mark Update Indexes

- (void)_updateIndexes{
    
    if(indexLoader == nil)
        return;
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
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
    
    self.layoutAnimation = FJSpringBoardCellAnimationNone;
    self.layoutIsDirty = NO;

}

#pragma mark -
#pragma mark Load / Unload Cells



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
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
       
        NSUInteger realIndex = [self.indexMap oldIndexForNewIndex:index];

        FJSpringBoardCell* cell = [self.dataSource springBoardView:self cellAtIndex:realIndex];
        [cell retain];
        
        cell.springBoardView = self;
        
        [self.cells replaceObjectAtIndex:index withObject:cell];
        [cell release];
        
    }];

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

- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
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
        
        if([self.reorderingCellView superview] == nil)
            [self addSubview:eachCell];
        else
            [self insertSubview:eachCell belowSubview:self.reorderingCellView];
    
    }];
}



- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes{
    
    __block NSUInteger positionIndex = [positionIndexes firstIndex];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.onScreenCellIndexes containsIndex:index]){
            
            return;
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        eachCell.mode = self.mode;
        
        //NSLog(@"Laying Out Cell At Index %i in Old Index Position %i", index, positionIndex);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:positionIndex];
        eachCell.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        if([self.reorderingCellView superview] == nil)
            [self addSubview:eachCell];
        else
            [self insertSubview:eachCell belowSubview:self.reorderingCellView];
        
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
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
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
    
    if(firstIndex > [self.allIndexes lastIndex] + 1){
        
        ALWAYS_ASSERT;
    } 
    
    
    self.layoutAnimation = animation; //reset on next layout update
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self.indexesToInsert addIndexes:indexSet];
    
    NSUInteger startIndex = MAX([indexSet lastIndex] + 1, [self.onScreenCellIndexes firstIndex]);
    NSUInteger lastIndex = [self.onScreenCellIndexes lastIndex] + [indexSet count];
    NSIndexSet* toLayOut = contiguousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); //non-continuous:remove indexSet form vis cell set, remove indexes less than the first index in indexset
    [self.indexesNeedingLayout addIndexes:toLayOut];
    
    //not necesarily needed if we can figure how to not fuck up double loading these later when we scroll since the indexloader is left in the dark
    startIndex = [self.onScreenCellIndexes lastIndex] + 1;
    NSUInteger length = [indexSet count];
    [self.indexesScrollingOutOfView addIndexesInRange:NSMakeRange(startIndex, length)];
    
    //insert new cells
    [self _insertCellsAtIndexes:[self.indexesToInsert copy]];
    
    //load cells comming into range??
    NSMutableIndexSet* unloaded = [indexSet mutableCopy];
    [unloaded removeIndexes:self.onScreenCellIndexes];
    startIndex = [self.onScreenCellIndexes firstIndex];
    length = [unloaded count];
    
    NSIndexSet* toQueue = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
    
    //get pre-animation indexes for cells to be added to screen
    NSMutableIndexSet* previousIndexPositionsForIndexesToQueue = [NSMutableIndexSet indexSet]; 
    [toQueue enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger newIndex = idx - [indexSet count];
        [previousIndexPositionsForIndexesToQueue addIndex:newIndex];
        
    }];
    
    [self.indexesScrollingInView addIndexes:toQueue];
    [self _loadCellsAtIndexes:[self.indexesScrollingInView copy]];

    //place at pre-animation indexes
    [self _layoutCellsAtIndexes:[self.indexesScrollingInView copy] inIndexPositions:previousIndexPositionsForIndexesToQueue];
    
    
    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){
        
        [self _layoutCellsAtIndexes:[self.indexesNeedingLayout copy]];
        [self.indexesNeedingLayout removeAllIndexes];
        //dequeue any newly off screen cells
        [self _unloadCellsScrollingOutOfViewAtIndexes:[self.indexesScrollingOutOfView copy]];
        //update layout, content size, index loader, etc
        [self _updateLayout];
        
        return;
    }
    
    
    
    //move cells out of the way
    [UIView animateWithDuration:LAYOUT_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                     animations:^(void) {
                        
                         [self _layoutCellsAtIndexes:[self.indexesNeedingLayout copy]];
                         [self.indexesNeedingLayout removeAllIndexes];

                     } completion:^(BOOL finished) {
                         
                         //dequeue any newly off screen cells
                         [self _unloadCellsScrollingOutOfViewAtIndexes:[self.indexesScrollingOutOfView copy]];
                         //update layout, content size, index loader, etc
                         [self _updateLayout];


                     }];
    
    
}



- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    //make room in the array
    NSArray* nulls = nullArrayOfSize([indexes count]);
    [self.cells insertObjects:nulls atIndexes:indexes];    
    
    //load
    [self _loadCellsAtIndexes:indexes];
    
    //add to view
    [self _layoutCellsAtIndexes:indexes];
    
    //update indexset
    [self.indexesToInsert removeIndexes:indexes];
    
    if(self.layoutAnimation == FJSpringBoardCellAnimationNone)
        return;
    
    self.userInteractionEnabled = NO; 

    //fade in
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        eachCell.alpha = 0;
        
        [UIView animateWithDuration:INSERT_ANIMATION_DURATION 
                              delay:0 
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                         animations:^(void) {
                             
                             eachCell.alpha = 1;
                             
                         } completion:^(BOOL finished) {
                             
                             
                             self.userInteractionEnabled = YES;

                             
                         }];
        
        
    }];
    
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
    

    self.layoutAnimation = animation; //reset on next layout update
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self.indexesToDelete addIndexes:indexSet];
    
    NSUInteger startIndex = MAX([indexSet firstIndex], [self.onScreenCellIndexes firstIndex]);
    NSUInteger lastIndex = [self.onScreenCellIndexes lastIndex] - [indexSet count];
    NSIndexSet* toLayOut = contiguousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); //non-continuous:remove indexSet form vis cell set, remove indexes less than the first index in indexset
    [self.indexesNeedingLayout addIndexes:toLayOut];
    
    
    startIndex = MAX([self.onScreenCellIndexes lastIndex] + 1 - [indexSet count], [indexSet firstIndex]);
    NSUInteger length = [indexSet count];
    NSIndexSet* toQueue = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
    
    //remove indexes not on screen
    toQueue  = [toQueue indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
    
        return [self.onScreenCellIndexes containsIndex:idx];
    
    }];
    
    //remove non-existent indexes
    toQueue = [toQueue indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        return [self.allIndexes containsIndex:idx];
        
    }];
    
    
    [self.indexesScrollingInView addIndexes:toQueue];
    
    //get pre-animation indexes for cells to be added to screen
    NSMutableIndexSet* previousIndexPositionsForIndexesToQueue = [NSMutableIndexSet indexSet]; 
    [toQueue enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        NSUInteger newIndex = idx + [indexSet count];
        [previousIndexPositionsForIndexesToQueue addIndex:newIndex];
        
    }];
        
    [self _deleteCellsAtIndexes:[self.indexesToDelete copy]];

    //add new cells
    [self _loadCellsAtIndexes:[self.indexesScrollingInView copy]];

    //place at pre-animation indexes
    [self _layoutCellsAtIndexes:[self.indexesScrollingInView copy] inIndexPositions:previousIndexPositionsForIndexesToQueue];
       
    
    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){
        
        [self _layoutCellsAtIndexes:[self.indexesScrollingInView copy]];
        [self.indexesScrollingInView removeAllIndexes];
        
        [self _layoutCellsAtIndexes:[self.indexesNeedingLayout copy]];
        [self.indexesNeedingLayout removeAllIndexes];
        
        //update layout, cell count, content size, index loader, etc
        [self _updateLayout];
        
        return;
    }
    
    
    //animate
    [UIView animateWithDuration:LAYOUT_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                     animations:^(void) {
                         
                         [self _layoutCellsAtIndexes:[self.indexesScrollingInView copy]];
                         [self.indexesScrollingInView removeAllIndexes];
                         
                         [self _layoutCellsAtIndexes:[self.indexesNeedingLayout copy]];
                         [self.indexesNeedingLayout removeAllIndexes];

                         
                     } completion:^(BOOL finished) {
                         
                         //update layout, cell count, content size, index loader, etc
                         [self _updateLayout];

                     }];
        
    
}


- (void)_deleteCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    NSArray* cellsToRemove = [self.cells objectsAtIndexes:indexes];
        
    [self.cells removeObjectsAtIndexes:indexes];
    [self.indexesToDelete removeIndexes:indexes];

    if(self.layoutAnimation == FJSpringBoardCellAnimationNone){

        [cellsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
            
            if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                
                return;
            }
            
            [cell removeFromSuperview];
            [cell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
            [self.reusableCells addObject:cell];
            cell.alpha = 1;
            
        }];
     
        return;
    }
    
    
    self.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                     animations:^(void) {
                         
                         [cellsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }                                 
                             cell.alpha = 0;
                             
                         }];
                         
                     } 
                     completion:^(BOOL finished) {
                         
                         [cellsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }
                             
                             [cell removeFromSuperview];
                             [cell setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
                             [self.reusableCells addObject:cell];
                             cell.alpha = 1;
                             
                         }];
                         
                         self.userInteractionEnabled = YES;

                         
                     }];
    
       
   
    
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
    
    if(self.mode != FJSpringBoardCellModeNormal)
        return;
    
    CGPoint p = [g locationInView:self];
    
    NSUInteger indexOfCell = [self _indexOfCellAtPoint:p];
    
    if(indexOfCell == NSNotFound)
        return;
    
    if([delegate respondsToSelector:@selector(springBoardView:cellWasTappedAtIndex:)])
        [delegate springBoardView:self cellWasTappedAtIndex:indexOfCell];
    
}



- (void)didDoubleTap:(UITapGestureRecognizer*)g{
    
    if(self.mode != FJSpringBoardCellModeNormal)
        return;
    
    if(doubleTapped){
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetDoubleTapped) object:nil];
        
        [self performSelector:@selector(resetDoubleTapped) withObject:nil afterDelay:0.5];
        
        return;
    }
    
    CGPoint p = [g locationInView:self];
    
    NSUInteger indexOfCell = [self _indexOfCellAtPoint:p];
    
    if(indexOfCell == NSNotFound)
        return;
    
    self.doubleTapped = YES;
    [self performSelector:@selector(resetDoubleTapped) withObject:nil afterDelay:0.5];
    
    if([delegate respondsToSelector:@selector(springBoardView:cellWasDoubleTappedAtIndex:)]){
        
        [delegate springBoardView:self cellWasDoubleTappedAtIndex:indexOfCell];
        
        
    }
    
}

- (void)resetDoubleTapped{
    
    self.doubleTapped = NO;
}


- (void)didLongTap:(UILongPressGestureRecognizer*)g{
    
    if(self.longTapped){
        
        if(g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled){
            
            self.longTapped = NO;
        }
        
        return;
    }
    
    //don't do anything if we are in the middle of scrolling animation
    if(self.animatingContentOffset)
        return;
        
    
    CGPoint p = [g locationInView:self];

    if(self.mode == FJSpringBoardCellModeNormal){
        
        if(g.state == UIGestureRecognizerStateBegan){
            
            NSUInteger indexOfCell = [self _indexOfCellAtPoint:p];
            
            if(indexOfCell != NSNotFound)
                self.mode = FJSpringBoardCellModeEditing;
            
            self.longTapped = YES;        

        }

        return;
    }
    
    
    if(self.mode == FJSpringBoardCellModeEditing){
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_completeReorder) object:nil];
        
        if(g.state == UIGestureRecognizerStateBegan){
            
            [self _makeCellReorderableAtTouchPoint:p];
            
            return;
        }
        
        if(g.state == UIGestureRecognizerStateChanged){
            
            [self _handleReorderbleCellWithTouchPoint:p];       
    
            return;
        }
        
        if(g.state == UIGestureRecognizerStateEnded || UIGestureRecognizerStateCancelled){
            
            [self _completeReorder];
            
            return;
        }
        
        return;
    }
    
}


- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point{
    
    NSIndexSet* a = [self.cells indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* c = (FJSpringBoardCell*)obj;
        
        if([c isEqual:[NSNull null]])
            return NO;
        
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

- (void)_keepReorderingCellUnderTouchPointDuringAnimationWithStartingTouchPoint:(CGPoint)point{
    
    //overly complicated way to keep the floating tile under the touch position until the scroll animation is complete
    //all this just to avoid an ivar
    __block CGPoint touchPosition = point;
    __block dispatch_block_t updateCheck;
    
    updateCheck = ^{
        
        touchPosition.x += (self.contentOffset.x - self.lastContentOffset.x); 
        self.reorderingCellView.center = touchPosition;
        POINTLOG(touchPosition);
        
        if(self.animatingContentOffset){
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(1/30.0)), 
                           dispatch_get_main_queue(), 
                           ^{
                               updateCheck();
                           });
        }else{
            
            [self performSelector:@selector(_completeReorder) withObject:nil afterDelay:0.25];
            
            Block_release(updateCheck);

        }
    };
    
    updateCheck = Block_copy(updateCheck);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(1/30.0)), 
                   dispatch_get_main_queue(), 
                   ^{
                       updateCheck();
                   });
    
    

}



- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch{
    
    CGRect f;
    f.origin = self.contentOffset;
    f.size = self.bounds.size;
    
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
#pragma mark reorder

- (void)_makeCellReorderableAtTouchPoint:(CGPoint)point{
    
    NSUInteger index = [self _indexOfCellAtPoint:point];

    if(index == NSNotFound)
        return;
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([cell isEqual:[NSNull null]]){
        
        ALWAYS_ASSERT;
    }
    
    //crrate map for indexes
    self.indexMap = [[[FJReorderingIndexMap alloc] initWithArray:self.cells reorderingObjectIndex:index] autorelease];
    
    //create imageview to animate
    UIImage* i = [self _createImageFromCell:cell];
    UIImageView* iv = [[UIImageView alloc] initWithImage:i];
    iv.frame = cell.frame;
    self.reorderingCellView = iv;
    [self addSubview:iv];
    [iv release];
    
    //notify cell it is being reordered, give power of invisibility!
    cell.reordering = YES;
    
    [UIView animateWithDuration:0.3 
                          delay:0.1 
                        options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                     
                         self.reorderingCellView.alpha = 0.8;
                         self.reorderingCellView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                     
                     } 
                     
                     completion:^(BOOL finished) {
                     
                     
                     
                     }];

}

- (UIImage*)_createImageFromCell:(FJSpringBoardCell*)cell{
    
    UIView* cellView = cell;
    
    UIGraphicsBeginImageContext(cellView.bounds.size);
    [cellView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
    
}

- (void)_handleReorderbleCellWithTouchPoint:(CGPoint)point{
    
    self.reorderingCellView.center = point;
    
    //check if we need to scroll the view
    FJSpringBoardViewEdge e = [self _edgeOfViewAtTouchPoint:point];
    if(e == FJSpringBoardViewEdgeNone){
        
        //don't do anything if we are in the middle of a reordering animation
        if(self.animatingReorder)
            return;    
        
        //if not, lets check to see if we need to reshuffle
        NSUInteger index = [self _newCellIndexForTouchPoint:point];
        [self _reorderCellsByUpdatingPlaceHolderIndex:index];
        
        
    }else{
        
        if([self _scrollSpringBoardInDirectionOfEdge:e])
            [self _keepReorderingCellUnderTouchPointDuringAnimationWithStartingTouchPoint:point];
        
    }
    
}



- (NSUInteger)_newCellIndexForTouchPoint:(CGPoint)point{
    
    CGRect insetRect = CGRectInset(self.reorderingCellView.frame, 
                                   0.15*self.reorderingCellView.frame.size.width, 
                                   0.15*self.reorderingCellView.frame.size.height);
    
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




- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index{
    
    if(index == NSNotFound)
        return;
    
    self.animatingReorder = YES;
    FJReorderingIndexMap* im = (FJReorderingIndexMap*)self.indexMap;

    NSIndexSet* affectedIndexes = [im modifiedIndexesByMovingReorderingObjectToIndex:index];
    
    [UIView animateWithDuration:LAYOUT_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                     animations:^(void) {
                         
                         [self _layoutCellsAtIndexes:affectedIndexes];
                                                  
                     } completion:^(BOOL finished) {
                         
                         self.animatingReorder = NO;
                         //update layout, cell count, content size, index loader, etc
                         [self _updateLayout];
                         
                     }];
    
}


- (void)_completeReorder{
    
    if(self.animatingReorder)
        return;
    
    FJReorderingIndexMap* im = (FJReorderingIndexMap*)self.indexMap;
    if(![im isKindOfClass:[FJReorderingIndexMap class]])
        return;

    
    
    NSLog(@"completing reorder...");
    self.animatingReorder = YES;

    UIView* v = [self.reorderingCellView retain];
    self.reorderingCellView = nil;
        
    NSUInteger original = im.originalReorderingIndex;
    NSUInteger current = im.currentReorderingIndex;
    FJSpringBoardCell* cell = [self.cells objectAtIndex:im.currentReorderingIndex];

    self.indexMap = [[FJNormalIndexMap alloc] initWithArray:self.cells];

    id<FJSpringBoardViewDataSource> d = self.dataSource;
    
    if([self.cells count] == 0){
        
        ALWAYS_ASSERT;
    }


    [UIView animateWithDuration:0.3 
                          delay:0.1 
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                         
                         v.alpha = 1.0;
                         v.transform = CGAffineTransformIdentity;
                         v.frame = cell.frame;

                     } 
     
                     completion:^(BOOL finished) {
                        
                         [v removeFromSuperview];
                         [v release];

                         cell.reordering = NO;
                         self.animatingReorder = NO;
                         if([d respondsToSelector:@selector(springBoardView:moveCellAtIndex:toIndex:)])
                             [d springBoardView:self moveCellAtIndex:original toIndex:current];
                         

                     }];


    
    
    
    
    
}


#pragma mark -
#pragma mark paging


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
    
    return [self.selectedIndexes copy];
}


@end
