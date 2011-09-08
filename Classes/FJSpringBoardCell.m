
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

@property(nonatomic,retain) UIView *selectionView;

@property (nonatomic, retain) UIButton *deleteButton;

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
@synthesize deleteButton;
@synthesize selectedBackgroundView;
@synthesize selectionStyle;
@synthesize selectionView;

- (void) dealloc
{
    [selectionView release];
    selectionView = nil;
    [selectedBackgroundView release];
    selectedBackgroundView = nil;
    [deleteButton release];
    deleteButton = nil;
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
    [deleteImage release];
    deleteImage = nil;
    [super dealloc];
}

+ (void)initialize{
    
    _deleteImage = [[UIImage imageNamed:@"close.png"] retain];
    _defaultBackgroundColor = [UIColor whiteColor];
    
}


- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier{
    
    CGRect minFrame;
    minFrame.origin = CGPointZero;
    minFrame.size = size;
    
    self = [super initWithFrame:minFrame];
    if (self != nil) {
                
        CGRect contentFrame = minFrame;
                        
        self.backgroundColor = [UIColor clearColor];
        
        self.contentView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
        self.contentView.backgroundColor = _defaultBackgroundColor;
        contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        [self addSubview:self.contentView];
        
        self.backgroundView = [[[UIView alloc] initWithFrame:contentFrame] autorelease]; //adds to view
        self.backgroundView.backgroundColor = _defaultBackgroundColor;

#ifdef DEBUG_LAYOUT
        
        self.backgroundColor = [UIColor greenColor];
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 2.0;
        self.backgroundView.backgroundColor = [UIColor yellowColor];
        self.contentView.layer.borderColor = [UIColor orangeColor].CGColor;
        self.contentView.layer.borderWidth = 2.0;
        
#endif
        
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
        l.minimumPressDuration = 0.2;
        l.cancelsTouchesInView = NO;
        [self addGestureRecognizer:l];
        self.draggingSelectionRecognizer = l;
        [l release];
        
        /*
        UIPanGestureRecognizer* p = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanningGestureReceived:)];
        p.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:p];
        self.draggingRecognizer = p;
        [p release]; 
         */
    

    }
    return self;
    
}  

- (void)setFrame:(CGRect)frame{
    
    [super setFrame:frame];
    self.deleteButton.center = self.frame.origin;
    [self setNeedsLayout];
}

- (void)layoutSubviews{
    
    if(self.mode == FJSpringBoardCellModeEditing)
        [self.superview insertSubview:self.deleteButton aboveSubview:self];

}



- (void)prepareForReuse{
    
    self.mode = FJSpringBoardCellModeNormal;
    self.reordering = NO;
    self.selected = NO;
    self.draggable = NO;
    self.tappedAndHeld = NO;
    self.deleteButton = nil;
    
}

- (void)delete{
    debugLog(@"deleted!");
    
    [self.springBoardView _deleteCell:self];
    
}


#pragma mark - Setters

- (void)setBackgroundView:(UIView *)bv{
    
    if(backgroundView == bv)
        return;
    
    [backgroundView removeFromSuperview];
    bv.frame = self.contentView.frame;
    contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    [backgroundView release];
    backgroundView = [bv retain];
    [self insertSubview:backgroundView belowSubview:contentView];
    
}

/*
- (void)setFrame:(CGRect)f{
    
    [super setFrame:f];
    
    CGRect contentFrame = self.contentView.frame;
    contentFrame.origin = CGPointMake(CELL_INVISIBLE_LEFT_MARGIN, CELL_INVISIBLE_TOP_MARGIN);
    
    backgroundView.frame = contentFrame;
    contentView.frame = contentFrame;
    
    //backgroundView.center = CGPointMake(CGRectGetMidX(self.bounds)+CELL_INVISIBLE_LEFT_MARGIN, CGRectGetMidY(self.bounds)+CELL_INVISIBLE_TOP_MARGIN);    
    //contentView.center = CGPointMake(CGRectGetMidX(self.bounds)+CELL_INVISIBLE_LEFT_MARGIN, CGRectGetMidY(self.bounds)+CELL_INVISIBLE_TOP_MARGIN);   
    
    //backgroundView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    //contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));    

}
 */


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
    mode = aMode;

    if(aMode == FJSpringBoardCellModeNormal){
        
        self.singleTapRecognizer.enabled = YES;
        self.editingModeRecognizer.enabled = YES;
        self.draggingRecognizer.enabled = NO;
        self.draggingSelectionRecognizer.enabled = NO;
        
        [self _stopWiggle];
        [self _removeDeleteButton];
        
    }else{
        
        self.singleTapRecognizer.enabled = NO;
        self.editingModeRecognizer.enabled = YES; //to get the first drag
        self.draggingRecognizer.enabled = YES;
        self.draggingSelectionRecognizer.enabled = YES;
        
        if(showsDeleteButton)
            [self _addDeleteButton];
        
        if(draggable)
            [self _startWiggle];
        
       
    }
}


- (void)setReordering:(BOOL)flag{
    
    if(reordering == flag)
        return;
    
    reordering = flag;
    
    if(reordering){
        
        self.tappedAndHeld = NO;
        self.alpha = 0;
        
    }else{
        
        self.alpha = 1;

    }
    
    
}

- (void)setSelectionStyle:(FJSpringBoardCellSelectionStyle)aSelectionStyle{
    
    selectionStyle = aSelectionStyle;
    
    if(selected){
        
        //update selection view
        
        
    }
    
}


- (void)setSelected:(BOOL)flag{
    
    if(selected == flag)
        return;
    
    selected = flag;
    
    if(selected){
        
        UIView* sv = [[UIView alloc] initWithFrame:self.bounds];
        sv.layer.transform = CATransform3DMakeScale(1.3, 1.3, 0);
        sv.layer.cornerRadius = 10.0;
        sv.alpha = 0.8;
        
        sv.backgroundColor = [UIColor darkGrayColor];
        self.selectionView = sv;
        [self addSubview:sv];
        [sv release];

    }else{
        
        [self.selectionView removeFromSuperview];
        self.selectionView = nil;
    }
    
}

- (void)setSelected:(BOOL)flag animated:(BOOL)animated{
    

    if(!animated){
        
        [self setSelected:flag];

    }else{
        
        [self willChangeValueForKey:@"selected"];
        
        selected = flag;
        
        [self didChangeValueForKey:@"selected"];
        
        if(selected){
            
            UIView* sv = [[UIView alloc] initWithFrame:self.bounds];
            sv.layer.transform = CATransform3DMakeScale(1.3, 1.3, 0);
            sv.layer.cornerRadius = 10.0;
            sv.alpha = 0.8;
            
            sv.backgroundColor = [UIColor darkGrayColor];
            self.selectionView = sv;
            [self addSubview:sv];
            [sv release];            
            
            self.selectionView.alpha = 0.0;
            
        }
        
        
        [UIView animateWithDuration:0.4 animations:^(void) {
            
            if(selected){
                
                self.selectionView.alpha = 0.8;
            }else{
                
                self.selectionView.alpha = 0.0;
            }
            
        } completion:^(BOOL finished) {
            
            if(!selected){
                
                [self.selectionView removeFromSuperview];
                self.selectionView = nil;

            }
          
        }];
    }
    
    
}

- (void)setTappedAndHeld:(BOOL)flag{
    
    if(tappedAndHeld == flag)
        return;
    
    tappedAndHeld = flag;
    
    if(tappedAndHeld){
        
        self.alpha = CELL_DRAGGABLE_ALPHA;
        
    }else{
        
        self.alpha = 1;
    }

}

- (void)setDraggable:(BOOL)flag{
    
    if(draggable == flag)
        return;
    
    draggable = flag;

    if(self.mode == FJSpringBoardCellModeNormal){
        
        [self _stopWiggle];
        
    }else{
        
        if(draggable)
            [self _startWiggle];
    
    }

}

- (void)setShowsDeleteButton:(BOOL)flag{
    
    if(showsDeleteButton == flag)
        return;
    
    showsDeleteButton = flag;

    if(self.mode == FJSpringBoardCellModeNormal){
        
        [self _removeDeleteButton];
        
    }else{
        
        if(showsDeleteButton)
            [self _addDeleteButton];
    }
    
}


- (void)_addDeleteButton{
    
    if(self.deleteImage == nil){
        
        self.deleteImage = _deleteImage;
    }
    
    if(self.deleteButton == nil)
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.deleteButton.frame = CGRectMake(0, 0, 44, 44);
    self.deleteButton.center = self.frame.origin;
    [self.deleteButton setImage:self.deleteImage forState:UIControlStateNormal];
    self.deleteButton.contentMode = UIViewContentModeCenter;
    //[b setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 14, 14)];
    [self.deleteButton addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
    [self.superview insertSubview:self.deleteButton aboveSubview:self];
    
}

- (void)_removeDeleteButton{
    
    [self.deleteButton removeFromSuperview];
}

- (void)_startWiggle{
    
    [self _stopWiggle];
    
    CAAnimation *wiggle = wiggleAnimation();
    recursivelyApplyAnimationToAllSubviewLayers(self, wiggle, @"wiggle");

    [self.deleteButton.layer addAnimation:wiggle forKey:@"wiggle"];
}

- (void)_stopWiggle{
    
    recursivelyRemoveAnimationFromAllSubviewLayers(self, @"wiggle");
    
    [self.deleteButton.layer removeAnimationForKey:@"wiggle"];

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

/*
- (void)_updateView{
    
    
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
*/

#pragma mark -
#pragma mark Touches

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    return YES;
    
}


- (void)didSingleTap:(UITapGestureRecognizer*)g{
        
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
    
    [self setTappedAndHeld:NO];
    
    [self.springBoardView cellWasLongTapped:self];
    
    [self _processEditingLongTapWithRecognizer:g];
    
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

- (NSString*)description{
    
    NSString* desc = [super description];
    
    //desc = [desc stringByAppendingString:@"\n"];

    desc = [desc stringByAppendingFormat:@" tag: %i", self.contentView.tag];

    desc = [desc stringByAppendingFormat:@" index: %i", self.index];
    
    return desc;
    
}


    
@end



