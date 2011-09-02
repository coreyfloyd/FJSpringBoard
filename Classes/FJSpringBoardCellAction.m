//
//  FJSpringBoardCellAction.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardCellAction.h"

@implementation FJSpringBoardCellAction

@synthesize type;
@synthesize needsLoaded;
@synthesize animation;
@synthesize oldSpringBoardIndex;
@synthesize newSpringBoardIndex;

- (id)init
{
    self = [super init];
    if (self) {
        self.oldSpringBoardIndex = NSNotFound;
        self.newSpringBoardIndex = NSNotFound;
    }
    
    return self;
}

- (void)markNeedsLoaded{
    
    needsLoaded = YES;
    
}

- (void)finalizeType{
    
    if(self.oldSpringBoardIndex == NSNotFound && self.newSpringBoardIndex == NSNotFound){
        
        //cell is being inserted and subsequesntly deleted. should be rare
        self.type = FJSpringBoardCellActionNone;
        
        NSLog(@"cell inserted and deleted in same update batch!");;
        
        
    }else if(self.oldSpringBoardIndex == NSNotFound && self.newSpringBoardIndex != NSNotFound){
        
        //this is a new cell it is not on screen
        self.type = FJSpringBoardCellActionInsert;
        
        
    }else if(self.oldSpringBoardIndex != NSNotFound && self.newSpringBoardIndex == NSNotFound){
        
        //cell is being deleted
        self.type = FJSpringBoardCellActionDelete;
        

    }else if(self.oldSpringBoardIndex == self.newSpringBoardIndex){
        
        //cell is being reloaded
        self.type = FJSpringBoardCellActionReload;
        
        
    }else if(self.oldSpringBoardIndex != NSNotFound && self.newSpringBoardIndex != NSNotFound){
        
        //cell is being moved
        self.type = FJSpringBoardCellActionMove;
        
    }else{
        
        ALWAYS_ASSERT;
    }
}

- (NSUInteger)comparisonIndex{
    
    switch (self.type) {
        case FJSpringBoardCellActionNone:
            return 0;
            break;
        case FJSpringBoardCellActionInsert:
            return self.newSpringBoardIndex;
            break;
        case FJSpringBoardCellActionDelete:
            return self.oldSpringBoardIndex;
            break;
        case FJSpringBoardCellActionReload:
            return self.oldSpringBoardIndex;
            break;
        case FJSpringBoardCellActionMove:
            return MIN(self.oldSpringBoardIndex, self.newSpringBoardIndex);
            break;
        default:
            ALWAYS_ASSERT;
            break;
    }
    
    return NSNotFound;
    
}


- (NSComparisonResult)compare:(FJSpringBoardCellAction*)anAction{
    
    if([self comparisonIndex] == [anAction comparisonIndex])
        return NSOrderedSame;
    if([self comparisonIndex] < [anAction comparisonIndex])
        return NSOrderedAscending;
    if([self comparisonIndex] > [anAction comparisonIndex])
        return NSOrderedDescending;
    
    return NSOrderedSame;
        
}


@end
