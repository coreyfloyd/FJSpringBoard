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
    
    NSNumber* newNum = [self.mapOldToNew objectAtIndex:oldIndex];
    
    return [newNum unsignedIntegerValue];
    
    
}
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex{
    
    NSNumber* newNum = [self.mapNewToOld objectAtIndex:newIndex];
    
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
    if(self.currentReorderingIndex == NSNotFound)
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
    [self.mapNewToOld insertObject:[NSNumber numberWithUnsignedInt:NSNotFound] atIndex:index];
    
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[self.mapOldToNew count]];
    
    [self.mapOldToNew enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldVal = [val unsignedIntegerValue];
        
        if(oldVal != NSNotFound){
            
            if(oldVal >= index){
                oldVal++;
                
                val = [NSNumber numberWithUnsignedInteger:oldVal];
                
            }
        }
        
        [editedValues addObject:val];
        
    }];
    
    self.mapOldToNew = editedValues;
        
    NSRange affectedRange = NSMakeRange(index, [self.cells count] - index);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
    
}

- (NSIndexSet*)modifiedIndexesByRemovingCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return nil;
    
    NSMutableArray* nulls = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    for(int i = 0; i< [indexes count]; i++){
        
        [nulls addObject:[NSNumber numberWithUnsignedInt:NSNotFound]];
    }
    

    NSMutableIndexSet* oldIndexes = [NSMutableIndexSet indexSet];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        NSUInteger old = [self oldIndexForNewIndex:idx];
        [oldIndexes addIndex:old];    
    }];
    
    [self.mapOldToNew replaceObjectsAtIndexes:oldIndexes withObjects:nulls];
    
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[self.mapOldToNew count]];

    [self.mapOldToNew enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldVal = [val unsignedIntegerValue];
        
        if(oldVal != NSNotFound){
            
            __block int numToDecrement = 0;
            
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
                if(oldVal > idx)
                    numToDecrement++;
            }];
            
            oldVal = oldVal-numToDecrement;
            
            val = [NSNumber numberWithUnsignedInteger:oldVal];
                        
        }
        
        
        [editedValues addObject:val];
        
    }];
    
    self.mapOldToNew = editedValues;
    
    /*
    for (int i = 0; i < [indexes count]; i++) {
        [self.mapOldToNew removeLastObject];
    }
    */
    
    //remove cells
    [self.cells removeObjectsAtIndexes:indexes];
    [self.mapNewToOld removeObjectsAtIndexes:indexes];
    
        
    NSUInteger min = [indexes firstIndex];
    NSRange affectedRange = NSMakeRange(min, [self.cells count] - min);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
}

- (NSIndexSet*)modifiedIndexesByAddingCellsAtIndexes:(NSIndexSet*)indexes{

    
    if([indexes count] == 0)
        return nil;

    NSArray* nulls = nullArrayOfSize([indexes count]);

    
    //insert cells
    [self.cells insertObjects:nulls atIndexes:indexes];
    
    NSMutableArray* notfounds = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    for(int i = 0; i< [indexes count]; i++){
        
        [notfounds addObject:[NSNumber numberWithUnsignedInt:NSNotFound]];
    }
    
    
    [self.mapNewToOld insertObjects:notfounds atIndexes:indexes];
    
    
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[self.mapOldToNew count]];
    
    [self.mapOldToNew enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldVal = [val unsignedIntegerValue];
        
        if(oldVal != NSNotFound){
            
            NSUInteger numberOfInsertedCellsBeforeIndex = [[indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
            
                if(oldVal >= idx)
                    return YES;
                
                return NO;
            
            }] count];
            
            
            oldVal+=numberOfInsertedCellsBeforeIndex;
                
            val = [NSNumber numberWithUnsignedInteger:oldVal];
                
            }
        
        [editedValues addObject:val];
        
    }];
     
    self.mapOldToNew = editedValues;
    
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
