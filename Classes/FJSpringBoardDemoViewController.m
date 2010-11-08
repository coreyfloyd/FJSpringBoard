

#import "FJSpringBoardDemoViewController.h"
#import "DemoModelObject.h"

#define CELL_COUNT 20
#define CELL_WIDTH 90
#define CELL_HEIGHT 90
@implementation FJSpringBoardDemoViewController

@synthesize model;
@synthesize springBoardView;


- (void)dealloc {
    [model release];
    model = nil;
    [springBoardView release];
    springBoardView = nil;
    
    [super dealloc];
}

- (IBAction)insert{
    
    DemoModelObject* o;
    
    o = [[DemoModelObject alloc] init];
    o.value = [self.model count];
    [self.model insertObject:o atIndex:4];
    [o release];
    o = [[DemoModelObject alloc] init];
    o.value = [self.model count];
    [self.model insertObject:o atIndex:5];
    [o release];
    
    [self.springBoardView insertCellsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(4, 2)] withCellAnimation:FJSpringBoardCellAnimationFade];

}



- (IBAction)deleteCells{
    
    [self.model removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
    [self.springBoardView deleteCellsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withCellAnimation:FJSpringBoardCellAnimationFade];
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray* a = [NSMutableArray arrayWithCapacity:CELL_COUNT];
    for (int i = 0; i < CELL_COUNT; i++) {
        
        DemoModelObject* o = [[DemoModelObject alloc] init];
        o.value = i;
        [a addObject:o];
        [o release];
        
    }
    
    self.model = a;
    
    CGRect f = self.view.bounds;
    f.origin.y += 40;
    f.size.height -= 40;
    self.springBoardView = [[FJSpringBoardView alloc] initWithFrame:f];
    self.springBoardView.backgroundColor = [UIColor redColor];
    self.springBoardView.cellSize = CGSizeMake(CELL_WIDTH, CELL_HEIGHT);
    self.springBoardView.springBoardInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    self.springBoardView.delegate = self;
    self.springBoardView.dataSource = self;
    self.springBoardView.scrollDirection = FJSpringBoardViewScrollDirectionHorizontal;
    
    [self.view addSubview:self.springBoardView];
    
    [self.springBoardView reloadData];
    
}

- (NSUInteger)numberOfCellsInSpringBoardView:(FJSpringBoardView *)springBoardView{
    
    return [model count];
    
}

- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index{
    
    static NSString* cellID = @"Cell";
    FJSpringBoardCell* cell = [self.springBoardView dequeueReusableCellWithIdentifier:cellID];
    
    if(cell == nil){
     
        cell = [[[FJSpringBoardCell alloc] initWithSize:CGSizeMake(CELL_WIDTH, CELL_HEIGHT) reuseIdentifier:cellID] autorelease];
        
        cell.contentView.backgroundColor = [UIColor blueColor];
        cell.backgroundView.backgroundColor = [UIColor blueColor];
        
        CGRect contentFrame = cell.contentView.bounds;

        UIView* b = [[UIView alloc] initWithFrame:contentFrame];
        b.backgroundColor = [UIColor blueColor];
        [cell.contentView addSubview:b];
        [b release];
        
        UILabel* l = [[UILabel alloc] initWithFrame:contentFrame];
        l.tag = 10101;
        [cell.contentView addSubview:l];
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [UIColor blueColor];
        l.textAlignment = UITextAlignmentCenter;
        [l release];
        
        
    }else{
     

    }
    
    DemoModelObject* o  = [self.model objectAtIndex:index];
    UILabel* l = (UILabel*)[cell.contentView viewWithTag:10101];
    l.text = [NSString stringWithFormat:@"%i", [o value]];
    cell.contentView.tag = [o value];
  
    return cell;
    
}

- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger )index{
    
    [self.model removeObjectAtIndex:index];
    NSLog(@"Cell Deleted at Index: %i", index);
    
}

- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasTappedAtIndex:(NSUInteger)index{
    
    NSLog(@"cell tapped at index: %i", index);
}    


- (void)springBoardView:(FJSpringBoardView *)springBoardView cellWasDoubleTappedAtIndex:(NSUInteger)index{
    
    NSLog(@"cell double tapped at index: %i", index);
    
}

- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex{
    
    id obj = [[self.model objectAtIndex:fromIndex] retain];
    [self.model removeObjectAtIndex:fromIndex];
    [self.model insertObject:obj atIndex:toIndex];
    [obj release];
}

- (FJSpringBoardGroupCell *)emptyGroupCellForSpringBoardView:(FJSpringBoardView *)springBoardView{
    
    static NSString* groupID = @"Group";
     FJSpringBoardGroupCell *cell = (FJSpringBoardGroupCell*)[self.springBoardView dequeueReusableCellWithIdentifier:groupID];
    
    if(cell == nil)
        cell = [[[FJSpringBoardGroupCell alloc] initWithSize:CGSizeMake(CELL_WIDTH, CELL_HEIGHT) reuseIdentifier:groupID] autorelease];
    
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
