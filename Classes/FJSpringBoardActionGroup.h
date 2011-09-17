//
//  FJSpringBoardActionGroup.h
//  Vimeo
//
//  Created by Corey Floyd on 9/15/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"
#import "FJSpringBoardAction.h"

@interface FJSpringBoardActionGroup : SMModelObject{
    
    NSArray* cellStateBeforeAction;
    
    NSMutableSet* reloadActions;
    NSMutableSet* deleteActions;
    NSMutableSet* insertActions;
    
    BOOL locked;
}
@property (nonatomic, copy) NSArray *cellStateBeforeAction;
@property (nonatomic, retain) NSMutableSet *reloadActions;
@property (nonatomic, retain) NSMutableSet *deleteActions;
@property (nonatomic, retain) NSMutableSet *insertActions;
@property (nonatomic, getter=isLocked, readonly) BOOL locked;


- (id)initWithBeginningCellState:(NSArray*)cellState;

- (void)addActionWithType:(FJSpringBoardActionType)type indexes:(NSIndexSet*)indexSet animation:(FJSpringBoardCellAnimation)animation;

- (void)lock;

@end
