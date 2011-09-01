//
//  FJSpringBoardAction.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardView.h"

@class FJSpringBoardActionIndexMap;

typedef enum{
    FJSpringBoardActionReload,
    FJSpringBoardActionMove,
    FJSpringBoardActionInsert,
    FJSpringBoardActionDelete
    
}FJSpringBoardActionType;


@interface FJSpringBoardAction : NSObject{
    
    FJSpringBoardActionType action;
    FJSpringBoardCellAnimation animation;
    NSUInteger index;
    NSUInteger newIndex;    
    
}
@property (nonatomic) FJSpringBoardActionType action;
@property (nonatomic) FJSpringBoardCellAnimation animation;
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSUInteger newIndex;

+ (FJSpringBoardAction*)actionForReloadingCellAtIndex:(NSUInteger)idx animation:(FJSpringBoardCellAnimation)anim;

+ (FJSpringBoardAction*)actionForMovingCellAtIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex animation:(FJSpringBoardCellAnimation)anim;

+ (FJSpringBoardAction*)actionForInsertingCellAtIndex:(NSUInteger)idx animation:(FJSpringBoardCellAnimation)anim;

+ (FJSpringBoardAction*)actionForDeletingCellAtIndex:(NSUInteger)idx animation:(FJSpringBoardCellAnimation)anim;

- (void)buildCellActionsAndApplyToMap:(FJSpringBoardActionIndexMap*)map;



@end
