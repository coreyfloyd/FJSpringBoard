//
//  FJSpringBoardIndexLoader.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJSpringBoardUtilities.h"

@class FJSpringBoardLayout;

@interface FJSpringBoardIndexLoader : NSObject {

    FJSpringBoardLayout *layout;
    
    CGPoint contentOffset;
    NSIndexSet* currentIndexes;
    IndexRangeChanges lastChangeSet;
    
    NSUInteger currentPage;

}
@property (nonatomic, retain) FJSpringBoardLayout *layout;


- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset;
@property(nonatomic, readonly) CGPoint contentOffset;

@property(nonatomic, retain, readonly) NSIndexSet *currentIndexes;
@property(nonatomic, readonly) IndexRangeChanges lastChangeSet;




@end
