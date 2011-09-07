//
//  FJSpringBoardActionItem.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

/*
 FJSpringBoardActionItem is used by FJSpringBoardAction to hold and calculate information about individual indexes of an action
*/

#import "SMModelObject.h"

@interface FJSpringBoardActionItem : SMModelObject{
    
    NSUInteger index;
}
@property (nonatomic) NSUInteger index;

@end
