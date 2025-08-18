
;+
;Important:
;  This is an incomplete helper function and is still in development.
;
;
;Procedure:
;  thm_part_slice1d_mult
;
;Purpose:
;  Produce line plots from particle velocity slices along various orientations.
;  
;Calling Sequence:
;  thm_part_slice1d, slice, [,x=x | ,y=y | ,v=v | ,e=e ] [,angle=angle] [,data=data]
;
;Input:
;     slice: slice structure from thm_part_slice2d
;         x: values at which to align cut along the x axis (km/s)
;         y: values at which to align cut along the y axis (km/s)
;            (defaults to y=0 if x, y, v, e not set)
;         v: values at which to align a radial cut (km/s)
;         e: values at which to align a radial cut (eV)
;     angle: value (degrees) to rotate the cut by if using x or y 
;
;Graphis Keywords: 
;   -Any IDL graphics keywords that are valid for the "plot" and "oplot" procedure
;    may also be used.
;
;Output:
;
;
;Notes:   
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice1d_mult.pro $
;
;-

pro thm_part_slice1d_mult, slice, $
                      ; output  keywords
                      type=type, $
                      value=value, $
                      angle=angle, $
                      ; plotting keywords
                      overplot=overplot, $
                      xrange=xrange0, $
                      yrange=yrange0, $
                      ; other
                      data=data, $
                      error=error, $
                      _extra=_extra

    compile_opt idl2


  if ~is_struct(slice) then begin
    dprint, dlevel=1, 'Input must be slice structure from thm_part_slice2d'
    return
  endif

  
  ;Only allow single output type
  output = [ n_elements(v0), n_elements(e0), n_elements(x0), n_elements(y0) ]
  idx = where(output gt 0, no)
  if no ne 1 then begin
    dprint, dlevel=1, 'Must specify single cut type (v=v, e=e, x=x, or y=y).'
    return
  endif
  
  
  ncuts = output[idx[0]] ;"[0]" index to ensure output not an array

  
  ;set angle to 0 if 
  if undefined(angle) then angle=0
  nangles = n_elements(angle)
  
  
  if ncuts ne nangles then begin
    if ncuts eq 1 or nangles eq 1 then begin
      ncuts = nangles > ncuts
    endif else begin
      dprint, dlevel=1, 'Number of angles must match the number of '+ $
                        'cuts when both are specified as arrays.'
      return
    endelse
  endif

  
  
  ;Loop over requested cuts
  for i=0, ncuts-1 do begin
  
  
    ;This section will allow for array keywords to be passed in through _extra.
    ;Scalar keywords will be applied to all cuts.
    ;Array keywords will be applied to cuts in the order given.
    if is_struct(_extra) then begin
      
      ex = _extra
      tags = tag_names(ex)
      
      for j=0, n_elements(tags)-1 do begin
        nti = n_elements(ex.(j))
        if nti ge ncuts then begin
          str_element, ex, tags[j], (_extra.(j))[i], /add_replace
        endif else if nti gt 1 then begin
          str_element, ex, tags[j], /delete
          dprint, dlevel=1, 'Incorrect number of elements for keyword: "'+tags[j]+'"'
          continue
        endif
      endfor
      
      ;prevent error in case all tags are removed
      if ~is_struct(ex) then ex = {dummy:0}
      
    endif
  
  
    ;Call the core code
    ;This will both produce the plot and pass out the data to this routine.
    if ~undefined(v0) then begin
      thm_part_slice1d, slice, v=v0[i], overplot=overplot, error=error, _extra=ex
    endif else if ~undefined(e0) then begin
      thm_part_slice1d, slice, e=e0[i], overplot=overplot, error=error, _extra=ex
    endif else if ~undefined(x0) then begin
      thm_part_slice1d, slice, x=x0[i mod n_elements(x0)], angle=angle[i mod n_elements(angle)], $
                             overplot=overplot, error=error, _extra=ex
    endif else begin
      thm_part_slice1d, slice, y=y0[i mod n_elements(y0)], angle=angle[i mod n_elements(angle)], $
                             overplot=overplot, error=error, _extra=ex
    endelse
    
    
    ;Draw over the current plot once one exists
    if ~error then overplot = 1b
    
   
  endfor



end