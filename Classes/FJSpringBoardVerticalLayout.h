//
//  FJSpringBoardVerticalLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FJSpringBoardLayout.h"

@interface FJSpringBoardVerticalLayout : FJSpringBoardLayout {

    
}

- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset;

- (NSIndexSet*)visibleCellIndexesWithPaddingForContentOffset:(CGPoint)offset; //gives indexes with 1 row of padding on top and bottom



@end
