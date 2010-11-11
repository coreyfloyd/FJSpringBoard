
#import "FJSpringBoardCell.h"
#import "FJSpringBoardView.h"
#import <QuartzCore/QuartzCore.h>
#import "FJSpringBoardUtilities.h"

CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

NSNumber* DegreesToNumber(CGFloat degrees) {
    return [NSNumber numberWithFloat: DegreesToRadians(degrees)];
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


@end


@interface FJSpringBoardCell()

@property(nonatomic, assign) FJSpringBoardView* springBoardView;

@property (nonatomic, retain, readwrite) UIView *contentView;

@property (nonatomic, copy, readwrite) NSString *reuseIdentifier;

- (void)_startWiggle;
- (void)_stopWiggle;
- (CAAnimation*)_wiggleAnimation;
- (void)_removeDeleteButton;
- (void)_addDeleteButton;
- (void)_updateView;

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
@synthesize glowsOnSelection;
@synthesize selected;
@synthesize deleteImage;
@synthesize springBoardView;
@synthesize reordering;
@synthesize showsDeleteButton;
@synthesize draggable;




- (void) dealloc
{
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
    
    _deleteImage = [UIImage imageNamed:@"close.png"];
    _defaultBackgroundColor = [UIColor whiteColor];
    
}


- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier{
    
    CGRect f;
    f.origin = CGPointZero;
    f.size = size;
    
    self = [super initWithFrame:f];
    if (self != nil) {
        
        UIEdgeInsets e = UIEdgeInsetsMake(CELL_INVISIBLE_TOP_MARGIN, CELL_INVISIBLE_LEFT_MARGIN, 0, 0);
        f = UIEdgeInsetsInsetRect(f, e);
        
        self.backgroundColor = [UIColor clearColor];
        
        self.backgroundView = [[[UIView alloc] initWithFrame:f] autorelease];
        self.backgroundView.backgroundColor = _defaultBackgroundColor;
        [self addSubview:self.backgroundView];

        self.contentView = [[[UIView alloc] initWithFrame:f] autorelease];
        self.contentView.backgroundColor = _defaultBackgroundColor;
        [self addSubview:self.contentView];
        
        self.showsDeleteButton = YES;
        self.draggable = YES;
        
        self.reuseIdentifier = identifier;
    }
    return self;
    
}  

- (void)delete{
    NSLog(@"deleted!");
    
    [self.springBoardView _deleteCell:self];
    
}


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
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



- (void)_addDeleteButton{
    
    if(self.deleteImage == nil){
        
        self.deleteImage = _deleteImage;
    }
    
    UIButton* b  = (UIButton*)[self viewWithTag:1001];

    if(b == nil)
        b  = [UIButton buttonWithType:UIButtonTypeCustom];
    
    b.tag = 1001;
    b.frame = CGRectMake(0, 0, 30, 30);
    [b setImage:self.deleteImage forState:UIControlStateNormal];
    [b addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
    [self insertSubview:b aboveSubview:self.contentView];
    
}

- (void)_removeDeleteButton{
    
    [[self viewWithTag:1001] removeFromSuperview];
}

- (void)_startWiggle{
    CAAnimation *wiggle = [self _wiggleAnimation];
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
      
    NSMutableArray *values = [NSMutableArray array]; // Turn right
    [values addObject:DegreesToNumber(-2)]; // Turn left
    [values addObject:DegreesToNumber(2)]; // Turn right
    [values addObject:DegreesToNumber(-2)]; // Set the values for the animation
    [animation setValues:values]; return animation;
    
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
        
        self.alpha = 1;
        
    }
    
}
    
@end


@interface FJSpringBoardGroupCellContentView : UIView
{
    
}

@property(nonatomic, copy) NSArray *contentImages;


@end


@implementation FJSpringBoardGroupCellContentView

@synthesize contentImages;


- (void) dealloc
{
    
    [contentImages release];
    contentImages = nil;
    [super dealloc];
}


-(void)drawRect:(CGRect)rect{
    b
    CGRect f = self.bounds;
    f.origin = CGPointMake(2, 2);
    f.size = CGSizeMake((f.size.width-4-2)/2, (f.size.height-4-2)/2);
    
    [self.contentImages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
        if(idx == 1){
         
            f.origin.x+=(f.size.width+2)
            
        }
        if(idx == 2){
            
            f.origin.x-=(f.size.width+2)
            f.origin.y+=(f.size.height+2)

        }
        if(idx == 3){
            
            f.origin.x+=(f.size.width+2)
            stop = YES;
        }
        
        UIImage* i = (UIImage*)obj;
        
        [i drawInRect:f];

        
    }];
    
}


@end



@interface FJSpringBoardGroupCell()

@property(nonatomic, retain) FJSpringBoardGroupCellContentView* contentImageHolder;

@end

//configure an empty folder
@implementation  FJSpringBoardGroupCell

@synthesize contentImageHolder;

- (void) dealloc
{
    
    [contentImageHolder release];
    contentImageHolder = nil;
    [super dealloc];
}

- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier{
    
    self = [super initWithSize:size reuseIdentifier:identifier];
    if (self != nil) {
        
        self.contentImageHolder = [[[FJSpringBoardGroupCellContentView alloc] initWithFrame:self.contentView.frame] autorelease];
        self.contentImageHolder.backgroundColor = [UIColor clearColor];
        [self addSubview:self.contentImageHolder];
        
    }
    return self;
    
}  


- (void)setContentImages:(NSArray*)images{
    
    self.contentImageHolder.contentImages = images;
    
}

@end


