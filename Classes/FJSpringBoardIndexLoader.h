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

@interface FJSpringBoardIndexLoader : SMModelObject {

    FJSpringBoardLayout *layout;
    
    CGPoint contentOffset;
    
    NSMutableIndexSet *mutableAllIndexes;
    NSMutableIndexSet* mutableIndexesToLoad;
    NSMutableIndexSet* mutableIndexesToUnload;
    
    NSIndexSet *visibleIndexes; //visible means should be loaded due to layout not neccesarily in the view port.
    NSMutableArray* cells;
        
}
- (id)initWithCellCount:(NSUInteger)count;


//set the layout so we can determine the visible cells
@property (nonatomic, retain) FJSpringBoardLayout *layout; 


//all indexes (as determined by the datasource cell count)
- (NSIndexSet*)allIndexes;

//indexes that are visible (this is determined using the layout and independent of actual cell count)
- (NSIndexSet*)visibleIndexes;

//scrub a given index set leaving only the visible members
- (NSIndexSet*)visibleIndexesInIndexSet:(NSIndexSet*)someIndexes;

//check a single index
- (BOOL)indexIsVisible:(NSUInteger)anIndex;


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

//This should be equal to the actual cell indexes loaded into the springboard!!
//updated as the indexes are cleared above
- (NSIndexSet*)loadedIndexes;

//call this method after the gridview processes an update to adjust the values of the loaded indexes to their new values 
- (void)adjustLoadedIndexesByDeletingIndexes:(NSIndexSet*)indexes insertingIndexes:(NSIndexSet*)indexes;


@end
