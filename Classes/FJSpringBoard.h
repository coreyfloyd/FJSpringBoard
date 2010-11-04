

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
 
 @todo
 
 cancel touches / scrolling during animations
 
 editing mode
 
 shake animation
 
 drag and drop reorder

 drag and drop and make a folder
 
 drag and drop on a folder
 
 


*/