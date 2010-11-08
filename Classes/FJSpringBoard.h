

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
        
 fix deletion of last cell
 
 @todo
    
 add to exising group
 
 check multipage drag drops (unloaded pages)
 
 
 
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
 
 
 consider using NSOperationQueue with update object
 
 update object
    unanimated layout "fixes" (add / remove cells from view on visible boundries)
    apply cell changes (insert, delete, reorder)
    animation changes (BOOL YES or NO)
 
*/