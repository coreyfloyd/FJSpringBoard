
#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import <QuartzCore/QuartzCore.h>
#import "FJReorderingIndexMap.h"

#define DELETE_ANIMATION_DURATION 1
#define INSERT_ANIMATION_DURATION 1
#define RELOAD_ANIMATION_DURATION 1
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

@property(nonatomic, retain) NSMutableIndexSet *allIndexes;

@property(nonatomic, retain) NSMutableIndexSet *queuedCellIndexes; 

//used to process changes due to movement
@property(nonatomic, retain) NSMutableIndexSet *indexesToQueue; 
@property(nonatomic, retain) NSMutableIndexSet *indexesToDequeue; 


//used to process changes due to insertion/deletion
@property(nonatomic, retain) NSMutableIndexSet *indexesToInsert;
@property(nonatomic, retain) NSMutableIndexSet *indexesToDelete;

@property(nonatomic, retain) NSMutableIndexSet *indexesNeedingLayout; //indexes that have moved

@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;

@property(nonatomic, retain, readwrite) NSMutableArray *cells; 
@property(nonatomic, retain) NSMutableSet *dequeuedCells;

@property(nonatomic) BOOL layoutIsDirty;

@property(nonatomic) FJSpringBoardCellAnimation layoutAnimation;

@property(nonatomic) BOOL doubleTapped;
@property(nonatomic) BOOL longTapped;

@property(nonatomic, retain) FJReorderingIndexMap *reorderingIndexMap;
@property(nonatomic, retain) UIView *reorderingCellView;
@property(nonatomic) BOOL animatingReorder;


@property(nonatomic) BOOL animatingContentOffset;
@property(nonatomic) CGPoint lastContentOffset;



- (void)_configureLayout;
- (void)_updateLayout;
- (void)_updateIndexes;

- (void)_queueCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_removeCellsFromViewAtIndexes:(NSIndexSet*)indexes;
- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes;

- (void)_deleteCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes;

- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point;

//reordering
- (UIImage*)_createImageFromCell:(FJSpringBoardCell*)cell;
- (void)_makeCellReorderableAtIndex:(NSUInteger)index;
- (NSUInteger)_newCellIndexForTouchPoint:(CGPoint)point;
- (void)_reorderCellsByUpdatingPlaceHolderIndex:(NSUInteger)index;
- (void)_completeReorder;

//scrolling during reordering
- (BOOL)_scrollSpringBoardWithTouchPoint:(CGPoint)touch;
- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch;

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

@synthesize horizontalCellSpacing;
@synthesize verticalCellSpacing;

@synthesize cells;
@synthesize dequeuedCells;

@synthesize allIndexes;
@synthesize indexesToQueue;
@synthesize indexesNeedingLayout;
@synthesize indexesToDelete;
@synthesize indexesToDequeue;
@synthesize selectedIndexes;
@synthesize indexesToInsert;

@synthesize layoutIsDirty;
@synthesize layoutAnimation;

@synthesize doubleTapped;
@synthesize longTapped;

@synthesize reorderingIndexMap;
@synthesize animatingReorder;
@synthesize reorderingCellView;

@synthesize animatingContentOffset;
@synthesize lastContentOffset;







#pragma mark -
#pragma mark NSObject


- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [reorderingIndexMap release];
    reorderingIndexMap = nil;    
    [reorderingCellView release];
    reorderingCellView = nil;    
    [allIndexes release];
    allIndexes = nil; 
    [indexesToInsert release];
    indexesToInsert = nil;
    [indexesToDequeue release];
    indexesToDequeue = nil;    
    [indexesToQueue release];
    indexesToQueue = nil;
    [indexesToDelete release];
    indexesToDelete = nil;
    [indexesNeedingLayout release];
    indexesNeedingLayout = nil;
    [selectedIndexes release];
    selectedIndexes = nil;    
    [cells release];
    cells = nil;
    [dequeuedCells release];
    dequeuedCells = nil;
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
        self.indexesToQueue = [NSMutableIndexSet indexSet];
        self.indexesNeedingLayout = [NSMutableIndexSet indexSet];
        self.selectedIndexes = [NSMutableIndexSet indexSet];
        self.indexesToInsert = [NSMutableIndexSet indexSet];
        self.indexesToDelete = [NSMutableIndexSet indexSet];
        self.indexesToDequeue = [NSMutableIndexSet indexSet];
        self.cells = [NSMutableArray array];
        self.dequeuedCells = [NSMutableSet set];
        
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
    
    return cell.contentView.frame;
    
}

- (NSIndexSet*)visibleCellIndexes{
    
    return self.indexLoader.currentIndexes;   
}

- (NSMutableIndexSet*)queuedCellIndexes{
    
    return self.indexLoader.currentIndexes;
}

- (void)setQueuedCellIndexes:(NSMutableIndexSet *)indexes{
    
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
    
    if([self.dequeuedCells count] == 0)
        return nil;
    
    NSSet* c = [self.dequeuedCells objectsWithOptions:NSEnumerationConcurrent passingTest:^(id obj, BOOL *stop) {
        
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
    
    [self.dequeuedCells removeObject:cell];
    
    return cell;
    
}


#pragma mark -
#pragma mark Reload

- (void)reloadData{
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _dequeueCellsAtIndexes:self.queuedCellIndexes];
    self.cells = nullArrayOfSize([self.allIndexes count]);
    
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
    self.layout.horizontalCellSpacing = self.horizontalCellSpacing;
    self.layout.verticalCellSpacing = self.verticalCellSpacing;
    
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
    
    if([self.queuedCellIndexes count] > 0 && !indexesAreContinuous(self.queuedCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    //check maths, newI == oldI - removed + added    
    [self.indexesToDequeue addIndexesInRange:rangeToRemove];
    
    [self.indexesToQueue addIndexesInRange:rangeToLoad];
    
    //dequeue cells that are no longer "visible"
    [self _dequeueCellsAtIndexes:[self.indexesToDequeue copy]];
    
    //queue cells that are now visible
    [self _queueCellsAtIndexes:[self.indexesToQueue copy]];
    
    if([cells count] != [self.allIndexes count]){
        
        ALWAYS_ASSERT;
    }
    
    self.layoutAnimation = FJSpringBoardCellAnimationNone;
    self.layoutIsDirty = NO;

}


#pragma mark -
#pragma mark Queue / Dequeue cells


- (void)_queueCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    //load: create and insert in array
    [self _loadCellsAtIndexes:indexes];
    
    //set frame and add to view
    [self _layoutCellsAtIndexes:indexes];
    
    [self.indexesToQueue removeIndexes:indexes];
    
}


- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    [self _removeCellsFromViewAtIndexes:indexes];
    
    [self _unloadCellsAtIndexes:indexes];
    
    [self.indexesToDequeue removeIndexes:indexes];        
    
    if([self.indexesToDequeue count] > 0){
        
        ALWAYS_ASSERT;
    }
}




#pragma mark -
#pragma mark Load / Unload Cells

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
       
        FJSpringBoardCell* cell = [self.dataSource springBoardView:self cellAtIndex:index];
        [cell retain];
        
        cell.springBoardView = self;
        
        //potential wasting of already loaded cells or hiding a bug
        [self _unloadCellsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
        
        [self.cells replaceObjectAtIndex:index withObject:cell];
        [cell release];
        
    }];

}


- (void)_unloadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        
        if(![self.allIndexes containsIndex:index]){
            
            return;
        }
        
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        [self.dequeuedCells addObject:eachCell];
        [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
        
        
    }];
    
}

#pragma mark -
#pragma mark layout / remove cells from view

- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        NSMutableArray* cellData = self.cells;
        
        if(self.reorderingIndexMap != nil)
            cellData = [self.reorderingIndexMap newArray];
        
        FJSpringBoardCell* eachCell = [cellData objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            return;
        }
        
        eachCell.mode = self.mode;

        //NSLog(@"Laying Out Cell %i", index);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.contentView.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        [self addSubview:eachCell.contentView];
    
    }];
}



- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes inIndexPositions:(NSIndexSet*)positionIndexes{
    
    __block NSUInteger positionIndex = [positionIndexes firstIndex];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.queuedCellIndexes containsIndex:index]){
            
            return;
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        eachCell.mode = self.mode;
        
        //NSLog(@"Laying Out Cell At Index %i in Old Index Position %i", index, positionIndex);
        //RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:positionIndex];
        eachCell.contentView.frame = cellFrame;
        //RECTLOG(eachCell.contentView.frame);
        
        [self addSubview:eachCell.contentView];
        
        positionIndex = [positionIndexes indexGreaterThanIndex:positionIndex];
        
    }];
}



- (void)_removeCellsFromViewAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.allIndexes containsIndex:index]){
        
            return;
        }
        
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        NSLog(@"Removing Cell From View %i", index);
        RECTLOG(eachCell.contentView.frame);
        
        [eachCell.contentView removeFromSuperview];
        [eachCell.contentView setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
        eachCell.mode = FJSpringBoardCellModeNormal;
        RECTLOG(eachCell.contentView.frame);
        
    }];
    
}

#pragma mark -
#pragma mark Reload Specific Indexes


- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self _dequeueCellsAtIndexes:indexSet];
    
    //load: create and insert in array
    [self _loadCellsAtIndexes:indexSet];
    
    //set frame and add to view
    [self _layoutCellsAtIndexes:indexSet];
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if(![self.queuedCellIndexes containsIndex:index]){
            
            return;
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        eachCell.contentView.alpha = 0;
        
        [UIView animateWithDuration:RELOAD_ANIMATION_DURATION 
                              delay:DELETE_ANIMATION_DURATION 
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                         animations:^(void) {
                             
                             eachCell.contentView.alpha = 1;
                             
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
    
    
    self.layoutAnimation = animation;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self.indexesToInsert addIndexes:indexSet];
    
    NSUInteger startIndex = MAX([indexSet lastIndex] + 1, [self.queuedCellIndexes firstIndex]);
    NSUInteger lastIndex = [self.queuedCellIndexes lastIndex] + [indexSet count];
    NSIndexSet* toLayOut = contiguousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); //non-continuous:remove indexSet form vis cell set, remove indexes less than the first index in indexset
    [self.indexesNeedingLayout addIndexes:toLayOut];
    
    //not necesarily needed if we can figure how to not fuck up double loading these later when we scroll since the indexloader is left in the dark
    startIndex = [self.queuedCellIndexes lastIndex] + 1;
    NSUInteger length = [indexSet count];
    [self.indexesToDequeue addIndexesInRange:NSMakeRange(startIndex, length)];
    
    //insert new cells
    [self _insertCellsAtIndexes:[self.indexesToInsert copy]];
    
    //load cells comming into range??
    NSMutableIndexSet* unloaded = [indexSet mutableCopy];
    [unloaded removeIndexes:self.queuedCellIndexes];
    startIndex = [self.queuedCellIndexes firstIndex];
    length = [unloaded count];
    
    NSIndexSet* toQueue = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
    
    //get pre-animation indexes for cells to be added to screen
    NSMutableIndexSet* previousIndexPositionsForIndexesToQueue = [NSMutableIndexSet indexSet]; 
    [toQueue enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger newIndex = idx - [indexSet count];
        [previousIndexPositionsForIndexesToQueue addIndex:newIndex];
        
    }];
    
    [self.indexesToQueue addIndexes:toQueue];
    [self _loadCellsAtIndexes:[self.indexesToQueue copy]];

    //place at pre-animation indexes
    [self _layoutCellsAtIndexes:[self.indexesToQueue copy] inIndexPositions:previousIndexPositionsForIndexesToQueue];
    
    //move cells out of the way
    [UIView animateWithDuration:LAYOUT_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                     animations:^(void) {
                        
                         [self _layoutCellsAtIndexes:[self.indexesNeedingLayout copy]];
                         [self.indexesNeedingLayout removeAllIndexes];

                     } completion:^(BOOL finished) {
                         
                         //dequeue any newly off screen cells
                         [self _dequeueCellsAtIndexes:[self.indexesToDequeue copy]];
                         //update layout, content size, index loader, etc
                         [self _updateLayout];


                     }];
    
    
}



- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    self.userInteractionEnabled = NO; 

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
    
    //fade in
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        eachCell.contentView.alpha = 0;
        
        [UIView animateWithDuration:INSERT_ANIMATION_DURATION 
                              delay:0 
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                         animations:^(void) {
                             
                             eachCell.contentView.alpha = 1;
                             
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
    

    self.layoutAnimation = animation;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInSpringBoardView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self.indexesToDelete addIndexes:indexSet];
    
    NSUInteger startIndex = MAX([indexSet firstIndex], [self.queuedCellIndexes firstIndex]);
    NSUInteger lastIndex = [self.queuedCellIndexes lastIndex] - [indexSet count];
    NSIndexSet* toLayOut = contiguousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); //non-continuous:remove indexSet form vis cell set, remove indexes less than the first index in indexset
    [self.indexesNeedingLayout addIndexes:toLayOut];
    
    
    startIndex = MAX([self.queuedCellIndexes lastIndex] + 1 - [indexSet count], [indexSet firstIndex]);
    NSUInteger length = [indexSet count];
    NSIndexSet* toQueue = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
    
    //remove indexes not on screen
    toQueue  = [toQueue indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
    
        return [self.queuedCellIndexes containsIndex:idx];
    
    }];
    
    //remove non-existent indexes
    toQueue = [toQueue indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        return [self.allIndexes containsIndex:idx];
        
    }];
    
    
    [self.indexesToQueue addIndexes:toQueue];
    
    //get pre-animation indexes for cells to be added to screen
    NSMutableIndexSet* previousIndexPositionsForIndexesToQueue = [NSMutableIndexSet indexSet]; 
    [toQueue enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        NSUInteger newIndex = idx + [indexSet count];
        [previousIndexPositionsForIndexesToQueue addIndex:newIndex];
        
    }];
        
    [self _deleteCellsAtIndexes:[self.indexesToDelete copy]];

    //add new cells
    [self _loadCellsAtIndexes:[self.indexesToQueue copy]];

    //place at pre-animation indexes
    [self _layoutCellsAtIndexes:[self.indexesToQueue copy] inIndexPositions:previousIndexPositionsForIndexesToQueue];
        
    //animate
    [UIView animateWithDuration:LAYOUT_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)  
                     animations:^(void) {
                         
                         [self _layoutCellsAtIndexes:[self.indexesToQueue copy]];
                         [self.indexesToQueue removeAllIndexes];
                         
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
    
    self.userInteractionEnabled = NO;

    NSArray* cellsToRemove = [self.cells objectsAtIndexes:indexes];
    
    [UIView animateWithDuration:DELETE_ANIMATION_DURATION 
                          delay:0 
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut) 
                     animations:^(void) {
                         
                         [cellsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }                                 
                             cell.contentView.alpha = 0;
                             
                         }];
                         
                     } 
                     completion:^(BOOL finished) {
                         
                         [cellsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             
                             FJSpringBoardCell* cell = (FJSpringBoardCell*)obj;
                             
                             if(![cell isKindOfClass:[FJSpringBoardCell class]]){
                                 
                                 return;
                             }
                             
                             [cell.contentView removeFromSuperview];
                             [cell.contentView setFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
                             [self.dequeuedCells addObject:cell];
                             cell.contentView.alpha = 1;
                             
                         }];
                         
                         self.userInteractionEnabled = YES;

                         
                     }];
    
       
    [self.cells removeObjectsAtIndexes:indexes];
    
    [self.indexesToDelete removeIndexes:indexes];
    
}

#pragma mark -
#pragma mark Mode


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
    if(mode == aMode)
        return;
    
    //FJSpringBoardCellMode oldMode = mode;
    
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
    
    if(indexOfCell == NSUIntegerMax)
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
    
    if(indexOfCell == NSUIntegerMax)
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

    if(self.mode == FJSpringBoardCellModeEditing){
        
        if(g.state == UIGestureRecognizerStateBegan){
            
            
            NSUInteger indexOfCell = [self _indexOfCellAtPoint:p];
            [self _makeCellReorderableAtIndex:indexOfCell];
            
            return;
        }
        
        if(g.state == UIGestureRecognizerStateChanged){
            
            
            
            self.reorderingCellView.center = p;
            
            //check if we need to scroll the view
            if(![self _scrollSpringBoardWithTouchPoint:p]){
                
                //don't do anything if we are in the middle of a reordering animation
                if(self.animatingReorder)
                    return;    
                
                //if not, lets check to see if we need to reshuffle
                NSUInteger index = [self _newCellIndexForTouchPoint:p];
                [self _reorderCellsByUpdatingPlaceHolderIndex:index];

            }
            
            return;
        }
        
        if(g.state == UIGestureRecognizerStateEnded){
            
            [self _completeReorder];
            
            return;
        }
        
        return;
    }
    
  
    NSUInteger indexOfCell = [self _indexOfCellAtPoint:p];
    
    if(indexOfCell == NSUIntegerMax)
        return;
    
    self.longTapped = YES;
    
    if([delegate respondsToSelector:@selector(springBoardView:cellWasTappedAndHeldAtIndex:)])
        [delegate springBoardView:self cellWasTappedAndHeldAtIndex:indexOfCell];
    
}



- (NSUInteger)_indexOfCellAtPoint:(CGPoint)point{
    
    NSIndexSet* a = [self.cells indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCell* c = (FJSpringBoardCell*)obj;
        
        if([c isEqual:[NSNull null]])
            return NO;
        
        if(CGRectContainsPoint(c.contentView.frame, point)){
            //TODO: uncomment
            //*stop = YES;
            return YES;
            
        }
        
        return NO;
        
    }];
    
    if([a count] == 0)
        return NSUIntegerMax;
    
    if([a count] > 1){
        
        ALWAYS_ASSERT;
        
    }
    
    return [a firstIndex];
    
}


- (BOOL)_scrollSpringBoardWithTouchPoint:(CGPoint)touch{
    
    FJSpringBoardViewEdge direction = [self _edgeOfViewAtTouchPoint:touch];
    
    if(direction == FJSpringBoardViewEdgeNone)
        return NO;
    
    if(self.scrollDirection == FJSpringBoardViewScrollDirectionVertical){
        
        if(direction == FJSpringBoardViewEdgeTop){
            
            return NO;
            
            
        }else if(direction == FJSpringBoardViewEdgeBottom){
         
            return NO;
            
        }
        
    }else{
        
        
        if(direction == FJSpringBoardViewEdgeLeft){
            
            NSUInteger prevPage = [self previousPage];
            
            if(prevPage == NSNotFound)
                return NO;
           
            [self scrollToPage:prevPage animated:YES];
                        
            
        }else if(direction == FJSpringBoardViewEdgeRight){
            
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
        
        if(self.animatingContentOffset){
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(1/30.0)), 
                           dispatch_get_main_queue(), 
                           ^{
                               updateCheck();
                           });
        }else{
            
            
        }
    };
    
    updateCheck = Block_copy(updateCheck);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(1/30.0)), 
                   dispatch_get_main_queue(), 
                   ^{
                       updateCheck();
                   });
    
    
    Block_release(updateCheck);

}



- (FJSpringBoardViewEdge)_edgeOfViewAtTouchPoint:(CGPoint)touch{
    
    CGRect centerFrame = CGRectInset(self.bounds, EDGE_CUSHION, EDGE_CUSHION);
    
    if(CGRectContainsPoint(centerFrame, touch))
        return FJSpringBoardViewEdgeNone;
    
    CGRect top = CGRectMake(self.bounds.origin.x+EDGE_CUSHION, 0, self.bounds.size.width-(2*EDGE_CUSHION), EDGE_CUSHION);
    
    if(CGRectContainsPoint(top, touch))
        return FJSpringBoardViewEdgeTop;
    
    CGRect right = CGRectMake(self.bounds.size.width-EDGE_CUSHION, self.bounds.origin.y+EDGE_CUSHION, EDGE_CUSHION, self.bounds.size.height-(2*EDGE_CUSHION));
    
    if(CGRectContainsPoint(right, touch))
        return FJSpringBoardViewEdgeRight;
    
    CGRect bottom = CGRectMake(self.bounds.origin.x+EDGE_CUSHION, self.bounds.size.height-EDGE_CUSHION, self.bounds.size.width-(2*EDGE_CUSHION), EDGE_CUSHION);
    
    if(CGRectContainsPoint(bottom, touch))
        return FJSpringBoardViewEdgeBottom;
    
    CGRect left = CGRectMake(0, self.bounds.origin.y+EDGE_CUSHION, EDGE_CUSHION, self.bounds.size.height-(2*EDGE_CUSHION));    
    
    if(CGRectContainsPoint(left, touch))
        return FJSpringBoardViewEdgeLeft;
    
    
    return FJSpringBoardViewEdgeNone;
}


#pragma mark -
#pragma mark reorder
- (void)_makeCellReorderableAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([cell isEqual:[NSNull null]]){
        
        ALWAYS_ASSERT;
    }
    
    //crrate map for indexes
    self.reorderingIndexMap = [[[FJReorderingIndexMap alloc] initWithOriginalArray:self.cells reorderingObjectIndex:index] autorelease];
    
    //create imageview to animate
    UIImage* i = [self _createImageFromCell:cell];
    UIImageView* iv = [[UIImageView alloc] initWithImage:i];
    iv.frame = cell.contentView.frame;
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
    
    UIView* cellView = cell.contentView;
    
    UIGraphicsBeginImageContext(cellView.bounds.size);
    [cellView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
    
}

- (NSUInteger)_newCellIndexForTouchPoint:(CGPoint)point{
    
    CGRect insetRect = CGRectInset(self.reorderingCellView.frame, 
                                   0.15*self.reorderingCellView.frame.size.width, 
                                   0.15*self.reorderingCellView.frame.size.height);
    
    NSMutableIndexSet* coveredIndexes = [NSMutableIndexSet indexSet];
    
    [[self.reorderingIndexMap newArray] enumerateObjectsAtIndexes:self.queuedCellIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
        FJSpringBoardCell* c = (FJSpringBoardCell*)obj;
        
        if([c isEqual:[NSNull null]]){
            
            ALWAYS_ASSERT;
            
        }        
        
        CGRect f = c.contentView.frame;
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
    
        FJSpringBoardCell* cell = [[self.reorderingIndexMap newArray] objectAtIndex:idx];
        CGRect rect = CGRectIntersection(insetRect, cell.contentView.frame);
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
    NSIndexSet* affectedIndexes = [self.reorderingIndexMap modifiedIndexesBymovingReorderingObjectToIndex:index];
    
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
        
    FJSpringBoardCell* cell = [[self.reorderingIndexMap newArray] objectAtIndex:self.reorderingIndexMap.currentReorderingIndex];
    UIView* v = self.reorderingCellView;
    self.reorderingCellView = nil;

    [UIView animateWithDuration:0.3 
                          delay:0.1 
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction) 
                     animations:^(void) {
                         
                         v.alpha = 1.0;
                         v.transform = CGAffineTransformIdentity;
                         v.frame = cell.contentView.frame;

                         
                     } 
     
                     completion:^(BOOL finished) {
                        
                         [v removeFromSuperview];
                         
                         cell.reordering = NO;
                         self.cells = [self.reorderingIndexMap newArray];
                         
                         if([dataSource respondsToSelector:@selector(springBoardView:moveCellAtIndex:toIndex:)])
                             [self.dataSource springBoardView:self moveCellAtIndex:self.reorderingIndexMap.originalReorderingIndex toIndex:self.reorderingIndexMap.currentReorderingIndex];
                         
                         self.reorderingIndexMap = nil;
                         
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
        return (currentPage--);
    
       
    return NSNotFound;
    
}

- (void)scrollToPage:(NSUInteger)page animated:(BOOL)animated{
    
    if(self.scrollDirection != FJSpringBoardViewScrollDirectionHorizontal)
        return;
    
    CGFloat x = page * self.bounds.size.width;
    
    [self setContentOffset:CGPointMake(x, 0) animated:animated];
    
}


#pragma mark -
#pragma mark Selection

- (NSIndexSet *)indexesForSelectedCells{
    
    return [self.selectedIndexes copy];
}


@end
