;+
;Procedure:
;  thm_part_slice1d_r
;
;Purpose:
;  Return the set of points at which a radial cut will be interpolated
;  and corresponding plot labels.
;
;Calling Sequence:
;  thm_part_slice1d_r, slice (vin=vin | ein=ein), xout=xout, yout=yout, 
;                      xaxis=xaxis, xtitle=xtitle
;
;Input:
;  slice: 2D slice structure
;  vin: velocity (km/s) at which to create cut
;  ein: energy (eV) at which to create cut
; 
;
;Output:
;  xout: x coordinates of points to interpolate to
;  yout: y coordinates of points to interpolate to
;  xaxis: final plot's x axis (angle)
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice1d_r.pro $
;
;-
pro thm_part_slice1d_r, slice, $
                        vin=v0, ein=e0, $
                        xout=x, yout=y, $
                        xaxis=xaxis, xtitle=xtitle, $
                        error=error

    compile_opt idl2, hidden


  error = 1b


  ;Get values at which to interpolate data
  ;---------------------------------------

  thm_part_slice2d_const, c=c

  ;cuts specified by velocity
  if ~undefined(v0) then begin 
    
    type = 'V'
    units = 'km/s'
    value = v0
    
    ;convert requested value to energy
    if slice.energy then begin
      
      if ~finite(slice.mass) then begin
        dprint, dlevel=0, 'Invalid mass in slice structure, cannot convert requested energy to velocity.  '+ $
                          '2D slice input may have had variable mass.'
        return
      endif
      
      erest = slice.mass * c^2 / 1e6 ; eV/(km/s)^2 -> eV/c^2
      r = erest * ( (1 - (v0*1000.)^2/c^2)^(-.5)  -  1 )

    endif else begin
      
      r = v0
      
    endelse

  ;cuts specified by energy
  endif else if ~undefined(e0) then begin
    
    type = 'E'
    units = 'eV'
    value = e0
    
    if slice.energy then begin
      
      r = e0
      
    ;convert requested value to velocity
    endif else begin
    
      if ~finite(slice.mass) then begin
        dprint, dlevel=0, 'Invalid mass in slice structure, cannot convert requested energy to velocity.  '+ $
                          '2D slice input may have had variable mass.'
        return
      endif
      
      er = slice.mass * c^2 / 1e6 ;  eV/(km/s)^2 -> eV/c^2
      r = c * sqrt( 1 - 1/((e0/er + 1)^2) )
      r = r / 1000. ; m/s -> km/s
      
    endelse
    
  endif else begin
    
    return
    
  endelse


  ;map into normalized log range (see thm_part_slice2d_rlog)
  if keyword_set(slice.rlog) then begin
    
    log_text = 'Radial Log - '
    
    log_range = alog10(slice.rrange)
    r = (alog10(r) - log_range[0]) / (log_range[1] - log_range[0]) > 0
    
  endif else begin
    log_text = ''
  endelse


  ;number of points
  nv = 3 * n_elements(slice.xgrid)

  ;theta values
  t = 2 * !pi * findgen(nv)/nv

  ;cartesian values
  x = r * cos(t)
  y = r * sin(t)


  ;Get plot axis and annotations
  ;--------------------
  
  ;get plot's x axis
  xaxis = 180/!pi * t
  
  ;x axis title
  xtitle = ' '+type+'=' + strtrim(value,2) + ' '+units+ $
           ' (' + log_text + strupcase(slice.rot) + $
           ', ' + strupcase(slice.coord) + ')'
  

  error = 0b

end
