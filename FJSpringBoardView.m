
#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"


#define DELETE_ANIMATION_DURATION 3
#define INSERT_ANIMATION_DURATION 3
#define RELOAD_ANIMATION_DURATION 3
#define LAYOUT_ANIMATION_DURATION 2


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


#pragma mark -
#pragma mark NSObject


- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
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
#pragma mark Touches

- (void)didSingleTap:(UITapGestureRecognizer*)g{
    
    CGPoint p = [g locationInView:self];
    
    NSUInteger indexOfCell = [self _indexOfCellAtPoint:p];
    
    if(indexOfCell == NSUIntegerMax)
        return;

    if([delegate respondsToSelector:@selector(springBoardView:cellWasTappedAtIndex:)])
        [delegate springBoardView:self cellWasTappedAtIndex:indexOfCell];
    
    
    
}



- (void)didDoubleTap:(UITapGestureRecognizer*)g{
    
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


- (void)resetDoubleTapTimer:(NSTimer*)timer{
    
    self.doubleTapped = NO;
}


- (void)didLongTap:(UILongPressGestureRecognizer*)g{
    
    if(self.longTapped){
        
        if(g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled){
            
            self.longTapped = NO;
        }
        
        return;
    }
    
    CGPoint p = [g locationInView:self];
    
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
    
	[super setContentOffset: offset animated: animate];    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self _updateIndexes];
        
    });    
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
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            NSLog(@"Error! attempting to layout unloaded cell.");
            return;
        }
        
        eachCell.mode = self.mode;

        NSLog(@"Laying Out Cell %i", index);
        RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.contentView.frame = cellFrame;
        RECTLOG(eachCell.contentView.frame);
        
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
        
        NSLog(@"Laying Out Cell At Index %i in Old Index Position %i", index, positionIndex);
        RECTLOG(eachCell.contentView.frame);
        CGRect cellFrame = [self.layout frameForCellAtIndex:positionIndex];
        eachCell.contentView.frame = cellFrame;
        RECTLOG(eachCell.contentView.frame);
        
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
    NSIndexSet* toLayOut = continuousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); //non-continuous:remove indexSet form vis cell set, remove indexes less than the first index in indexset
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
    NSIndexSet* toLayOut = continuousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); //non-continuous:remove indexSet form vis cell set, remove indexes less than the first index in indexset
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
#pragma mark Selection

- (NSIndexSet *)indexesForSelectedCells{
    
    return [self.selectedIndexes copy];
}



@end
