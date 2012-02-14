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


@implementation NSIndexSet(intersection)

- (NSIndexSet*)_intersectionWithIndexSet:(NSIndexSet*)otherIndexSet{
    
    return [self indexesWithOptions:0 passingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        
        if([otherIndexSet containsIndex:idx])
            return YES;
        
        return NO;
        
    }];
}


- (NSIndexSet*)intersectionWithIndexSet:(NSIndexSet*)otherIndexSet{
    
    if([self count] < [otherIndexSet count]){
        
        return [self _intersectionWithIndexSet:otherIndexSet];
    }
    
    return [otherIndexSet _intersectionWithIndexSet:self];
    
}

@end


@interface FJSpringBoardIndexLoader()

@property(nonatomic, readwrite) CGPoint contentOffset;

@property(nonatomic, retain) NSMutableIndexSet *mutableAllIndexes;
@property(nonatomic, retain) NSMutableIndexSet *mutableLoadedIndexes;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToLoad;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToUnload;

@property (nonatomic, retain) NSIndexSet* visibleIndexes;


@end


@implementation FJSpringBoardIndexLoader


@synthesize layout;
@synthesize contentOffset;

@synthesize mutableAllIndexes;
@synthesize mutableLoadedIndexes;    
@synthesize mutableIndexesToLoad;
@synthesize mutableIndexesToUnload;

@synthesize visibleIndexes;


- (void) dealloc
{
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

- (id)initWithCellCount:(NSUInteger)count{
    
    self = [super init];
    if (self != nil) {
        
        if(count)
            self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];    
        else
            self.mutableAllIndexes = [NSMutableIndexSet indexSet];    
            
        self.mutableLoadedIndexes = [NSMutableIndexSet indexSet];
        self.mutableIndexesToLoad = [NSMutableIndexSet indexSet];
        self.mutableIndexesToUnload = [NSMutableIndexSet indexSet];
                    
    }
    return self;
}

- (void)adjustLoadedIndexesByDeletingIndexes:(NSIndexSet*)deleted insertingIndexes:(NSIndexSet*)inserted{
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray* loaded = [NSMutableArray arrayWithCapacity:self.allIndexes.count];
    
    NSNumber* no = [NSNumber numberWithBool:NO];
    NSNumber* yes = [NSNumber numberWithBool:YES];
    
    [self.allIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
       
        [loaded addObject:no];
        
    }];
    
    [self.loadedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        [loaded replaceObjectAtIndex:idx withObject:yes];
        
    }];
    
    [loaded removeObjectsAtIndexes:deleted];

    NSIndexSet* insertedVisible = [inserted intersectionWithIndexSet:self.visibleIndexes];
    NSMutableIndexSet* insertedNotVisible = [NSMutableIndexSet indexSet];
    [insertedNotVisible addIndexes:inserted];
    [insertedNotVisible removeIndexes:insertedVisible];
    
    NSMutableArray* new = [NSMutableArray arrayWithCapacity:inserted.count];

    [inserted enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
       
        if([insertedVisible containsIndex:idx])
            [new addObject:yes];
        else
            [new addObject:no];
        
    }];
        
    [loaded insertObjects:new atIndexes:inserted];
    
    NSIndexSet* newLoaded = [loaded indexesOfObjectsWithOptions:0 passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = obj;
        return [val boolValue];
        
    }];
        
    NSUInteger newCount = self.allIndexes.count + [inserted count] - [deleted count];
    self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newCount)];    
    
    self.mutableLoadedIndexes = [[newLoaded mutableCopy] autorelease];
    
    [pool drain];
}



- (NSIndexSet*)allIndexes{
    
    return [[self.mutableAllIndexes copy] autorelease];

}

- (NSIndexSet*)visibleIndexesInIndexSet:(NSIndexSet*)someIndexes{
        
    return [self.visibleIndexes intersectionWithIndexSet:someIndexes];

}

- (BOOL)indexIsVisible:(NSUInteger)anIndex{
    
    return [self.visibleIndexes containsIndex:anIndex];
    
}

- (void)updateIndexesWithContentOffest:(CGPoint)newOffset{
    
    self.contentOffset = newOffset;
        
    NSRange visRange = [self.layout visibleRangeWithPaddingForContentOffset:newOffset];
    
    NSMutableIndexSet* newIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:visRange];
        
    self.visibleIndexes = newIndexes;
    
    //visible indexes are "theoretical" lets only try to load indexes that are actually backed by data
    NSIndexSet* newIndexesToLoad = [self.allIndexes intersectionWithIndexSet:newIndexes];
    
    NSIndexSet* added = indexesAdded(self.loadedIndexes, newIndexesToLoad);
    NSIndexSet* removed = indexesRemoved(self.loadedIndexes, newIndexesToLoad);
    
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
