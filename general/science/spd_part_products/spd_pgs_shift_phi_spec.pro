

;+
;Purpose:
;  The new y range may not align perfectly with the shifted 
;  data, causing a white bar at the top of the plot.  This 
;  routine copies the botton row onto the top to cover the 
;  white space.
;  
;  (requested fix, probably no good solution)
;
;  ^ The other solution would be to snap the new y axis range
;    to that of the reordered bins rather than plotting exactly
;    what the user requested.
;
;Arguments:
;  data: data structure from tplot, already shifted
;  yrange: full range of y data from main routine
;
;-
pro spd_pgs_shift_phi_spec_pad, data, yrange

    compile_opt idl2, hidden

  tsize = n_elements(data.x)
  ysize = dimen2(data.v)
  dsize = dimen2(data.y)

  ;expand y axis
  if ysize eq 1 then begin
    
    ;assumes v component is monotonic
    v_tmp = [data.v, data.v[0] + yrange[1] ]
    
  endif else begin
    
    ;assumes finite v values monotonic at each time sample
    v_tmp = fltarr(tsize,ysize+1,/nozero)
    v_tmp[0,0] = data.v
    v_tmp[0,ysize] = data.v[*,0] + yrange[1]
    
  endelse

  ;copy data to larger array
  y_tmp = fltarr(tsize,dsize+1,/nozero)
  y_tmp[0,0] = data.y
  y_tmp[0,dsize] = data.y[*,0]
  
  data = {x:data.x, y:temporary(y_tmp), v:temporary(v_tmp)}

end


;+
;Procedure:
;  spd_pgs_shift_phi_spec
;
;Purpose:
;  Shifts phi (longitudinal) spectrogram's y-axis to start at a different angle.
;
;Input:
;  names: string or string array of tplot variable names (wildcards accepted)
;  start_angle: value in degrees at which to start the plot (e.g. 90, 180)
;
;Output:
;  None, alters input tplot variable(s).
;
;Notes:
;  -Bins intersected by the start angle will be copied to the top (end)
;   of the spectrogram to ensure that the portion of those bin that is <
;   the start angle is still plotted.
;  -This procedure assumes that the input variables' y axes are
;   monotonic and that any NaNs are at the end of the arrays.
;  -NaNs in the y axis are shifted along with valid numbers to
;   ensure that missing data along the original spectrogram's
;   edge is represented correctly.
;    
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-08-04 18:15:27 -0700 (Thu, 04 Aug 2016) $
;$LastChangedRevision: 21602 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_shift_phi_spec.pro $
;-

pro spd_pgs_shift_phi_spec, names=names_in, start_angle=start_angle

  compile_opt idl2, hidden
  
  if ~keyword_set(start_angle) then begin
    start_angle = 0.
  endif
  
  
  ;this should be the range of the data being passed in,
  ;could be made a keyword in the future if needed
  yrange = [0,360.]


  ;angle must be within yrange for value_locate to work  
  angle = float(start_angle) mod yrange[1]
  
  absolute_shift = start_angle - angle
    
  if angle lt 0 then begin
    angle = yrange[1] + angle
  endif
  
  
  ;get valid tplot variable names
  names = tnames(names_in)
  
  if names[0] eq '' then begin
    dprint, dlevel=0, 'No valid tplot variables detected for: "'+strjoin(names_in,'", "')+'"'
    return
  endif
  
  
  ;loop over tplot variables
  for i=0, n_elements(names)-1 do begin
  
  
    get_data, names[i], data=data, dlimits=dl
    
    if ~is_struct(data) then begin
      dprint, dlevel=0, 'No valid tplot variable: "'+names[i]+'", no start angle applied.'
      continue
    endif
    
    
    ;1D Y Axis
    ;----------
    ;use value locate for single dimensional y axis
    if dimen2(data.v) eq 1 then begin
    
      ;check if shift is needed
      idx = value_locate(data.v, angle)
      
      ;shift axis & data
      if idx gt 0 and idx lt n_elements(data.v) then begin
      
        data.v = shift(data.v, -1*idx )
        data.y = shift(data.y, [0,-1*idx] )
      
        ;keep y axis monotonic
        disjoint = n_elements(data.v) - idx
        
        if start_angle gt 0 then begin
          data.v[disjoint:n_elements(data.v)-1] += yrange[1]
        endif else begin
          data.v[ 0:disjoint-1 > 0] -= yrange[1]
        endelse
      
      endif
      
    ;2D Y Axis
    ;----------
    ;Compare values and check # of NaNs for two dimensional y axis.
    ;NaNs will always be at the end of the second dimension
    ;so this should give a complete list of places where the
    ;y axis changes. Each segment will then be shifted separately.
    endif else begin
    
      ;find changes in y axis values
      vc = where(  total( abs(data.v - shift(data.v,[-1,0])) , 2, /nan)  ,nvc)
      
      ;find changes in the number of nans
      nc = uniq(  total( finite(data.v,/nan), 2)  )
      
      ;combine
      if nvc gt 0 then begin
        end_idx = ssl_set_union(nc,vc)
      endif else begin
        end_idx = nc
      endelse
      
      ;get starting index for each segment
      if n_elements(end_idx) eq 1 then begin
        start_idx = [0]
      endif else begin
        start_idx = [0, end_idx[0:n_elements(end_idx)-2] + 1]
      endelse
      
      ;loop over segments
      for j=0, n_elements(start_idx)-1 do begin

        ;NaNs at the end will mess up value_locate
        last_num = max( where( finite(data.v[start_idx[j],*]), nnum ) )
        
        if nnum eq 0 then continue ;just in case

        ;shift this section of the spectrogram leaving the NaNs in place
        idx = value_locate( data.v[start_idx[j,*],0:last_num], angle )
        
        if idx le 0 or idx gt last_num then continue ;no shift
        
        data.v[start_idx[j]:end_idx[j],*] = shift( data.v[start_idx[j]:end_idx[j],*], [0,-1*idx] )
        data.y[start_idx[j]:end_idx[j],*] = shift( data.y[start_idx[j]:end_idx[j],*], [0,-1*idx] )

        ;find where values were wrapped to keep them monotonic
        disjoint = n_elements( data.v[start_idx[j,*],*] ) - idx

        if start_angle gt 0 then begin
           data.v[start_idx[j]:end_idx[j], disjoint:dimen2(data.v)-1] += yrange[1]
        endif else begin
          data.v[start_idx[j]:end_idx[j], 0:disjoint-1 > 0] -= yrange[1]
        endelse
        
      endfor
    
    endelse
    
    data.v += absolute_shift
    
    ;copy bottom bin onto top of spectrogram to account for white space
    ;cause by shift value not being aligned with bin edges
    spd_pgs_shift_phi_spec_pad, data, yrange
    
    
    ;store shifted data
    str_element, dl, 'yrange', yrange+start_angle, /add_replace
    store_data, names[i], data=data, dlimits=dl,verbose=0
  
  endfor
  
  
end