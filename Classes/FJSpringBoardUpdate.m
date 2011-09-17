//
//  FJSpringBoardUpdate.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardUpdate.h"
#import "FJSpringBoardCellUpdate.h"
#import "FJSpringBoardActionGroup.h"
#import "FJSpringBoardAction.h"


@interface FJSpringBoardUpdate()

@property (nonatomic, retain) FJSpringBoardActionGroup *actionGroup;

@property (nonatomic) NSRange visibleIndexRange;

@property (nonatomic, copy) NSArray *reloadUpdates;
@property (nonatomic, copy) NSArray *deleteUpdates;
@property (nonatomic, copy) NSArray *insertUpdates;

@property (nonatomic, copy) NSArray *moveUpdates;

@property (nonatomic, copy) NSIndexSet *reloadIndexes;
@property (nonatomic, copy) NSIndexSet *deleteIndexes;
@property (nonatomic, copy) NSIndexSet *insertIndexes;

@property (nonatomic, retain, readwrite) NSMutableArray *newCellState;

- (void)createMovesWithDeletionIndexes;
- (void)createMovesWithInsertionIndexes;

@end

@implementation FJSpringBoardUpdate

@synthesize actionGroup;
@synthesize newCellCount;
@synthesize visibleIndexRange;
@synthesize reloadUpdates;
@synthesize deleteUpdates;
@synthesize insertUpdates;
@synthesize reloadIndexes;
@synthesize deleteIndexes;
@synthesize insertIndexes;
@synthesize moveUpdates;
@synthesize newCellState;



- (void)dealloc {
    [newCellState release];
    newCellState = nil;
    [moveUpdates release];
    moveUpdates = nil;
    [reloadIndexes release];
    reloadIndexes = nil;
    [deleteIndexes release];
    deleteIndexes = nil;
    [insertIndexes release];
    insertIndexes = nil;
    [reloadUpdates release];
    reloadUpdates = nil;
    [deleteUpdates release];
    deleteUpdates = nil;
    [insertUpdates release];
    insertUpdates = nil;
    [actionGroup release];
    actionGroup = nil;
    [super dealloc];
}

- (id)initWithCellCount:(NSUInteger)count visibleIndexRange:(NSRange)range actionGroup:(FJSpringBoardActionGroup*)anActionGroup{
    
    self = [super init];
    if (self) {
        
        self.actionGroup = anActionGroup;
        
        NSRange newRange = range;
        
        NSMutableIndexSet* idxSet = [NSMutableIndexSet indexSet];
        
        NSMutableArray* actions = [NSMutableArray array];
        
        [self.actionGroup.deleteActions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            
            FJSpringBoardAction* anAction = obj;
            
            [anAction.indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
                NSUInteger actualIndex = idx;
                
                //create and add cell action
                FJSpringBoardCellUpdate* deletedCell = [[FJSpringBoardCellUpdate alloc] init];
                deletedCell.type = FJSpringBoardCellupdateDelete;

                deletedCell.animation = anAction.animation;
                deletedCell.oldSpringBoardIndex = actualIndex;
                deletedCell.newSpringBoardIndex = NSNotFound;
                
                [idxSet addIndex:actualIndex];
                
                [actions addObject:deletedCell]; 
                [deletedCell release];
                
            }];
            
        }];
        
        
                
        //adjust vis range for deleted cells
        
        NSUInteger padding;
        NSUInteger finish;
        
        if(count > 0){
            padding = [idxSet count];
            finish = count - 1;        
            if(padding <=  count - 1 - NSMaxRange(newRange))
                finish = newRange.length + padding;
            
            newRange.length = finish;
        }
     
        self.deleteIndexes = idxSet;
        self.deleteUpdates = [actions sortedArrayUsingSelector:@selector(compare:)];

        idxSet = [NSMutableIndexSet indexSet];
        actions = [NSMutableArray array];

                
        [self.actionGroup.insertActions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            
            FJSpringBoardAction* anAction = obj;
            
            [idxSet addIndexes:anAction.indexes];
            
            [anAction.indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
                //shift by deleted cells
                NSUInteger toShift = [self.deleteIndexes countOfIndexesInRange:NSMakeRange(0, idx)];                
                NSUInteger actualIndex = idx - toShift;
                
                //create and add cell action
                FJSpringBoardCellUpdate* insertedCell = [[FJSpringBoardCellUpdate alloc] init];
                insertedCell.type = FJSpringBoardCellupdateInsert;
                insertedCell.animation = anAction.animation;
                insertedCell.oldSpringBoardIndex = NSNotFound;
                insertedCell.newSpringBoardIndex = actualIndex;
                
                //add the action
                [actions addObject:insertedCell];
                [insertedCell release];
                
                    
            }];

            
        }];
        

        //adjust vis range for inserted cells
        
        if(count > 0){
            
            padding = [idxSet count];
            
            NSUInteger start = 0;
            if(padding <= newRange.location)
                start = newRange.location - padding;
            newRange.location  = start;
            
            finish = count - 1;
            if(padding <=  count - 1 - NSMaxRange(newRange))
                finish = newRange.length + padding;
            
            newRange.length = finish;   
        }
        
        
        self.visibleIndexRange = newRange;


        self.insertIndexes = idxSet;
        self.insertUpdates = [actions sortedArrayUsingSelector:@selector(compare:)];;

        
        actions = [NSMutableArray array];
        idxSet = [NSMutableIndexSet indexSet];

        
        [self.actionGroup.reloadActions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            
            FJSpringBoardAction* anAction = obj;
            [idxSet addIndexes:anAction.indexes];
            
            [anAction.indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
                if([self.deleteIndexes containsIndex:idx]) //trying to refresh a deleted cell, skipping!!
                    return; 
                
                
                FJSpringBoardCellUpdate* affectedCell = [[[FJSpringBoardCellUpdate alloc] init] autorelease];
                affectedCell.type = FJSpringBoardCellupdateReload;

                affectedCell.oldSpringBoardIndex = idx;
                
                NSUInteger actualIndex = 0;
                NSUInteger toShift = [self.deleteIndexes countOfIndexesInRange:NSMakeRange(0, idx)];
                actualIndex = idx - toShift;
                
                toShift = [self.insertIndexes countOfIndexesInRange:NSMakeRange(0, idx)];
                actualIndex += toShift;
                
                affectedCell.newSpringBoardIndex = actualIndex;

                [actions addObject:affectedCell];
                
                affectedCell.animation = anAction.animation;
            }];
            
            
        }];
        
        self.reloadIndexes = idxSet;        
        self.reloadUpdates = [actions sortedArrayUsingSelector:@selector(compare:)];;
    
        
        self.newCellState = [[self.cellStatePriorToAction mutableCopy] autorelease];
        self.newCellCount = [self.cellStatePriorToAction count];
              
        [self createMovesWithDeletionIndexes];
                
        [self.newCellState removeObjectsAtIndexes:self.deleteIndexes];
        self.newCellCount -= [self.deleteIndexes count];

        
        [self createMovesWithInsertionIndexes];
        
        [self.newCellState insertObjects:nullArrayOfSize([self.insertIndexes count]) atIndexes:self.insertIndexes];
        self.newCellCount += [self.insertIndexes count];

    }
    
    return self;
    
}


- (FJSpringBoardCellUpdate*)findActionWithOldIndex:(NSUInteger)index inArray:(NSArray*)actions{
    
    FJSpringBoardCellUpdate* action = [actions objectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellUpdate* act = obj;
        if(act.oldSpringBoardIndex == index){
            
            *stop = YES;
            return YES;
        }
        
        return NO;
    }];
    
    return action;
    
}

- (FJSpringBoardCellUpdate*)findActionWithNewIndex:(NSUInteger)index inArray:(NSArray*)actions{
    
    FJSpringBoardCellUpdate* action = [actions objectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardCellUpdate* act = obj;
        if(act.newSpringBoardIndex == index){
            
            *stop = YES;
            return YES;
        }
        
        return NO;
    }];
    
    return action;
    
}


- (void)createMovesWithDeletionIndexes{
        
    NSMutableArray* moves = [NSMutableArray array];
    
    NSUInteger lastIndex = [self.cellStatePriorToAction lastIndex];

    [self.deleteIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        //lets get the affected range (old indexes)                
        NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(idx+1, lastIndex);
        
        //now lets shift the affected cells (this uses the new to old map)
        extendedDebugLog(@"range to shift: %i - %i", affectedRange.location, NSMaxRange(affectedRange));
        
        affectedRangeThatNeedShifted = NSIntersectionRange(self.visibleIndexRange, affectedRangeThatNeedShifted);
        
        NSIndexSet* indexesThatRequireAction = [NSIndexSet indexSetWithIndexesInRange:affectedRangeThatNeedShifted];
        
        extendedDebugLog(@"visible range to shift: %i - %i", affectedRangeThatNeedShifted.location, NSMaxRange(affectedRangeThatNeedShifted));
                
        //lets update the cell actions of the cells we are shuffling
        [indexesThatRequireAction enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            
            FJSpringBoardCellUpdate* affectedCell = [self findActionWithOldIndex:idx inArray:moves];
            //NSUInteger newIndex = [self.indexMap mapOldIndexToNewIndex:idx];
            
            if(!affectedCell){
                
                affectedCell = [[FJSpringBoardCellUpdate alloc] init];
                affectedCell.type = FJSpringBoardCellupdateMove;
                affectedCell.oldSpringBoardIndex = idx;
                affectedCell.newSpringBoardIndex = idx;
                [moves addObject:affectedCell];
                [affectedCell release];
                
            }
            affectedCell.newSpringBoardIndex -=1;
                        
        }];
        
    }];

    self.moveUpdates = [moves sortedArrayUsingSelector:@selector(compare:)];;

    extendedDebugLog(@"updates after all shifts: %@",[self.moveUpdatesFromDeletions description]);
    
}


- (void)createMovesWithInsertionIndexes{
    
    NSMutableArray* deleteMoves = [NSMutableArray arrayWithArray:self.moveUpdates];
    NSMutableArray* moves = [NSMutableArray array];
    
    NSUInteger lastIndex = [self.cellStatePriorToAction lastIndex];
    
    [self.insertIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        //lets get the affected range (old indexes)                
        NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(idx, lastIndex);
        
        //now lets shift the affected cells (this uses the new to old map)
        extendedDebugLog(@"range to shift: %i - %i", affectedRange.location, NSMaxRange(affectedRange));
        
        affectedRangeThatNeedShifted = NSIntersectionRange(self.visibleIndexRange, affectedRangeThatNeedShifted);
        
        NSIndexSet* indexesThatRequireAction = [NSIndexSet indexSetWithIndexesInRange:affectedRangeThatNeedShifted];
        
        extendedDebugLog(@"visible range to shift: %i - %i", affectedRangeThatNeedShifted.location, NSMaxRange(affectedRangeThatNeedShifted));
        
        //lets update the cell actions of the cells we are shuffling
        [indexesThatRequireAction enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            
            //first lets look in previous moves from deletions
            FJSpringBoardCellUpdate* affectedCell = [self findActionWithNewIndex:idx inArray:deleteMoves];
            [[affectedCell retain] autorelease];
            [deleteMoves removeObject:affectedCell];
            //NSUInteger newIndex = [self.indexMap mapOldIndexToNewIndex:idx];
            
            //if we can't find it lets look in our new moves
            if(!affectedCell){
                
                FJSpringBoardCellUpdate* affectedCell = [self findActionWithOldIndex:idx inArray:moves];
                //NSUInteger newIndex = [self.indexMap mapOldIndexToNewIndex:idx];
                
                if(!affectedCell){
                    
                    affectedCell = [[FJSpringBoardCellUpdate alloc] init];
                    affectedCell.type = FJSpringBoardCellupdateMove;
                    affectedCell.oldSpringBoardIndex = idx;
                    affectedCell.newSpringBoardIndex = idx;
                    [moves addObject:affectedCell];
                    [affectedCell release];
                    
                }
                
            }
            
            affectedCell.newSpringBoardIndex +=1;

        }];
        
    }];
    
    [moves addObjectsFromArray:deleteMoves];
    
    self.moveUpdates = [moves sortedArrayUsingSelector:@selector(compare:)];;
    
    extendedDebugLog(@"updates after all shifts: %@",[self.moveUpdatesFromInsertions description]);

    
    
}


- (NSArray*)cellStatePriorToAction{
    
    return [[self actionGroup] cellStateBeforeAction];
}


@end
