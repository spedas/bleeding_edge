;+
;PROCEDURE: tplot_rename
;PURPOSE:
;  Simple procedure to perform a rename of tplot variable without copy.
;  Uses the store_data,newname= keyword to implement, but performs some
;  checks to make it more user friendly.
;
;Inputs(required):
;
; old_name: current name of the variable or index.(string or integer)
; new_name: name the variable will have after procedure call.(string)
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-06 14:36:07 -0700 (Fri, 06 Sep 2013) $
;$LastChangedRevision: 12962 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_rename.pro $
;-
pro tplot_rename,old_name,new_name

  if tnames(old_name) eq new_name then return ;rename to self is no-op
  
  if find_handle(new_name) gt 0 then begin ;checking first suppresses superfluous message from store data
    store_data,new_name,/delete ;tplot will not overwrite existing with newname keyword
  endif
  store_data,old_name,newname=new_name

end