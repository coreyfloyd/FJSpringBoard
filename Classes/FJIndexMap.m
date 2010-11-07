//
//  FJIndexMap.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 11/5/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJIndexMap.h"
#import "FJSpringBoardUtilities.h"


@implementation FJNormalIndexMap

@synthesize array;

- (void) dealloc
{
    
    [array release];
    array = nil;
    [super dealloc];
}

- (id)initWithArray:(NSMutableArray*)anArray{
     
    self = [super init];
    if (self != nil) {
        
        self.array = anArray;
    }
    
    return self;

}

- (NSArray*)oldArray{
    
    return self.array;
}

- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex{
    
    return oldIndex;
    
    
}
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex{

    return newIndex;
}


@end


@implementation FJReorderingIndexMap

@synthesize mapNewToOld;
@synthesize mapOldToNew;
@synthesize oldArray;
@synthesize array;
@synthesize originalReorderingIndex;
@synthesize currentReorderingIndex;


- (void) dealloc
{
    [mapOldToNew release];
    mapOldToNew = nil;
    [oldArray release];
    oldArray = nil;
    [array release];
    array = nil;
    [mapNewToOld release];
    mapNewToOld = nil;
    [super dealloc];
}

- (id)initWithArray:(NSMutableArray*)anArray reorderingObjectIndex:(NSUInteger)index{
    
    self = [super init];
    if (self != nil) {
        
        self.oldArray = [anArray copy];
        self.array = anArray;
        self.originalReorderingIndex = index;
        self.currentReorderingIndex = index;
        
        self.mapNewToOld = [NSMutableArray arrayWithCapacity:[anArray count]];
        self.mapOldToNew = [NSMutableArray arrayWithCapacity:[anArray count]];
        
        [self.oldArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
            NSNumber* n = [NSNumber numberWithUnsignedInteger:idx];
            [self.mapNewToOld addObject:n];
            [self.mapOldToNew addObject:n];
            
        }];
        
        
    }
    return self;
    
    
}

- (NSIndexSet*)modifiedIndexesByMovingReorderingObjectToIndex:(NSUInteger)index{
    
    if(self.currentReorderingIndex == index)
        return nil;
    
    if(index == NSNotFound)
        return nil;
    

    id obj = [[self.array objectAtIndex:self.currentReorderingIndex] retain];
    [self.array removeObjectAtIndex:self.currentReorderingIndex];
    [self.array insertObject:obj atIndex:index];
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
