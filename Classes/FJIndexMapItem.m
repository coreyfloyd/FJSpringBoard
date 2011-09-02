//
//  IndexMapItem.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJIndexMapItem.h"

@implementation FJIndexMapItem

@synthesize mappedIndex;

- (id)init
{
    self = [super init];
    if (self) {
        self.mappedIndex = NSNotFound;
    }
    
    return self;
}

@end
