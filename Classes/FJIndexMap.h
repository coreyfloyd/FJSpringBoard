//
//  FJIndexMap.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 11/5/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FJIndexMapping <NSObject>

- (NSArray*)oldArray;  //original array before modifications

//map values
- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex;
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex;


@end


//this maps 1-1
@interface FJNormalIndexMap : NSObject <FJIndexMapping>
{
    NSMutableArray* array;   
}
@property(nonatomic, retain) NSMutableArray *array;

- (id)initWithArray:(NSMutableArray*)anArray;

@end


//adjusts indexes based on the reordering
@interface FJReorderingIndexMap : NSObject <FJIndexMapping> {

    NSMutableArray* mapNewToOld;
    NSMutableArray* mapOldToNew;
    
    NSArray* oldArray;
    NSMutableArray* array;
    
    NSUInteger originalReorderingIndex;
    NSUInteger currentReorderingIndex;
    
}
@property(nonatomic, retain) NSMutableArray *mapNewToOld;
@property(nonatomic, retain) NSMutableArray *mapOldToNew;

@property(nonatomic, retain) NSArray *oldArray;
@property(nonatomic, retain) NSMutableArray *array;

@property(nonatomic) NSUInteger originalReorderingIndex;
@property(nonatomic) NSUInteger currentReorderingIndex;

- (id)initWithArray:(NSMutableArray*)anArray reorderingObjectIndex:(NSUInteger)index;

- (NSIndexSet*)modifiedIndexesByMovingReorderingObjectToIndex:(NSUInteger)index;



@end

