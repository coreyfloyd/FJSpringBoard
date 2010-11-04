

#import "FJSpringBoardUtilities.h"


NSIndexSet* continuousIndexSetWithFirstAndLastIndexes(NSUInteger first, NSUInteger last){
    
    NSUInteger length = last-first + 1;
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(first, length)];
    
    return indexes;
    
}


NSIndexSet* indexesAdded(NSIndexSet* oldSet, NSIndexSet* newSet){
    
    NSMutableIndexSet* s = [newSet mutableCopy];
    [s removeIndexes:oldSet];
    
    return s;
}

NSIndexSet* indexesRemoved(NSIndexSet* oldSet, NSIndexSet* newSet){
    
    NSMutableIndexSet* s = [oldSet mutableCopy];
    [s removeIndexes:newSet];
    
    return s;
}

IndexRangeChanges indexRangeChangesMake(NSRange total, NSRange added, NSRange removed){
    
    IndexRangeChanges c;
    c.indexRangeToAdd = added;
    c.indexRangeToRemove = removed;
    c.fullIndexRange = total;
    
    return c;
    
}


NSRange rangeWithIndexes(NSIndexSet* indexes){
    
    if(!indexesAreContinuous(indexes))
        return NSMakeRange(0, 0);
    
    NSUInteger firstIndex = [indexes firstIndex];
    NSUInteger length = [indexes count];
    
    return NSMakeRange(firstIndex, length);
    
}


BOOL rangesAreContiguous(NSRange first, NSRange second){
    
    NSIndexSet* firstIndexes = [NSIndexSet indexSetWithIndexesInRange:first];
    NSIndexSet* secondIndexes = [NSIndexSet indexSetWithIndexesInRange:second];
    
    NSUInteger endOfFirstRange = [firstIndexes lastIndex];
    NSUInteger beginingOfSecondRange = [secondIndexes firstIndex];
    
    if(beginingOfSecondRange - endOfFirstRange == 1)
        return YES;
    
    return NO;
    
}

BOOL indexesAreContinuous(NSIndexSet* indexes){
    
    return ((([indexes lastIndex] - [indexes firstIndex]) + 1) == [indexes count]);
}


NSMutableArray* nullArrayOfSize(NSUInteger size){
    
    NSMutableArray* c = [NSMutableArray arrayWithCapacity:size];
    
    for(int i = 0; i < size; i++){
        
        [c addObject:[NSNull null]];
    }
    
    return c;
    
}
