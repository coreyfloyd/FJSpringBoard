//
//  FJSpringBoardActionIndexMap.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"
#import "FJSpringBoardUpdate.h"

/*
 FJSpringBoardActionIndexMap is used by FJSpringBoardUpdate to compute a map from the cell indexes before and after a FJSpringBoardAction. 
*/


@class FJSpringBoardAction;

@interface FJSpringBoardActionIndexMap : SMModelObject{
    
    NSMutableArray* oldToNew;
    NSMutableArray* newToOld;
        
}

- (id)initWithCellCount:(NSUInteger)count;


//these update the new to old maps, which is pretty easy
- (void)updateMapByInsertItemAtIndex:(NSUInteger)index;
- (void)updateMapByDeletingItemsAtIndexes:(NSIndexSet*)indexes;

//these are used to update the old to new maps, which requires a bit "pre-calculation" on your part
- (void)rightShiftOldToNewIndexesInAffectedRange:(NSRange)rangeOfItemesInNewArray; //range is in new indexes
- (void)leftShiftOldToNewIndexesInAffectedRange:(NSRange)rangeOfItemesInNewArray; //range is in old indexes

- (NSUInteger)mapNewIndexToOldIndex:(NSUInteger)newIndex;
- (NSUInteger)mapOldIndexToNewIndex:(NSUInteger)oldIndex;

- (NSUInteger)oldCount;
- (NSUInteger)newCount;


@end
