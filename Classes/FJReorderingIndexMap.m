//
//  FJIndexMap.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 11/5/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJReorderingIndexMap.h"
#import "FJSpringBoardUtilities.h"

@implementation FJReorderingIndexMap

@synthesize mapNewToOld;
@synthesize mapOldToNew;
@synthesize oldArray;
@synthesize newArray;
@synthesize originalReorderingIndex;
@synthesize currentReorderingIndex;


- (void) dealloc
{
    [mapOldToNew release];
    mapOldToNew = nil;
    [oldArray release];
    oldArray = nil;
    [newArray release];
    newArray = nil;
    [mapNewToOld release];
    mapNewToOld = nil;
    [super dealloc];
}

- (id)initWithOriginalArray:(NSArray*)original reorderingObjectIndex:(NSUInteger)index{
    
    self = [super init];
    if (self != nil) {
        
        self.oldArray = original;
        self.newArray = [[original mutableCopy] autorelease];
        self.originalReorderingIndex = index;
        self.currentReorderingIndex = index;
        
        self.mapNewToOld = [NSMutableArray arrayWithCapacity:[original count]];
        self.mapOldToNew = [NSMutableArray arrayWithCapacity:[original count]];
        
        [self.oldArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
            NSNumber* n = [NSNumber numberWithUnsignedInteger:idx];
            [self.mapNewToOld addObject:n];
            [self.mapOldToNew addObject:n];
            
        }];
        
        
    }
    return self;
    
    
}

- (NSIndexSet*)modifiedIndexesBymovingReorderingObjectToIndex:(NSUInteger)index{
    
    if(self.currentReorderingIndex == index)
        return nil;
    
    if(index == NSNotFound)
        return nil;
    

    id obj = [[self.newArray objectAtIndex:self.currentReorderingIndex] retain];
    [self.newArray removeObjectAtIndex:self.currentReorderingIndex];
    [self.newArray insertObject:obj atIndex:index];
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


@end
