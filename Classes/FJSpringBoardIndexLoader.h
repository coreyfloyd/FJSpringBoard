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
    IndexRangeChanges lastChangeSet;
    
    NSMutableIndexSet *allIndexes;

    NSMutableIndexSet* currentIndexes;
    NSMutableIndexSet* currentPages;
    
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

@property (nonatomic, retain) FJSpringBoardLayout *layout;

- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset;
@property(nonatomic, readonly) CGPoint contentOffset;

@property(nonatomic, retain) NSMutableIndexSet *allIndexes;

@property(nonatomic, retain) NSMutableIndexSet *currentIndexes;
@property(nonatomic, readonly) IndexRangeChanges lastChangeSet;


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
