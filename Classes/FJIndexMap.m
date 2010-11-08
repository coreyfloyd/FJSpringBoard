//
//  FJIndexMap.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 11/5/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJIndexMap.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardCell.h"

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
        [self commitChanges];
        
    }
    return self;
}


- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex{
    
    NSNumber* newNum = [self.mapNewToOld objectAtIndex:oldIndex];
    
    return [newNum unsignedIntegerValue];
    
    
}
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex{
    
    NSNumber* newNum = [self.mapOldToNew objectAtIndex:newIndex];
    
    return [newNum unsignedIntegerValue];
}


- (void)beginReorderingIndex:(NSUInteger)index{
    
    self.originalReorderingIndex = index;
    self.currentReorderingIndex = index;
}

- (NSIndexSet*)modifiedIndexesByMovingReorderingCellToCellAtIndex:(NSUInteger)index{
    
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

- (NSIndexSet*)modifiedIndexesByAddingGroupCell:(FJSpringBoardGroupCell*)groupCell atIndex:(NSUInteger)index{
    
    if(index == NSNotFound)
        return nil;
    
    //insert group cell
    [self.cells insertObject:groupCell atIndex:index];
    [self.mapNewToOld insertObject:[NSNull null] atIndex:index];
    
    NSRange rangeToEdit = NSMakeRange(index, [self.mapOldToNew count]-index);
    
    NSArray* mapToEdit = [self.mapOldToNew subarrayWithRange:rangeToEdit];
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[mapToEdit count]];
    
    [mapToEdit enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
        NSNumber* val = (NSNumber*)obj;
        
        if(![obj isEqual:[NSNull null]]){
            
            NSUInteger newVal = [val unsignedIntegerValue] + 1;
            val = [NSNumber numberWithUnsignedInteger:newVal];

        }
        
        [editedValues addObject:val];
        
    }];
    
    [self.mapOldToNew replaceObjectsInRange:rangeToEdit withObjectsFromArray:editedValues];
        
    NSRange affectedRange = NSMakeRange(index, [self.cells count] - index);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
    
}

- (NSIndexSet*)modifiedIndexesByRemovingCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return nil;
    
    //remove cells
    [self.cells removeObjectsAtIndexes:indexes];
    [self.mapNewToOld removeObjectsAtIndexes:indexes];
    
    NSArray* nulls = nullArrayOfSize([indexes count]);
    [self.mapOldToNew insertObjects:nulls atIndexes:indexes];
    
    for (int i = 0; i < [indexes count]; i++) {
        [self.mapOldToNew removeLastObject];
    }
    
    NSUInteger min = [indexes firstIndex];
    NSRange affectedRange = NSMakeRange(min, [self.cells count] - min);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
}


- (void)commitChanges{
    
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
