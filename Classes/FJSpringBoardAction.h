//
//  FJSpringBoardAction.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

/*
 FJSpringBoardAction defines any actions taken on the springboard: Inserts, Deletions, Reloads
*/

#import <Foundation/Foundation.h>
#import "FJSpringBoardView.h"
#import "SMModelObject.h"

typedef enum{
    FJSpringBoardActionReload,
    FJSpringBoardActionInsert,
    FJSpringBoardActionDelete
    
}FJSpringBoardActionType;


@interface FJSpringBoardAction : SMModelObject{
    
    FJSpringBoardActionType type;
    FJSpringBoardCellAnimation animation;
    NSIndexSet* indexes;
}
@property (nonatomic) FJSpringBoardActionType type;
@property (nonatomic) FJSpringBoardCellAnimation animation;
@property (nonatomic, copy) NSIndexSet *indexes;

+ (FJSpringBoardAction*)deletionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim; 

+ (FJSpringBoardAction*)insertionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim; 

+ (FJSpringBoardAction*)reloadActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim; 



@end
