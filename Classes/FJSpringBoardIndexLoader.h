//
//  FJSpringBoardIndexLoader.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum  {
    FJSpringBoardLayoutDirectionVertical,
    FJSpringBoardLayoutDirectionHorizontal
} FJSpringBoardLayoutDirection;

typedef struct {
    NSRange fullIndexRange;
    NSRange indexRangeToAdd;
    NSRange indexRangeToRemove;
} IndexRangeChanges;


@interface FJSpringBoardIndexLoader : NSObject {

    FJSpringBoardLayoutDirection layoutDirection;
    FJSpringBoardLayout *layout;

}
@property(nonatomic) FJSpringBoardLayoutDirection layoutDirection; // default = vertical
@property (nonatomic, retain) FJSpringBoardLayout *layout;

- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset;





@end
