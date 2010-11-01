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
@property(nonatomic) NSUInteger currentPage;

- (IndexRangeChanges)horizontalChnagesBySettingContentOffset:(CGPoint)offset;
- (IndexRangeChanges)verticalChnagesBySettingContentOffset:(CGPoint)offset;

@end


@implementation FJSpringBoardIndexLoader

@synthesize layout;
@synthesize lastChangeSet;
@synthesize contentOffset;
@synthesize currentIndexes;    
@synthesize currentPage;

- (void) dealloc
{
    
    [layout release];
    layout = nil;
    [currentIndexes release];
    currentIndexes = nil;
    [super dealloc];
}


- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset{
        
    
    if([self.layout isKindOfClass:[FJSpringBoardVerticalLayout class]])
        return [self verticalChnagesBySettingContentOffset:offset];
    else
        return [self horizontalChnagesBySettingContentOffset:offset];
    
}

- (IndexRangeChanges)verticalChnagesBySettingContentOffset:(CGPoint)offset{
    
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


- (IndexRangeChanges)horizontalChnagesBySettingContentOffset:(CGPoint)offset{
    
    FJSpringBoardHorizontalLayout* hor = (FJSpringBoardHorizontalLayout*)self.layout;
    
    NSUInteger nextPage = [hor pageToLoadForPreviousContentOffset:self.contentOffset currentContentOffset:offset];
    
    BOOL movePositive = (nextPage > self.currentPage ? YES:NO); 

    NSIndexSet* nextPageIndexes = [hor cellIndexesForPage:nextPage];
    
    NSIndexSet* currentPageIndexes = [hor cellIndexesForPage:self.currentPage];

    NSIndexSet* previousPageIndexes = nil;
    
    NSIndexSet* indexesToRemove = nil;

    
    if(movePositive){
        
        if(self.currentPage > 0){
            
            previousPageIndexes = [hor cellIndexesForPage:self.currentPage-1];
            
        } 
        
        if(self.currentPage > 1){
            
            indexesToRemove = [hor cellIndexesForPage:self.currentPage-2];
            
        }
        
    }else{
        
        if(hor.pageCount > self.currentPage+1){
            
            previousPageIndexes = [hor cellIndexesForPage:self.currentPage+1];
            
        } 
        
        if(hor.pageCount > self.currentPage+2){
            
            indexesToRemove = [hor cellIndexesForPage:self.currentPage+2];
            
        }
        
    }
    
    NSMutableIndexSet* newIndexes = [NSMutableIndexSet indexSet];
    [newIndexes addIndexes:currentPageIndexes];
    [newIndexes addIndexes:nextPageIndexes];
    [newIndexes addIndexes:previousPageIndexes];
    
    
    
    
    NSIndexSet* addedIndexes = indexesAdded(self.currentIndexes, newIndexes);
    
    if([addedIndexes count] == 0){
        
        return indexRangeChangesMake(NSMakeRange(0, 0), NSMakeRange(0, 0), NSMakeRange(0, 0));
        
    } 
    
    if(!indexesAreContiguous(addedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange addedRange = rangeWithIndexes(addedIndexes);
    
        
    if(!indexesAreContiguous(indexesToRemove)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange removedRange = rangeWithIndexes(indexesToRemove);
    
    NSRange totalRange = rangeWithIndexes(newIndexes);
    
    IndexRangeChanges changes = indexRangeChangesMake(totalRange, addedRange, removedRange);
    
    self.contentOffset = offset;
    self.currentPage = [hor pageForContentOffset:offset];
    self.lastChangeSet = changes;
    self.currentIndexes = newIndexes;
    
    return changes;
    
    
}




@end
