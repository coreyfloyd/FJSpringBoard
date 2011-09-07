//
//  FJSpringBoardUpdate.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardUpdate.h"
#import "FJSpringBoardCellUpdate.h"
#import "FJSpringBoardActionIndexMap.h"
#import "FJSpringBoardActionItem.h"

@interface FJSpringBoardUpdate()

@property (nonatomic, retain) FJSpringBoardActionIndexMap *indexMap;

@property (nonatomic, retain) FJSpringBoardAction *action;

@property (nonatomic, retain) NSMutableSet *cellActionUpdates; 
@property (nonatomic, retain) NSMutableSet *cellMovementUpdates; 


- (void)_applyActionsAndCalculateUpdate;
- (void)leftShiftCellMovementUpdatesInAffectedRange:(NSRange)affectedRange;
- (void)rightShiftCellMovementUpdatesInAffectedRange:(NSRange)affectedRange;

- (void)applyReloadAction:(FJSpringBoardAction*)reload;
- (void)applyDeletionAction:(FJSpringBoardAction*)deletion;
- (void)applyInsertionAction:(FJSpringBoardAction*)insertion;

- (void)addCellMovementUpdate:(id)aCellMovementUpdate;
- (void)removeCellMovementUpdate:(id)aCellMovementUpdate;
- (void)addCellActionUpdate:(id)aCellActionUpdate;
- (void)removeCellActionUpdate:(id)aCellActionUpdate;

@end

@implementation FJSpringBoardUpdate

@synthesize action;
@synthesize indexMap;
@synthesize newCellCount;
@synthesize cellActionUpdates;
@synthesize cellMovementUpdates;


- (void)dealloc {
    [action release];
    action = nil;
    [cellActionUpdates release];
    cellActionUpdates = nil;
    [cellMovementUpdates release];
    cellMovementUpdates = nil;
    [indexMap release];
    indexMap = nil;
    [super dealloc];
}

- (id)initWithCellCount:(NSUInteger)count springBoardAction:(FJSpringBoardAction*)anAction{
    
    self = [super init];
    if (self) {
        
        FJSpringBoardActionIndexMap* map = [[FJSpringBoardActionIndexMap alloc] initWithCellCount:count];
        self.indexMap = map;
        [map release];
        
        self.action = anAction;
        
        self.cellActionUpdates = [NSMutableSet set];
        self.cellMovementUpdates = [NSMutableSet set];
        
        [self _applyActionsAndCalculateUpdate];

    }
    
    return self;
    
}

- (NSArray*)sortedCellActionUpdates{
    
    NSArray* u = [[self cellActionUpdates] allObjects];
    u = [u sortedArrayUsingSelector:@selector(compare:)];    
    return u;
}

- (NSArray*)sortedCellMovementUpdates{
    
    NSArray* u = [[self cellMovementUpdates] allObjects];
    u = [u sortedArrayUsingSelector:@selector(compare:)];  
    return u;
}

- (FJSpringBoardActionType)actionType{
    
    return [self action].type;
}

- (void)_applyActionsAndCalculateUpdate{
    
    FJSpringBoardActionType type = action.type;
    
    switch (type) {
        case FJSpringBoardActionInsert:
            [self applyInsertionAction:action];
            break;
        case FJSpringBoardActionDelete:
            [self applyDeletionAction:action];
            break; 
        case FJSpringBoardActionReload:
            [self applyReloadAction:action];
            break;     
        default:
            ALWAYS_ASSERT;
            break;
    }
     
    ASSERT_TRUE(self.newCellCount == [self.indexMap newCount]);
    
}


- (void)addCellActionUpdate:(id)aCellActionUpdate
{
    [[self cellActionUpdates] addObject:aCellActionUpdate];
}
- (void)removeCellActionUpdate:(id)aCellActionUpdate
{
    [[self cellActionUpdates] removeObject:aCellActionUpdate];
}
- (void)addCellMovementUpdate:(id)aCellMovementUpdate
{
    [[self cellMovementUpdates] addObject:aCellMovementUpdate];
}
- (void)removeCellMovementUpdate:(id)aCellMovementUpdate
{
    [[self cellMovementUpdates] removeObject:aCellMovementUpdate];
}



- (FJSpringBoardCellUpdate*)actionForNewIndex:(NSUInteger)index{
    
    NSSet* objs = [self.cellMovementUpdates objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        
        FJSpringBoardCellUpdate* act = obj;
        if(act.newSpringBoardIndex == index){
            
            *stop = YES;
            return YES;
        }
        
        return NO;
        
    }];
    
    ASSERT_TRUE([objs count] < 2);
    
    return [objs anyObject];
    
}

- (FJSpringBoardCellUpdate*)actionForOldIndex:(NSUInteger)index{
    
    NSSet* objs = [self.cellMovementUpdates objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        
        FJSpringBoardCellUpdate* act = obj;
        if(act.oldSpringBoardIndex == index){
            
            *stop = YES;
            return YES;
        }
        
        return NO;
        
    }];
    
    ASSERT_TRUE([objs count] < 2);
    
    return [objs anyObject];
    
}


- (void)rightShiftCellMovementUpdatesInAffectedRange:(NSRange)affectedRange{
    
    //[self shiftCellMovementUpdatesInAffectedRange:affectedRange by:1];
    
    debugLog(@"range to shift: %i - %i", affectedRange.location, NSMaxRange(affectedRange));
    
    NSIndexSet* indexesThatRequireAction = [NSIndexSet indexSetWithIndexesInRange:affectedRange];
    
    NSMutableSet* affectedUpdates = [NSMutableSet set];    
    //lets update the cell actions of the cells we are shuffling
    [indexesThatRequireAction enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
        FJSpringBoardCellUpdate* affectedCell = [self actionForNewIndex:idx];
        NSUInteger oldIndex = [self.indexMap mapNewIndexToOldIndex:idx];
        
        if(oldIndex == NSNotFound) //cell that was inserted, ignore
            return;
        
        if(!affectedCell){
            
            affectedCell = [[FJSpringBoardCellUpdate alloc] init];
            affectedCell.oldSpringBoardIndex = oldIndex;
            affectedCell.newSpringBoardIndex = oldIndex;
            [self.cellMovementUpdates addObject:affectedCell];
            [affectedCell autorelease];
            
        }
        
        [affectedUpdates addObject:affectedCell];
        
    }];
    
    [affectedUpdates enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardCellUpdate* affectedCell = obj;
                
        affectedCell.newSpringBoardIndex += 1;
        
        
    }];
    
    debugLog(@"updates after shift: %@",[affectedUpdates description]);

}

- (void)leftShiftCellMovementUpdatesInAffectedRange:(NSRange)affectedRange{
    
    //[self shiftCellMovementUpdatesInAffectedRange:affectedRange by:-1];
    
    debugLog(@"range to shift: %i - %i", affectedRange.location, NSMaxRange(affectedRange));
    
    NSIndexSet* indexesThatRequireAction = [NSIndexSet indexSetWithIndexesInRange:affectedRange];
    
    NSMutableSet* affectedUpdates = [NSMutableSet set];    
    //lets update the cell actions of the cells we are shuffling
    [indexesThatRequireAction enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
        FJSpringBoardCellUpdate* affectedCell = [self actionForOldIndex:idx];
        //NSUInteger newIndex = [self.indexMap mapOldIndexToNewIndex:idx];
        
        if(!affectedCell){
            
            affectedCell = [[FJSpringBoardCellUpdate alloc] init];
            affectedCell.oldSpringBoardIndex = idx;
            affectedCell.newSpringBoardIndex = idx;
            [self.cellMovementUpdates addObject:affectedCell];
            [affectedCell autorelease];
            
        }
        
        [affectedUpdates addObject:affectedCell];
        
    }];
    
    [affectedUpdates enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardCellUpdate* affectedCell = obj;
                
        affectedCell.newSpringBoardIndex -= 1;
        
        
    }];

    debugLog(@"updates after shift: %@",[affectedUpdates description]);

}


- (void)applyReloadAction:(FJSpringBoardAction*)reload{
    
    [reload.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        FJSpringBoardCellUpdate* affectedCell = [self actionForNewIndex:item.index];    
        
        if(!affectedCell){
            
            affectedCell = [[[FJSpringBoardCellUpdate alloc] init] autorelease];
            affectedCell.oldSpringBoardIndex = item.index;
            [self.cellActionUpdates addObject:affectedCell];
            
        }
        
        [affectedCell markNeedsLoaded];
        affectedCell.newSpringBoardIndex = item.index;
        affectedCell.animation = reload.animation;
        
    }];
    
}


- (void)applyDeletionAction:(FJSpringBoardAction*)deletion{
    
    self.newCellCount = [self.indexMap oldCount] - [deletion actionItems].count;
    
    debugLog(@"applying deletion action %@", [deletion description]);
    
    //hold indexes for fast lookup later
    NSMutableIndexSet* deletionIndexes = [NSMutableIndexSet indexSet];
    
    [deletion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        NSUInteger actualIndex = item.index;
        
        //add index
        [deletionIndexes addIndex:actualIndex];
        
        //create and add cell action
        FJSpringBoardCellUpdate* deletedCell = [[FJSpringBoardCellUpdate alloc] init];
        deletedCell.animation = deletion.animation;
        deletedCell.oldSpringBoardIndex = actualIndex;
        deletedCell.newSpringBoardIndex = NSNotFound;
        
        [self.cellActionUpdates addObject:deletedCell];
        [deletedCell release];
                        

    }];
    
    //now we need to update the new to old map
    [self.indexMap updateMapByDeletingItemsAtIndexes:deletionIndexes];  
    

    [deletion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        NSUInteger actualIndex = item.index;
        
        //lets get the affected range (old indexes)                
        NSUInteger lastIndex = [self.indexMap oldCount]-1;
        NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(actualIndex+1, lastIndex);
        
        //update the old to new map 
        [self.indexMap leftShiftOldToNewIndexesInAffectedRange:affectedRangeThatNeedShifted];
        
        //now lets shift the affected cells (this uses the new to old map)
        [self leftShiftCellMovementUpdatesInAffectedRange:affectedRangeThatNeedShifted];
        
        
        
        
    }];
    //get rid of any movements associated with cells that are being deleted
    NSMutableSet* deletedCellsThatAreBeingMoved = [NSMutableSet set];
    
    [self.cellMovementUpdates enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardCellUpdate* update = obj;
        
        if([deletionIndexes containsIndex:update.oldSpringBoardIndex]){
            
            [deletedCellsThatAreBeingMoved addObject:update];
            
        }
        
    }];
    
    [deletedCellsThatAreBeingMoved enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        [self.cellMovementUpdates removeObject:obj];
        
    }];
    
    
}

- (void)applyInsertionAction:(FJSpringBoardAction*)insertion{
    
    self.newCellCount = [self.indexMap oldCount] + [insertion actionItems].count;

    debugLog(@"applying insertion action %@", [insertion description]);
        
    
    [insertion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        NSUInteger actualIndex = item.index;
        
        //create and add cell action
        FJSpringBoardCellUpdate* insertedCell = [[FJSpringBoardCellUpdate alloc] init];
        [insertedCell markNeedsLoaded];
        insertedCell.animation = insertion.animation;
        insertedCell.oldSpringBoardIndex = NSNotFound;
        insertedCell.newSpringBoardIndex = actualIndex;
        
        //add the action
        [self.cellActionUpdates addObject:insertedCell];
        [insertedCell release];
        
        //lets get the affected range (new indexes)
        NSUInteger lastIndex = [self.indexMap newCount]-1; 
        NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(actualIndex, lastIndex);
                
        //now lets shift the affected cells (this uses the the new to old map)
        [self rightShiftCellMovementUpdatesInAffectedRange:affectedRangeThatNeedShifted];
        
        //now we need to update the new to old map
        [self.indexMap updateMapByInsertItemAtIndex:actualIndex];
         
        //update the old to new map 
        [self.indexMap rightShiftOldToNewIndexesInAffectedRange:affectedRangeThatNeedShifted];

               
    }];
        
}



@end
