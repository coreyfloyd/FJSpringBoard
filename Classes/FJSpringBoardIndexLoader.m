//
//  FJSpringBoardIndexLoader.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardCell.h"
#import "FJSpringBoardAction.h"
#import "FJSpringBoardActionIndexMap.h"
#import "FJSpringBoardCellUpdate.h"
#import "FJSpringBoardUpdate.h"

#define MAX_PAGES 3

NSUInteger indexWithLargestAbsoluteValueFromStartignIndex(NSUInteger start, NSIndexSet* indexes){
    
    __block NSUInteger answer = start;
    __block int largestDiff = 0;
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        int diff = abs((int)((int)start - (int)idx));
        
        if(diff > largestDiff){
            largestDiff = diff;
            answer = idx;
        }
        
    }];
    
    return answer;
}

@interface FJSpringBoardIndexLoader()

@property(nonatomic, readwrite) CGPoint contentOffset;

@property(nonatomic, retain) NSMutableIndexSet *mutableAllIndexes;
@property(nonatomic, retain) NSMutableIndexSet *mutableLoadedIndexes;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToLoad;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToUnload;

@property (nonatomic, retain) NSIndexSet* visibleIndexes;

@property (nonatomic, retain) NSMutableArray *actionQueue;


@end


@implementation FJSpringBoardIndexLoader


@synthesize layout;
@synthesize contentOffset;

@synthesize mutableAllIndexes;
@synthesize mutableLoadedIndexes;    
@synthesize mutableIndexesToLoad;
@synthesize mutableIndexesToUnload;

@synthesize visibleIndexes;

@synthesize actionQueue;


- (void) dealloc
{
    [actionQueue release];
    actionQueue = nil;
    [mutableIndexesToLoad release];
    mutableIndexesToLoad = nil;
    [mutableIndexesToUnload release];
    mutableIndexesToUnload = nil;
    [mutableAllIndexes release];
    mutableAllIndexes = nil; 
    [layout release];
    layout = nil;
    [super dealloc];
}

- (id)initWithCount:(NSUInteger)count{
    
    self = [super init];
    if (self != nil) {
        
        self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];
        self.mutableLoadedIndexes = [NSMutableIndexSet indexSet];
        self.mutableIndexesToLoad = [NSMutableIndexSet indexSet];
        self.mutableIndexesToUnload = [NSMutableIndexSet indexSet];
        
        self.actionQueue = [NSMutableArray array];
            
    }
    return self;
}

- (NSIndexSet*)allIndexes{
    
    return [[self.mutableAllIndexes copy] autorelease];

}

- (void)updateIndexesWithContentOffest:(CGPoint)newOffset{
    
    self.contentOffset = newOffset;
        
    NSRange visRange = [self.layout visibleRangeForContentOffset:newOffset];
    
    NSMutableIndexSet* newIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:visRange];
    
    self.visibleIndexes = newIndexes;
    
    NSIndexSet* added = indexesAdded(self.loadedIndexes, newIndexes);
    NSIndexSet* removed = indexesRemoved(self.loadedIndexes, newIndexes);
    
    [self markIndexesForLoading:added];
    [self markIndexesForUnloading:removed];

}


- (void)markIndexesForLoading:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToLoad addIndexes:indexes];
    [self.mutableIndexesToUnload removeIndexes:indexes];
}

- (void)markIndexesForUnloading:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToUnload addIndexes:indexes];
    [self.mutableIndexesToLoad removeIndexes:indexes];

}

- (NSIndexSet*)indexesToLoad{
    
    return [[self.mutableIndexesToLoad copy] autorelease];
}


- (NSIndexSet*)indexesToUnload{
    
    return [[self.mutableIndexesToUnload copy] autorelease];

}

- (void)clearIndexesToLoad{
    
    [self.mutableLoadedIndexes addIndexes:self.mutableIndexesToLoad];
    [self.mutableIndexesToLoad removeAllIndexes];
}

- (void)clearIndexesToUnload{
    
    [self.mutableLoadedIndexes removeIndexes:self.mutableIndexesToUnload];
    [self.mutableIndexesToUnload removeAllIndexes];

}

- (NSIndexSet*)loadedIndexes{
    
    return [[self.mutableLoadedIndexes copy] autorelease];

}

- (void)enqueueAction:(FJSpringBoardAction*)action{
    
    [self.actionQueue enqueue:action];
    
}
- (FJSpringBoardAction*)dequeueNextAction{
    
    if([self.actionQueue count] == 0)
        return nil;
    
    FJSpringBoardAction* next = [self.actionQueue dequeue];
    return next;
    
}



- (void)queueActionByReloadingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self enqueueAction:[FJSpringBoardAction reloadActionWithIndexes:indexes animation:animation]];
    
}

- (void)queueActionByInsertingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self enqueueAction:[FJSpringBoardAction insertionActionWithIndexes:indexes animation:animation]];
    
}

- (void)queueActionByDeletingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [self enqueueAction:[FJSpringBoardAction deletionActionWithIndexes:indexes animation:animation]];
    
}

- (FJSpringBoardUpdate*)processFirstActionInQueue{
        
    FJSpringBoardAction* action = [self dequeueNextAction];
    
    if(action == nil)
        return nil;

    ASSERT_TRUE(indexesAreContiguous(self.visibleIndexes));
    NSRange range = rangeWithContiguousIndexes(self.visibleIndexes);
    
    debugLog(@"visible range: %i - %i", range.location, NSMaxRange(range));
    
    FJSpringBoardUpdate* update = [[FJSpringBoardUpdate alloc] initWithCellCount:[self.allIndexes count]  visibleIndexRange:range springBoardAction:action];
    
    self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [update newCellCount])];    
    //TODO: if we had any cells to reload we are fucked. we should go to a delegate pattern so the index loader can call the 
       
    return update;


}

/*
- (void)purgeActionsOutsideOfActionableRange{
    
    
     //if an index is inserted offscreen, it technically wouldn't need an action.
     //However, if it is later bumped onscreen by another action, we would lose the information about the insertion.
     //So we do want to purge actions outside of the affected range after we are done create actions.
     
    
    extendedDebugLog(@"range in view: %i - %i", actionableIndexRange.location, NSMaxRange(actionableIndexRange));
    
    
    NSSet* actionsToRemove = [[self cellActions] objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        
        FJSpringBoardCellUpdate* affectedCell = obj;
        
        if(!NSLocationInRange(affectedCell.newSpringBoardIndex, self.actionableIndexRange)){
            return YES;
        }
        
        return NO;
    }];
    
    [actionsToRemove enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        [self removeCellAction:obj];
        
    }];
    
}
*/



@end
