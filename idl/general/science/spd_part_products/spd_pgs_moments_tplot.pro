;+
;Procedure:
;  spd_pgs_moments_tplot
;
;
;Purpose:
;  Creates tplot variables from moments structures.  Originally developed for THEMIS, but can be used for other missions (e.g. MMS).
;
;
;Arguments:
;  moments:  Array of moments structures returned from moments_3d 
;  
;  
;Keywords:
;  get_error: Flag indicating that the current moment structure
;             contains error estimates.
;  no_mag: Flag to omit outputs associated with b field
;  prefix: Tplot variable name prefix (e.g. 'tha_peif_')
;  suffix: Tplot variable name suffix
;  tplotnames: Array of tplot variable names created by the parent 
;              routine.  Any tplot variables created in this routine
;              should have their names appended to this array.
;  coords: Coordinate system to be used for non-FA moments that need coordinate metadata. Defaults to 'DSL'.
;  use_mms_sdc_units: Flag to convert pressure values and units to nPa, and heat flux values and units to mW/m^2, 
;              for compatibility with MMS SDC moments data.
;  
;
;Notes:
;  Much of this code was copied from thm_part_moments.pro
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-07-12 19:14:21 -0700 (Sat, 12 Jul 2025) $
;$LastChangedRevision: 33459 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_moments_tplot.pro $
;-
pro spd_pgs_moments_tplot, moments, $
                           get_error=get_error, $
                           no_mag=no_mag, $
                           prefix=prefix0, $
                           suffix=suffix0, $
                           tplotnames=tplotnames, $
                           coords=coords, $
                           use_mms_sdc_units=use_mms_sdc_units, $
                           _extra = _extra

    compile_opt idl2, hidden


  if undefined(prefix0) then prefix='' else prefix=prefix0
  if undefined(suffix0) then suffix='' else suffix=suffix0
  
  if undefined(use_mms_sdc_units) then use_mms_sdc_units=0
  if keyword_set(use_mms_sdc_units) then begin
    ; MMS SDC units
    pressure_conversion_factor = 0.000160217663d
    pressure_units = 'nPa'
    pressure_subtitle = '!c[NPa]'
    
    qflux_conversion_factor = 1.6021765974585869d-12
    qflux_units='mW/m^2'
    qflux_subtitle = '!c[mW/m^w]'
  endif else begin
    ; Standard moments_3d units
    pressure_conversion_factor = 1.0D
    pressure_units = 'eV/cm^3'
    pressure_subtitle = '!c[eV/cm^3]'
    
    qflux_conversion_factor = 1.0
    qflux_units='eV/(cm^2-sec)'
    qflux_subtitle = '!c[eV/(cm^2-sec)]'
  endelse
  
  if keyword_set(get_error) then suffix = '_sigma'+suffix
  ; Default to DSL coordinates if not specified
  if n_elements(coords) eq 0 or (size(coords,/type) ne 7) then coords='DSL'


  ;Get names of valid moments
  if keyword_set(get_error) then begin
    ;error estimates produced by moments_3d
    valid_moments = ['avgtemp', 'density', 'eflux', 'flux', $
                     'mftens', 'ptens', 'sc_current', $
                     'velocity', 'vthermal']
  endif else if keyword_set(no_mag)  then begin
    ;error estimates produced by moments_3d
    valid_moments = ['avgtemp', 'density', 'eflux', 'flux', $
      'mftens', 'ptens', 'sc_current', $
      'velocity', 'vthermal', 'qflux']
  endif else begin
    ;moments produced by moments_3d
    valid_moments = ['avgtemp', 'density', 'eflux', 'flux', $
                     'mftens', 'ptens', 'sc_current', $
                     'velocity', 'vthermal', 'qflux', $
                     'magf', 'magt3', 't3', 'sc_pot', 'symm', $
                     'symm_theta', 'symm_phi', 'symm_ang']
  endelse


  ;Create tplot variables
  ;-----------------------------------------


  ;loop over valid names to create variables
  ;options will be set later
  for i=0, n_elements(valid_moments)-1 do begin
  
    tname = prefix + valid_moments[i] + suffix
    
    mom_data = struct_value(moments, valid_moments[i])
    If(n_elements(mom_data) Gt 1) Then Begin
       mom_data = reform(transpose(temporary(mom_data))) ;copied from tpm
    Endif

    if valid_moments[i] eq 'qflux' then begin
      store_data, tname, data= {x:moments.time, y:mom_data*qflux_conversion_factor} ;,verbose=0    
    endif else if valid_moments[i] eq 'ptens' then begin
      store_data, tname, data= {x:moments.time, y:mom_data*pressure_conversion_factor} ;,verbose=0
    endif else begin
     store_data, tname, data= {x:moments.time, y:mom_data} ;,verbose=0
    endelse
    if size(/n_dimen,mom_data) gt 1 then options,tname,colors='bgr',/def
    
    mom_tnames = undefined(mom_tnames) ? tname:array_concat(mom_tnames,tname)
    
  endfor
  
  
  ;Set tplot options
  ;-----------------------------------------
  
  ;set ranges and subtitles (mostly copied from thm_part_moments)
  options,strfilter(mom_tnames,'*_density'+suffix),/def ,/ystyle,ysubtitle='!c[1/cc]'
  options,strfilter(mom_tnames,'*_velocity'+suffix),/def ,yrange=[-800,800.],/ystyle,ysubtitle='!c[km/s]'
  options,strfilter(mom_tnames,'*_flux'+suffix),/def ,yrange=[-1e8,1e8],/ystyle,ysubtitle='!c[#/s/cm2 ??]'
  options,strfilter(mom_tnames,'*t3'+suffix),/def ,yrange=[1,10000.],/ystyle,/ylog,ysubtitle='!c[eV]'
  options,strfilter(mom_tnames,'*mftens'+suffix),/def ,colors='bgrmcy',ysubtitle='!c[eV/cm^3]'
  options,strfilter(mom_tnames,'*ptens'+suffix),/def ,colors='bgrmcy',ysubtitle=pressure_subtitle
  options,strfilter(mom_tnames,'*_eflux'+suffix),/def ,colors='bgr',ysubtitle='!c[eV/(cm^2-s)]'  
  options,strfilter(mom_tnames,'*_qflux'+suffix),/def ,colors='bgr',ysubtitle=qflux_subtitle
    
  ;set units (copied from thm_part_moments)
  spd_new_units, strfilter(mom_tnames, '*_density'+suffix), units_in = '1/cm^3'
  spd_new_units, strfilter(mom_tnames,'*_velocity'+suffix), units_in = 'km/s'
  spd_new_units, strfilter(mom_tnames,'*_vthermal'+suffix), units_in = 'km/s'
  spd_new_units, strfilter(mom_tnames,'*_flux'+suffix), units_in = '#/s/cm^2'
  spd_new_units, strfilter(mom_tnames,'*t3'+suffix), units_in = 'eV'
  spd_new_units, strfilter(mom_tnames,'*_avgtemp'+suffix), units_in = 'eV'
  spd_new_units, strfilter(mom_tnames,'*_sc_pot'+suffix), units_in = 'V'
  spd_new_units, strfilter(mom_tnames,'*_eflux'+suffix), units_in = 'eV/(cm^2-s)'
  spd_new_units, strfilter(mom_tnames,'*_qflux'+suffix), units_in = qflux_units
  spd_new_units, strfilter(mom_tnames,'*mtens'+suffix), units_in = 'eV/cm^3'
  spd_new_units, strfilter(mom_tnames,'*ptens'+suffix), units_in = pressure_units
  spd_new_units, strfilter(mom_tnames,'*_symm_theta'+suffix), units_in = 'degrees'
  spd_new_units, strfilter(mom_tnames,'*_symm_phi'+suffix), units_in = 'degrees'
  spd_new_units, strfilter(mom_tnames,'*_symm_ang'+suffix), units_in = 'degrees'
  spd_new_units, strfilter(mom_tnames,'*_magf'+suffix), units_in = 'nT'

  ;set coordinates (copied from thm_part_moments)
  spd_new_coords, strfilter(mom_tnames,'*_velocity'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*_flux'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*_t3'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*_eflux'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*_qflux'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*tens'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*_magf'+suffix), coords_in = coords
  spd_new_coords, strfilter(mom_tnames,'*_magt3'+suffix), coords_in = 'FA'

  
  ;Output the names of created tplot variables
  ;-----------------------------------------
  tplotnames = undefined(tplotnames) ? mom_tnames:array_concat(tplotnames,mom_tnames)


  return

end
