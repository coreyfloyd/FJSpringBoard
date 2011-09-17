//
//  FJSpringBoardUpdate.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

/*
  FJSpringBoardUpdate defines the update of the springboard as a result of processing a FJSpringBoardAction. 1 action -> 1 update.
  An update is completely independent of the content offset, layout, and visible indexes.
*/

#import <Foundation/Foundation.h>
#import "SMModelObject.h"

@class FJSpringBoardActionGroup;

@interface FJSpringBoardUpdate : SMModelObject{
        
    FJSpringBoardActionGroup* actionGroup;
    
    NSArray* reloadUpdates;
    NSArray* deleteUpdates;
    NSArray* insertUpdates;
    NSArray* moveUpdates;
    
    NSIndexSet* reloadIndexes;
    NSIndexSet* deleteIndexes;
    NSIndexSet* insertIndexes;
    
    NSMutableSet* cellMovementUpdates;
    
    NSUInteger newCellCount;
    
    NSMutableArray* newCellState;
    
}

- (id)initWithCellCount:(NSUInteger)count visibleIndexRange:(NSRange)range actionGroup:(FJSpringBoardActionGroup*)anActionGroup;


//These should be processed in this order.
- (NSArray*)deleteUpdates;
- (NSIndexSet*)deleteIndexes;

- (NSArray*)insertUpdates;
- (NSIndexSet*)insertIndexes;

- (NSArray*)moveUpdates;

- (NSArray*)reloadUpdates;
- (NSIndexSet*)reloadIndexes;

@property (nonatomic, readonly) NSArray *cellStatePriorToAction; //only used for deletes now
@property (nonatomic, retain, readonly) NSMutableArray *newCellState; //cells after action is processed


@property (nonatomic) NSUInteger newCellCount;

@end
