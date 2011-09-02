//
//  FJSpringBoardCellAction.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/1/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardView.h"
#import <QuartzCore/QuartzCore.h>
#import "SMModelObject.h"

@class FJSpringBoardCell;
@class FJSpringBoardLayout;



@interface FJSpringBoardCellAction : SMModelObject{

    BOOL needsLoaded; //should load a new cell from the model and replace the existing n the springboard
    FJSpringBoardCellAnimation animation;
    NSUInteger oldSpringBoardIndex; //original index of cell on the springboard, if NSNotFound this is a new cell
    NSUInteger newSpringBoardIndex; //index that the cell will be moved to, if NSNotFound this cell is being deleted, can be used to get info from the model
    
}
@property (nonatomic, readonly) BOOL needsLoaded;
@property (nonatomic) FJSpringBoardCellAnimation animation;
@property (nonatomic) NSUInteger oldSpringBoardIndex;
@property (nonatomic) NSUInteger newSpringBoardIndex;

- (void)markNeedsLoaded;


//- (void)applyActionToCell:(FJSpringBoardCell*)cell inLayout:(FJSpringBoardLayout*)layout;

@end

