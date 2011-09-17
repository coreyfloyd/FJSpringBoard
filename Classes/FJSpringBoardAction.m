//
//  FJSpringBoardAction.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardAction.h"

@implementation FJSpringBoardAction

@synthesize type;
@synthesize animation;
@synthesize indexes;


- (void)dealloc {
    [indexes release];
    indexes = nil;
    [super dealloc];
}
+ (FJSpringBoardAction*)deletionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.type = FJSpringBoardActionDelete;
    a.animation = anim;
    a.indexes = indexes;

    return [a autorelease];

}

+ (FJSpringBoardAction*)insertionActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.type = FJSpringBoardActionInsert;
    a.animation = anim;
    a.indexes = indexes;

    return [a autorelease];

}

+ (FJSpringBoardAction*)reloadActionWithIndexes:(NSIndexSet*)indexes animation:(FJSpringBoardCellAnimation)anim{
    
    FJSpringBoardAction* a = [[FJSpringBoardAction alloc] init];
    a.type = FJSpringBoardActionReload;
    a.animation = anim;
    a.indexes = indexes;

    return [a autorelease];

}



@end
