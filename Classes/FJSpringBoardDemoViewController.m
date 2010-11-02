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
@synthesize count;


- (void)dealloc {
    
    [springBoardView release];
    springBoardView = nil;
    
    [super dealloc];
}

- (IBAction)insert{
    
    self.count += 2;

    [self.springBoardView insertCellsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withCellAnimation:FJSpringBoardCellAnimationFade];
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.count = 16;
    
    CGRect f = self.view.bounds;
    f.origin.y += 40;
    f.size.height -= 40;
    self.springBoardView = [[FJSpringBoardView alloc] initWithFrame:f];
    self.springBoardView.backgroundColor = [UIColor redColor];
    self.springBoardView.cellSize = CGSizeMake(100, 150);
    self.springBoardView.horizontalCellSpacing = 20;
    self.springBoardView.verticalCellSpacing = 20;
    self.springBoardView.springBoardInsets = UIEdgeInsetsMake(15, 10, 15, 10);
    self.springBoardView.delegate = self;
    self.springBoardView.dataSource = self;
    self.springBoardView.scrollDirection = FJSpringBoardViewScrollDirectionHorizontal;
    
    [self.view addSubview:self.springBoardView];
    
    [self.springBoardView reloadData];
    
}

- (NSUInteger)numberOfCellsInGridView:(FJSpringBoardView *)gridView{
    
    return self.count;
    
}

- (FJSpringBoardCell *)gridView:(FJSpringBoardView *)gridView cellAtIndex:(NSUInteger )index{
    
    static NSString* cellID = @"Cell";
    FJSpringBoardCell* cell = [self.springBoardView dequeueReusableCellWithIdentifier:cellID];
    
    if(cell == nil){
     
        cell = [[FJSpringBoardCell alloc] initWithContentSize:CGSizeMake(100, 150) reuseIdentifier:cellID];\
        
        UILabel* l = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
        l.tag = 99;
        [cell.contentView addSubview:l];
        l.textColor = [UIColor blackColor];
        l.backgroundColor = [UIColor clearColor];
        l.textAlignment = UITextAlignmentCenter;
        [l release];
        
        cell.contentView.backgroundColor = [UIColor blueColor];
        
    }else{
     
        cell.contentView.backgroundColor = [UIColor greenColor];

    }
    
    UILabel* l = (UILabel*)[cell.contentView viewWithTag:99];
    l.text = [NSString stringWithFormat:@"%i", index];
  
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
