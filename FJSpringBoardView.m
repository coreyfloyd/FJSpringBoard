//
//  FJGridView.m
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardView.h"
#import "FJSpringBoardLayout.h"
#import "FJSpringBoardCellItem.h"

NSIndexSet* indexesAdded(NSIndexSet* oldSet, NSIndexSet* newSet){
    
    NSMutableIndexSet* s = [newSet mutableCopy];
    [s removeIndexes:oldSet];
    
    return s;
}

NSIndexSet* indexesRemoved(NSIndexSet* oldSet, NSIndexSet* newSet){
    
    NSMutableIndexSet* s = [oldSet mutableCopy];
    [s removeIndexes:newSet];

    return s;
}

@interface FJSpringBoardCell(Internal)

@property(nonatomic, assign) FJSpringBoardView* springBoardView;


@end


@interface FJSpringBoardView()

@property(nonatomic, retain) FJSpringBoardLayout *layout;

@property(nonatomic, retain) NSMutableArray *cellItems; //by index

@property(nonatomic, retain, readwrite) NSMutableIndexSet *visibleIndexes; 
@property(nonatomic, retain, readwrite) NSMutableArray *visibleCells; 
@property(nonatomic, retain) NSMutableSet *dequeuedCells;

- (void)_layoutCells;

@end

@implementation FJSpringBoardView

@synthesize dataSource;
@synthesize delegate;
@synthesize gridViewInsets;
@synthesize cellPadding;
@synthesize cellSize;
@synthesize mode;
@synthesize scrollDirection;
@synthesize allowsDeleteMode;
@synthesize cellItems;
@synthesize layout;
@synthesize visibleIndexes;
@synthesize visibleCells;
@synthesize dequeuedCells;







- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [visibleCells release];
    visibleCells = nil;
    [dequeuedCells release];
    dequeuedCells = nil;
    [visibleIndexes release];
    visibleIndexes = nil;
    [layout release];
    layout = nil;
    [cellItems release];
    cellItems = nil;
    [super dealloc];
    
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.layout = [[[FJSpringBoardLayout alloc] init] autorelease];
        self.contentSize = CGSizeZero;
    }
    return self;
}

- (void)initializeView{
    
    self.layout = [[[FJSpringBoardLayout alloc] init] autorelease];
    self.contentSize = CGSizeZero;
    
}

- (void)_configureLayout{
    
    [self.layout reset];
    self.layout.gridViewBounds = self.bounds;
    self.layout.gridViewInsets = self.gridViewInsets;
    self.layout.cellSize = self.cellSize;
    self.layout.cellPadding = self.cellPadding;
    self.layout.layoutDirection = self.scrollDirection;

}



- (void)reloadData{
    
    [self _configureLayout];
    
    NSInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    self.contentSize = [self.layout contentSizeWithCellCount:numOfCells];
        
    NSInteger numOfVisibleCells = [self.layout numberOfVisibleCells];
    numOfVisibleCells = MIN(numOfCells,numOfVisibleCells);
    
    NSMutableArray* visCells = [NSMutableArray arrayWithCapacity:numOfVisibleCells];
    
    for(int i = 0; i < numOfVisibleCells; i++){
        
        FJSpringBoardCell* cell = [self.dataSource gridView:self cellAtIndex:i];
        cell.springBoardView = self;
        [visCells addObject:cell];
    }
    self.visibleCells = visCells;
    
    self.visibleIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numOfVisibleCells)];
    
    self.dequeuedCells = [NSMutableSet setWithCapacity:numOfVisibleCells];
    
    
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:numOfCells];
    for(int i = 0; i < numOfCells; i++){
        
        FJSpringBoardCellItem* item = [[FJSpringBoardCellItem alloc] init];
        [items addObject:item];
        
    }
    self.cellItems = items;
    
    [self _layoutCells];
}

- (void)_layoutCells{
    
    NSInteger firstIndex = [self.visibleIndexes firstIndex];
    
    for(FJSpringBoardCell *eachCell in self.visibleCells){
        
        CGRect cellFrame = [self.layout frameForCellAtIndex:firstIndex];
        eachCell.contentView.frame = cellFrame;
        [self addSubview:eachCell.contentView];
        firstIndex++;
    }
    
    
}



- (void) setContentOffset:(CGPoint) offset{
    
	[super setContentOffset: offset];
}

- (void)setContentOffset: (CGPoint) contentOffset animated: (BOOL) animate
{
	// Call our super duper method
	[super setContentOffset: contentOffset animated: animate];
	
	// for long grids, ensure there are visible cells when scrolled to
	if (!animate)
	{
		//[self updateVisibleGridCellsNow];
		/*if (![_visibleCells count])
         {
         NSIndexSet * newIndices = [_gridData indicesOfCellsInRect: [self gridViewVisibleBounds]];
         [self updateForwardCellsForVisibleIndices: newIndices];
         }*/
	}
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
