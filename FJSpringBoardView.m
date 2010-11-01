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

@property(nonatomic, retain, readwrite) NSMutableIndexSet *visibleCellIndexes; 
@property(nonatomic, retain, readwrite) NSMutableArray *cells; 
@property(nonatomic, retain) NSMutableSet *dequeuedCells;

@property(nonatomic) BOOL reloading;

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_dequeueCellsAtIndexes:(NSIndexSet*)indexes;
- (void)_loadCellItemsAtIndexes:(NSIndexSet*)indexes;
- (void)_layoutCells;
- (void)_updateCells;

@end

@implementation FJSpringBoardView

@synthesize dataSource;
@synthesize delegate;
@synthesize gridViewInsets;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;
@synthesize allowsDeleteMode;
@synthesize cellItems;
@synthesize cells;
@synthesize dequeuedCells;
@synthesize indexLoader;
@synthesize layout;
@synthesize horizontalCellSpacing;
@synthesize verticalCellSpacing;
@synthesize visibleCellIndexes;
@synthesize reloading;



- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
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
        self.cells = [NSMutableArray array];
        self.dequeuedCells = [NSMutableSet set];
        self.cellItems = [NSMutableArray array];
        self.scrollDirection = FJSpringBoardViewScrollDirectionVertical;
    }
    return self;
}

- (void)_configureLayout{
      
    if(scrollDirection == FJSpringBoardViewScrollDirectionHorizontal)
        self.layout = [[[FJSpringBoardHorizontalLayout alloc] init] autorelease];
    else
        self.layout = [[[FJSpringBoardVerticalLayout alloc] init] autorelease];
    
    self.indexLoader.layout = self.layout;
    self.layout.springBoardbounds = self.bounds;
    self.layout.insets = self.gridViewInsets;
    self.layout.cellSize = self.cellSize;
    self.layout.horizontalCellSpacing = self.horizontalCellSpacing;
    self.layout.verticalCellSpacing = self.verticalCellSpacing;
    
    NSUInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];

    self.layout.cellCount = numOfCells;
    
    [self.layout updateLayout];
}



- (void)reloadData{
    
    if(self.reloading)
        return;
    
    self.reloading = YES;
    
    [self _configureLayout];
        
    self.contentSize = self.layout.contentSize;
    
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

- (void)_loadCellsAtIndexes:(NSIndexSet*)indexes{
    
    NSUInteger index = [indexes firstIndex];

    while(index != NSNotFound){
        
        FJSpringBoardCell* cell = [self.dataSource gridView:self cellAtIndex:index];
        cell.springBoardView = self;
        [self.cells replaceObjectAtIndex:index withObject:cell];

        index = [indexes indexGreaterThanIndex:index];
    }
}

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

- (void) setContentOffset:(CGPoint) offset{
    
	[super setContentOffset: offset];
    [self _updateCells];
}

- (void)setContentOffset: (CGPoint) contentOffset animated: (BOOL) animate{
    
	[super setContentOffset: contentOffset animated: animate];    
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


@end
