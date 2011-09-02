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
@synthesize newIndex;
@synthesize affectedRange;


- (id)init {
    self = [super init];
    if (self) {
        self.index = NSNotFound;
        self.newIndex = NSNotFound;
        self.affectedRange = NSMakeRange(0,0);
    }
    return self;
}

- (void)updatedAffectedRangeWithIndexCount:(NSUInteger)numberOfIndexes{
    
    if(index != NSNotFound && newIndex == NSNotFound){
        
        NSUInteger lastIndex = numberOfIndexes-1;
        NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(self.index, lastIndex);
        self.affectedRange = affectedRangeThatNeedShifted;
        
        
    }else if(index == NSNotFound && newIndex != NSNotFound){
        
        NSUInteger lastIndex = numberOfIndexes-1;
        NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(self.newIndex, lastIndex);
        self.affectedRange = affectedRangeThatNeedShifted;
        
        
    }else if(index != NSNotFound && newIndex != NSNotFound){
        
        //lets get the affected range in the new array
        NSUInteger startIndex = NSNotFound;
        NSUInteger lastIndex = NSNotFound;
        
        //moving forward
        if(self.newIndex > self.index){
            
            startIndex = self.index + 1; //first index after item
            lastIndex = self.newIndex; //index where it will be moved to
            
            NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(startIndex, lastIndex);
            self.affectedRange = affectedRangeThatNeedShifted;

        //backwards    
        }else{
            
            startIndex = self.newIndex; //index where it will be moved to
            lastIndex = self.index - 1; //first index before the item
            
            NSRange affectedRangeThatNeedShifted = rangeWithFirstAndLastIndexes(startIndex, lastIndex);
            self.affectedRange = affectedRangeThatNeedShifted;

        }
        
        
    }else{
        
        ALWAYS_ASSERT;
        self.affectedRange = NSMakeRange(0,0);

    }
    
   
    debugLog(@"item with affected range: %@", self);

}

@end
