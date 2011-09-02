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

#import "FJSpringBoardCellAction.h"


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
@property (nonatomic) NSRange actionableIndexRange;
@property (nonatomic, copy) NSArray *springBoardActions;
@property (nonatomic, retain) NSMutableSet *cellActions;


- (NSUInteger)mapNewIndexToOldIndex:(NSUInteger)oldIndex;
- (NSUInteger)mapOldIndexToNewIndex:(NSUInteger)newIndex;

- (void)purgeActionsOutsideOfActionableRange;

- (void)applyMoveAction:(FJSpringBoardAction*)move;
- (void)applyReloadAction:(FJSpringBoardAction*)reload;
- (void)applyDeletionAction:(FJSpringBoardAction*)deletion;
- (void)applyInsertionAction:(FJSpringBoardAction*)insertion;

@end

@implementation FJSpringBoardActionIndexMap

@synthesize oldToNew;
@synthesize newToOld;
@synthesize cellActions;
@synthesize actionableIndexRange;
@synthesize springBoardActions;


- (void)dealloc {
    [springBoardActions release];
    springBoardActions = nil;
    [cellActions release];
    cellActions = nil;
    [oldToNew release];
    oldToNew = nil;
    [newToOld release];
    newToOld = nil;
    [super dealloc];
}

- (id)initWithCellCount:(NSUInteger)count actionableIndexRange:(NSRange)indexRange springBoardActions:(NSArray*)actions
{
    self = [super init];
    if (self) {
        
        NSMutableArray* map = indexArrayOfSize(count);
        NSMutableArray* map2 = indexArrayOfSize(count); 
        self.oldToNew = map;
        self.newToOld = map2;
        
        self.actionableIndexRange = indexRange;
        
        self.cellActions = [NSMutableSet set];
        
        self.springBoardActions = actions;
        
        [self.springBoardActions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            FJSpringBoardAction* action = obj;
            
            FJSpringBoardActionType type = action.action;
            
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
                case FJSpringBoardActionMove:
                    [self applyMoveAction:action];
                    break;
                default:
                    break;
            }
            
        }];
        
        [self purgeActionsOutsideOfActionableRange];
    }
    
    return self;
}

- (NSUInteger)mapNewIndexToOldIndex:(NSUInteger)newIndex{
    
    FJIndexMapItem* newNum = [self.newToOld objectAtIndex:newIndex];
    
    return [newNum mappedIndex];
    
    
}
- (NSUInteger)mapOldIndexToNewIndex:(NSUInteger)oldIndex{
    
    FJIndexMapItem* newNum = [self.oldToNew objectAtIndex:oldIndex];
    
    return [newNum mappedIndex];
}

- (void)addCellAction:(id)aCellAction
{
    [[self cellActions] addObject:aCellAction];
}
- (void)removeCellAction:(id)aCellAction
{
    [[self cellActions] removeObject:aCellAction];
}

- (NSArray*)cellActionsOrderedByNewIndex{
  
    NSSortDescriptor* s = [NSSortDescriptor sortDescriptorWithKey:@"newSpringBoardIndex" ascending:YES];

    NSArray* array = [[self cellActions] sortedArrayUsingDescriptors:[NSArray arrayWithObject:s]];
    NSMutableArray* mutableArray = [array mutableCopy];
    
    NSIndexSet* notFound = [mutableArray indexesOfObjectsWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellAction* act = obj;
        if(act.newSpringBoardIndex == NSNotFound){
            
            return YES;
            
        }
        
        *stop = YES;
        return NO;  
        
    }];
    
    [mutableArray removeObjectsAtIndexes:notFound];
     
    return [mutableArray autorelease];
    
}

- (NSArray*)cellActionsOrderedByOldIndexes{

    NSSortDescriptor* s = [NSSortDescriptor sortDescriptorWithKey:@"oldSpringBoardIndex" ascending:YES];
    
    NSArray* array = [[self cellActions] sortedArrayUsingDescriptors:[NSArray arrayWithObject:s]];
    NSMutableArray* mutableArray = [array mutableCopy];
    
    NSIndexSet* notFound = [mutableArray indexesOfObjectsWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellAction* act = obj;
        if(act.oldSpringBoardIndex == NSNotFound){
            
            return YES;
            
        }
        
        *stop = YES;
        return NO;  
        
    }];
    
    [mutableArray removeObjectsAtIndexes:notFound];
    
    return [mutableArray autorelease];

}

- (FJSpringBoardCellAction*)actionForNewIndex:(NSUInteger)index{
    
    NSSet* objs = [self.cellActions objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        
        FJSpringBoardCellAction* act = obj;
        if(act.newSpringBoardIndex == index){
            
            *stop = YES;
            return YES;
        }
        
        return NO;
        
    }];
    
    ASSERT_TRUE([objs count] < 2);
    
    return [objs anyObject];
    
}

- (FJSpringBoardCellAction*)actionForOldIndex:(NSUInteger)index{
    
    NSSet* objs = [self.cellActions objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        
        FJSpringBoardCellAction* act = obj;
        if(act.oldSpringBoardIndex == index){
            
            *stop = YES;
            return YES;
        }
        
        return NO;
        
    }];
    
    ASSERT_TRUE([objs count] < 2);
    
    return [objs anyObject];
    
}


- (void)shiftIndexesInAffectedRange:(NSRange)affectedRange by:(NSUInteger)num{
    
    debugLog(@"range to shift: %i - %i", affectedRange.location, NSMaxRange(affectedRange));
    
    NSIndexSet* indexesThatRequireAction = [NSIndexSet indexSetWithIndexesInRange:affectedRange];
    
    NSMutableArray* actions = [NSMutableArray arrayWithCapacity:[indexesThatRequireAction count]];
    
    //lets update the cell actions of the cells we are shuffling
    [self.newToOld enumerateObjectsAtIndexes:indexesThatRequireAction options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJIndexMapItem* item = obj;
        
        FJSpringBoardCellAction* affectedCell = [self actionForNewIndex:idx]; 
        //performance: we can sort and do this faster if needed
        
        if(!affectedCell){
            
            affectedCell = [[FJSpringBoardCellAction alloc] init];
            affectedCell.oldSpringBoardIndex = item.mappedIndex;
            affectedCell.newSpringBoardIndex = item.mappedIndex;
            [self.cellActions addObject:affectedCell];
            [affectedCell autorelease];
            
        }
        
        [actions addObject:affectedCell];
        
        
    }];
    
    
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellAction* affectedCell = obj;
        
        debugLog(@"action before shift: %@",[affectedCell description]);
        
        affectedCell.newSpringBoardIndex += num;
        
        debugLog(@"action after shift: %@",[affectedCell description]);
        
    }];
    
    
}

- (void)rightShiftIndexesInAffectedRange:(NSRange)affectedRange{
    
    [self shiftIndexesInAffectedRange:affectedRange by:1];
    
}

- (void)leftShiffIndexesInAffectedRange:(NSRange)affectedRange{
    
    [self shiftIndexesInAffectedRange:affectedRange by:-1];
    
}


- (void)updateOldToNewMapByShiftingItemsInNewRange:(NSRange)rangeOfItemesInNewArray by:(NSUInteger)num{
    
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:rangeOfItemesInNewArray];
    
    //storage for the mapped Indexes
    NSMutableIndexSet* oldAffectedIndexes = [NSMutableIndexSet indexSet];
    
    //map the indexes
    [affectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger oldIndex = [self mapNewIndexToOldIndex:idx];
        [oldAffectedIndexes addIndex:oldIndex];
        
    }];       
    
    ASSERT_TRUE([oldAffectedIndexes count] == [affectedIndexes count]); //sanity check
    
    debugLog(@"all affected indexes (old): %@", oldAffectedIndexes);
    
    //add 1 to each
    [self.oldToNew enumerateObjectsAtIndexes:oldAffectedIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJIndexMapItem* item = obj;
        item.mappedIndex += num;
        
    }];
    
}

- (void)updateOldToNewMapByRightShiftingItemsInNewRange:(NSRange)rangeOfItemesInNewArray{
    
    [self updateOldToNewMapByShiftingItemsInNewRange:rangeOfItemesInNewArray by:1];
    
}
- (void)updateOldToNewMapByLeftShiftingItemsInNewRange:(NSRange)rangeOfItemesInNewArray{
    
    [self updateOldToNewMapByShiftingItemsInNewRange:rangeOfItemesInNewArray by:-1];
    
}


- (void)applyMoveAction:(FJSpringBoardAction*)move{
    
    ASSERT_TRUE([move.actionItems count] == 1);
    
    [move.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        FJSpringBoardCellAction* affectedCell = [self actionForNewIndex:item.index];    
        
        if(!affectedCell){
            
            affectedCell = [[[FJSpringBoardCellAction alloc] init] autorelease];
            affectedCell.oldSpringBoardIndex = item.index;
            
        }
        
        [affectedCell markNeedsLoaded];
        affectedCell.newSpringBoardIndex = item.newIndex;
        affectedCell.animation = move.animation;
        
        [item updatedAffectedRangeWithIndexCount:[self.newToOld count]];
        
        [self leftShiffIndexesInAffectedRange:item.affectedRange];

        //update new to old map: medium easy, remove and insert
        FJIndexMapItem* mapItem = [[self.newToOld objectAtIndex:item.index] retain];
        [self.newToOld removeObjectAtIndex:item.index];
        [self.newToOld insertObject:mapItem atIndex:item.newIndex];
        
        //update old to new map: medium easy, do the opposite of above. Some sort of mathematical phenomenon er something
        mapItem = [[self.oldToNew objectAtIndex:item.newIndex] retain];
        [self.newToOld removeObjectAtIndex:item.newIndex];
        [self.newToOld insertObject:obj atIndex:item.index];
        
        [self addCellAction:affectedCell];
        
    }];

    
       
        
}

- (void)applyReloadAction:(FJSpringBoardAction*)reload{

    [reload.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        FJSpringBoardCellAction* affectedCell = [self actionForNewIndex:item.index];    
        
        if(!affectedCell){
            
            affectedCell = [[[FJSpringBoardCellAction alloc] init] autorelease];
            affectedCell.oldSpringBoardIndex = item.index;
            [self.cellActions addObject:affectedCell];
            
        }
        
        [affectedCell markNeedsLoaded];
        affectedCell.newSpringBoardIndex = item.index;
        affectedCell.animation = reload.animation;
        
    }];
    
  
}


- (void)applyDeletionAction:(FJSpringBoardAction*)deletion{
    
    debugLog(@"applying deletion action %@", [deletion description]);
    
    //hold indexes for fast lookup later
    NSMutableIndexSet* deletionIndexes = [NSMutableIndexSet indexSet];
    
    //tmep storage for actions, adding these before completing the mappings will mess up our calculations
    NSMutableSet* deletionCellActions = [NSMutableSet setWithCapacity:[deletion.actionItems count]];
    
    [deletion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        NSUInteger actualIndex = item.index;
        
        //add index
        [deletionIndexes addIndex:actualIndex];
        
        //create and add cell action
        FJSpringBoardCellAction* deletedCell = [[[FJSpringBoardCellAction alloc] init] autorelease];
        deletedCell.animation = deletion.animation;
        deletedCell.oldSpringBoardIndex = actualIndex;
        deletedCell.newSpringBoardIndex = NSNotFound;

        
        [deletionCellActions addObject:deletedCell];
        [deletedCell release];
        
        
        //lets get the affected range 
        [item updatedAffectedRangeWithIndexCount:[self.newToOld count]];
        
        //now lets take shift of the affected cells
        [self leftShiffIndexesInAffectedRange:item.affectedRange];
        
    }];
    
    
    
    //now we need to update the maps
    
    //update new to old map: easy, remove the objects from the new array
    [self.newToOld removeObjectsAtIndexes:deletionIndexes];

    
    //update old to new map: hardish, need to find all old affected indexes and decrease by 1
    [deletion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
                
        //get the affected indexes from the range we calculated earlier
        [self updateOldToNewMapByLeftShiftingItemsInNewRange:item.affectedRange];

        
    }];
    
    
    debugLog(@"map new to old: %@", [self.newToOld description]);
    debugLog(@"map old to new: %@", [self.oldToNew description]);
    
    //Maps are done!
    
    
    //finally. lets add the actions for the new cells
    [deletionCellActions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        [self addCellAction:obj];
        
    }];
    

}
- (void)applyInsertionAction:(FJSpringBoardAction*)insertion{
    
    debugLog(@"applying insertion action %@", [insertion description]);
    
    //hold indexes for fast lookup later
    NSMutableIndexSet* insertionIndexes = [NSMutableIndexSet indexSet];
    
    //tmep storage for actions, adding these before completing the mappings will mess up our calculations
    NSMutableSet* insertionCellActions = [NSMutableSet setWithCapacity:[insertion.actionItems count]];
        
    [insertion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
        
        NSUInteger actualIndex = item.index;
        
        //add index
        [insertionIndexes addIndex:actualIndex];
        
        //create and add cell action
        FJSpringBoardCellAction* insertedCell = [[FJSpringBoardCellAction alloc] init];
        [insertedCell markNeedsLoaded];
        insertedCell.animation = insertion.animation;
        insertedCell.oldSpringBoardIndex = NSNotFound;
        insertedCell.newSpringBoardIndex = actualIndex;
        
        [insertionCellActions addObject:insertedCell];
        [insertedCell release];

        
        //lets get the affected range 
        [item updatedAffectedRangeWithIndexCount:[self.newToOld count]];
        
        //now lets take shift of the affected cells
        [self rightShiftIndexesInAffectedRange:item.affectedRange];
        
    }];
    
    
    
    //now we need to update the maps
    
    //update new to old map: easy, the new object did not exist in the old array
    NSMutableArray* insertionObjectsForNewMap = [NSMutableArray arrayWithCapacity:[insertionIndexes count]];
    for (int i = 0; i<[insertionIndexes count]; i++) {
        
        FJIndexMapItem* item = [[FJIndexMapItem alloc] init];
        item.mappedIndex = NSNotFound;
        
        [insertionObjectsForNewMap addObject:item];
        
        [item release];
    }
        
    
    //update old to new map: hardish, need to find all old affected indexes and increase by 1
    [insertion.actionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = obj;
                        
        //get the affected indexes from the range we calculated earlier
        [self updateOldToNewMapByRightShiftingItemsInNewRange:item.affectedRange];

    }];
    
    [self.newToOld insertObjects:insertionObjectsForNewMap atIndexes:insertionIndexes];

    debugLog(@"map new to old: %@", [self.newToOld description]);
    debugLog(@"map old to new: %@", [self.oldToNew description]);
    
    //Maps are done!
    
    
    //finally. lets add the actions for the new cells
    [insertionCellActions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        [self addCellAction:obj];

    }];
        
        
}

- (void)purgeActionsOutsideOfActionableRange{
    
    /*
     if an index is inserted offscreen, it technically wouldn't need an action.
     However, if it is later bumped onscreen by another action, we would lose the information about the insertion.
     So we do want to purge actions outside of the affected range after we are done create actions.
     */
    
    debugLog(@"range in view: %i - %i", actionableIndexRange.location, NSMaxRange(actionableIndexRange));

    
    NSSet* actionsToRemove = [[self cellActions] objectsPassingTest:^BOOL(id obj, BOOL *stop) {
       
        FJSpringBoardCellAction* affectedCell = obj;
        
        if(!NSLocationInRange(affectedCell.newSpringBoardIndex, self.actionableIndexRange)){
            return YES;
        }
        
        return NO;
    }];
    
    [actionsToRemove enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        [self removeCellAction:obj];
 
    }];
    
}


- (NSSet*)mappedCellActions{
    
    return [[[self cellActions] copy] autorelease];
    
}


@end
