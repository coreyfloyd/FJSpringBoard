

#import <Foundation/Foundation.h>

typedef enum  {
    FJSpringBoardCellModeNormal,
    FJSpringBoardCellModeSelection,
    FJSpringBoardCellModeDelete
} FJSpringBoardCellMode;

typedef enum  {
    FJSpringBoardCellAnimationFade
} FJSpringBoardCellAnimation;

typedef enum  {
    FJSpringBoardCellScrollPositionMiddle
} FJSpringBoardCellScrollPosition;


@interface FJSpringBoardCell : NSObject {

}
- (id)initWithContentSize:(CGSize)size reuseIdentifier:(NSString*)identifier;

@property(nonatomic, retain, readonly) UIView *contentView;

@property(nonatomic, copy, readonly) NSString *reuseIdentifier;


@property(nonatomic) FJSpringBoardCellMode mode;


@property(nonatomic, retain) UIImageView *selectionModeImageView; //shown in selsct mode
@property(nonatomic, retain) UIImageView *selectedImageView; //shown when selected in select mode
@property(nonatomic) BOOL glowsOnSelection;

@property(nonatomic) BOOL selected;


@property(nonatomic, retain) UIImage *deleteImage; //shown in delete mode


@property(nonatomic) BOOL pulseOnTouchAndHold;


@end








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




@protocol FJGridViewCellModel <NSObject>

- (BOOL)canDelete;
- (BOOL)isDraggable;
- (BOOL)isGroupable;

@end

