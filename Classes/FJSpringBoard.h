

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
     
 stop readding group cell over and over again
 
 fix empty cell when moving creating folder before dragging index
 
 fire timer to get rid of drag cell that never completes
 
 
 
 @todo
    
 clean up 
 
 
 @low priority todo
 @refactoring
 
 allows edit mode
 
 pre-setup delegate detection BOOLs
 
 make insert delete more like reorder by using an indexmap
 
 calculate path animation from old to new indexes (instead of straight line)
 
 forward all scrollview messages to scrollview
 
 indexes Scrolling on off:
    1)for each inserted in view, scroll 1 off on the right
    2)for each removed in view, scroll 1 on from the right
    3)for each cell add before view,  scroll 1 on form the left + #1
    4)for each cell removed before view, scroll 1 off on the left (unless it was the cell that was removed) + #2

    for each page change, do what we do now
 
 
 create contentView for springboard to hold all cells
 
 
 
 consider using NSOperationQueue with update object
 
 update object
    unanimated layout "fixes" (add / remove cells from view on visible boundries)
    apply cell changes (insert, delete, reorder)
    animation changes 
 
*/