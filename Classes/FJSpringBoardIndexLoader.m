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

#define MAX_PAGES 3

NSUInteger indexWithLargestAbsoluteValueFromStartignIndex(NSUInteger start, NSIndexSet* indexes){
    
    __block NSUInteger answer = start;
    __block int largestDiff = 0;
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        int diff = abs((int)((int)start - (int)idx));
        
        if(diff > largestDiff){
            largestDiff = diff;
            answer = idx;
        }
        
    }];
    
    return answer;
}

@interface FJSpringBoardIndexLoader()

@property(nonatomic, readwrite) IndexRangeChanges lastChangeSet;
@property(nonatomic, readwrite) CGPoint contentOffset;
@property(nonatomic, retain) NSMutableIndexSet *currentPages;

- (IndexRangeChanges)horizontalChnagesBySettingContentOffset:(CGPoint)offset;
- (IndexRangeChanges)verticalChnagesBySettingContentOffset:(CGPoint)offset;


@end


@implementation FJSpringBoardIndexLoader

@synthesize layout;
@synthesize lastChangeSet;
@synthesize contentOffset;
@synthesize currentIndexes;    
@synthesize currentPages;



- (void) dealloc
{
    
    [layout release];
    layout = nil;
    [currentPages release];
    currentPages = nil;
    [currentIndexes release];
    currentIndexes = nil;
    [super dealloc];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.currentPages = [NSMutableIndexSet indexSet];
        self.currentIndexes = [NSMutableIndexSet indexSet];
    }
    return self;
}


- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset{
        
    
    if([self.layout isKindOfClass:[FJSpringBoardVerticalLayout class]])
        return [self verticalChnagesBySettingContentOffset:offset];
    else
        return [self horizontalChnagesBySettingContentOffset:offset];
    
}

- (IndexRangeChanges)verticalChnagesBySettingContentOffset:(CGPoint)offset{
    
    FJSpringBoardVerticalLayout* vert = (FJSpringBoardVerticalLayout*)self.layout;
    
    NSMutableIndexSet* newVisibleIndexes = [[vert visibleCellIndexesWithPaddingForContentOffset:offset] mutableCopy];
    
    NSIndexSet* addedIndexes = indexesAdded(self.currentIndexes, newVisibleIndexes);
    
    if([addedIndexes count] == 0){
        
        return indexRangeChangesMake(NSMakeRange(0, 0), NSMakeRange(0, 0), NSMakeRange(0, 0));
        
    } 
    
    if(!indexesAreContinuous(addedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange addedRange = rangeWithIndexes(addedIndexes);
    
    
    
    NSIndexSet* removedIndexes = indexesRemoved(self.currentIndexes, newVisibleIndexes);
    
    if(!indexesAreContinuous(removedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange removedRange = rangeWithIndexes(removedIndexes);
    
    NSRange totalRange = rangeWithIndexes(newVisibleIndexes);
    
    IndexRangeChanges changes = indexRangeChangesMake(totalRange, addedRange, removedRange);
    
    self.contentOffset = offset;
    self.lastChangeSet = changes;
    self.currentIndexes = newVisibleIndexes;
    
    [newVisibleIndexes release];
    
    return changes;
    
}


- (IndexRangeChanges)horizontalChnagesBySettingContentOffset:(CGPoint)offset{
    
    FJSpringBoardHorizontalLayout* hor = (FJSpringBoardHorizontalLayout*)self.layout;
    
    NSUInteger currentPage = [hor pageForContentOffset:offset];
    
    NSUInteger nextPage = [hor nextPageWithPreviousContentOffset:self.contentOffset currentContentOffset:offset];
    
    NSUInteger pageCount = [hor pageCount];
    
    NSIndexSet* pageIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, pageCount)];
    
    if(abs((int)(currentPage-nextPage) > 1)){
        
        ALWAYS_ASSERT;
    }
    
    if([self.currentPages count] > 0 && ![self.currentPages containsIndex:currentPage]){
        
        ALWAYS_ASSERT;
    }
    
    if([self.currentPages count] == 0){
        
        //first load
        if(pageCount > 1)
            nextPage = 1;
        
    }   

   
    
    [self.currentPages addIndex:currentPage];
    [self.currentPages addIndex:nextPage];
    
    NSUInteger rightPage = currentPage+1;
    NSUInteger leftPage = currentPage-1;
    
    if([pageIndexes containsIndex:leftPage])
        [self.currentPages addIndex:leftPage];
    
    if([pageIndexes containsIndex:rightPage])
        [self.currentPages addIndex:rightPage];

         
    //removed pages
    if([self.currentPages count] > MAX_PAGES){
        
        NSUInteger pageToKill = indexWithLargestAbsoluteValueFromStartignIndex(currentPage, self.currentPages);
        [self.currentPages removeIndex:pageToKill];
        
    }

    //total indexes
    NSMutableIndexSet* totalIndexes = [NSMutableIndexSet indexSet];
    [self.currentPages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        NSIndexSet* pIndexes = [hor cellIndexesForPage:idx];
        [totalIndexes addIndexes:pIndexes];
    
    }];
    
    NSIndexSet* addedIndexes = indexesAdded(self.currentIndexes, totalIndexes);
    NSIndexSet* removedIndexes = indexesRemoved(self.currentIndexes, totalIndexes);

    
    if([addedIndexes count] > 0 && !indexesAreContinuous(addedIndexes)){
        
        ALWAYS_ASSERT;
    }    
    
    if([removedIndexes count] > 0 && !indexesAreContinuous(removedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    if([addedIndexes count] > 0 && !indexesAreContinuous(totalIndexes)){
        
        ALWAYS_ASSERT;
    }   
    
    //NSLog(@"total indexes: %@", [totalIndexes description]);
    //NSLog(@"pages to load: %@", [pages description]);
    //NSLog(@"indexes to add: %@", [addedIndexes description]);
    //NSLog(@"indexes to remove: %@", [indexesToRemove description]);
    
      
    
    NSRange addedRange = rangeWithIndexes(addedIndexes);
    
    NSRange removedRange = rangeWithIndexes(removedIndexes);
    
    NSRange totalRange = rangeWithIndexes(totalIndexes);
    
    IndexRangeChanges changes = indexRangeChangesMake(totalRange, addedRange, removedRange);
    
    self.contentOffset = offset;
    self.lastChangeSet = changes;
    self.currentIndexes = totalIndexes;
    
    return changes;
    
    
}




@end
