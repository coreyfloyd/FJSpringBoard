//
//  FJSpringBoardAction.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardView.h"

typedef enum{
    FJSpringBoardActionReload,
    FJSpringBoardActionMove,
    FJSpringBoardActionInsert,
    FJSpringBoardActionDelete
    
}FJSpringBoardAction;


@interface FJSpringBoardActionItem : NSObject{
    
    NSIndexSet* affectedIndexes;
    FJSpringBoardAction action;
    FJSpringBoardCellAnimation animation;
    NSUInteger index;
    NSUInteger newIndex;    
    
}

@end
