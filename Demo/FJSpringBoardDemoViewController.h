//
//  FJGridViewViewController.h
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FJSpringBoardView.h"

@interface FJSpringBoardDemoViewController : UIViewController <FJSpringBoardViewDelegate, FJSpringBoardViewDataSource, UIScrollViewDelegate> {

    NSMutableArray* model;
    FJSpringBoardView* springBoardView;
    UIToolbar *doneButton;
    UIToolbar *doneBar;
}
@property(nonatomic, retain) NSMutableArray *model;
@property (nonatomic, retain) FJSpringBoardView *springBoardView;

- (IBAction)insert;
- (IBAction)deleteCells;

@property (nonatomic, retain) IBOutlet UIToolbar *doneBar;
@property (nonatomic, retain) IBOutlet UIToolbar *doneButton;
- (IBAction)doneEditing;

- (IBAction)scroll:(id)sender;

@end

