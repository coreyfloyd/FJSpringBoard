//
//  FJSpringBoardUpdate.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardUpdate.h"
#import "FJSpringBoardCellAction.h"

@implementation FJSpringBoardUpdate

@synthesize reloads;
@synthesize insertions;
@synthesize deletions;
@synthesize moves;

- (void)dealloc {
    [reloads release];
    reloads = nil;
    [insertions release];
    insertions = nil;
    [deletions release];
    deletions = nil;
    [moves release];
    moves = nil;
    [super dealloc];
}
- (id)initWithCellActions:(NSSet*)actions
{
    self = [super init];
    if (self) {
        
        NSMutableSet* rel = [NSMutableSet set];
        NSMutableSet* ins = [NSMutableSet set];
        NSMutableSet* del = [NSMutableSet set];
        NSMutableSet* mov = [NSMutableSet set];
        
        [actions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
            FJSpringBoardCellAction* action = obj;
            
            [action finalizeType];
            
            switch (action.type) {
                case FJSpringBoardCellActionNone:
                    break;
                case FJSpringBoardCellActionInsert:
                    [ins addObject:action];
                    break;
                case FJSpringBoardCellActionDelete:
                    [del addObject:action];
                    break;
                case FJSpringBoardCellActionReload:
                    [rel addObject:action];
                    break;
                case FJSpringBoardCellActionMove:
                    [mov addObject:action];
                    break;
                default:
                    ALWAYS_ASSERT;
                    break;
            }
            
        }];
        
        self.reloads = [[rel allObjects] sortedArrayUsingSelector:@selector(compare:)];
        self.insertions = [[ins allObjects] sortedArrayUsingSelector:@selector(compare:)]; 
        self.deletions = [[del allObjects] sortedArrayUsingSelector:@selector(compare:)];
        self.moves = [[mov allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
    }
    
    return self;
}

@end
