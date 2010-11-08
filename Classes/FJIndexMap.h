//
//  FJIndexMap.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 11/5/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FJReorderingIndexMap : NSObject {

    NSMutableArray* mapNewToOld;
    NSMutableArray* mapOldToNew;
    
    NSArray* cellsWithoutCurrentChangesApplied;
    NSMutableArray* cells;
    
    NSUInteger originalReorderingIndex;
    NSUInteger currentReorderingIndex;
    
}
@property(nonatomic, retain) NSMutableArray *mapNewToOld;
@property(nonatomic, retain) NSMutableArray *mapOldToNew;

@property(nonatomic, retain) NSArray *cellsWithoutCurrentChangesApplied;
@property(nonatomic, retain) NSMutableArray *cells;

@property(nonatomic, readonly) NSUInteger originalReorderingIndex;
@property(nonatomic, readonly) NSUInteger currentReorderingIndex;

- (id)initWithArray:(NSMutableArray*)anArray;

- (void)beginReorderingIndex:(NSUInteger)index;

- (NSIndexSet*)modifiedIndexesByMovingReorderingObjectToIndex:(NSUInteger)index;

- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex;
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex;

- (void)commitReorder; 

@end

