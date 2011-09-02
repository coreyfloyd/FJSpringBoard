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
        
    NSSet* reloads;
    NSSet* insertions;
    NSSet* deletions;
    NSSet* moves; //weird duck, couldd possibly include a reload
    
}
@property (nonatomic, copy) NSSet *reloads;
@property (nonatomic, copy) NSSet *insertions;
@property (nonatomic, copy) NSSet *deletions;
@property (nonatomic, copy) NSSet *moves;

- (id)initWithCellActions:(NSSet*)actions;




@end
