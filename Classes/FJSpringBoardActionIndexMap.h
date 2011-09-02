//
//  FJSpringBoardActionIndexMap.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FJSpringBoardActionIndexMap : NSObject{
    
    NSMutableArray* oldToNew;
    NSMutableArray* newToOld;
    NSRange actionableIndexRange;
    
    NSArray* springBoardActions;
    NSMutableSet* cellActions; //actions are stored at the new index of a cell
    
}
//maps are created in the init method, I know, we should be lazy, but I am too lazy to be lazy.
- (id)initWithCellCount:(NSUInteger)count actionableIndexRange:(NSRange)indexRange springBoardActions:(NSArray*)actions;

- (NSSet*)mappedCellActions; //get actions



@end
