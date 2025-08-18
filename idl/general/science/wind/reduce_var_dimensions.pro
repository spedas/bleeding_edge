;+
;PROCEDURE: reduce_var_dimensions,data,limits
;INPUT:  data:  a structure with elements:
;      x (typically time)
;      y (3 dimensional data array)
;      v1
;      v2
;        limits:  a structure with elements:
;      v1_range:  bin range for dimension 1  (two element array)
;      v2_range:  bin range for dimension 2  (two element array)
;      avg_var:   1 or 2.  variable to sum over
;
;
;Caution:  This procedure is still in development.
;Created by: Davin Larson,  Sept 1995
;File:  %M%
;Version:  %I%
;Last Modified:  %E%
;-
pro reduce_var_dimensions,data,options

extract_tags,data,options   ; place all options into data

dim = dimen(data.y)

avg_var = 1  ; default
str_element,data,'avg_var',value=avg_var
str_element,data,'v_range',value= range
if avg_var eq 1 then begin
   v = reform(data.v2)
   if n_elements(range) eq 0 then range = [0,dim(1)-1]
   y = data.y(*,range(0):range(1),*)
endif else begin
   v = reform(data.v1)
   if n_elements(range) eq 0 then range = [0,dim(2)-1]
   y = data.y(*,*,range(0):range(1))
endelse

y = total(y,avg_var+1)/dim(avg_var)
data = {x:data.x,y:y,v:v}

help,data,options,/st

end
