//
//  FJSpringBoardHorizontalLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FJSpringBoardLayout.h"

@interface FJSpringBoardHorizontalLayout : FJSpringBoardLayout {

    NSInteger rowsPerPage;
    NSInteger cellsPerPage;
    
    CGSize pageSize;
    CGSize pageSizeWithInsetsApplied;
    
}


- (CGRect)frameForPage:(NSInteger)page;

- (NSInteger)numberOfPages; 

- (NSIndexSet*)cellIndexesForPage:(NSInteger)page;

- (CGRect)pageRelativeFrameForCellAtIndex:(NSInteger)index;

@end
