;+
;Procedure:
;  spd_pgs_concat_yaxis
;
;Purpose:
;  Concatenates different y axes as spectrogram is built across mode changes
;
;Input:
;  y: Previous y axes, either single dimension or ny x ntimes
;  yc: Y axis for current sample, single dimension
;  ns: Number of samples before the current one in the spectrogram.
;      (used when 1D y axis is converted to 2D axis)  
;
;Output:
;  -If y is 1D and yc==y then no variables are changed.
;  -If y is 1D and yc!=y then y will become a two dimensional
;   and yc will be appended 
;  -If y is 2D then yc will be appended.
;  -If y and yc have different numbers of elements the smaller
;   will be expanded and padded with NaNs
;
;Notes:
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:09:48 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_concat_yaxis.pro $
;-
pro spd_pgs_concat_yaxis, y, yc, ns=ns

    compile_opt idl2, hidden
  
  
  flag = !values.f_nan
  
  ydim = size(y,/dim) > 1
  ycdim = size(yc,/dim) > 1
  
  
  ;ensure the number of elements in the second dimension
  ;is set so that the check below will not fail
  if n_elements(ydim) eq 1 then ydim = [ydim,1]
;  if n_elements(ycdim) eq 1 then ydim = [ycdim,1]
  
  
  ;only append new axis if it is different 
  ;or if there is already a 2D axis
  if ydim[1] gt 1 || ~array_equal( yc, y[*,ydim[1]-1] ) then begin
    
    
    ;expand previous axes to match elements in new axis
    if ycdim[0] gt ydim[0] then begin
      
      y = [ temporary(y), replicate(flag, ycdim[0]-ydim[0], ydim[1]) ]
    
    ;expand new axis to match elements in previous axes
    endif else if ycdim[0] lt ydim[0] then begin
      
      yc = [ yc, replicate(flag, ydim[0]-ycdim[0]) ]
      
    endif

    
    ;concatenate
    if ydim[1] gt 1 then begin
      y = [ [temporary(y)], [yc] ]
    endif else begin
      y = [ [temporary(y) # replicate(1,ns)], [yc] ]
    endelse
  
  endif
  
  
end