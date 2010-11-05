//
//  FJGridViewViewController.h
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FJSpringBoardView.h"

@interface FJSpringBoardDemoViewController : UIViewController <FJSpringBoardViewDelegate, FJSpringBoardViewDataSource> {

    NSMutableArray* model;
    FJSpringBoardView* springBoardView;
}
@property(nonatomic, retain) NSMutableArray *model;
@property (nonatomic, retain) FJSpringBoardView *springBoardView;

- (IBAction)insert;
- (IBAction)deleteCells;

@end

