

#import "FJSpringBoardView.h"

#import "FJSpringBoardCell.h"

#import "FJSpringBoardIndexLoader.h"

#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"


/*

 @bugs

 @high
   
 
 @low
 balance all copies with releases
         
 Dangling cells left sometimes. need a full proof cleanup strategy, but now it fixes itself
 
 mostly cell is left during an edge animation, need to clean up better

 ---------
 
 @todo
    
 
 action / selection
 
 --------
 
 @refactoring (all low)
 
 
 allows edit mode

 Create FJSpringBoardItem Protocol, rely on that for the creation of cells

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
 
 pre-setup delegate detection BOOLs if needed

 
*/