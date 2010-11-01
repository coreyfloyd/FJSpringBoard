

#import <Foundation/Foundation.h>


NSMutableArray* nullArrayOfSize(NSUInteger size);

BOOL rangesAreContiguous(NSRange first, NSRange second);

NSRange rangeWithIndexes(NSIndexSet* indexes);


BOOL indexesAreContiguous(NSIndexSet* indexes);

NSIndexSet* indexesRemoved(NSIndexSet* oldSet, NSIndexSet* newSet);

NSIndexSet* indexesAdded(NSIndexSet* oldSet, NSIndexSet* newSet);



typedef struct {
    NSRange fullIndexRange;
    NSRange indexRangeToAdd;
    NSRange indexRangeToRemove;
} IndexRangeChanges;

IndexRangeChanges indexRangeChangesMake(NSRange total, NSRange added, NSRange removed);


typedef struct {
    NSUInteger row;
    NSUInteger column;
} CellPosition;
