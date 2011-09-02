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
#import "FJSpringBoardCellAction.h"
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


- (void)addToActionQueue:(id)actionQueueObject
{
    [[self actionQueue] addObject:actionQueueObject];
}
- (void)removeFromActionQueue:(id)actionQueueObject
{
    [[self actionQueue] removeObject:actionQueueObject];
}


- (void)queueActionByReloadingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        FJSpringBoardAction* a = [FJSpringBoardAction actionForReloadingCellAtIndex:idx animation:animation];
        [self addToActionQueue:a];
        
    }];
    
}
- (void)queueActionByMovingCellAtIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex withAnimation:(FJSpringBoardCellAnimation)animation{
    
    FJSpringBoardAction *a = [FJSpringBoardAction actionForMovingCellAtIndex:startIndex toIndex:endIndex animation:animation];
    [self addToActionQueue:a];
    
}
- (void)queueActionByInsertingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardAction* a = [FJSpringBoardAction actionForInsertingCellAtIndex:idx animation:animation];
        [self addToActionQueue:a];
        
    }];
    
}
- (void)queueActionByDeletingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
       
        FJSpringBoardAction* a = [FJSpringBoardAction actionForDeletingCellAtIndex:idx animation:animation];
        [self addToActionQueue:a];
        
    }];
    
}

- (FJSpringBoardUpdate*)processActionQueueAndGetUpdate{
    
    ASSERT_TRUE(indexesAreContiguous(self.visibleIndexes));
    
    NSRange range = rangeWithContiguousIndexes(self.visibleIndexes);
    FJSpringBoardActionIndexMap* map = [[FJSpringBoardActionIndexMap alloc] initWithCellCount:[self.allIndexes count] actionableIndexRange:range springBoardActions:self.actionQueue];
    
    NSSet* actions = [map mappedCellActions];
    
    FJSpringBoardUpdate* update = [[FJSpringBoardUpdate alloc] initWithCellActions:actions];
    
    return [update autorelease];


}

- (void)clearActionQueueAndUpdateCellCount:(NSUInteger)count{
    
    [self.actionQueue removeAllObjects];
    
    self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];

    //TODO: if we had any cells to reload we are fucked. we should go to a delegate pattern so the index loader can call the 
    
}



@end
