

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
   
 need to handle deleting while reordering indexmap is actve
 
 
 
 @todo
 
 drag and drop 
 
 decide whether to move cell or insert into folder
 
 remove cell when adding to folder
 
 make a folder
 
 drag and drop on a folder
 
 
 
 @low priority todo
 @refactoring
 
 allows edit mode
 
 pre-setup delegate detection BOOLs
 
 make insert delete more like reorder by using an indexmap
 
 calculate path animation from old to new indexes (instead of straight line)
 
 create contentView for springboard to hold all cells
  
 
*/