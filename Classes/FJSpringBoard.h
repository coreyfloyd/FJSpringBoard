

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
 
 find a way to keep the tile better in sync during paging
   
 
 @todo

 allows edit mode
 
 drag and drop and make a folder
 
 drag and drop on a folder
 
 
 @refactoring
 
 pre-setup delegate detection BOOLs
 
 dont load next page until scroll stops
 
 make insert delete more like reorder by using an indexmap
 
 calculate path animation from old to new indexes (instead of straight line)
 
*/