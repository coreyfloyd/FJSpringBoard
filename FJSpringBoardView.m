//
//  FJGridView.m
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardView.h"
#import "FJSpringBoardLayout.h"

@interface FJSpringBoardCell(Internal)

@property(nonatomic, assign) FJSpringBoardView springBoardView;


@end


@interface FJSpringBoardView()

@property(nonatomic, retain) FJSpringBoardLayout *layout;

@property(nonatomic, retain) NSMutableArray *cellItems; //by index

@property(nonatomic, retain) NSMutableArray *visibleCells; 
@property(nonatomic, retain) NSMutableArray *dequeuedCells;

- (void)addCellItem:(id)aCellItem;
- (void)removeCellItem:(id)aCellItem;

@end

@implementation FJSpringBoardView

@synthesize dataSource;
@synthesize delegate;
@synthesize gridViewPadding;
@synthesize cellPadding;
@synthesize cellSize;
@synthesize mode;
@synthesize allowsDeleteMode;
@synthesize cellItems;
@synthesize layout;





- (void)dealloc {    
    dataSource = nil;
    delegate = nil;
    [layout release];
    layout = nil;
    [cellItems release];
    cellItems = nil;
    [super dealloc];
    
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

- (void)initializeView{
    
    self.layout = [[[FJSpringBoardLayout alloc] init] autorelease];
    
}

- (void)reloadData{
    
    NSInteger numOfCells = [self.dataSource numberOfCellsInGridView:self];
    
    //calculate number of vis cells
    
    NSInteger numOfVisibleCells;
    
    
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:numOfCells];
    
    for(int i = 0; i < numOfVisibleCells; i++){
        
        FJSpringBoardCell* cell = [self.dataSource gridView:self cellAtIndex:i];
        cell.springBoardView = self;
        
        
    }
    
    
    
    
}

- (CGRect)frameForCellAtIndex:(NSInteger)index{

}

- (void)addCellItem:(id)aCellItem
{
    [[self cellItems] addObject:aCellItem];
}
- (void)removeCellItem:(id)aCellItem
{
    [[self cellItems] removeObject:aCellItem];
}



//based in real time data
- (NSIndexSet)visibleIndexesForContentOffset:(CGPoint)offset{
    
    
}


- (CGSize)contentSizeForWithNumberOfCells:(NSInteger)count{
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
