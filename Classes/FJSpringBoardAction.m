//
//  FJSpringBoardAction.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardAction.h"
#import "FJSpringBoardActionItem.h"

@implementation FJSpringBoardAction

@synthesize action;
@synthesize animation;
@synthesize actionItems;


- (void)dealloc {
    
    [actionItems release];
    actionItems = nil;
    [super dealloc];
}
+ (FJSpringBoardAction*)deletionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionDelete;
    a.animation = anim;

    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = [[FJSpringBoardActionItem alloc] init];
        item.index = idx;
        [items addObject:item];
        [item release];
        
    }];
    
    a.actionItems = items;
    return [a autorelease];

}

+ (FJSpringBoardAction*)insertionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionInsert;
    a.animation = anim;
    
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = [[FJSpringBoardActionItem alloc] init];
        item.index = idx;
        [items addObject:item];
        [item release];
        
    }];

    a.actionItems = items;
    return [a autorelease];

}


+ (FJSpringBoardAction*)reloadActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionReload;
    a.animation = anim;
    
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardActionItem* item = [[FJSpringBoardActionItem alloc] init];
        item.index = idx;
        [items addObject:item];
        [item release];
        
    }];
    
    a.actionItems = items;
    return [a autorelease];

}

+ (FJSpringBoardAction*)moveActionWithStartIndex:(NSUInteger)startIndex endIndex:(NSUInteger)endIndex animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.action = FJSpringBoardActionReload;
    a.animation = anim;
    
    FJSpringBoardActionItem* item = [[FJSpringBoardActionItem alloc] init];
    item.index = startIndex;
    item.newIndex = endIndex;
    
    a.actionItems = [NSArray arrayWithObject:item];
    [item release];

    return [a autorelease];
    
}


- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)buildCellActionsAndApplyToMap:(FJSpringBoardActionIndexMap*)map{
    
    
    
    
    
}



@end
