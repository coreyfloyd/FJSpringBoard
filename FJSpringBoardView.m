//
//  FJGridView.m
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardView.h"
#import "FJSpringBoardCellItem.h"
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

@property(nonatomic, retain) NSMutableArray *cellItems; //by index

@property(nonatomic, retain) NSMutableIndexSet *allIndexes;
@property(nonatomic, retain, readwrite) NSMutableIndexSet *visibleCellIndexes; //rename to loaded
@property(nonatomic, retain, readwrite) NSMutableArray *cells; 
@property(nonatomic, retain) NSMutableSet *dequeuedCells;

@property(nonatomic) BOOL reloading;

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_loadCellItemsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCells;
- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_updateCells;
- (void)_insertCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_updateLayout;

@end

@implementation FJSpringBoardView

@synthesize dataSource;
@synthesize delegate;
@synthesize springBoardInsets;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;
@synthesize cellItems;
@synthesize cells;
@synthesize dequeuedCells;
@synthesize indexLoader;
@synthesize layout;
@synthesize horizontalCellSpacing;
@synthesize verticalCellSpacing;
@synthesize visibleCellIndexes;
@synthesize reloading;
@synthesize allIndexes;




- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [allIndexes release];
    allIndexes = nil;    
    [visibleCellIndexes release];
    visibleCellIndexes = nil;
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
    [cellItems release];
    cellItems = nil;
    [super dealloc];
    
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.indexLoader = [[[FJSpringBoardIndexLoader alloc] init] autorelease];
        self.visibleCellIndexes = [NSMutableIndexSet indexSet];
        self.allIndexes = [NSMutableIndexSet indexSet];
        self.cells = [NSMutableArray array];
        self.dequeuedCells = [NSMutableSet set];
        self.cellItems = [NSMutableArray array];
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
    }
    return self;
}

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



- (void)reloadData{
    
    if(self.reloading)
        return;
    
    self.reloading = YES;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _configureLayout];
        
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
    NSRange rangeToLoad = changes.fullIndexRange;
        
    [self _dequeueCellsAtIndexes:self.visibleCellIndexes];
    
    self.cells = nullArrayOfSize(self.layout.cellCount);
    
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:rangeToLoad];
    
    [self _loadCellsAtIndexes:indexes];
    
    [self _loadCellItemsAtIndexes:indexes];      
    
    [self.visibleCellIndexes addIndexes:indexes];
    
    [self _layoutCells];
    
    self.reloading = NO;
}

#pragma mark -


#pragma mark - Load unload cells

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];

    while(index != NSNotFound){
        
        FJSpringBoardCell* cell = [self.dataSource gridView:self cellAtIndex:index];
        cell.springBoardView = self;
        [self.cells replaceObjectAtIndex:index withObject:cell];

        index = [indexes indexGreaterThanIndex:index];
    }
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


- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
    
    while(index != NSNotFound){
        
        FJSpringBoardCell* cell = [[self.cells objectAtIndex:index] retain];
        
        if(![cell isKindOfClass:[FJSpringBoardCell class]]){
            
            ALWAYS_ASSERT;
        }
        
        [cell.contentView removeFromSuperview];
        [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
        [self.dequeuedCells addObject:cell];
        [cell release];
        
        index = [indexes indexGreaterThanIndex:index];
    }
    
}

#pragma mark -
#pragma mark Items

- (void)_loadCellItemsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    while(index != NSNotFound){
        
        FJSpringBoardCellItem* item = [[FJSpringBoardCellItem alloc] init];
        [items addObject:item];
        
        index = [indexes indexGreaterThanIndex:index];
    }
    
    [self.cellItems addObjectsFromArray:items];    

}

- (void)_layoutCells{
    
    [self _layoutCellsAtIndexes:self.visibleCellIndexes];
    
}

- (void)_layoutCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];
    
    while(index != NSNotFound){
        
        if(![self.visibleCellIndexes containsIndex:index])
            return;
        
        FJSpringBoardCell* eachCell = [self.cells objectAtIndex:index];
        
        if(![eachCell isKindOfClass:[FJSpringBoardCell class]]){
            
            ALWAYS_ASSERT;
        }
        
        CGRect cellFrame = [self.layout frameForCellAtIndex:index];
        eachCell.contentView.frame = cellFrame;
        [self addSubview:eachCell.contentView];
        
        index = [indexes indexGreaterThanIndex:index];
    }
}


#pragma mark -

- (void)setContentOffset:(CGPoint)offset{
    
	[super setContentOffset: offset];
    [self _updateCells];
}

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animate{
    
	[super setContentOffset: offset animated: animate];    
    [self _updateCells];
    
}

- (void)_updateCells{
        
    if(self.visibleCellIndexes == nil)
        return;
    
    if(self.reloading)
        return;
    
    if(!indexesAreContiguous(self.visibleCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    IndexRangeChanges changes = [self.indexLoader changesBySettingContentOffset:self.contentOffset];
    
    NSRange rangeToRemove = changes.indexRangeToRemove;
    
    NSIndexSet* indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:rangeToRemove];
    
    if([indexesToRemove count] > 0){
        
        NSLog(@"removing cells %@", [indexesToRemove description]);
    }
    
    
    if(!indexesAreContiguous(indexesToRemove)){
        
        ALWAYS_ASSERT;
    }
    
    [self _dequeueCellsAtIndexes:indexesToRemove];


    NSRange rangeToLoad = changes.indexRangeToAdd;

    NSIndexSet* indexesToLoad = [NSIndexSet indexSetWithIndexesInRange:rangeToLoad];

    
    if([indexesToLoad count] > 0){
        
        NSLog(@"loading cells %@", [indexesToLoad description]);
    }
    
    if(!indexesAreContiguous(indexesToLoad)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange fullRange = changes.fullIndexRange;
    NSMutableIndexSet* newIndexes = [NSIndexSet indexSetWithIndexesInRange:fullRange];
    
    self.visibleCellIndexes = newIndexes;
    
    [self _loadCellsAtIndexes:indexesToLoad];
    
    [self _layoutCellsAtIndexes:indexesToLoad];
    
    if(!indexesAreContiguous(self.visibleCellIndexes)){
        
        ALWAYS_ASSERT;
    }
    
}


- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier{
    
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
#pragma mark Insertion and Removal

- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
    
    NSUInteger firstIndex = [indexSet firstIndex];

    if(firstIndex > [self.allIndexes lastIndex] + 1){
        
        ALWAYS_ASSERT;
    } 
    
    
    NSIndexSet* indexesToMove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstIndex, ([self.allIndexes count] - firstIndex))];
    
    //NSIndexSet* newLastIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self.allIndexes lastIndex]+1, [indexSet count])];
    
    NSIndexSet* indexesToRelayout = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstIndex, ([indexesToMove count] + [indexSet count]))];
    
    [self _insertCellsAtIndexes:indexSet];
        
    [self _layoutCellsAtIndexes:indexesToRelayout];
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfCells)];
    
    [self _updateLayout];
    
}



- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation{
        
    [self _dequeueCellsAtIndexes:indexSet];
    
    [self _loadCellsAtIndexes:indexSet];
    
    [self _layoutCellsAtIndexes:indexSet];
    
}



@end
