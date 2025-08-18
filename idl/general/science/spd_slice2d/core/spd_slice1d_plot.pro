;+
; PROCEDURE:
;  spd_slice1d_plot
;
; PURPOSE:
;  Create 1D plot from a 2D particle slice; note that:
;   1) if the 'value' argument is a scalar, this provides
;      a cut through the distribution at the nearest point
;      in that direction
;   2) if the 'value' argument is an array, this sums over
;      the values between the min and max of the array
;
; EXAMPLES:
;  MMS> spd_slice1d_plot, slice, 'x', 0.0, title='Vx at Vy=0'
;  
;  or
;  
;  MMS> spd_slice1d_plot, slice, 'x', [-1000, 1000], title='Vx at Vy=[-1000, 1000] (summed)'
;
; see: projects/mms/examples/advanced/mms_slice2d_1d_plot_crib.pro for more examples
; 
; INPUT:
;  slice: slice returned by spd_slice2d
;  direction: axis to plot - 'x' or 'y'
;  value: if direction is 'x', this is the y-value to create a 1D plot at; 
;         can also be a range of values, e.g., [-1000, 1000] to sum over 
;         the y-values from -1000 to +1000 
;
; KEYWORDS:
;   accepts most keywords accepted by the PLOT procedure
;
; NOTES:
;   work in progress! please send bugs/problems/complaints/etc to egrimes@igpp.ucla.edu
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-11-30 13:11:06 -0800 (Fri, 30 Nov 2018) $
;$LastChangedRevision: 26211 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice1d_plot.pro $
;-

pro spd_slice1d_plot, slice, direction, value, xrange=xrange, yrange=yrange, _extra=ex
  compile_opt idl2

  if ~is_struct(slice) then begin
    dprint, dlevel = 0, 'Error, invalid slice'
    return
  endif
  
  if undefined(value) || (strlowcase(direction) ne 'x' && strlowcase(direction) ne 'y') then begin
    dprint, dlevel = 0, 'Error, invalid direction; valid options are: "x" or "y"'
    return
  endif
  
  if undefined(value) then begin
    dprint, dlevel = 0, 'Error, no value provided.'
    return
  end
  
  if undefined(xrange) then begin
    if direction eq 'x' then xrange = minmax(slice.ygrid)
    if direction eq 'y' then xrange = minmax(slice.xgrid)
  endif
  
  ; Get general annotations
  spd_slice2d_getinfo, slice, $
    title=title, $
    short_title=short_title, $
    xtitle=xtitle, $
    ytitle=ytitle, $
    ztitle=ztitle

  yunits = spd_units_string(strlowcase(slice.units))
  xunits = slice.XYUNITS
  
  xmargin = [11,9]
  ymargin = [4,2]

  if slice.energy eq 0 then xtitle = 'V ('+xunits+')' else xtitle = 'E ('+xunits+')'

  ; multiple points, summed
  if n_elements(value) eq 2 then begin

    if direction eq 'x' then begin
      values_to_include = where(slice.ygrid ge value[0] and slice.ygrid le value[1], value_count)
      if value_count ne 0 then begin
        plot, slice.xgrid, total(/nan, /double, slice.data[*, values_to_include], 2), xrange=xrange, yrange=yrange, xmargin=xmargin, ymargin=ymargin, xstyle=5, ystyle=5, _extra=ex
      endif
    endif else if direction eq 'y' then begin
      values_to_include = where(slice.xgrid ge value[0] and slice.xgrid le value[1], value_count)
      if value_count ne 0 then begin
        plot, slice.ygrid, total(/nan, /double, slice.data[values_to_include, *], 1), xrange=xrange, yrange=yrange, xmargin=xmargin, ymargin=ymargin, xstyle=5, ystyle=5, _extra=ex
      endif
    endif
    ; replot without the color, for the axes/labels
    if is_struct(ex) then str_element, ex, 'color', /delete
    if ~undefined(ex) && ~is_struct(ex) && ex eq 0 then undefine, ex

    plot, [0, 0], /nodata, /noerase, xtitle=xtitle, ytitle=yunits, xrange=xrange, yrange=yrange, xmargin=xmargin, ymargin=ymargin, xstyle=1, ystyle=1, _extra=ex, color=0
    return
  endif
  
  ; single point
  if direction eq 'x' then begin
    closest_at_this_value = find_nearest_neighbor(slice.ygrid, value)
    idx_at_this_value = where(slice.ygrid eq closest_at_this_value)
    plot, slice.xgrid, slice.data[*, idx_at_this_value], xtitle=xtitle, ytitle=yunits, xrange=xrange, yrange=yrange, xmargin=xmargin, ymargin=ymargin, xstyle=5, ystyle=5, _extra=ex
  endif else if direction eq 'y' then begin
    closest_at_this_value = find_nearest_neighbor(slice.xgrid, value)
    idx_at_this_value = where(slice.xgrid eq closest_at_this_value)
    plot, slice.ygrid, slice.data[idx_at_this_value, *], xtitle=xtitle, ytitle=yunits, xrange=xrange, yrange=yrange, xmargin=xmargin, ymargin=ymargin, xstyle=5, ystyle=5, _extra=ex
  endif
  ; replot without the color, for the axes/labels
  str_element, ex, 'color', /delete
  plot, [0, 0], /nodata, /noerase, xtitle=xtitle, ytitle=yunits, xrange=xrange, yrange=yrange, xmargin=xmargin, ymargin=ymargin, xstyle=1, ystyle=1, _extra=ex, color=0

end