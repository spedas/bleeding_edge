;+
;Procedure:
;  thm_part_slice1d_xy
;
;Purpose:
;  Return the set of points at which a linear cut will be interpolated
;  and corresponding plot labels.
;
;Calling Sequence:
;  thm_part_slice1d_r, slice (xin=xin | yin=yin), xout=xout, yout=yout, 
;                      xaxis=xaxis, xtitle=xtitle
;
;Input:
;  slice: 2D slice structure
;  xin: x value at which to create cut perpendicular to the x axis
;  yin: y value at which to create cut perpendicular to the y axis
; 
;
;Output:
;  xout: x coordinates of points to interpolate to
;  yout: y coordinates of points tointerpolate to
;  xaxis: final plot's x axis
;  xtitle: title for final plot's x axis
;  error: flag, 1 if error 0 if not
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice1d_xy.pro $
;
;-
pro thm_part_slice1d_xy, slice, $
                         xin=x0, yin=y0, angle=angle, $
                         xout=x, yout=y, $
                         xaxis=xaxis, xtitle=xtitle, $
                         error=error

    compile_opt idl2, hidden

  
  error = 1b
  
  
  n = n_elements(slice.xgrid)
  
  
  ;Get values at which to interpolate data
  ;---------------------------------------
  
  ;get coordinates and for  vertical cuts
  if ~undefined(x0) then begin

    x = x0
    y = interpol( minmax(slice.ygrid), 3*n)

  ;get coordinates and for horizontal cuts
  endif else begin
    
    if undefined(y0) then y0 = 0
    
    x = interpol( minmax(slice.xgrid), 3*n)
    y = y0
    
  endelse
  

  ;rotate indices to get off-axis cuts
  if keyword_set(angle) then begin
    
    ;pad indices to cover entire plot area after rotating
    if n_elements(x) gt 1 then begin

      ;create array with equal spacing
      pad = median(x - shift(x,1)) * (findgen(n/2.) + 1)
      x = [ min(x) - reverse(pad), x, max(x) + pad ]
      
      rotated_axis = x ;used as plot's x axis

    endif else begin

      ;create array with equal spacing
      pad = median(y - shift(y,1)) * (findgen(n/2.) + 1)
      y = [ min(y) - reverse(pad), y, max(y) + pad ]
      
      rotated_axis = y ;used as plot's x axis
      
    endelse
    
    ;convert to polar
    r = sqrt(x^2 + y^2)
    theta = atan(y,x)
    
    ;rotate by specified angle
    theta += angle * !pi/180.
    
    ;convert to cartesian
    x = cos(theta) * r
    y = sin(theta) * r
    
  endif
  

  ;Get plot axis and annotations
  ;--------------------

  ;check if x or y was requested
  if ~undefined(x0) then begin
    alignment = 'x=' + strtrim(x0,2)
    axis = 'y'
    xaxis = y
  endif else begin
    alignment = 'y=' + strtrim(y0,2)
    axis = 'x'
    xaxis = x
  endelse

  ;adjust annotations and xaxis if the cut was rotated
  if keyword_set(angle) then begin
    alignment += ', ' + ((angle ge 0) ? '+':'-') + strtrim(angle,2) + string(byte('b0'xu))
    axis = ''
    xaxis = rotated_axis
  endif
  
  type = slice.energy ? 'E':'V'
  
  xtitle = type + axis + ' (' + alignment + ')' + $
           '  (' + strupcase(slice.rot) + ', ' + $
           strupcase(slice.coord) + ')' + $
           ' ('+slice.xyunits+')'

  
  error = 0b
  
end

