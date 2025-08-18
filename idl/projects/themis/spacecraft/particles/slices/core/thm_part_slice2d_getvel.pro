;+
;Procedure:
;  thm_part_slice2d_getvel
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Retrieves an average of the bulk velocity vectors over the 
;  slice's time range either from the particle structures 
;  or a user specified tplot variable.
;
;
;Input:
;  ds: (pointer) Pointer array to particle distribution structures.
;  trange: (double) Two element time range.
;  vel_data: (string) Name of tplot variable containing bulk velocity data (in km/s).
;  
;
;Output:
;  return value: (float) Average bulk velocity vector (m/s) or -1 on error.
;
;
;Notes:
;  thm_esa_slice2d divides total flux over the time range by 
;  the total density; here the flux/density was previously 
;  calculated for each distribution and is now averaged.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_getvel.pro $
;
;-
function thm_part_slice2d_getvel, ds, vel_data=vel_data, $
                                trange=trange, $
                                energy=energy, $
                                fail=fail

    compile_opt idl2, hidden
  
  
  thm_part_slice2d_const, c=c
  
  
  if keyword_set(vel_data) then begin
  
    ; user specified variable
    ; this assumes the data is in km/s!
    vbulk = thm_dat_avg(vel_data, trange[0], trange[1], /interp)

    if total(finite(vbulk,/nan)) gt 0 then begin
      fail = 'Invalid velocity variable: "'+vel_data+'".'
      dprint, dlevel=1, fail
      return, -1
    endif

  endif else begin
  
  
    ; data added in thm_part_dist_array
    for i=0, n_elements(ds)-1 do begin 
      ; only use data in requested time range
      times_ind = thm_part_slice2d_intrange(ds[i], trange, n=ndat)
      if ndat gt 0 then begin
        vdata = ~keyword_set(vdata) ? [ (*ds[i])[times_ind].velocity ]  :  $
                                      [ [vdata], [(*ds[i])[times_ind].velocity] ]
      endif
    endfor 
    
    if ~keyword_set(vdata) then begin
      fail = 'Unknown error retrieving bulk velocity data. '+ $
             'Please report this to the TDAS development team.' 
      dprint, dlevel=0, fail
      return, -1
    endif
  
    ; average combined data
    vbulk = average(vdata, 2) ;vel in km/s
  
  endelse


  ;if plotting against energy convert km/s to eV
  if keyword_set(energy) then begin
    
    ;convert from eV/(km/s)^2 to eV/c^2
    erest = (*ds[0])[0].mass * c^2 / 1e6
    
    vmag = sqrt( total(vbulk^2) )
    vdir = vbulk / vmag
    
    ;vector magnitude converted to eV
    emag = erest * ( 1/sqrt(1-(vmag/c)^2) - 1 ) 
    
    vbulk = emag * vdir
  endif


  return, vbulk

end
