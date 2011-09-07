//
//  IndexMapItem.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 9/2/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

/*
 FJIndexMapItem is used by FJSpringBoardActionIndexMap to define index mappings between pre and post update states.
*/


#import "SMModelObject.h"

@interface FJIndexMapItem : SMModelObject{
    
    NSUInteger mappedIndex;
}
@property (nonatomic) NSUInteger mappedIndex;

@end
