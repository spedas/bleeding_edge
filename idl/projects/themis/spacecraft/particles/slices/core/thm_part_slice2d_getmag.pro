;+
;Procedure:
;  thm_part_slice2d_getmag
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Retrieves an average of the b-field vectors over the 
;  slice's time range either from the particle structures 
;  or a user specified tplot variable.
;
;
;Input:
;  ds: (pointer) Pointer array to particle distribution structures.
;  trange: (double) Two element time range.
;  mag_data: (string) Name of tplot variable containing b-field data.
;  
;
;Output:
;  return value: (float) Average magnetic field vector or -1 on error.
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_getmag.pro $
;
;-
function thm_part_slice2d_getmag, ds, mag_data=mag_data, $
                                  trange=trange, $
                                  fail=fail

    compile_opt idl2, hidden
  
  
  
  if keyword_set(mag_data) then begin
  
    ; user specified tplot variable 
    bfield = thm_dat_avg(mag_data, trange[0], trange[1], /interp)
  
    if total(finite(bfield,/nan)) gt 0 then begin
      fail = 'Invalid magnetic field variable: "'+mag_data+'".'
      dprint, dlevel=1, fail
      return, -1
    endif
  
  endif else begin
    
    ; data added in thm_part_dist_array
    for i=0, n_elements(ds)-1 do begin
      ; only use data in requested time range
      times_ind = thm_part_slice2d_intrange(ds[i], trange, n=ndat)
      if ndat gt 0 then begin
        bdata = ~keyword_set(bdata) ? [ (*ds[i])[times_ind].magf ]   :    $
                                      [ [bdata], [(*ds[i])[times_ind].magf] ]
      endif
    endfor 
    
    if ~keyword_set(bdata) then begin
      fail = 'Unknown error retrieving B field data. '+ $
             'Please report this to the TDAS development team.' 
      dprint, dlevel=0, fail
      return, -1
    endif
    
    ;average combined data
    bfield = average(bdata, 2)
    
  endelse
  
  return, bfield

end
