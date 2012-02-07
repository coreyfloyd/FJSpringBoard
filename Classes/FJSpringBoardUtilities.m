

#import "FJSpringBoardUtilities.h"

IndexRangeChanges indexRangeChangesMake(NSRange total, NSRange added, NSRange removed){
    
    IndexRangeChanges c;
    c.indexRangeToAdd = added;
    c.indexRangeToRemove = removed;
    c.fullIndexRange = total;
    
    return c;
    
}

NSMutableArray* nullArrayOfSize(NSUInteger size){
    
    NSMutableArray* c = [NSMutableArray arrayWithCapacity:size];
    
    for(int i = 0; i < size; i++){
        
        [c addObject:[NSNull null]];
    }
    
    return c;
    
}
