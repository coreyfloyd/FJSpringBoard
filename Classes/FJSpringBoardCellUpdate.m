//
//  FJSpringBoardCellUpdate.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardCellUpdate.h"

@implementation FJSpringBoardCellUpdate

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
        self.type = FJSpringBoardCellupdateNone;
        
        NSLog(@"cell inserted and deleted in same update batch!");;
        
        
    }else if(self.oldSpringBoardIndex == NSNotFound && self.newSpringBoardIndex != NSNotFound){
        
        //this is a new cell it is not on screen
        self.type = FJSpringBoardCellupdateInsert;
        
        
    }else if(self.oldSpringBoardIndex != NSNotFound && self.newSpringBoardIndex == NSNotFound){
        
        //cell is being deleted
        self.type = FJSpringBoardCellupdateDelete;
        

    }else if(self.oldSpringBoardIndex == self.newSpringBoardIndex){
        
        //cell is being reloaded
        self.type = FJSpringBoardCellupdateReload;
        
        
    }else if(self.oldSpringBoardIndex != NSNotFound && self.newSpringBoardIndex != NSNotFound){
        
        //cell is being moved
        self.type = FJSpringBoardCellupdateMove;
        
    }else{
        
        ALWAYS_ASSERT;
    }
}

- (NSUInteger)comparisonIndex{
    
    switch (self.type) {
        case FJSpringBoardCellupdateNone:
            return 0;
            break;
        case FJSpringBoardCellupdateInsert:
            return self.newSpringBoardIndex;
            break;
        case FJSpringBoardCellupdateDelete:
            return self.oldSpringBoardIndex;
            break;
        case FJSpringBoardCellupdateReload:
            return self.oldSpringBoardIndex;
            break;
        case FJSpringBoardCellupdateMove:
            return MIN(self.oldSpringBoardIndex, self.newSpringBoardIndex);
            break;
        default:
            ALWAYS_ASSERT;
            break;
    }
    
    return NSNotFound;
    
}


- (NSComparisonResult)compare:(FJSpringBoardCellUpdate*)anAction{
    
    if([self comparisonIndex] == [anAction comparisonIndex])
        return NSOrderedSame;
    if([self comparisonIndex] < [anAction comparisonIndex])
        return NSOrderedAscending;
    if([self comparisonIndex] > [anAction comparisonIndex])
        return NSOrderedDescending;
    
    return NSOrderedSame;
        
}


@end
