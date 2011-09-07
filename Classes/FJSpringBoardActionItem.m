//
//  FJSpringBoardActionItem.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardActionItem.h"
#import "FJSpringBoardUtilities.h"

@implementation FJSpringBoardActionItem

@synthesize index;


- (id)init {
    self = [super init];
    if (self) {
        self.index = NSNotFound;
    }
    return self;
}


@end
