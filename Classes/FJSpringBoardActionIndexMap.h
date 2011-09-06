//
//  FJSpringBoardActionIndexMap.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"

@interface FJSpringBoardActionIndexMap : SMModelObject{
    
    NSMutableArray* oldToNew;
    NSMutableArray* newToOld;
    NSRange actionableIndexRange;
    
    NSArray* springBoardActions;
    NSMutableSet* cellActions;
    
}
//maps are created in the init method, I know, we should be lazy, but I am too lazy to be lazy.
- (id)initWithCellCount:(NSUInteger)count actionableIndexRange:(NSRange)indexRange springBoardActions:(NSArray*)actions;

- (NSSet*)mappedCellActions; //get actions



@end
