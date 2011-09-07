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
#import "FJSpringBoardAction.h"

@class FJSpringBoardActionIndexMap;

@interface FJSpringBoardUpdate : SMModelObject{
        
    FJSpringBoardAction* action;
    FJSpringBoardActionIndexMap* indexMap;
    
    NSMutableSet* cellActionUpdates;
    NSMutableSet* cellMovementUpdates;
    
    NSUInteger newCellCount;
    
}

- (id)initWithCellCount:(NSUInteger)count springBoardAction:(FJSpringBoardAction*)anAction;

@property (nonatomic, readonly) FJSpringBoardActionType actionType; //are the cellActionUpdates insert, deletes, or reloads?

- (NSArray*)sortedCellActionUpdates; //an insert, delete, or relaod, direct result of the Action
- (NSArray*)sortedCellMovementUpdates; //cell movements in response to the action

@property (nonatomic) NSUInteger newCellCount;

@end
