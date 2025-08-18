;+
;PROCEDURE: dif_data, n1,n2
;PURPOSE:
;   Creates a tplot variable that is the difference of two tplot variables.
;INPUT: n1,n2  tplot variable names (strings)
;KEWORDS:
;  copy_dlimits: set to 1 to use the first variable's dlimits, 2 to use the second's
;-
PRO dif_data,n1,n2,newname=newname, copy_dlimits=cdl
get_data,n1,data=d1, dlimits = dl1
get_data,n2,data=d2, dlimits = dl2
if not keyword_set(d1) or not keyword_set(d2) then begin
   dprint,'data not defined!'
   return
endif
if not keyword_set(newname) then newname = n1+'-'+n2
if size(cdl, /type) ne 0 then begin
  case cdl of
    1:dl_out = dl1
    2:dl_out = dl2
    else:
  endcase
endif
y2 = data_cut(d2,d1.x)
dif = d1.y-y2
dat = {x:d1.x,y:dif}
store_data,newname,data=dat, dlimits=dl_out
return
end
