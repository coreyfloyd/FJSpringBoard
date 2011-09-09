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
    UIBarButtonItem *doneButton;
    UIToolbar *doneBar;
    UIBarButtonItem *directionButton;
    
    NSArray* colors;
}
@property(nonatomic, retain) NSMutableArray *model;
@property (nonatomic, retain) FJSpringBoardView *springBoardView;

- (IBAction)insert;
- (IBAction)deleteCells;
- (IBAction)reload:(id)sender;

@property (nonatomic, copy) NSArray *colors;
@property (nonatomic, retain) IBOutlet UIToolbar *doneBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
- (IBAction)doneEditing;

- (IBAction)scroll:(id)sender;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *directionButton;
- (IBAction)switchDirection:(id)sender;

@end

