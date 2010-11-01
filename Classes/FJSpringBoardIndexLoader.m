//
//  FJSpringBoardIndexLoader.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"

#define NUMBER_OF_PAGES_TO_PAD 1

@interface FJSpringBoardIndexLoader()

@property(nonatomic, readwrite) IndexRangeChanges lastChangeSet;
@property(nonatomic, readwrite) CGPoint contentOffset;
@property(nonatomic, retain, readwrite) NSIndexSet *currentIndexes;

@end


@implementation FJSpringBoardIndexLoader

@synthesize layout;
@synthesize lastChangeSet;
@synthesize contentOffset;
@synthesize currentIndexes;    


- (void) dealloc
{
    
    [layout release];
    layout = nil;
    [currentIndexes release];
    currentIndexes = nil;
    [super dealloc];
}


- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset{
        
    FJSpringBoardVerticalLayout* vert = (FJSpringBoardVerticalLayout*)self.layout;
    
    NSIndexSet* newVisibleIndexes = [vert visibleCellIndexesWithPaddingForContentOffset:offset];
    
    
    NSIndexSet* addedIndexes = indexesAdded(self.currentIndexes, newVisibleIndexes);
    
    if([addedIndexes count] == 0){
        
        return indexRangeChangesMake(NSMakeRange(0, 0), NSMakeRange(0, 0), NSMakeRange(0, 0));
        
    } 
    
    if(!indexesAreContiguous(addedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange addedRange = rangeWithIndexes(addedIndexes);
    
    
    
    NSIndexSet* removedIndexes = indexesRemoved(self.currentIndexes, newVisibleIndexes);

    if(!indexesAreContiguous(removedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange removedRange = rangeWithIndexes(removedIndexes);

    
    NSRange totalRange = rangeWithIndexes(newVisibleIndexes);
    
    IndexRangeChanges changes = indexRangeChangesMake(totalRange, addedRange, removedRange);
    
    self.contentOffset = offset;
    self.lastChangeSet = changes;
    self.currentIndexes = newVisibleIndexes;
    
    return changes;
    
}




@end
