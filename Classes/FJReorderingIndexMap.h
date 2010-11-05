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
    
    NSArray* oldArray;
    NSMutableArray* newArray;
    
    NSUInteger originalReorderingIndex;
    NSUInteger currentReorderingIndex;
    
}
@property(nonatomic, retain) NSMutableArray *mapNewToOld;
@property(nonatomic, retain) NSMutableArray *mapOldToNew;


@property(nonatomic, retain) NSArray *oldArray;
@property(nonatomic, retain) NSMutableArray *newArray;

@property(nonatomic) NSUInteger originalReorderingIndex;
@property(nonatomic) NSUInteger currentReorderingIndex;

- (id)initWithOriginalArray:(NSArray*)original reorderingObjectIndex:(NSUInteger)index;

- (NSIndexSet*)modifiedIndexesBymovingReorderingObjectToIndex:(NSUInteger)index;

- (NSArray*)oldArray;
- (NSMutableArray*)newArray;

- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex;
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex;

@end
