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

            if(action.oldSpringBoardIndex == NSNotFound && action.newSpringBoardIndex == NSNotFound){
                
                //cell is being inserted and subsequesntly deleted. should be rare
                
                NSLog(@"cell inserted and deleted in smae update batch!");;
                
                
            }else if(action.oldSpringBoardIndex == NSNotFound && action.newSpringBoardIndex != NSNotFound){
                
                //this is a new cell it is not on screen
                [ins addObject:action];
                

            }else if(action.oldSpringBoardIndex != NSNotFound && action.newSpringBoardIndex == NSNotFound){
                
                //cell is being deleted
                [del addObject:action];

                
            }else if(action.oldSpringBoardIndex == action.newSpringBoardIndex){

                //cell is being reloaded
                [rel addObject:action];

                
            }else if(action.oldSpringBoardIndex != NSNotFound && action.newSpringBoardIndex != NSNotFound){
                
                //cell is being moved
                [mov addObject:action];

            }else{
                
                ALWAYS_ASSERT;
            }
            
        }];
        
        self.reloads = rel;
        self.insertions = ins;
        self.deletions = del;
        self.moves = mov;
        
    }
    
    return self;
}

@end
