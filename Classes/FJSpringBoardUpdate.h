//
//  FJSpringBoardUpdate.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"

@interface FJSpringBoardUpdate : SMModelObject{
        
    NSArray* reloads;
    NSArray* insertions;
    NSArray* deletions;
    NSArray* moves; //weird duck, couldd possibly include a reload
    
}
@property (nonatomic, copy) NSArray *reloads;
@property (nonatomic, copy) NSArray *insertions;
@property (nonatomic, copy) NSArray *deletions;
@property (nonatomic, copy) NSArray *moves;

- (id)initWithCellActions:(NSSet*)actions;




@end
