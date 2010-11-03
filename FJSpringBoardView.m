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
@property(nonatomic, retain) NSMutableIndexSet *indexesToDequeue;
@property(nonatomic, retain) NSMutableIndexSet *selectedIndexes;
@property(nonatomic, retain) NSMutableIndexSet *indexesToInsert;


@property(nonatomic, retain, readwrite) NSMutableArray *cells; 
@property(nonatomic, retain) NSMutableSet *dequeuedCells;

@property(nonatomic) BOOL layoutIsDirty;

@property(nonatomic) FJSpringBoardCellAnimation layoutAnimation;

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCellAtIndex:(NSUInteger)index;
- (void)_loadCellAtIndex:(NSUInteger)index;
- (void)_processChanges;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_updateIndexes;
- (void)_updateLayout;
- (void)_removeCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_insertNullsAtIndexes:(NSIndexSet*)indexes;
- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_setCellContentViewsAtIndexes:(NSIndexSet*)indexes toAlpha:(float)alphaValue;
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
@synthesize indexesToDequeue;
@synthesize selectedIndexes;
@synthesize indexesToInsert;

@synthesize layoutIsDirty;
@synthesize layoutAnimation;


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
        self.indexesToInsert = [NSMutableIndexSet indexSet];
        self.indexesToDelete = [NSMutableIndexSet indexSet];
        self.indexesToDequeue = [NSMutableIndexSet indexSet];
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
    
    self.layoutIsDirty = YES;

    self.layout.springBoardbounds = self.bounds;
    self.layout.insets = self.springBoardInsets;
    self.layout.cellSize = self.cellSize;
    self.layout.horizontalCellSpacing = self.horizontalCellSpacing;
    self.layout.verticalCellSpacing = self.verticalCellSpacing;
    
    self.layout.cellCount = [self.allIndexes count];
    
    [self.layout updateLayout];
    
    self.contentSize = self.layout.contentSize;
    
    if(self.layoutIsDirty)
        [self _updateIndexes];
    
}


#pragma mark -
#pragma mark UIScrollView

- (void)setContentOffset:(CGPoint)offset{
    
	[super setContentOffset: offset];
    [self _updateIndexes];
}

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animate{
    
	[super setContentOffset: offset animated: animate];    
    [self _updateIndexes];
    
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
#pragma mark Reload

- (void)reloadData{
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _dequeueCellsAtIndexes:self.visibleCellIndexes];
    self.cells = nullArrayOfSize([self.allIndexes count]);

    [self _configureLayout]; //triggers _updateCells
}


- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self.dirtyIndexes addIndexes:indexSet];
    [self.indexesNeedingLayout addIndexes:indexSet];
    
    [self _processChanges];
    
}

- (void)_updateIndexes{
    
    if(indexLoader == nil)
        return;
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
    NSRange rangeToRemove = changes.indexRangeToRemove;
    
    NSRange rangeToLoad = changes.indexRangeToAdd;
    
    NSRange fullRange = changes.fullIndexRange;
    NSMutableIndexSet* newIndexes = [NSIndexSet indexSetWithIndexesInRange:fullRange];
    
    if([self.visibleCellIndexes count] > 0 && !indexesAreContinuous(self.visibleCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    //check maths, newI == oldI - removed + added
    self.visibleCellIndexes = newIndexes;    
    
    [self.indexesToDequeue addIndexesInRange:rangeToRemove];
    
    [self.dirtyIndexes addIndexesInRange:rangeToLoad];
    
    [self.indexesNeedingLayout addIndexesInRange:rangeToLoad];

    if([indexesToDequeue count] > 0)
        NSLog(@"Indexes to Dequeue %@", indexesToDequeue);
    if([dirtyIndexes count] > 0)
        NSLog(@"Indexes to Load: %@", dirtyIndexes);
    if([indexesNeedingLayout count] > 0)
        NSLog(@"Indexes to Layout: %@", indexesNeedingLayout);
    
       
    [self _processChanges];
   
    
    self.layoutAnimation = FJSpringBoardCellAnimationNone;
    self.layoutIsDirty = NO;

}



- (void)_processChanges{
    
    [self _insertCellsAtIndexes:[self.indexesToInsert copy]];
    
    [self _dequeueCellsAtIndexes:[self.indexesToDequeue copy]];
    
    [self _removeCellsAtIndexes:[self.indexesToDelete copy]];
    
    
    if(self.layoutAnimation != FJSpringBoardCellAnimationNone){
        
        [UIView beginAnimations:@"layoutCells" context:nil];
        [UIView setAnimationDuration:0.25];
    }
    
    [self _layoutCellsAtIndexes:[self.indexesNeedingLayout copy]];
    
    if(self.layoutAnimation != FJSpringBoardCellAnimationNone){
        
        [UIView commitAnimations];

    }
}


#pragma mark -
#pragma mark Layout Cells


- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
    
        if(![self.visibleCellIndexes containsIndex:index]){
            
            return;
        }
        
        if([self.dirtyIndexes containsIndex:index]){
            
            [self _loadCellAtIndex:index];
            
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            [self _loadCellAtIndex:index];
            eachCell = [self.cells objectAtIndex:index];
        }
        
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.contentView.frame = cellFrame;
        [self addSubview:eachCell.contentView];
        
        [self.indexesNeedingLayout removeIndex:index];
                
    
    }];
    
}



#pragma mark -
#pragma mark Load cells

- (void)_loadCells{
    
    [self _loadCellsAtIndexes:self.visibleCellIndexes];
}

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
       
        [self _loadCellAtIndex:index];

    }];

}

- (void)_loadCellAtIndex:(NSUInteger)index{
    
    FJSpringBoardCell* cell = [self.dataSource gridView:self cellAtIndex:index];
    [cell retain];
    
    cell.springBoardView = self;
    [self _dequeueCellAtIndex:index];
    
    [self.cells replaceObjectAtIndex:index withObject:cell];
    [cell release];
    
    [self.dirtyIndexes removeIndex:index];

    
}


#pragma mark -
#pragma mark Insert Cells

- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    [self _insertNullsAtIndexes:indexes];
    
    [self _layoutCellsAtIndexes:indexes];
        
    if(self.layoutAnimation != FJSpringBoardCellAnimationNone){
        
        [self _setCellContentViewsAtIndexes:indexes toAlpha:0];
        
        [UIView beginAnimations:@"insertCells" context:nil];
        [UIView setAnimationDuration:1];
        
        [self _setCellContentViewsAtIndexes:indexes toAlpha:1];

        [UIView commitAnimations];

    }
    
    [self.indexesToInsert removeIndexes:indexes];
    
}

- (void)_setCellContentViewsAtIndexes:(NSIndexSet*)indexes toAlpha:(float)alphaValue{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
       
        if(![self.visibleCellIndexes containsIndex:index]){
            
            return;
        }
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if([eachCell isEqual:[NSNull null]]){
            
            return;
            
        }
        
        eachCell.contentView.alpha = alphaValue;
                
    }];
    
}


#pragma mark -
#pragma mark Remove Cells

- (void)_removeCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    [self _dequeueCellsAtIndexes:indexes];
    
    [self.cells removeObjectsAtIndexes:indexes];
    
    [self.indexesToDelete removeIndexes:indexes];

}

#pragma mark -
#pragma mark Dequeue Cells


- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return;
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        [self _dequeueCellAtIndex:index];
        
        [self.indexesToDequeue removeIndex:index];        
    }];
    
    if([self.indexesToDequeue count] > 0){
        
        ALWAYS_ASSERT;
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
    
    self.layoutAnimation = animation;

    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];

    [self.indexesToInsert addIndexes:indexSet];
    
    NSIndexSet* indexesToRelayout = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstIndex, ([self.allIndexes count] - firstIndex))];
    [self.indexesNeedingLayout addIndexes:indexesToRelayout];
    
    [self _updateLayout]; //triggers update
            
}

- (void)_insertNullsAtIndexes:(NSIndexSet*)indexes{
    
    NSArray* nulls = nullArrayOfSize([indexes count]);
    
    [self.cells insertObjects:nulls atIndexes:indexes];
}


- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    NSIndexSet* idxs = [indexSet indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
        
        return [self.allIndexes containsIndex:idx];
        
    }];
    
    if([idxs count] != [indexSet count]){
        
        ALWAYS_ASSERT;
    }   
    
    self.layoutAnimation = animation;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self.indexesToDelete addIndexes:indexSet];
    [self.indexesNeedingLayout addIndexesInRange:NSMakeRange([indexSet firstIndex], [self.allIndexes count]-[indexSet firstIndex])];
    
    [self _updateLayout];
    
}

#pragma mark -


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
