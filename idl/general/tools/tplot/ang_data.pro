;+
;PROCEDURE: ang_data, n1,n2
;PURPOSE:
;   Creates a tplot variable that is the angle between two tplot variables.
;INPUT: n1,n2  tplot variable names (strings)
;   These should each be 3 element vectors
;KEWORDS:
;  copy_dlimits: set to 1 to use the first variable's dlimits, 2 to use the second's
;-
PRO ang_data,n1,n2,newname=newname,dot=dotp,copy_dlimits=cdl
get_data,n1,data=d1, dlimits = dl1
get_data,n2,data=d2, dlimits = dl2
if not keyword_set(d1) or not keyword_set(d2) then begin
   dprint,'data not defined!'
   return
endif
c = keyword_set(dotp) ? '.' : '@'
if not keyword_set(newname) then newname = n1+c+n2
if size(cdl, /type) ne 0 then begin
  case cdl of
    1:dl_out = dl1
    2:dl_out = dl2
    else:
  endcase
endif
y2 = data_cut(d2,d1.x)
y1 = d1.y
dot = total(y1*y2,2)
y1m = sqrt(total(y1^2,2))
y2m = sqrt(total(y2^2,2))
;help,y1,y2,dot,y1m,y2m
ang = acos(dot/y1m/y2m) * !radeg

dat = {x:d1.x,y:(keyword_set(dotp) ? dot :ang)}
store_data,newname,data=dat, dlimits=dl_out
return
end
