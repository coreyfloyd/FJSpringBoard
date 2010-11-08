

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
    
 stop readding group cell over and over again
 
 
 
 
 @todo
   
 remove cell when adding to folder
 
 make a folder
 
 drag and drop on a folder
 
 
 
 @low priority todo
 @refactoring
 
 allows edit mode
 
 pre-setup delegate detection BOOLs
 
 make insert delete more like reorder by using an indexmap
 
 calculate path animation from old to new indexes (instead of straight line)
 
 
 indexes Scrolling on off:
    for each inserted, scroll 1 off on the right
    for each deleted, scroll 1 on from the right
    for each page change, do what we do now
 
 
 create contentView for springboard to hold all cells
 
 
 
 consider using NSOperationQueue with update object
 
 update object
    unanimated layout "fixes" (add / remove cells from view on visible boundries)
    apply cell changes (insert, delete, reorder)
    animation changes 
 
*/