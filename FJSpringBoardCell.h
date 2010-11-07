

#import <Foundation/Foundation.h>

typedef enum  {
    FJSpringBoardCellModeNormal,
    FJSpringBoardCellModeSelection,
    FJSpringBoardCellModeEditing //delete + move
} FJSpringBoardCellMode;

typedef enum  {
    FJSpringBoardCellAnimationNone,
    FJSpringBoardCellAnimationFade
} FJSpringBoardCellAnimation;

typedef enum  {
    FJSpringBoardCellScrollPositionMiddle
} FJSpringBoardCellScrollPosition;


@interface FJSpringBoardCell : UIView {

}
- (id)initWithSize:(CGSize)size reuseIdentifier:(NSString*)identifier;

@property(nonatomic, retain) UIView *backgroundView; //default is plain white background, you can set this to whatever you like
@property(nonatomic, retain, readonly) UIView *contentView; //add content here

@property(nonatomic, copy, readonly) NSString *reuseIdentifier;

@property(nonatomic) FJSpringBoardCellMode mode;

@property(nonatomic, retain) UIImageView *selectionModeImageView; //shown in select mode
@property(nonatomic, retain) UIImageView *selectedImageView; //shown when selected in select mode
@property(nonatomic) BOOL glowsOnSelection;

@property(nonatomic) BOOL selected;

@property(nonatomic, retain) UIImage *deleteImage; //shown in delete mode, shown as a 30x30 image with origin = self.bounds.origin. place your content accordingly

@property(nonatomic) BOOL reordering;


@end



//configure an empty folder
@interface FJSpringBoardGroupCell : FJSpringBoardCell {
    
}

@end




//Icon / Folder specific Cells
@interface FJSpringBoardIconCell : FJSpringBoardCell{
    
}

@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) NSString *name;



@end

@interface FJSpringBoardFolderCell : FJSpringBoardGroupCell {
    
}

@property(nonatomic, retain) UIImage *folderImage;
@property(nonatomic, retain) NSArray *groupImages;
@property(nonatomic, retain) NSString *name;


@end

