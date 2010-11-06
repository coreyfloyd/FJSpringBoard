

#import <Foundation/Foundation.h>

#define CELL_INVISIBLE_TOP_MARGIN 10
#define CELL_INVISIBLE_LEFT_MARGIN 10

NSMutableArray* nullArrayOfSize(NSUInteger size);

BOOL rangesAreContiguous(NSRange first, NSRange second);

NSRange rangeWithIndexes(NSIndexSet* indexes);


BOOL indexesAreContinuous(NSIndexSet* indexes);

NSIndexSet* indexesRemoved(NSIndexSet* oldSet, NSIndexSet* newSet);

NSIndexSet* indexesAdded(NSIndexSet* oldSet, NSIndexSet* newSet);

NSIndexSet* contiguousIndexSetWithFirstAndLastIndexes(NSUInteger first, NSUInteger last);

typedef struct {
    NSRange fullIndexRange;
    NSRange indexRangeToAdd;
    NSRange indexRangeToRemove;
} IndexRangeChanges;

IndexRangeChanges indexRangeChangesMake(NSRange total, NSRange added, NSRange removed);


typedef struct {
    NSUInteger index;
    NSUInteger row;
    NSUInteger column;
} CellPosition;
