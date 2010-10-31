//
//  FJSpringBoardIndexLoader.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardIndexLoader.h"


@implementation FJSpringBoardIndexLoader

@synthesize layout;

- (void) dealloc
{
    
    [layout release];
    layout = nil;
    [super dealloc];
}




- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset{
    
    
    
}


@end
