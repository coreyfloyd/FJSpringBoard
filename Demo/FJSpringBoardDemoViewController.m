

#import "FJSpringBoardDemoViewController.h"
#import "DemoModelObject.h"
#import "FJSpringBoardCell.h"

#define CELL_COUNT 400
#define CELL_WIDTH 57
#define CELL_HEIGHT 57

@implementation FJSpringBoardDemoViewController

@synthesize directionButton;
@synthesize doneBar;
@synthesize doneButton;
@synthesize model;
@synthesize springBoardView;
@synthesize colors;



- (void)dealloc {
    [colors release];
    colors = nil;
    [model release];
    model = nil;
    [springBoardView release];
    springBoardView = nil;
    
    [doneButton release];
    [doneBar release];
    [directionButton release];
    [super dealloc];
}

- (IBAction)insert{
    
    
    NSMutableIndexSet *is = [NSMutableIndexSet indexSet];
    [is addIndex:3];
    [is addIndex:30];
    
    DemoModelObject* o = [[DemoModelObject alloc] init];
    o.value = [self.model count];
    DemoModelObject* p = [[DemoModelObject alloc] init];
    p.value = [self.model count] + 1;
    
    NSArray* a = [NSArray arrayWithObjects:o,p,nil];
    [o release];
    [p release];
    
    [self.model insertObjects:a atIndexes:is];

    [self.springBoardView insertCellsAtIndexes:is withCellAnimation:FJSpringBoardCellAnimationFade];

}



- (IBAction)deleteCells{
        
    NSMutableIndexSet *is = [NSMutableIndexSet indexSet];
    [is addIndex:3];
    [is addIndex:30];
    
    [self.model removeObjectsAtIndexes:is];
    
    [self.springBoardView deleteCellsAtIndexes:is withCellAnimation:FJSpringBoardCellAnimationFade];
    
}

- (IBAction)doneEditing{
    
    self.springBoardView.mode = FJSpringBoardCellModeNormal;
}

- (IBAction)scroll:(id)sender {
    
    [self.springBoardView scrollToCellAtIndex:20 atScrollPosition:FJSpringBoardCellScrollPositionMiddle animated:YES];
    
}

- (IBAction)switchDirection:(id)sender {
    
    if(self.springBoardView.scrollDirection == FJSpringBoardViewScrollDirectionHorizontal){
        
        self.springBoardView.scrollDirection = FJSpringBoardViewScrollDirectionVertical;

    }else{
        
        self.springBoardView.scrollDirection = FJSpringBoardViewScrollDirectionHorizontal;

    }
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray* c = [NSArray arrayWithObjects:[UIColor redColor], [UIColor blueColor], [UIColor greenColor], [UIColor orangeColor], [UIColor purpleColor], nil];
    self.colors = c;
    
    NSMutableArray* a = [NSMutableArray arrayWithCapacity:CELL_COUNT];
    for (int i = 0; i < CELL_COUNT; i++) {
        
        DemoModelObject* o = [[DemoModelObject alloc] init];
        o.value = i;
        [a addObject:o];
        [o release];
        
    }
    
    self.model = a;
    
    CGRect f = self.view.bounds;
    f.origin.y += 44;
    f.size.height -= 88;
    self.springBoardView = [[FJSpringBoardView alloc] initWithFrame:f];
    self.springBoardView.backgroundColor = [UIColor lightGrayColor];
    self.springBoardView.cellSize = CGSizeMake(CELL_WIDTH, CELL_HEIGHT);
    //self.springBoardView.pageInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    self.springBoardView.delegate = self;
    self.springBoardView.dataSource = self;
    self.springBoardView.scrollDirection = FJSpringBoardViewScrollDirectionHorizontal;
    
    [self.view addSubview:self.springBoardView];
    
    [self.springBoardView reloadData];
    
    [self.doneBar setItems:[NSArray arrayWithObject:self.directionButton] animated:NO];
    [self.springBoardView addObserver:self forKeyPath:@"mode" options:0 context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if(self.springBoardView.mode == FJSpringBoardCellModeEditing){
        
        UIBarButtonItem* i  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        [self.doneBar setItems:[NSArray arrayWithObjects:self.directionButton, i, self.doneButton, nil] animated:YES];
        
        [i release];

    }else{
        
        [self.doneBar setItems:[NSArray arrayWithObject:self.directionButton] animated:NO];

    }
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

        /*
        UIView* b = [[UIView alloc] initWithFrame:contentFrame];
        b.backgroundColor = [UIColor blueColor];
        [cell.contentView addSubview:b];
        [b release];
        */
        
        UILabel* l = [[UILabel alloc] initWithFrame:contentFrame];
        l.tag = 10101;
        [cell.contentView addSubview:l];
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [UIColor clearColor];
        l.textAlignment = UITextAlignmentCenter;
        [l release];
        
        
    }else{
     

    }
    

    
    DemoModelObject* o  = [self.model objectAtIndex:index];
    UIColor* c = [self.colors objectAtIndex:(o.value % [self.colors count])];
    cell.contentView.backgroundColor = c;
    UILabel* l = (UILabel*)[cell.contentView viewWithTag:10101];
    l.text = [NSString stringWithFormat:@"%i", [o value]];
    cell.contentView.tag = [o value];
  
    return cell;
    
}

- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger )index{
    
    [self.model removeObjectAtIndex:index];
}


- (void)springBoardView:(FJSpringBoardView *)springBoardView didSelectCellAtIndex:(NSUInteger)index{
    
    NSLog(@"cell tapped at index: %i", index);
}    

- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger )fromIndex toIndex:(NSUInteger )toIndex{
    
    id obj = [[self.model objectAtIndex:fromIndex] retain];
    [self.model removeObjectAtIndex:fromIndex];
    [self.model insertObject:obj atIndex:toIndex];
    [obj release];
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
    [self setDirectionButton:nil];
    [self setDoneBar:nil];
    [self setDoneButton:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end
