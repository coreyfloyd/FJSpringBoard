

#import <Foundation/Foundation.h>
#import "FJSpringBoardUtilities.h"


typedef enum  {
    FJSpringBoardCellModeNormal,
    FJSpringBoardCellModeMultiSelection, //not implemented
    FJSpringBoardCellModeEditing //delete + move
} FJSpringBoardCellMode;

typedef enum {
    FJSpringBoardCellSelectionStyleNone,
    FJSpringBoardCellSelectionStyleBlue,
    FJSpringBoardCellSelectionStyleGray
} FJSpringBoardCellSelectionStyle;

@interface FJSpringBoardCell : UIView <UIGestureRecognizerDelegate> {

}
- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier;
- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier contentNib:(UINib*)nib; //use this if you layout your content in a nib. properties with IBOutlet are supported. Set file owner to the FJSpringBoardCell or your custom subclass


@property(nonatomic, retain) IBOutlet UIView *backgroundView; //default is plain white background, you can set this to whatever you like, will autmatically be resized to the content size.
@property(nonatomic, retain, readonly) IBOutlet UIView *contentView; //add content here

@property(nonatomic, copy, readonly) NSString *reuseIdentifier; 

@property(nonatomic) FJSpringBoardCellMode mode;

@property(nonatomic,retain) IBOutlet UIView *selectedBackgroundView;
@property(nonatomic) FJSpringBoardCellSelectionStyle  selectionStyle;   

@property(nonatomic) BOOL selected;
- (void)setSelected:(BOOL)flag animated:(BOOL)animated; //subclasses should overide this method instead the property above


@property(nonatomic, retain) UIImage *deleteImage; //shown in delete mode, shown as a 30x30 image with origin = self.bounds.origin. place your content accordingly

@property(nonatomic, readonly) BOOL reordering;

- (void)prepareForReuse; //subclasses must call super implementation


@end
