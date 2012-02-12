//
//  FJSpringBoardActionGroup.m
//  Vimeo
//
//  Created by Corey Floyd on 9/15/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardActionGroup.h"

@interface FJSpringBoardActionGroup()

@property (nonatomic, getter=isLocked, readwrite) BOOL locked;

@end

@implementation FJSpringBoardActionGroup

@synthesize reloadActions;
@synthesize deleteActions;
@synthesize insertActions;
@synthesize locked;
@synthesize lockCount;
@synthesize validated;


- (void)dealloc {
    [cellStateBeforeAction release];
    cellStateBeforeAction = nil;
    [reloadActions release];
    reloadActions = nil;
    [deleteActions release];
    deleteActions = nil;
    [insertActions release];
    insertActions = nil;
    [super dealloc];
}

- (id)init{
    
    self = [super init];
    if (self) {
        // Initialization code here.
        self.reloadActions = [NSMutableSet set];
        self.insertActions = [NSMutableSet set];
        self.deleteActions = [NSMutableSet set];
    }
    
    return self;
}

- (void)addReloadAction:(FJSpringBoardAction*)action{
    
    [[self reloadActions] addObject:action];

}
- (void)addDeleteAction:(FJSpringBoardAction*)action{
    
    [[self deleteActions] addObject:action];
   
}
- (void)addInsertAction:(FJSpringBoardAction*)action{
    
    [[self insertActions] addObject:action];
}

- (void)addActionWithType:(FJSpringBoardActionType)type indexes:(NSIndexSet*)indexSet animation:(FJSpringBoardCellAnimation)animation{

    ASSERT_TRUE(!self.isLocked);
    
    FJSpringBoardAction* action;
    
    switch (type) {
        case FJSpringBoardActionReload:
            action = [FJSpringBoardAction reloadActionWithIndexes:indexSet animation:animation];
            [self addReloadAction:action];
            break;
        case FJSpringBoardActionDelete:
            action = [FJSpringBoardAction deletionActionWithIndexes:indexSet animation:animation];
            [self addDeleteAction:action];
            break;
        case FJSpringBoardActionInsert:
            action = [FJSpringBoardAction insertionActionWithIndexes:indexSet animation:animation];
            [self addInsertAction:action];
            break;
        default:
            break;
    }
    
    if(self.lockCount == 0)
        [self lock];
    
}

- (NSIndexSet*)indexesToInsert{
    
    NSMutableIndexSet* r = [NSMutableIndexSet indexSet];
    
    [self.insertActions enumerateObjectsWithOptions:0 usingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardAction* a = obj;
        
        [r addIndexes:a.indexes];
        
    }];
    
    return r;
}
- (NSIndexSet*)indexesToDelete{
    
    NSMutableIndexSet* r = [NSMutableIndexSet indexSet];
    
    [self.deleteActions enumerateObjectsWithOptions:0 usingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardAction* a = obj;
        
        [r addIndexes:a.indexes];
        
    }];
    
    return r;
}

- (NSString*)description{
    
    NSMutableString* s = [NSMutableString string];
    
    NSMutableIndexSet* r = [NSMutableIndexSet indexSet];
    
    [self.reloadActions enumerateObjectsWithOptions:0 usingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardAction* a = obj;
        
        [r addIndexes:a.indexes];
        
    }];
    
    [s appendFormat:@"FJSpringboardAcionGroup - indexes to reload: %@", [r description]];
    
    [s appendString:@"\n"];

    r = [NSMutableIndexSet indexSet];
    
    [self.insertActions enumerateObjectsWithOptions:0 usingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardAction* a = obj;
        
        [r addIndexes:a.indexes];
        
    }];
    
    [s appendFormat:@"FJSpringboardAcionGroup - indexes to insert: %@", [r description]];

    [s appendString:@"\n"];
    
    r = [NSMutableIndexSet indexSet];
    
    [self.deleteActions enumerateObjectsWithOptions:0 usingBlock:^(id obj, BOOL *stop) {
        
        FJSpringBoardAction* a = obj;
        
        [r addIndexes:a.indexes];
        
    }];
    
    [s appendFormat:@"FJSpringboardAcionGroup - indexes to delete: %@", [r description]];
    
    return s;
    
}

- (void)lock{
    self.locked = YES;
}

- (void)beginUpdates{
    
    self.lockCount++;
    
}

- (void)endUpdates{    
    
    self.lockCount--;
    
    if(self.lockCount == 0)
        [self lock];

}


@end
