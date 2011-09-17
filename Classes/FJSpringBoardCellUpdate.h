//
//  FJSpringBoardCellUpdate.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

/*
 FJSpringBoardCellUpdate is the encapsulates the update of an individual cell. FJSpringBoardUpdate is comprised of one or more FJSpringBoardCellUpdates.
*/


#import <Foundation/Foundation.h>
#import "FJSpringBoardView.h"
#import <QuartzCore/QuartzCore.h>
#import "SMModelObject.h"

@class FJSpringBoardCell;
@class FJSpringBoardLayout;

typedef enum{
    FJSpringBoardCellupdateNone = 0,
    FJSpringBoardCellupdateReload,
    FJSpringBoardCellupdateMove,
    FJSpringBoardCellupdateInsert,
    FJSpringBoardCellupdateDelete
    
}FJSpringBoardCellupdateType;

@interface FJSpringBoardCellUpdate : SMModelObject{

    FJSpringBoardCellupdateType type;
    FJSpringBoardCellAnimation animation;
    NSUInteger oldSpringBoardIndex; //original index of cell on the springboard, if NSNotFound this is a new cell
    NSUInteger newSpringBoardIndex; //index that the cell will be moved to, if NSNotFound this cell is being deleted, can be used to get info from the model
    
}
@property (nonatomic) FJSpringBoardCellupdateType type; //not set, but calculated after all actions are applied
@property (nonatomic) FJSpringBoardCellAnimation animation;
@property (nonatomic) NSUInteger oldSpringBoardIndex;
@property (nonatomic) NSUInteger newSpringBoardIndex;


- (NSComparisonResult)compare:(FJSpringBoardCellUpdate*)anAction;

//- (void)applyActionToCell:(FJSpringBoardCell*)cell inLayout:(FJSpringBoardLayout*)layout;

@end

