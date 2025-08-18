
;+
;Procedure:
;  thm_part_slice1d.pro
;
;Purpose:
;  Produce line plots from 2D particle velocity slices along various orientations.
;  
;Calling Sequence:
;  thm_part_slice1d, slice, [,xcut=xcut | ,ycut=ycut | ,vcut=vcut | ,ecut=ecut ]
;                           [,angle=angle] [,/overplot] [,data=data] [,window=window]
;
;Input:
;     slice: slice structure from thm_part_slice2d
;      xcut: value at which to align a linear cut along the x axis (vertical slice)
;      ycut: value at which to align a linear cut along the y axis (horizontal slice)
;            (defaults to ycut=0 if xcut, ycut, vcut, and ecut not set)
;      vcut: value at which to align a radial cut (km/s)
;      ecut: value at which to align a radial cut (eV)
;     angle: value (degrees) to rotate a cut by (clockwise) if using xcut or ycut
;  overplot: flag to add trace to the previous plot
;    window: index of plotting window to be used
;  
;  *IDL graphics keywords may also be used; see IDL documentation for usage.
;   (e.g. color, psym, linestyle)
;
;Output:
;  data: set this keyword to a named variable to return a structure
;        containing the data for the specified 1D slice
;
;Notes:
;  See also: thm_crib_part_slice1d.pro
;   
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-18 11:45:09 -0800 (Thu, 18 Feb 2016) $
;$LastChangedRevision: 20062 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice1d.pro $
;
;-

pro thm_part_slice1d, slice, $
                      ; output type keywords
                      xcut=x0, ycut=y0, angle=angle, $
                      vcut=v0, ecut=e0, $
                      ; plotting keywords
                      xrange=xrange0, $
                      yrange=yrange0, $
                      overplot=overplot, $
                      window=window, $
                      ; other
                      data=data, $
                      error=error, $
                      _extra=_extra

    compile_opt idl2, hidden


  error = 1b
  
  
  if ~is_struct(slice) then begin
    dprint, dlevel=1, 'Input must be slice structure from thm_part_slice2d'
    return
  endif


  ;Construct the set of points the data will be interpolated to.
  if ~undefined(v0) or ~undefined(e0) then begin

    ;Get values & labels for radial cuts
    thm_part_slice1d_r, slice, vin=v0, ein=e0, $
                        xout=x, yout=y, xaxis=xaxis, xtitle=xtitle, $
                        error=sub_error
  
  endif else begin
    
    if keyword_set(slice.rlog) then begin
      dprint, dlevel=1, 'Linear 1D slices not yet implemented for radial log plots'
      return
    endif 
    
    ;Get values & labels for linear cuts
    thm_part_slice1d_xy, slice, xin=x0, yin=y0, angle=angle, $
                         xout=x, yout=y, xaxis=xaxis, xtitle=xtitle, $
                         error=sub_error
  endelse
  
  ;handle error from helper routine
  if keyword_set(sub_error) then return


  ;Get indices to the slice data corresponding to the points determined above
  n = n_elements(slice.xgrid)
  xi = interpol( findgen(n), slice.xgrid, x )
  yi = interpol( findgen(n), slice.ygrid, y ) 


  ;Ensure equal elements in x and y arrays
  ; -important for linear cuts, 
  if n_elements(xi) eq 1 then xi = replicate(xi,n_elements(y))
  if n_elements(yi) eq 1 then yi = replicate(yi,n_elements(x))
  if n_elements(xi) ne n_elements(yi) then begin
    dprint, dlevel=0, 'Error generating coordinates for 1D slice.'
    return
  endif
  

  ;Remove indices outside the plot's range
  ; -primarily here to remove excess points for rotated linear cuts
  idx = where( xi ge 0 and xi le n and $
               yi ge 0 and yi le n ,c )
  if c gt 0 then begin
    xi = xi[idx]
    yi = yi[idx]
    xaxis = xaxis[idx]
  endif else begin
    dprint, dlevel=1, 'The requested 1D slice does not intersect the plot."
    return
  endelse


  ;Interpolate at the calculated set of indicies
  ; (this is the data that will be plotted)
  line = reform(  interpolate(slice.data, xi, yi)  )


  ;Annotations for plotting
  title = 'th'+strlowcase(slice.spacecraft)+' ' + $
          strjoin(slice.data_name,'/') + $
          ' ('+strupcase(slice.rot)+') ' + $
          time_string(slice.trange[0]) + $
          ' -> '+strmid(time_string(slice.trange[1]),11,8) + $
            ' ('+strtrim(fix(slice.n_samples),2)+')'
  xtitle = xtitle ;determined above
  ytitle = units_string(strlowcase(slice.units))
  
  
  xrange = keyword_set(xrange0) ? xrange0:minmax(xaxis)
  yrange = keyword_set(yrange0) ? yrange0:slice.zrange


  ;Plot
  ; -graphics keywords are passed through _extra
  ;  keyword to plot/oplot
  ; -keywords passed through _extra will supercede
  ;  keywords explicitly named in a call (IDL feature)
  thm_part_slice1d_plot, xaxis, line, $
                         overplot=overplot, $
                         title=title, $
                         xtitle=xtitle, $
                         ytitle=ytitle, $
                         xrange=xrange, $
                         yrange=yrange, $
                         window=window, $
                         _extra=_extra


  ;Return data if requested
  if arg_present(data) then begin
    data = {x:xaxis, $
            y:line, $
            xrange: xrange, $
            yrange: yrange, $
            xtitle: xtitle, $ 
            ytitle: ytitle, $
            title: title}
  endif


  error = 0b


  return
  
end


