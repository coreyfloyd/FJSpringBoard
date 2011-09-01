//
//  FJSpringBoardActionIndexMap.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardActionIndexMap.h"
#import "FJSpringBoardAction.h"
#import "FJSpringBoardCellAction.h"

NSMutableArray* indexArrayOfSize(NSUInteger size){
    
    NSMutableArray* a = [NSMutableArray arrayWithCapacity:size];
    
    for (int i = 0; i < size; i++) {
        
        [a addObject:[NSNumber numberWithInt:i]];
    }
    
    return a;
    
}

@interface FJSpringBoardActionIndexMap()

@property (nonatomic, retain) NSMutableArray *oldToNew;
@property (nonatomic, retain) NSMutableArray *newToOld;
@property (nonatomic) NSRange actionableIndexRange;
@property (nonatomic, copy) NSArray *springBoardActions;
@property (nonatomic, retain) NSMutableSet *cellActions;


- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex;
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex;

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
        NSMutableArray* map2 = [[map mutableCopy] autorelease]; 
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

- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex{
    
    NSNumber* newNum = [self.oldToNew objectAtIndex:oldIndex];
    
    return [newNum unsignedIntegerValue];
    
    
}
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex{
    
    NSNumber* newNum = [self.newToOld objectAtIndex:newIndex];
    
    return [newNum unsignedIntegerValue];
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

- (void)shiftExistinCellActionsInAffectedRange:(NSRange)affectedRange{
    
    //only cells whose new positions will be in the actionable range need to have actions, lets figure that out
    //lets get the intersection, this should be only be the indexes that "end up" on screen
    NSRange rangeThatRequiresActions = NSIntersectionRange(actionableIndexRange, affectedRange);
    
    NSIndexSet* indexesThatRequireAction = [NSIndexSet indexSetWithIndexesInRange:rangeThatRequiresActions];
    
    //lets update the cell actions of the cells we are shuffling
    [self.newToOld enumerateObjectsAtIndexes:indexesThatRequireAction options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        NSUInteger oldIndex = [val unsignedIntegerValue];
        
        FJSpringBoardCellAction* affectedCell = [self actionForNewIndex:idx];
        
        if(!affectedCell){
            
            affectedCell = [[FJSpringBoardCellAction alloc] init];
            affectedCell.oldSpringBoardIndex = oldIndex;
            [self.cellActions addObject:affectedCell];
            [affectedCell autorelease];
            
        }
        
        affectedCell.newSpringBoardIndex = idx;
        
    }];

}



- (void)applyMoveAction:(FJSpringBoardAction*)move{
    
    //update new to old map: medium easy, remove and insert
    NSNumber* obj = [[self.newToOld objectAtIndex:move.index] retain];
    [self.newToOld removeObjectAtIndex:move.index];
    [self.newToOld insertObject:obj atIndex:move.newIndex];
    
    //update old to new map: medium easy, do the opposite of above. Some sort of mathematical phenomenon er something
    obj = [[self.oldToNew objectAtIndex:move.newIndex] retain];
    [self.newToOld removeObjectAtIndex:move.newIndex];
    [self.newToOld insertObject:obj atIndex:move.index];

    
    //lets get the affected range in the new array
    NSUInteger startIndex = NSNotFound;
    NSUInteger lastIndex = NSNotFound;
    
    //moving forward
    if(move.newIndex > move.index){
        
        startIndex = move.index;
        lastIndex = move.newIndex;
        
    //backwards    
    }else{
        
        startIndex = move.newIndex;
        lastIndex = move.index;
        
    }

    NSRange affectedRange = rangeWithFirstAndLastIndexes(startIndex, lastIndex);
    
    //now lets take care of the affected cell actions
    [self shiftExistinCellActionsInAffectedRange:affectedRange];
    
}

- (void)applyReloadAction:(FJSpringBoardAction*)reload{

    FJSpringBoardCellAction* affectedCell = [self actionForNewIndex:reload.index];    
    
    if(!affectedCell){
        
        affectedCell = [[[FJSpringBoardCellAction alloc] init] autorelease];
        affectedCell.oldSpringBoardIndex = reload.index;
        affectedCell.newSpringBoardIndex = reload.index;
        [self.cellActions addObject:affectedCell];
        
    }
    
    [affectedCell markNeedsLoaded];
    affectedCell.animation = reload.animation;

}


- (void)applyDeletionAction:(FJSpringBoardAction*)deletion{
        
    //update new to old map: easy, remove the object from the new array
    [self.newToOld removeObjectAtIndex:deletion.index];
    
    //update old to new map: hardish, need to find all affected indexes and decrease by 1
    
    //NSUInteger length = [self.oldToNew lastIndex]-insertion.index + 1;//could use count, but this more readable
    //NSRange affectedRange = NSMakeRange(insertion.index, length);
    
    //lets get the affected range in the new array
    NSUInteger lastIndex = [self.newToOld lastIndex];
    NSRange affectedRange = rangeWithFirstAndLastIndexes(deletion.index, lastIndex);
    
    //make an index set
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange];
    
    //lets map these to the old indexes
    NSMutableIndexSet* oldAffectedIndexes = [NSMutableIndexSet indexSet];
    
    [affectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger oldIndex = [self oldIndexForNewIndex:idx];
        [oldAffectedIndexes addIndex:oldIndex];
        
    }];
    
    ASSERT_TRUE([oldAffectedIndexes count] == [affectedIndexes count]); //sanity check
    
    
    //make a temporary home for the updated old index objects
    NSMutableArray* affectedObjects = [NSMutableArray array];
    
    
    //add 1 to each
    [self.oldToNew enumerateObjectsAtIndexes:oldAffectedIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        ASSERT_TRUE(idx > 0); //0 should never be touched, will break us (if idx 0 was removed in the new array, the lowest this idx should be is 1
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldIndex = [val unsignedIntegerValue];
        NSUInteger newIndex = oldIndex - 1; //action is to remove 1 to affected indexes
        
        val = [NSNumber numberWithUnsignedInteger:newIndex];
        
        [affectedObjects addObject:val];
        
    }];
    
    ASSERT_TRUE([oldAffectedIndexes count] == [affectedObjects count]); //sanity check
    
    //put updated mappings back into array
    [self.oldToNew replaceObjectsInRange:affectedRange withObjectsFromArray:affectedObjects];
    
    //lets update the deleted object to point to NSNotFound, no longer present in the new array
    [self.oldToNew replaceObjectAtIndex:deletion.index withObject:[NSNumber numberWithInt:NSNotFound]];
    
    //Maps are done!
    
    
    //now lets take care of the affected cell actions
    [self shiftExistinCellActionsInAffectedRange:affectedRange];

    //lets create the action for the deleted cell
    FJSpringBoardCellAction* deletedCell = [[[FJSpringBoardCellAction alloc] init] autorelease];
    deletedCell.animation = deletion.animation;
    deletedCell.oldSpringBoardIndex = deletion.index;
    deletedCell.newSpringBoardIndex = NSNotFound;
    
    //insert the action
    [self.cellActions addObject:deletedCell];    


    
}
- (void)applyInsertionAction:(FJSpringBoardAction*)insertion{
    
    //update new to old map: easy, the new object did not exist in the old array
    [self.newToOld insertObject:[NSNumber numberWithInt:NSNotFound] atIndex:insertion.index];
    
    //update old to new map: hardish, need to find all affected indexes and increase by 1
    
    //NSUInteger length = [self.oldToNew lastIndex]-insertion.index + 1;//could use count, but this more readable
    //NSRange affectedRange = NSMakeRange(insertion.index, length);
    
    //lets get the affected range in the new array
    NSUInteger lastIndex = [self.newToOld lastIndex];
    NSRange affectedRange = rangeWithFirstAndLastIndexes(insertion.index+1, lastIndex);
    
    //make an index set
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange];
    
    //lets map these to the old indexes
    NSMutableIndexSet* oldAffectedIndexes = [NSMutableIndexSet indexSet];
    
    [affectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger oldIndex = [self oldIndexForNewIndex:idx];
        [oldAffectedIndexes addIndex:oldIndex];
        
    }];
    
    ASSERT_TRUE([oldAffectedIndexes count] == [affectedIndexes count]); //sanity check

    
    //make a temporary home for the updated old index objects
    NSMutableArray* affectedObjects = [NSMutableArray array];
    
    
    //add 1 to each
    [self.oldToNew enumerateObjectsAtIndexes:oldAffectedIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldIndex = [val unsignedIntegerValue];
        NSUInteger newIndex = oldIndex + 1; //action is to add 1 to affected indexes
        
        val = [NSNumber numberWithUnsignedInteger:newIndex];
        
        [affectedObjects addObject:val];
        
    }];
    
    ASSERT_TRUE([oldAffectedIndexes count] == [affectedObjects count]); //sanity check
    
    //put updated mappings back into array
    [self.oldToNew replaceObjectsInRange:affectedRange withObjectsFromArray:affectedObjects];
    

    //Maps are done!
    
      
    //now lets take care of the affected cell actions
    [self shiftExistinCellActionsInAffectedRange:affectedRange];
    
    //finally. lets create the action for the new cell
    FJSpringBoardCellAction* insertedCell = [[[FJSpringBoardCellAction alloc] init] autorelease];
    [insertedCell markNeedsLoaded];
    insertedCell.animation = insertion.animation;
    insertedCell.oldSpringBoardIndex = NSNotFound;
    insertedCell.newSpringBoardIndex = insertion.index;
    
    //insert the action
    [self.cellActions addObject:insertedCell];

    
}

- (void)purgeActionsOutsideOfActionableRange{
    
    /*
     if an index is inserted offscreen, it technically wouldn't need an action.
     However, if it is later bumped onscreen by another action, we would lose the information about the insertion.
     So we do want to purge actions outside of the affected range after we are done create actions.
     */
    
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


- (NSArray*)mappedCellActions{
    
    return [[self cellActions] mutableCopy];
    
}


@end
