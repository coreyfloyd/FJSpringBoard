

#import "FJSpringBoardView.h"

#import "FJSpringBoardCell.h"

#import "FJSpringBoardCellItem.h"

#import "FJSpringBoardIndexLoader.h"

#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"


/*

 @bugs
 
 Dangling cells left sometimes. need a full proof cleanup strategy
  
 balance all copies with releases
 
 get touch to entire close button or change to image and use the view
  
 
 @todo

 allows edit mode
 
 drag and drop and make a folder
 
 drag and drop on a folder
 
 
 @refactoring
 
 add view behind cell contentview
 change center to center and distribute evenly (both vertically and horizontally)

 pre-setup delegate detection BOOLs
 
 dont load next page until scroll stops
 
 make insert delete more like reorder by using an indexmap
 
 


*/