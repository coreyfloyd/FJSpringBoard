//
//  FJSpringBoardGroupCell.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 8/28/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardGroupCell.h"


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
    
    __block CGRect f = self.bounds;
    f.origin = CGPointMake(8, 8);
    f.size = CGSizeMake((f.size.width-16-4)/2, (f.size.height-16-4)/2);
    
    [self.contentImages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if(idx == 1){
            
            f.origin.x+=(f.size.width+4);
            
        }
        if(idx == 2){
            
            f.origin.x-=(f.size.width+4);
            f.origin.y+=(f.size.height+4);
            
        }
        if(idx == 3){
            
            f.origin.x+=(f.size.width+4);
            *stop = YES;
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

- (id)initWithContentSize:(CGSize)size reuseIdentifier:(NSString*)identifier{
    
    self = [super initWithContentSize:size reuseIdentifier:identifier];
    if (self != nil) {
        
        self.contentImageHolder = [[[FJSpringBoardGroupCellContentView alloc] initWithFrame:self.contentView.frame] autorelease];
        self.contentImageHolder.backgroundColor = [UIColor clearColor];
        [self addSubview:self.contentImageHolder];
        
    }
    return self;
    
}  


- (void)setContentImages:(NSArray*)images{
    
    self.contentImageHolder.contentImages = images;
    
    [self.contentImageHolder setNeedsDisplay];
    [[self.contentImageHolder layer] setNeedsDisplay];
    [[[self.contentImageHolder layer] presentationLayer] setNeedsDisplay];
    
}

@end


