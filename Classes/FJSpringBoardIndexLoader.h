//
//  FJSpringBoardIndexLoader.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardView.h"
#import "SMModelObject.h"

@class FJSpringBoardLayout;
@class FJSpringBoardGroupCell;
@class FJSpringBoardIndexLoader;
@class FJSpringBoardUpdate;

@interface FJSpringBoardIndexLoader : SMModelObject {

    FJSpringBoardLayout *layout;
    
    CGPoint contentOffset;
    
    NSMutableIndexSet *mutableAllIndexes;
    NSMutableIndexSet* mutableIndexesToLoad;
    NSMutableIndexSet* mutableIndexesToUnload;
    
    NSIndexSet *visibleIndexes; //visible means should be loaded due to layout not neccesarily in the view port.
    NSMutableArray* cells;


    NSMutableArray* actionQueue;
        
}
- (id)initWithCount:(NSUInteger)count;

- (NSIndexSet*)allIndexes;

@property (nonatomic, retain) FJSpringBoardLayout *layout;

//The methods below are used to process index changes due to movement.  
- (void)updateIndexesWithContentOffest:(CGPoint)newOffset;
@property(nonatomic, readonly) CGPoint contentOffset;


//mark any indexes for updating
- (void)markIndexesForLoading:(NSIndexSet*)indexes; 
- (void)markIndexesForUnloading:(NSIndexSet*)indexes;

//get indexes that need updating
//any changes that need to be processed by the springboard will be added to the index sets below
//These changes are not expected to be animated. For animations you must use an animation action.
- (NSIndexSet*)indexesToLoad; //need loaded from datasource
- (NSIndexSet*)indexesToUnload; //need to be removed from spreingboard

//mark as updated when processed
- (void)clearIndexesToLoad; 
- (void)clearIndexesToUnload;

//This should be equal to the actual indexes on screen!!
//updated as the indexes are cleared above
- (NSIndexSet*)loadedIndexes;


- (void)queueActionByReloadingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation;
- (void)queueActionByMovingCellAtIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex withAnimation:(FJSpringBoardCellAnimation)animation;
- (void)queueActionByInsertingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation;
- (void)queueActionByDeletingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation;


- (FJSpringBoardUpdate*)processActionQueueAndGetUpdate;

- (void)clearActionQueueAndUpdateCellCount:(NSUInteger)count;








@end
