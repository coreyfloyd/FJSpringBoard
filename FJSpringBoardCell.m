
#import "FJSpringBoardCell.h"
#import "FJSpringBoardView.h"

@interface FJSpringBoardCell()

@property(nonatomic, assign) FJSpringBoardView* springBoardView;

@property (nonatomic, retain, readwrite) UIView *contentView;

@property (nonatomic, copy, readwrite) NSString *reuseIdentifier;

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
    
@end
