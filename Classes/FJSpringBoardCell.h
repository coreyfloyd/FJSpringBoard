

#import <Foundation/Foundation.h>
#import "FJSpringBoardUtilities.h"


@interface FJSpringBoardCell : UIView {

}
- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier;

@property(nonatomic, retain) UIView *backgroundView; //default is plain white background, you can set this to whatever you like
@property(nonatomic, retain, readonly) UIView *contentView; //add content here

@property(nonatomic, copy, readonly) NSString *reuseIdentifier;

@property(nonatomic) FJSpringBoardCellMode mode;
@property(nonatomic) BOOL showsDeleteButton;


@property(nonatomic, retain) UIImageView *selectionModeImageView; //shown in select mode
@property(nonatomic, retain) UIImageView *selectedImageView; //shown when selected in select mode
@property(nonatomic) BOOL glowsOnTap;

@property(nonatomic, readonly) BOOL tapped;

@property(nonatomic) BOOL selected;

@property(nonatomic, retain) UIImage *deleteImage; //shown in delete mode, shown as a 30x30 image with origin = self.bounds.origin. place your content accordingly

@property(nonatomic) BOOL reordering;

@property(nonatomic) BOOL draggable;
@property(nonatomic) BOOL groupable; //can be added to a group, can become a group
@property(nonatomic) BOOL tapable; 


@end



//configure an empty folder
@interface FJSpringBoardGroupCell : FJSpringBoardCell {
    
    NSArray* contentImages;
}

- (void)setContentImages:(NSArray*)images;

@end

