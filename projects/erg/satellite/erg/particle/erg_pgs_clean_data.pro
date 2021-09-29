;+
;
;Author:
;  Tomo Hori, ERG Science Center, Nagoya Univ.
;  (E-mail tomo.hori _at_ nagoya-u.jp)
;
;History:
;  ver.0.0: The 1st experimental release 
;  
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-
pro erg_pgs_clean_data, data_in, output=output, units=units, $
                        magf=magf, muconv=muconv, relativistic=relativistic, $
                        for_moments=for_moments, $
                        debug=debug

  compile_opt idl2, hidden

  erg_convert_flux_units, data_in, units=units, output=data, relativistic=relativistic

  dims = dimen(data.data)
  angdims = long( product( dims[1:*], /int ) )

  output = {  $
           dims: dims, $
           time: data.time, $
           end_time:data.end_time, $
           charge:data.charge, $
           mass:data.mass, $
           species: data.species, $
           magf:[0., 0., 0.], $
           sc_pot:0., $
           scaling:fltarr(dims[0], angdims)+1, $
           units_name:data_in.units_name, $
           psd: reform(data_in.data, dims[0], angdims), $
           data: reform(data.data, dims[0], angdims), $
           bins: reform(data.bins, dims[0], angdims), $
           energy: reform(data.energy, dims[0], angdims), $
           denergy: reform(data.denergy, dims[0], angdims), $
           phi:reform(data.phi, dims[0], angdims), $
           dphi:reform(data.dphi, dims[0], angdims), $
           theta:reform(data.theta, dims[0], angdims), $
           dtheta:reform(data.dtheta, dims[0], angdims) $
           }
    
  ;; Exclude f_nan values from further calculations
    bins = byte(output.bins)
    output.bins = ( bins and finite(output.data) and finite(output.energy) )
  
  ;; Fill invalid values with zero for moment calculations
  if keyword_set(for_moments) then begin
    id = where( output.bins eq 0, nid )
    if nid gt 0 then begin
      output.data[id] = 0.
      output.psd[id] = 0.
      output.energy[id] = 1.
      output.denergy[id] = 1.
    endif
  endif
  
  if tag_exist(data, 'orig_energy') then str_element, output, 'orig_energy', data.orig_energy, /add


  return
end
