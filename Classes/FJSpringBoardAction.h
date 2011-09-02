//
//  FJSpringBoardAction.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardView.h"
#import "SMModelObject.h"

@class FJSpringBoardActionIndexMap;

typedef enum{
    FJSpringBoardActionReload,
    FJSpringBoardActionMove,
    FJSpringBoardActionInsert,
    FJSpringBoardActionDelete
    
}FJSpringBoardActionType;


@interface FJSpringBoardAction : SMModelObject{
    
    FJSpringBoardActionType action;
    FJSpringBoardCellAnimation animation;
    NSArray* actionItems;
    
}
@property (nonatomic) FJSpringBoardActionType action;
@property (nonatomic) FJSpringBoardCellAnimation animation;
@property (nonatomic, copy) NSArray *actionItems;

+ (FJSpringBoardAction*)deletionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim; 

+ (FJSpringBoardAction*)insertionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim; 

+ (FJSpringBoardAction*)reloadActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim; 

+ (FJSpringBoardAction*)moveActionWithStartIndex:(NSUInteger)startIndex endIndex:(NSUInteger)endIndex animation:(FJSpringBoardCellAnimation)anim; 

- (void)buildCellActionsAndApplyToMap:(FJSpringBoardActionIndexMap*)map;



@end
