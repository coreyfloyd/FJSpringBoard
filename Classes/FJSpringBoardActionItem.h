//
//  FJSpringBoardActionItem.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "SMModelObject.h"

@interface FJSpringBoardActionItem : SMModelObject{
    
    NSUInteger index;
    NSUInteger newIndex;
    NSRange affectedRange;
}
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSUInteger newIndex;
@property (nonatomic) NSRange affectedRange;

- (void)updatedAffectedRangeWithIndexCount:(NSUInteger)numberOfIndexes;

@end
