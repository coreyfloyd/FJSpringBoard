//
//  FJGridViewViewController.m
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardDemoViewController.h"

@implementation FJSpringBoardDemoViewController

@synthesize springBoardView;


- (void)dealloc {
    
    [springBoardView release];
    springBoardView = nil;
    
    [super dealloc];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.springBoardView = [[FJSpringBoardView alloc] initWithFrame:self.view.bounds];
    self.springBoardView.backgroundColor = [UIColor redColor];
    self.springBoardView.cellSize = CGSizeMake(60, 60);
    self.springBoardView.horizontalCellSpacing = 10;
    self.springBoardView.verticalCellSpacing = 10;
    self.springBoardView.gridViewInsets = UIEdgeInsetsMake(15, 10, 15, 10);
    self.springBoardView.delegate = self;
    self.springBoardView.dataSource = self;
    
    [self.view addSubview:self.springBoardView];
    
    [self.springBoardView reloadData];
    
}

- (NSUInteger)numberOfCellsInGridView:(FJSpringBoardView *)gridView{
    
    return 60;
    
}

- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView cellAtIndex:(NSUInteger )index{
    
    static NSString* cellID = @"Cell";
    FJSpringBoardCell* cell = [[FJSpringBoardCell alloc] initWithContentSize:CGSizeMake(60, 60) reuseIdentifier:cellID];
    
    cell.contentView.backgroundColor = [UIColor blueColor];
    
    return cell;
    
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end
