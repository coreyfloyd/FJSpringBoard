//
//  FJIndexMap.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 11/5/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJIndexMap.h"
#import "FJSpringBoardUtilities.h"


@interface FJReorderingIndexMap()

@property(nonatomic, readwrite) NSUInteger originalReorderingIndex;
@property(nonatomic, readwrite) NSUInteger currentReorderingIndex;

@end


@implementation FJReorderingIndexMap

@synthesize mapNewToOld;
@synthesize mapOldToNew;
@synthesize cellsWithoutCurrentChangesApplied;
@synthesize cells;
@synthesize originalReorderingIndex;
@synthesize currentReorderingIndex;


- (void) dealloc
{
    [mapOldToNew release];
    mapOldToNew = nil;
    [cellsWithoutCurrentChangesApplied release];
    cellsWithoutCurrentChangesApplied = nil;
    [cells release];
    cells = nil;
    [mapNewToOld release];
    mapNewToOld = nil;
    [super dealloc];
}

- (id)initWithArray:(NSMutableArray*)anArray{
    
    self = [super init];
    if (self != nil) {
        
        self.cells = anArray;
        [self commitReorder];
        
    }
    return self;
}

- (void)beginReorderingIndex:(NSUInteger)index{
    
    self.originalReorderingIndex = index;
    self.currentReorderingIndex = index;
}

- (NSIndexSet*)modifiedIndexesByMovingReorderingObjectToIndex:(NSUInteger)index{
    
    if(self.currentReorderingIndex == index)
        return nil;
    
    if(index == NSNotFound)
        return nil;
    

    id obj = [[self.cells objectAtIndex:self.currentReorderingIndex] retain];
    [self.cells removeObjectAtIndex:self.currentReorderingIndex];
    [self.cells insertObject:obj atIndex:index];
    [obj release];
    
    obj = [[self.mapNewToOld objectAtIndex:self.currentReorderingIndex] retain];
    [self.mapNewToOld removeObjectAtIndex:self.currentReorderingIndex];
    [self.mapNewToOld insertObject:obj atIndex:index];
    [obj release];
    
    obj = [[self.mapOldToNew objectAtIndex:index] retain];
    [self.mapOldToNew removeObjectAtIndex:index];
    [self.mapOldToNew insertObject:obj atIndex:self.currentReorderingIndex];
    [obj release];
    
    
    
    NSLog(@"moving from index: %i to index: %i", self.currentReorderingIndex, index);
    
    NSUInteger startIndex = NSNotFound;
    NSUInteger lastIndex = NSNotFound;
    
    //moving forward
    if(index > self.currentReorderingIndex){
        
        startIndex = self.currentReorderingIndex;
        lastIndex = index;
        
        //backwards    
    }else{
        
        startIndex = index;
        lastIndex = self.currentReorderingIndex;
        
    }
    
    self.currentReorderingIndex = index;

    NSIndexSet* affectedIndexes = contiguousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); 
    
    return affectedIndexes;
    
}

- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex{
    
    NSNumber* newNum = [self.mapNewToOld objectAtIndex:oldIndex];
    
    return [newNum unsignedIntegerValue];
    
    
}
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex{

    NSNumber* newNum = [self.mapOldToNew objectAtIndex:newIndex];
    
    return [newNum unsignedIntegerValue];
}

- (void)commitReorder{
    
    self.cellsWithoutCurrentChangesApplied = [[self.cells copy] autorelease];
    self.currentReorderingIndex = NSNotFound;
    self.originalReorderingIndex = NSNotFound;
    
    self.mapNewToOld = [NSMutableArray arrayWithCapacity:[self.cells count]];
    
    [self.cellsWithoutCurrentChangesApplied enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* n = [NSNumber numberWithUnsignedInteger:idx];
        [self.mapNewToOld addObject:n];
        
    }];
    
    self.mapOldToNew = [self.mapNewToOld mutableCopy];

}


@end
