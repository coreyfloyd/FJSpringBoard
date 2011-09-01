//
//  FJSpringBoardIndexLoader.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardUtilities.h"

@class FJSpringBoardLayout;
@class FJSpringBoardGroupCell;

@interface FJSpringBoardIndexLoader : NSObject {

    FJSpringBoardLayout *layout;
    
    CGPoint contentOffset;
    
    NSMutableIndexSet *mutableAllIndexes;
    NSMutableIndexSet* mutableIndexesToLoad;
    NSMutableIndexSet* mutableIndexesToLayout;
    NSMutableIndexSet* mutableIndexesToUnload;
        
    NSMutableArray* mapNewToOld;
    NSMutableArray* mapOldToNew;
    
    NSArray* cellsWithoutCurrentChangesApplied;
    NSMutableArray* cells;
    
    NSUInteger originalReorderingIndex;
    NSUInteger currentReorderingIndex;
    
    
    //allIndexes
    //visibleIndexes
    //paddedIndexes
    //loadedIndexes = vis + padded
    

}
- (id)initWithCount:(NSUInteger)count;

- (NSIndexSet*)allIndexes;

@property (nonatomic, retain) FJSpringBoardLayout *layout;

//The methods below are used to process index changes due to movement.  
- (void)updateIndexesWithContentOffest:(CGPoint)newOffset;
@property(nonatomic, readonly) CGPoint contentOffset;

//mark any indexes for updating
- (void)markIndexesForLoading:(NSIndexSet*)indexes; //also adds to Layout
- (void)markIndexesForLayout:(NSIndexSet*)indexes;
- (void)markIndexesForUnloading:(NSIndexSet*)indexes;

//get indexes that need updating
//any changes that need to be processed by the springboard will be added to the index sets below
//These changes are not expected to be animated. For animations you must use an animation action.
- (NSIndexSet*)indexesToLoad; //need loaded from datasource
- (NSIndexSet*)indexesToLayout; //need frames set and/or added to springboard
- (NSIndexSet*)indexesToUnload; //need to be removed from spreingboard

//mark as updated when processed
- (void)clearIndexesToLoad; 
- (void)clearIndexesToLayout;
- (void)clearIndexesToUnload;

//This should be equal to the actual indexes on screen!!
//updated as the indexes are cleared above
- (NSIndexSet*)loadedIndexes;





@property(nonatomic, retain) NSMutableArray *mapNewToOld;
@property(nonatomic, retain) NSMutableArray *mapOldToNew;

@property(nonatomic, retain) NSArray *cellsWithoutCurrentChangesApplied;
@property(nonatomic, retain) NSMutableArray *cells;

@property(nonatomic, readonly) NSUInteger originalReorderingIndex;
@property(nonatomic, readonly) NSUInteger currentReorderingIndex;


//map existing indexes back to the datasource
- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex;
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex;

//reordering
- (void)beginReorderingIndex:(NSUInteger)index;
- (NSIndexSet*)modifiedIndexesByMovingReorderingCellToCellAtIndex:(NSUInteger)index;

//remove cells
- (NSIndexSet*)modifiedIndexesByRemovingCellsAtIndexes:(NSIndexSet*)indexes;

//add cells
- (NSIndexSet*)modifiedIndexesByAddingCellsAtIndexes:(NSIndexSet*)indexes;


- (void)commitChanges; //resets maps








@end
