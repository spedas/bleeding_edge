;+
;FUNCTION:  find_handle(name)
;
;PURPOSE:
;   Returns the index associated with a string name.
;   This function is used by the "TPLOT" routines.
;
;INPUT:     name  (scalar string)
;    name can also be the corresponding integer index to a TPLOT quantity,
;    in which case name will be converted to the string handle.
;
;RETURN VALUE:   tplot index. (0 if not found)
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)find_handle.pro	1.14 99/02/26
;
;-
function find_handle,name,verbose=verbose
@tplot_com.pro
if n_elements(data_quants) eq 0 then begin
   dprint,verbose=verbose,'No Data stored yet!'
   return,0
endif
if n_elements(name) ne 1 then begin
   dprint,'Name must be a scalar',verbose=verbose
   return,0
endif
dt = size(/type,name)
if dt eq 7 then begin
  index = where(data_quants.name eq name[0],count)
  if count eq 0 then return,0
  return, index[0]
endif
if dt ge 1 and dt le 5 then begin
  index = round(name)
  if index gt 0 and index lt n_elements(data_quants) then $
     name = data_quants[index].name $
  else index = 0
  return,index
endif
return,0
end
