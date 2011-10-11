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

- (NSIndexSet*)visibleCellIndexesWithPaddingForContentOffset:(CGPoint)offset;
- (NSIndexSet*)visibleCellIndexesForContentOffset:(CGPoint)offset;

- (NSUInteger)rowForCellAtIndex:(NSUInteger)index;
- (CGRect)frameForRow:(NSUInteger)row;

@end
