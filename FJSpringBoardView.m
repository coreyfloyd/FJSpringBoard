//
//  FJGridView.m
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardView.h"
#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"

@interface FJSpringBoardCell(Internal)

@property(nonatomic, assign) FJSpringBoardView* springBoardView;


@end


@interface FJSpringBoardView()

@property(nonatomic, retain) FJSpringBoardIndexLoader *indexLoader;
@property(nonatomic, retain) FJSpringBoardLayout *layout;

@property(nonatomic, retain) NSMutableIndexSet *allIndexes;
@property(nonatomic, retain, readwrite) NSMutableIndexSet *visibleCellIndexes; //rename to loaded
@property(nonatomic, retain) NSMutableIndexSet *dirtyIndexes;
@property(nonatomic, retain) NSMutableIndexSet *indexesNeedingLayout;
@property(nonatomic, retain) NSMutableIndexSet *indexesToDelete;
@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;


@property(nonatomic, retain, readwrite) NSMutableArray *cells; 
@property(nonatomic, retain) NSMutableSet *dequeuedCells;

@property(nonatomic) BOOL reloading;

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCellAtIndex:(NSUInteger)index;
- (void)_loadCellAtIndex:(NSUInteger)index;
- (void)_processChanges;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_updateCells;
- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_updateLayout;
- (void)_removeCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCells;

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
@synthesize visibleCellIndexes;
@synthesize dirtyIndexes;
@synthesize indexesNeedingLayout;
@synthesize indexesToDelete;
@synthesize selectedIndexes;

@synthesize reloading;


#pragma mark NSObject


- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [allIndexes release];
    allIndexes = nil;    
    [visibleCellIndexes release];
    visibleCellIndexes = nil;
    [dirtyIndexes release];
    dirtyIndexes = nil;
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
    [visibleCellIndexes release];
    visibleCellIndexes = nil;
    [layout release];
    layout = nil;
    [indexLoader release];
    indexLoader = nil;
    [super dealloc];
    
}

#pragma mark UIView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

        self.indexLoader = [[[FJSpringBoardIndexLoader alloc] init] autorelease];
        
        self.visibleCellIndexes = [NSMutableIndexSet indexSet];
        self.allIndexes = [NSMutableIndexSet indexSet];
        self.dirtyIndexes = [NSMutableIndexSet indexSet];
        self.indexesNeedingLayout = [NSMutableIndexSet indexSet];
        self.selectedIndexes = [NSMutableIndexSet indexSet];
        self.indexesToDelete = [NSMutableIndexSet indexSet];
        self.cells = [NSMutableArray array];
        self.dequeuedCells = [NSMutableSet set];
        
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
    }
    return self;
}

#pragma mark configure layout

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

- (void)_updateLayout{
    
    self.layout.springBoardbounds = self.bounds;
    self.layout.insets = self.springBoardInsets;
    self.layout.cellSize = self.cellSize;
    self.layout.horizontalCellSpacing = self.horizontalCellSpacing;
    self.layout.verticalCellSpacing = self.verticalCellSpacing;
    
    self.layout.cellCount = [self.allIndexes count];
    
    [self.layout updateLayout];
    
    self.contentSize = self.layout.contentSize;
    
}


#pragma mark -
#pragma mark UIScrollView

- (void)setContentOffset:(CGPoint)offset{
    
	[super setContentOffset: offset];
    [self _updateCells];
}

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animate{
    
	[super setContentOffset: offset animated: animate];    
    [self _updateCells];
    
}



#pragma mark -
#pragma mark Reload

- (void)reloadData{
    
    if(self.reloading)
        return;
    
    self.reloading = YES;
    
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _dequeueCellsAtIndexes:self.visibleCellIndexes];
    self.cells = nullArrayOfSize([self.allIndexes count]);

    [self _configureLayout]; //triggers _updateCells
    
    /*
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
    NSRange rangeToLoad = changes.fullIndexRange;
        
    
    
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:rangeToLoad];
    
    [self _loadCellsAtIndexes:indexes];
        
    self.visibleCellIndexes = [NSMutableIndexSet indexSet];
    [self.visibleCellIndexes addIndexes:indexes];
    
    [self _layoutCells];
    */
    
    self.reloading = NO;
}


- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self.dirtyIndexes addIndexes:indexSet];
    
    [self _processChanges];
    
}

- (void)_updateCells{
    
    if(indexLoader == nil)
        return;
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
    NSRange rangeToRemove = changes.indexRangeToRemove;
    
    NSRange rangeToLoad = changes.indexRangeToAdd;
    
    NSRange fullRange = changes.fullIndexRange;
    NSMutableIndexSet* newIndexes = [NSIndexSet indexSetWithIndexesInRange:fullRange];
    
    if(!indexesAreContinuous(self.visibleCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    //check maths, newI == oldI - removed + added
    self.visibleCellIndexes = newIndexes;    
    
    [self.indexesToDelete addIndexesInRange:rangeToRemove];
    
    [self.dirtyIndexes addIndexesInRange:rangeToLoad];
    
    [self.indexesNeedingLayout addIndexesInRange:rangeToLoad];
    
    [self _processChanges];
    
    
    /*
    [self _loadCellsAtIndexes:indexesToLoad];
    
    [self _layoutCellsAtIndexes:indexesToLoad];
    
    if(!indexesAreContinuous(self.visibleCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    */
}



- (void)_processChanges{
    
    [self _dequeueCells];
    
    [self _layoutCellsAtIndexes:self.indexesNeedingLayout];
    
}


#pragma mark -
#pragma mark Layout Cells


- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
    
    while(index != NSNotFound){
        
        if(![self.visibleCellIndexes containsIndex:index]){
         
            ALWAYS_ASSERT;
        }
        
        if([self.dirtyIndexes containsIndex:index]){
            
            [self _loadCellAtIndex:index];
            [self.dirtyIndexes removeIndex:index];
            
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if([NSNull null] == (NSNull*)eachCell){
            
            ALWAYS_ASSERT;
        }
        
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.contentView.frame = cellFrame;
        [self addSubview:eachCell.contentView];
        
        [self.indexesNeedingLayout removeIndex:index];
        
        index = [indexes indexGreaterThanIndex:index];
    }
}



#pragma mark -
#pragma mark Load cells

- (void)_loadCells{
    
    [self _loadCellsAtIndexes:self.visibleCellIndexes];
}

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];

    while(index != NSNotFound){
        
        [self _loadCellAtIndex:index];
        
        index = [indexes indexGreaterThanIndex:index];
    }
}

- (void)_loadCellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.dataSource gridView:self cellAtIndex:index];
    [cell retain];
    
    cell.springBoardView = self;
    [self _dequeueCellAtIndex:index];
    
    [self.cells replaceObjectAtIndex:index withObject:cell];
    [cell release];
    
}

#pragma mark -
#pragma mark Dequeue Cells

- (void)_dequeueCells{
    
    [self _dequeueCellsAtIndexes:self.indexesToDelete];
    
}

- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
    
    while(index != NSNotFound){
        
        [self _dequeueCellAtIndex:index];
        
        index = [indexes indexGreaterThanIndex:index];
    }
}


- (void)_dequeueCellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if(![cell isKindOfClass:[FJSpringBoardCell class]]){
        
        return;
    }
    [self.dequeuedCells addObject:cell];

    [cell.contentView removeFromSuperview];
    [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
    
    [self.indexesToDelete removeIndex:index];
    
}


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
#pragma mark Insert / Delete Cells


- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    NSUInteger firstIndex = [indexSet firstIndex];
    
    if(firstIndex > [self.allIndexes lastIndex] + 1){
        
        ALWAYS_ASSERT;
    } 
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    [self _updateLayout];
    
    NSIndexSet* indexesToMove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstIndex, ([self.allIndexes count] - firstIndex))];
    
    NSIndexSet* indexesToRelayout = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstIndex, ([indexesToMove count] + [indexSet count]))];
    
    [self _insertCellsAtIndexes:indexSet];
    
    [self _layoutCellsAtIndexes:indexesToRelayout];
    
    
}

- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
    
    NSMutableArray* newCells = [NSMutableArray array];
    
    while(index != NSNotFound){
        
        FJSpringBoardCell* cell = (FJSpringBoardCell*)[NSNull null];
        
        if([self.visibleCellIndexes containsIndex:index]){
            
            cell = [self.dataSource gridView:self cellAtIndex:index];
            cell.springBoardView = self;
        }
        
        [newCells addObject:cell];
        
        index = [indexes indexGreaterThanIndex:index];
    }
    
    [self.cells insertObjects:newCells atIndexes:indexes];
    
}


- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    NSIndexSet* idxs = [indexSet indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        return [self.allIndexes containsIndex:idx];
        
    }];
    
    if([idxs count] != [indexSet count]){
        
        ALWAYS_ASSERT;
    }   
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    [self _updateLayout];
    
    
    IndexRangeChanges c = [self.indexLoader changesByRefreshingLayout];
    NSRange newVisIndexRange = c.fullIndexRange;
    
    self.visibleCellIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:newVisIndexRange];        
    
    NSMutableIndexSet* all = [self.allIndexes mutableCopy];
    NSUInteger firstIndex = [indexSet firstIndex];
    
    [all removeIndexesInRange:NSMakeRange(0, firstIndex)];
    
    NSIndexSet* indexesToMove = [all indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        return [self.visibleCellIndexes containsIndex:idx];
        
    }];
    
    NSMutableIndexSet* indexesToLoad = [indexesToMove mutableCopy];
    [indexesToLoad removeIndexesInRange:NSMakeRange([indexesToLoad lastIndex]-[indexSet count], [indexSet count])];
    
    NSLog(@"indexesToRemove: %@", [indexSet description]);
    NSLog(@"indexesToLoad: %@", [indexesToLoad description]);
    NSLog(@"indexesToLayout: %@", [indexesToMove description]);
    
    
    [self _removeCellsAtIndexes:indexSet];
    
    [self _loadCellsAtIndexes:indexesToLoad];
    
    [self _layoutCellsAtIndexes:indexesToMove];
    
    NSLog(@"visibleIndexes: %@", self.visibleCellIndexes);
    NSLog(@"allIndexes: %@", self.allIndexes);
    
    
}


- (void)_removeCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
        
    while(index != NSNotFound){
        
        FJSpringBoardCell* cell = [[self.cells objectAtIndex:index] retain];
        
        if(![cell isKindOfClass:[FJSpringBoardCell class]]){
            
            return;
        }
        
        [cell.contentView removeFromSuperview];
        [self.dequeuedCells addObject:cell];
        [cell release];
        
        index = [indexes indexGreaterThanIndex:index];
    }
    
    [self.cells removeObjectsAtIndexes:indexes];
    
}


- (NSUInteger)numberOfCells{
    
    return [self.allIndexes count];
    
}


- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([NSNull null] == (NSNull*)cell)
        return nil;
    
    return cell;
}


- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell{
    
    NSUInteger i = [self.cells indexOfObject:cell];
    
    return i;
    
}

- (CGRect)frameForCellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.cells objectAtIndex:index];
    
    if([NSNull null] == (NSNull*)cell){
        
       return [self.layout frameForCellAtIndex:index];
        
    }
    
    return cell.contentView.frame;
    
}

#pragma mark -

- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated{
        
    CGRect f =  [self frameForCellAtIndex:index];
    
    //TODO: support scroll positions?
    [self scrollRectToVisible:f animated:animated];
    
}

#pragma mark -
#pragma mark Selection

- (NSIndexSet *)indexesForSelectedCells{
    
    return [self.selectedIndexes copy];
}



@end
