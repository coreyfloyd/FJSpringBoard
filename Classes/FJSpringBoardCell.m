
#import "FJSpringBoardCell.h"
#import "FJSpringBoardView.h"
#import <QuartzCore/QuartzCore.h>

CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

NSNumber* DegreesToNumber(CGFloat degrees) {
    return [NSNumber numberWithFloat: DegreesToRadians(degrees)];
}

CAAnimation* wiggleAnimation() {
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"]; 
    [animation setDuration:0.2];
    [animation setRepeatCount:10000];
    // Try to get the animation to begin to start with a small offset // that makes it shake out of sync with other layers. srand([[NSDate date] timeIntervalSince1970]); float rand = (float)random();
    [animation setBeginTime: CACurrentMediaTime() + rand() * .0000000001];
    
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    NSMutableArray *values = [NSMutableArray array]; // Turn right
    [values addObject:DegreesToNumber(-2)]; // Turn left
    [values addObject:DegreesToNumber(2)]; // Turn right
    [values addObject:DegreesToNumber(-2)]; // Set the values for the animation
    [animation setValues:values]; 

    return animation;
}

void recursivelyApplyAnimationToAllSubviewLayers(UIView* view, CAAnimation* animation, NSString* keyPath){
    
    [view.layer addAnimation:animation forKey:keyPath];

    for(UIView* each in view.subviews){
                
        recursivelyApplyAnimationToAllSubviewLayers(each, animation, keyPath);
        
    }
}

void recursivelyRemoveAnimationFromAllSubviewLayers(UIView* view, NSString* keyPath){
    
    [view.layer removeAnimationForKey:keyPath];

    for(UIView* each in view.subviews){
        
        recursivelyRemoveAnimationFromAllSubviewLayers(each, keyPath);
        
    }
}

@interface FJSpringBoardView(CellInternal)

- (void)_deleteCell:(FJSpringBoardCell*)cell;

- (void)cellWasTapped:(FJSpringBoardCell*)cell;
- (void)cellWasLongTapped:(FJSpringBoardCell*)cell;
- (void)cell:(FJSpringBoardCell*)cell longTapMovedToLocation:(CGPoint)newLocation;
- (void)cellLongTapEnded:(FJSpringBoardCell*)cell;

@end


@interface FJSpringBoardCell()

@property(nonatomic, assign) FJSpringBoardView* springBoardView;

@property (nonatomic, retain, readwrite) UIView *contentView;

@property (nonatomic, copy, readwrite) NSString *reuseIdentifier;

@property(nonatomic, readwrite) BOOL reordering;

@property(nonatomic) BOOL draggable;
@property(nonatomic) BOOL showsDeleteButton;

@property(nonatomic) BOOL tappedAndHeld;

@property(nonatomic) NSUInteger index;

- (void)_startWiggle;
- (void)_stopWiggle;
- (void)_removeDeleteButton;
- (void)_addDeleteButton;
- (void)_updateView;

@property(nonatomic, retain) UILongPressGestureRecognizer *tapAndHoldRecognizer;
@property(nonatomic, retain) UITapGestureRecognizer *singleTapRecognizer;
@property(nonatomic, retain) UILongPressGestureRecognizer *editingModeRecognizer;
@property(nonatomic, retain) UILongPressGestureRecognizer *draggingSelectionRecognizer;
@property(nonatomic, retain) UIPanGestureRecognizer *draggingRecognizer;

- (void)_processEditingLongTapWithRecognizer:(UIGestureRecognizer*)g;

@end


static UIImage* _deleteImage = nil;
static UIColor* _defaultBackgroundColor = nil;

@implementation FJSpringBoardCell


@synthesize backgroundView;
@synthesize contentView;
@synthesize reuseIdentifier;
@synthesize mode;
@synthesize selectionModeImageView;
@synthesize selectedImageView;
@synthesize glowsOnTap;
@synthesize selected;
@synthesize deleteImage;
@synthesize springBoardView;
@synthesize reordering;
@synthesize showsDeleteButton;
@synthesize draggable;
@synthesize tappedAndHeld;
@synthesize index;
@synthesize tapAndHoldRecognizer;
@synthesize singleTapRecognizer;
@synthesize editingModeRecognizer;
@synthesize draggingSelectionRecognizer;
@synthesize draggingRecognizer;

- (void) dealloc
{
    [tapAndHoldRecognizer release];
    tapAndHoldRecognizer = nil;
    [singleTapRecognizer release];
    singleTapRecognizer = nil;
    [editingModeRecognizer release];
    editingModeRecognizer = nil;
    [draggingSelectionRecognizer release];
    draggingSelectionRecognizer = nil;
    [draggingRecognizer release];
    draggingRecognizer = nil;
    [backgroundView release];
    backgroundView = nil;
    springBoardView = nil;
    [contentView release];
    contentView = nil;
    [reuseIdentifier release];
    reuseIdentifier = nil;
    [selectionModeImageView release];
    selectionModeImageView = nil;
    [selectedImageView release];
    selectedImageView = nil;
    [deleteImage release];
    deleteImage = nil;
    [super dealloc];
}

+ (void)initialize{
    
    _deleteImage = [[UIImage imageNamed:@"close.png"] retain];
    _defaultBackgroundColor = [UIColor clearColor];
    
}


- (id)initWithContentSize:(CGSize)size reuseIdentifier:(NSString*)identifier{
    
    CGRect minFrame;
    minFrame.origin = CGPointZero;
    minFrame.size = size;
    minFrame.size.width += CELL_INVISIBLE_TOP_MARGIN;
    minFrame.size.height += CELL_INVISIBLE_LEFT_MARGIN;
    
    self = [super initWithFrame:minFrame];
    if (self != nil) {
                
        CGRect contentFrame;
        contentFrame.origin.x = CELL_INVISIBLE_LEFT_MARGIN;
        contentFrame.origin.y = CELL_INVISIBLE_TOP_MARGIN;
        contentFrame.size = size;
                        
        self.backgroundColor = [UIColor clearColor];
        
        self.backgroundView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
        self.backgroundView.backgroundColor = _defaultBackgroundColor;
        [self addSubview:self.backgroundView];

        self.contentView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.contentView];
        
        self.showsDeleteButton = YES;
        self.reuseIdentifier = identifier;
        
        UILongPressGestureRecognizer* g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(updateTapAndHold:)];
        g.minimumPressDuration = 0.1;
        g.delegate = self;
        g.cancelsTouchesInView = NO;
        [self addGestureRecognizer:g];
        self.tapAndHoldRecognizer = g;
        [g release];
        
        
        UITapGestureRecognizer* t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
        [self addGestureRecognizer:t];
        self.singleTapRecognizer = t;
        [t release];
        
        UILongPressGestureRecognizer* l = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editingLongTapRecieved:)];
        l.minimumPressDuration = 0.75;
        [self addGestureRecognizer:l];
        self.editingModeRecognizer = l;
        [l release];
        
        
        l = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingSelectionLongTapReceived:)];
        l.minimumPressDuration = 0.1;
        l.cancelsTouchesInView = NO;
        [self addGestureRecognizer:l];
        self.draggingSelectionRecognizer = l;
        [l release];
        
    
        UIPanGestureRecognizer* p = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanningGestureReceived:)];
        p.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:p];
        self.draggingRecognizer = p;
        [p release]; 
    

    }
    return self;
    
}  


- (void)prepareForReuse{
    
    self.mode = FJSpringBoardCellModeNormal;
    self.reordering = NO;
    self.selected = NO;
    self.draggable = NO;
    self.tappedAndHeld = NO;
    
}

- (void)delete{
    debugLog(@"deleted!");
    
    [self.springBoardView _deleteCell:self];
    
}


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
    if(aMode == FJSpringBoardCellModeNormal){
        
        self.singleTapRecognizer.enabled = YES;
        self.editingModeRecognizer.enabled = YES;
        self.draggingRecognizer.enabled = NO;
        self.draggingSelectionRecognizer.enabled = NO;
        
    }else{
        
        self.singleTapRecognizer.enabled = NO;
        self.editingModeRecognizer.enabled = YES; //to get the first drag
        self.draggingRecognizer.enabled = YES;
        self.draggingSelectionRecognizer.enabled = YES;
    }

    if(mode == aMode)
        return;
        
    mode = aMode;
    
    [self _updateView];
    
}


- (void)setReordering:(BOOL)flag{
    
    if(reordering == flag)
        return;
    
    reordering = flag;
    
    [self _updateView];
    
}

- (void)setSelected:(BOOL)flag{
    
    if(selected == flag)
        return;
    
    selected = flag;
    
    [self _updateView];
    
}

- (void)setSelected:(BOOL)flag animated:(BOOL)animated{
    
    if(selected == flag)
        return;
    
    selected = flag;
    
    if(animated)
        [UIView beginAnimations:@"SelectionAnimation" context:nil];
    
    [self _updateView];
    
    if(animated)
        [UIView commitAnimations];
    
}

- (void)setTappedAndHeld:(BOOL)flag{
    
    if(tappedAndHeld == flag)
        return;
    
    tappedAndHeld = flag;

    [self _updateView];

}

- (void)setDraggable:(BOOL)flag{
    
    if(draggable == flag)
        return;
    
    draggable = flag;

    [self _updateView];

}

- (void)setShowsDeleteButton:(BOOL)flag{
    
    if(showsDeleteButton == flag)
        return;
    
    showsDeleteButton = flag;

    [self _updateView];

}


- (void)_addDeleteButton{
    
    if(self.deleteImage == nil){
        
        self.deleteImage = _deleteImage;
    }
    
    UIButton* b  = (UIButton*)[self viewWithTag:1001];

    if(b == nil)
        b  = [UIButton buttonWithType:UIButtonTypeCustom];
    
    b.tag = 1001;
    b.frame = CGRectMake(0, 0, 44, 44);
    b.center = self.contentView.frame.origin;
    [b setImage:self.deleteImage forState:UIControlStateNormal];
    b.contentMode = UIViewContentModeCenter;
    //[b setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 14, 14)];
    [b addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
    [self insertSubview:b aboveSubview:self.contentView];
    
}

- (void)_removeDeleteButton{
    
    [[self viewWithTag:1001] removeFromSuperview];
}

- (void)_startWiggle{
    CAAnimation *wiggle = wiggleAnimation();
    recursivelyApplyAnimationToAllSubviewLayers(self, wiggle, @"wiggle");	    

}

- (void)_stopWiggle{
    recursivelyRemoveAnimationFromAllSubviewLayers(self, @"wiggle");
}

- (CAAnimation*)_wiggleAnimation {
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"]; 
    [animation setDuration:0.2];
    [animation setRepeatCount:10000];
    // Try to get the animation to begin to start with a small offset // that makes it shake out of sync with other layers. srand([[NSDate date] timeIntervalSince1970]); float rand = (float)random();
    [animation setBeginTime: CACurrentMediaTime() + rand() * .0000000001];
    
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
      
    NSMutableArray *values = [NSMutableArray array]; // Turn right
    [values addObject:DegreesToNumber(-2)]; // Turn left
    [values addObject:DegreesToNumber(2)]; // Turn right
    [values addObject:DegreesToNumber(-2)]; // Set the values for the animation
    [animation setValues:values]; 
    return animation;
    
}


- (void)_updateView{
    
    if(mode == FJSpringBoardCellModeEditing){
        
        if(draggable)
            [self _startWiggle];
        
        if(showsDeleteButton)
            [self _addDeleteButton];
        
    }else if(mode == FJSpringBoardCellModeNormal){
        
        [self _stopWiggle];
        [self _removeDeleteButton];
    }
    
    
    if(reordering){
        
        self.alpha = 0;
        
    }else{
        
        if(selected){
            
            self.alpha = 1;
            //TODO: show selection

        }else if(tappedAndHeld){
         
            self.alpha = CELL_DRAGGABLE_ALPHA;

        }else{
         
            self.alpha = 1;

        }
        
    }
    
}

#pragma mark -
#pragma mark Touches

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    return YES;
    
}


- (void)didSingleTap:(UITapGestureRecognizer*)g{
    
    [self setSelected:YES];
    
    [self.springBoardView cellWasTapped:self];
    
}

- (void)updateTapAndHold:(UIGestureRecognizer*)g{
        
    if(g.state == UIGestureRecognizerStateBegan){
        
        [self setTappedAndHeld:YES];
        
    }else if(g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || g.state == UIGestureRecognizerStateFailed){
        
        [self setTappedAndHeld:NO];
        
    }
}



- (void)editingLongTapRecieved:(UILongPressGestureRecognizer*)g{
    
    [self setSelected:NO];
    [self setTappedAndHeld:NO];
    
    [self.springBoardView cellWasLongTapped:self];
    
}


- (void)draggingSelectionLongTapReceived:(UILongPressGestureRecognizer*)g{
    
    [self _processEditingLongTapWithRecognizer:g];
}



- (void)dragPanningGestureReceived:(UIPanGestureRecognizer*)g{
    
    [self _processEditingLongTapWithRecognizer:g];
}


- (void)_processEditingLongTapWithRecognizer:(UIGestureRecognizer*)g{
    
    if(g.state == UIGestureRecognizerStateBegan){
        
        [springBoardView cellWasLongTapped:self];
        
    }
    
    //ok, we are still moving, update the drag cell and then check if we should reorder or animate a folder
    if(g.state == UIGestureRecognizerStateChanged){
        
        CGPoint p = [g locationInView:self];
        
        [springBoardView cell:self longTapMovedToLocation:p];
        
        return;
    }
    
    //we are done lets reorder or add to folder
    if(g.state == UIGestureRecognizerStateEnded){
        
        [springBoardView cellLongTapEnded:self];
        
        return;
    }
    
    //we failed to start panning, lets clean up
    if(g.state == UIGestureRecognizerStateFailed || g.state == UIGestureRecognizerStateCancelled){
        
        [springBoardView cellLongTapEnded:self];
        
        return;
    }
    
    if(g.state == UIGestureRecognizerStatePossible){
        
        [springBoardView cellLongTapEnded:self];
        
        return;
    }
    
}

    
@end



