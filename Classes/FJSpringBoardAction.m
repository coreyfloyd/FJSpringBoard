//
//  FJSpringBoardAction.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardAction.h"

@implementation FJSpringBoardAction

@synthesize action;
@synthesize animation;
@synthesize index;
@synthesize newIndex;


+ (FJSpringBoardAction*)actionForReloadingCellAtIndex:(NSUInteger)idx animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionReload;
    a.animation = anim;
    a.index = idx;
    
    return [a autorelease];
}

+ (FJSpringBoardAction*)actionForMovingCellAtIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionMove;
    a.animation = anim;
    a.index = startIndex;
    a.newIndex = endIndex;
    
    return [a autorelease];
}

+ (FJSpringBoardAction*)actionForInsertingCellAtIndex:(NSUInteger)idx animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionInsert;
    a.animation = anim;
    a.index = idx;
    
    return [a autorelease];
}

+ (FJSpringBoardAction*)actionForDeletingCellAtIndex:(NSUInteger)idx animation:(FJSpringBoardCellAnimation)anim{
    
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionDelete;
    a.animation = anim;
    a.index = idx;
    
    return [a autorelease];
}

- (void)buildCellActionsAndApplyToMap:(FJSpringBoardActionIndexMap*)map{
    
    
    
    
    
}



@end
