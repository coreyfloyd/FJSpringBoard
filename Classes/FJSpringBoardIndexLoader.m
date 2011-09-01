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
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToLayout;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToUnload;

@property(nonatomic, readwrite) NSUInteger originalReorderingIndex;
@property(nonatomic, readwrite) NSUInteger currentReorderingIndex;


@end


@implementation FJSpringBoardIndexLoader


@synthesize layout;
@synthesize contentOffset;


@synthesize mutableAllIndexes;
@synthesize mutableLoadedIndexes;    
@synthesize mutableIndexesToLoad;
@synthesize mutableIndexesToLayout;
@synthesize mutableIndexesToUnload;


@synthesize mapNewToOld;
@synthesize mapOldToNew;
@synthesize cellsWithoutCurrentChangesApplied;
@synthesize cells;
@synthesize originalReorderingIndex;
@synthesize currentReorderingIndex;


- (void) dealloc
{
    [mutableIndexesToLoad release];
    mutableIndexesToLoad = nil;
    [mutableIndexesToLayout release];
    mutableIndexesToLayout = nil;
    [mutableIndexesToUnload release];
    mutableIndexesToUnload = nil;
    [mutableAllIndexes release];
    mutableAllIndexes = nil; 
    [mapOldToNew release];
    mapOldToNew = nil;
    [cellsWithoutCurrentChangesApplied release];
    cellsWithoutCurrentChangesApplied = nil;
    [cells release];
    cells = nil;
    [mapNewToOld release];
    mapNewToOld = nil;
    [layout release];
    layout = nil;
    [super dealloc];
}

- (id)initWithCount:(NSUInteger)count{
    
    self = [super init];
    if (self != nil) {
        
        self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];
        self.mutableLoadedIndexes = [NSMutableIndexSet indexSet];
        self.mutableIndexesToLayout = [NSMutableIndexSet indexSet];
        self.mutableIndexesToLoad = [NSMutableIndexSet indexSet];
        self.mutableIndexesToUnload = [NSMutableIndexSet indexSet];
        
        self.cells = nullArrayOfSize(count);

        [self commitChanges];
        
    }
    return self;
}

- (NSIndexSet*)allIndexes{
    
    return [[self.mutableAllIndexes copy] autorelease];

}

- (void)updateIndexesWithContentOffest:(CGPoint)newOffset{
    
    self.contentOffset = newOffset;

    if([self.layout isKindOfClass:[FJSpringBoardVerticalLayout class]]){
        
        FJSpringBoardVerticalLayout* vert = (FJSpringBoardVerticalLayout*)self.layout;
        
        NSMutableIndexSet* newVisibleIndexes = [[[vert visibleCellIndexesWithPaddingForContentOffset:newOffset] mutableCopy] autorelease];
        
        NSIndexSet* added = indexesAdded(self.loadedIndexes, newVisibleIndexes);
        NSIndexSet* removed = indexesRemoved(self.loadedIndexes, newVisibleIndexes);
                
        [self markIndexesForLoading:added];
        [self markIndexesForUnloading:removed];
        
    }else{
        
        FJSpringBoardHorizontalLayout* hor = (FJSpringBoardHorizontalLayout*)self.layout;
        
        NSUInteger currentPage = [hor pageForContentOffset:newOffset];
        
        NSUInteger pageCount = [hor pageCount];
        
        NSUInteger nextPage = NSNotFound;
        
        if(currentPage < pageCount-1)
            nextPage = currentPage + 1;
        
        NSUInteger previousPage = NSNotFound;
        
        if(currentPage != 0)
            previousPage = currentPage - 1;
        
        NSMutableIndexSet* newIndexes = [NSMutableIndexSet indexSet];
        
        [newIndexes addIndexes:[hor cellIndexesForPage:currentPage]];
        [newIndexes addIndexes:[hor cellIndexesForPage:previousPage]];
        [newIndexes addIndexes:[hor cellIndexesForPage:nextPage]];
        
        NSIndexSet* added = indexesAdded(self.loadedIndexes, newIndexes);
        NSIndexSet* removed = indexesRemoved(self.loadedIndexes, newIndexes);
        
        [self markIndexesForLoading:added];
        [self markIndexesForUnloading:removed];
            
    }
    
}


- (void)markIndexesForLoading:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToLoad addIndexes:indexes];
    [self markIndexesForLayout:indexes];
    [self.mutableIndexesToUnload removeIndexes:indexes];
}

- (void)markIndexesForLayout:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToLayout addIndexes:indexes];
}

- (void)markIndexesForUnloading:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToUnload addIndexes:indexes];
    [self.mutableIndexesToLoad removeIndexes:indexes];
    [self.mutableIndexesToLayout removeIndexes:indexes];

}

- (NSIndexSet*)indexesToLoad{
    
    return [[self.mutableIndexesToLoad copy] autorelease];
}

- (NSIndexSet*)indexesToLayout{
    
    return [[self.mutableIndexesToLayout copy] autorelease];

}

- (NSIndexSet*)indexesToUnload{
    
    return [[self.mutableIndexesToUnload copy] autorelease];

}

- (void)clearIndexesToLoad{
    
    [self.mutableLoadedIndexes addIndexes:self.mutableIndexesToLoad];
    [self.mutableIndexesToLoad removeAllIndexes];
}

- (void)clearIndexesToLayout{
    
    [self.mutableIndexesToLayout removeAllIndexes];

}

- (void)clearIndexesToUnload{
    
    [self.mutableLoadedIndexes removeIndexes:self.mutableIndexesToUnload];
    [self.mutableIndexesToUnload removeAllIndexes];

}

- (NSIndexSet*)loadedIndexes{
    
    return [[self.mutableLoadedIndexes copy] autorelease];

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
    
    for(int i = 0; i < [indexes count]; i++)
        [self.mutableAllIndexes removeIndex:[self.allIndexes lastIndex]];

    
    self.layout.cellCount = [self.cells count];
    [self.layout calculateLayout];
    [self updateIndexesWithContentOffest:self.contentOffset];
        
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
        
    for(int i = 0; i < [indexes count]; i++){
        
        NSUInteger nextIndex = [self.allIndexes lastIndex];
        
        if(nextIndex == NSNotFound){
            
            nextIndex = 0;
   
        }else{
            
            nextIndex++;
        }
        
        [self.mutableAllIndexes addIndex:(nextIndex)];

    }

    self.layout.cellCount = [self.cells count];
    [self.layout calculateLayout];
    [self updateIndexesWithContentOffest:self.contentOffset];
    
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
