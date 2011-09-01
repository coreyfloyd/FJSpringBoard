
#define DEBUG_LAYOUT

#define CELL_INVISIBLE_TOP_MARGIN 10
#define CELL_INVISIBLE_LEFT_MARGIN 10
#define CELL_DRAGGABLE_ALPHA 0.6

NSMutableArray* nullArrayOfSize(NSUInteger size);


BOOL rangesAreContiguous(NSRange first, NSRange second);

NSRange rangeWithContiguousIndexes(NSIndexSet* indexes);

BOOL indexesAreContiguous(NSIndexSet* indexes);

NSIndexSet* indexesRemoved(NSIndexSet* oldSet, NSIndexSet* newSet);

NSIndexSet* indexesAdded(NSIndexSet* oldSet, NSIndexSet* newSet);

NSRange rangeWithFirstAndLastIndexes(NSUInteger first, NSUInteger last);

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

typedef struct {
    NSUInteger index;
    NSUInteger page;
    NSUInteger row;
    NSUInteger column;
} CellPagePosition;