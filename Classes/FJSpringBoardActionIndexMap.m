//
//  FJSpringBoardActionIndexMap.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardActionIndexMap.h"
#import "FJSpringBoardAction.h"
#import "FJSpringBoardActionItem.h"

#import "FJIndexMapItem.h"

#import "FJSpringBoardCellUpdate.h"


NSMutableArray* indexArrayOfSize(NSUInteger size){
    
    NSMutableArray* a = [NSMutableArray arrayWithCapacity:size];
    
    for (int i = 0; i < size; i++) {
        
        FJIndexMapItem* item = [[FJIndexMapItem alloc] init];
        item.mappedIndex = i;
        
        [a addObject:item];
        
        [item release];
    }
    
    return a;
    
}

@interface FJSpringBoardActionIndexMap()

@property (nonatomic, retain) NSMutableArray *oldToNew;
@property (nonatomic, retain) NSMutableArray *newToOld;

@end

@implementation FJSpringBoardActionIndexMap

@synthesize oldToNew;
@synthesize newToOld;



- (void)dealloc {
    [oldToNew release];
    oldToNew = nil;
    [newToOld release];
    newToOld = nil;
    [super dealloc];
}

- (id)initWithCellCount:(NSUInteger)count{
    
    self = [super init];
    if (self) {
        
        NSMutableArray* map = indexArrayOfSize(count);
        NSMutableArray* map2 = indexArrayOfSize(count); 
        self.oldToNew = map;
        self.newToOld = map2;
                     
    }
    
    return self;

}

- (NSUInteger)oldCount{
    
    return [self.oldToNew count];
    
}

- (NSUInteger)newCount{
    
    return [self.newToOld count];
    
}

- (NSUInteger)mapNewIndexToOldIndex:(NSUInteger)newIndex{
    
    FJIndexMapItem* newNum = [self.newToOld objectAtIndex:newIndex];
    
    return [newNum mappedIndex];
    
    
}
- (NSUInteger)mapOldIndexToNewIndex:(NSUInteger)oldIndex{
    
    FJIndexMapItem* newNum = [self.oldToNew objectAtIndex:oldIndex];
    
    return [newNum mappedIndex];
}


- (void)rightShiftOldToNewIndexesInAffectedRange:(NSRange)rangeOfItemesInNewArray{
    
   // [self shiftOldToNewIndexesInAffectedRange:rangeOfItemesInNewArray by:1]
    
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:rangeOfItemesInNewArray];
    
    //storage for the mapped Indexes
    NSMutableIndexSet* oldAffectedIndexes = [NSMutableIndexSet indexSet];
    
    //map the indexes
    [affectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger oldIndex = [self mapNewIndexToOldIndex:idx];
        
        if(oldIndex == NSNotFound) //newly inserted index, skipping
            return;
        
        [oldAffectedIndexes addIndex:oldIndex];
        
    }];       
    
    //ASSERT_TRUE([oldAffectedIndexes count] == [affectedIndexes count]); //sanity check: no longer valid since we are letting inserted indexes into the map
    
    debugLog(@"all affected indexes (old): %@", oldAffectedIndexes);
    
    //add 1 to each
    [self.oldToNew enumerateObjectsAtIndexes:oldAffectedIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJIndexMapItem* item = obj;
        item.mappedIndex += 1;
        
    }];
;
    
}
- (void)leftShiftOldToNewIndexesInAffectedRange:(NSRange)rangeOfItemesInNewArray{
    
   // [self shiftOldToNewIndexesInAffectedRange:rangeOfItemesInNewArray by:-1]
    
    NSIndexSet* oldAffectedIndexes = [NSIndexSet indexSetWithIndexesInRange:rangeOfItemesInNewArray];
    
    //ASSERT_TRUE([oldAffectedIndexes count] == [affectedIndexes count]); //sanity check: no longer valid since we are letting inserted indexes into the map
    
    debugLog(@"all affected indexes (old): %@", oldAffectedIndexes);

    //sub 1 to each
    [self.oldToNew enumerateObjectsAtIndexes:oldAffectedIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJIndexMapItem* item = obj;
        item.mappedIndex -= 1;
        
    }];
    
    
}

- (void)updateMapByInsertItemAtIndex:(NSUInteger)index{
    
    FJIndexMapItem* item = [[FJIndexMapItem alloc] init];
    item.mappedIndex = NSNotFound;
    [self.newToOld insertObject:item atIndex:index];
    [item release];
    
}

- (void)updateMapByDeletingItemsAtIndexes:(NSIndexSet*)indexes{
    
    [self.newToOld removeObjectsAtIndexes:indexes];
        
    [self.oldToNew enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJIndexMapItem* item = obj;
        item.mappedIndex = NSNotFound;

        
    }];
}

@end
