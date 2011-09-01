//
//  FJSpringBoardCellAction.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardCellAction.h"

@implementation FJSpringBoardCellAction

@synthesize needsLoaded;
@synthesize animation;
@synthesize oldSpringBoardIndex;
@synthesize newSpringBoardIndex;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)markNeedsLoaded{
    
    needsLoaded = YES;
    
}
@end
