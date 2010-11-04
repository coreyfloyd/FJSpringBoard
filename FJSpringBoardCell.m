
#import "FJSpringBoardCell.h"
#import "FJSpringBoardView.h"
#import <QuartzCore/QuartzCore.h>

CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

NSNumber* DegreesToNumber(CGFloat degrees) {
    return [NSNumber numberWithFloat: DegreesToRadians(degrees)];
}

@interface FJSpringBoardCell()

@property(nonatomic, assign) FJSpringBoardView* springBoardView;

@property (nonatomic, retain, readwrite) UIView *contentView;

@property (nonatomic, copy, readwrite) NSString *reuseIdentifier;

- (void)_startWiggle;
- (void)_stopWiggle;
- (CAAnimation*)_shakeAnimation;

@end


@implementation FJSpringBoardCell

@synthesize contentView;
@synthesize reuseIdentifier;
@synthesize mode;
@synthesize selectionModeImageView;
@synthesize selectedImageView;
@synthesize glowsOnSelection;
@synthesize selected;
@synthesize deleteImage;
@synthesize pulseOnTouchAndHold;
@synthesize springBoardView;



- (void) dealloc
{
    
    [springBoardView release];
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


- (id)initWithContentSize:(CGSize)size reuseIdentifier:(NSString*)identifier{
    
    self = [super init];
    if (self != nil) {
        
        CGRect f;
        f.origin = CGPointZero;
        f.size = size;
        self.contentView = [[[UIView alloc] initWithFrame:f] autorelease];
        
        self.reuseIdentifier = identifier;
    }
    return self;
    
}  


- (void)setMode:(FJSpringBoardCellMode)aMode{
    
    if(mode == aMode)
        return;
    
    FJSpringBoardCellMode oldMode = mode;
    
    mode = aMode;
    
    if(oldMode == FJSpringBoardCellModeEditing){
        
        [self _stopWiggle];
    }
    
    
    if(mode == FJSpringBoardCellModeEditing){
                
        [self _startWiggle];
    }
    
}

- (void)_startWiggle{
    
    CAAnimation *wiggle = [self _shakeAnimation];
	    
    [self.contentView.layer addAnimation:wiggle forKey:@"wiggle"];
}

- (void)_stopWiggle{
    
    [self.contentView.layer removeAnimationForKey:@"wiggle"];
}

- (CAAnimation*)_shakeAnimation {
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
    
@end
