;+
;Procedure:
;  erg_mepe_get_dist
;
;Purpose:
;  The helper function to put all necesssary data and parameters
;  in a 3-D data structure common to part_products libraries. 
;
;Calling Sequence:
;  Usually this routine is called internally by erg_mep_part_products.
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
function erg_mepe_get_dist $
   , tname, index, trange=trange, times=times $
   , structure=structure $
   , species=species $
   , units=units $
   , level=level $
   , single_time=time_in $
   , subtract_error=subtract_err, error=error $
   , _extra=_extra

  
  compile_opt idl2, hidden

  if undefined(units) then units = 'flux'
  if undefined(level) then level = 'l2'
  level = strlowcase(level)

  name = (tnames(tname))[0]
  if name eq '' then begin
    dprint, 'Variable: "'+tname+'" not found!'
    return, 0
  endif

  ;; Extract some information from a tplot variable name
  ;; e.g., erg_mepe_l2_3dflux_FEDU
  vn_info = strsplit(/ext, name, '_')
  instrument = vn_info[1]
  level = vn_info[2]
  vn_spph = strjoin( vn_info[0:3], '_' ) + '_spin_phase'
  case instrument of
    'mepe': species = 'e'
    else: begin
      dprint, 'ERROR: given an invalid tplot variable: '+name
      return, 0
    endelse
  endcase
  
  ;; Get a reference to data and metadata
  get_data, name, ptr=p, dlimits=dl
  if ~is_struct(p) then begin
    dprint, 'Variable: "'+tname+'" contains invalid data or no data!'
    return, 0
  endif
  if size(*p.y, /n_dim) ne 4 then begin
    dprint, 'Variable: "'+tname+'" contains wrong number of elements!'
    return, 0
  endif
  
  ;; Return time labels
  if keyword_set(times) then begin
    return, *p.x
  endif

  ;; single_time supersedes index and trange
  if ~undefined(single_time) then begin
    nearest_time = find_nearest_neighbor(*p.x, time_double(single_time))
    if nearest_time eq -1 then begin
      dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
      return, 0
    endif
    index = where(*p.x eq nearest_time)
    n_times = n_elements(index)
  endif else begin
    ;;index supersedes time range
    if undefined(index) then begin
      if ~undefined(trange) then begin
        tr = minmax(time_double(trange))
        index = where( *p.x ge tr[0] and *p.x lt tr[1], n_times)
        if n_times eq 0 then begin
          dprint, 'No data in time range: '+strjoin(time_string(tr, tformat='YYYY-MM-DD/hh:mm:ss.fff'), ' ')
          return, 0
        endif
      endif else begin
        n_times = n_elements(*p.x)
        index = lindgen(n_times)
      endelse
    endif else begin
      n_times = n_elements(index)
    endelse
  endelse 

  ;; --------------------------------------------------------------

  ;; MEPe data arr: [9550(time), 32(spin phase), 16(energy), 16(apd)]
  ;; Dimensions
  dim = (size(*p.y, /dim))[1:*]
  dim = dim[ [1, 0, 2] ] ;; to [ energy, spin phase(azimuth), apd(elevation) ]
  n_sp = dim[1] ;; # of spin phases in 1 spin
  base_arr = fltarr(dim)

  ;; Support data
  ;; Mass is given in eV/(km/s)^2 for compatibility with other
  ;; routines
  case strlowcase(species) of

    'e': begin
      mass = 5.68566e-06
      charge = -1.
      data_name = 'MEP-e Electron 3dflux'
      integ_time = 7.99 / 32 / 16 ;; currently hard-coded
    end
    else: begin
      dprint, 'given species is not supported by this routine.'
      return, 0
    endelse
    
  endcase

  ;; basic template structure compatible with spd_slice2d and other
  ;;routines
  template = $
     { $
     project_name: 'ERG', $
     spacecraft: 1, $           ; always 1 as a dummy value
     data_name: data_name, $
     units_name: 'flux', $      ; MEP-e data in [/keV-s-sr-cm2] should be converted to [/eV-s-sr-cm2] 
     units_procedure: 'erg_convert_flux_units', $
     species: species, $
     valid: 1b, $

     charge: charge, $
     mass: mass, $
     time: 0d, $
     end_time: 0d, $

     data: base_arr, $
     bins: base_arr+1, $        ; must be set or data will be consider invalid

     energy: base_arr, $        ; should be in eV
     denergy: base_arr, $
     nenergy: dim[0], $         ; # of energy chs
     nbins: dim[1]*dim[2], $    ; # thetas * # phis
     phi: base_arr, $
     dphi: base_arr, $
     theta: base_arr, $
     dtheta: base_arr $
     }
  
  dist = replicate( template, n_times)
    
  ;; Then, fill in arrays in the data structure
  ;;   dim[ nenergy, nspinph(azimuth), napd(elevation), ntime]
  
  dist.time = (*p.x)[index]
  dist.end_time = (*p.x)[index] + integ_time ;; currently hard-coded

  ;; Shuffle the original data array [time,spin phase,energy,apd] to
  ;; be energy-azimuth-elevation-time.
  ;; The factor 1d-3 is to convert [/keV-s-sr-cm2] (default unit of
  ;; MEP-e Lv2 flux data) to [/eV-s-sr-cm2] 
  dist.data = transpose( (*p.y)[index, *, *, *], [2, 1, 3, 0] ) * 1d-3
  
  ;; Energy ch. 0 is excluded due to difficulty in defining
  ;; the representative energy and energy bin width.
  dist.bins[0, *, *, *] =  0
  
  ;; Energy ch
  e0 = *p.v2 * 1e3  ;; [keV] (default of MEP-e Lv2 flux data) to [eV]
  dist.energy = rebin( reform(e0, [dim[0], 1, 1, 1]), [dim, n_times] )
  ;; Energy bin width
  e0bnd = sqrt( e0 * e0[1:*] )
  e0bnd_p = [ e0bnd[0], e0bnd ] ;; [16]  upper boundary of energy bin
  e0bnd_p[ [0, 1] ] = e0[1] + (e0[1]-e0bnd[1])
  e0bnd_m = [ e0bnd, e0bnd[14] ] ;; [16] lower boundary of energy bin
  e0bnd_m[0] = e0bnd_m[1]
  e0bnd_m[15] = e0[15] - (e0bnd[14]-e0[15])
  de = e0bnd_p-e0bnd_m ;; width of energy bin
  dist.denergy = rebin( reform(de, [dim[0], 1, 1, 1]), [dim, n_times] )
  
  ;; azimuthal angle in spin direction
  angarr = get_mepe_flux_angle_in_sga() ;;[elev/phi, min/cnt/max, (apd)] in SGA

  phissi = reform( angarr[1, 1, *] ) - (90.+21.6) ;; [(apd)] 
  spinph_ofst = *p.v1 * 11.25
  phi0 = rebin( reform(phissi, [1, 1, dim[2], 1]), [dim, n_times] ) $
         + rebin( reform(spinph_ofst, [1, dim[1], 1, 1]), [dim, n_times] )

  ofst_sv = (findgen(dim[0])+0.5) * 11.25/dim[0] ;; [(energy)]
  phi_ofst_for_sv = rebin( reform(ofst_sv, [dim[0], 1, 1, 1]), [dim, n_times] )
  ;;  phi angle for the start of each spin phase
  ;;    + offset angle foreach sv step
  dist.phi = ( phi0 + phi_ofst_for_sv + 360. ) mod 360 
  dist.dphi = replicate( 11.25, [dim, n_times] ) ;; 11.25 deg is set for the moment calculation
  undefine, phi0, phi_ofst_for_sv  ;; Clean huge arrays

  ;; elevation angle
  elev = reform( angarr[0, 1, *] ) ;; [(apd)]
  dist.theta = rebin( reform(elev, [1, 1, dim[2], 1]), [dim, n_times] )
  dist.dtheta = replicate( 11.25, [dim, n_times] ) ;; 11.25 deg is set for the moment calculation

  return, dist
end
