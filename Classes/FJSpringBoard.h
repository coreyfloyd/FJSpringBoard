

#import "FJSpringBoardView.h"

#import "FJSpringBoardCell.h"

#import "FJSpringBoardCellItem.h"

#import "FJSpringBoardIndexLoader.h"

#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"


/*

 @bugs
 
 Dangling cell left sometimes. (usually cell 7?)
 
 cells that move into range after adding indexes are not loaded (fixed?)
 
 balance all copies with releases
 
 get touch to entire close button or change to image and use the view
 
 compare to NSNotFound not NSUIntegerMax
 
 
 @todo
    
 reorder based on position
 move to index on release


 drag and drop and make a folder
 
 drag and drop on a folder
 
 
 @refactoring
 
 add view behind cell contentview
 
 pre-setup delegate detection BOOLs
 
 dont load next page until scroll stops
 
 change center to center and distribute evenly (both vertically and horizontally)
 
 


*/