;+
;Procedure:
;  erg_lepi_get_dist
;
;Purpose:
;  The helper function to put all necesssary data and parameters
;  in a 3-D data structure common to part_products libraries. 
;
;Calling Sequence:
;  Usually this routine is called internally by erg_lepi_part_products.
;  Currently the 1st argument "tname" can accept tplot variables in
;  the following list:
;  erg_lepi_l2_3dflux_(FPDU|FHEDU|FODU)
;  And keyword species must be given properly every time this routine is
;  called.
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
function erg_lepi_get_dist $
   , tname, index, trange=trange, times=times $
   , structure=structure $
   , species=species $
   , units=units $
   , level=level $
   , single_time=time_in $
   , subtract_error=subtract_err, error=error $
   , debug=debug $
   , _extra=_extra

  
  compile_opt idl2, hidden

  if undefined(debug) then debug = 0

  
  ;; If given the entire data set and times / time indices
  if is_struct(_extra) then begin
    if is_struct(*(_extra.alldist_ptr)) then begin

      ;;if debug then help, alldist
      
      if ~undefined(index) then begin
        return, (*(_extra.alldist_ptr))[index]
      endif
      
      if ~undefined(single_time) then begin
        nearest_time = find_nearest_neighbor((*(_extra.alldist_ptr)).time, time_double(single_time))
        if nearest_time eq -1 then begin
          dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
          return, 0
        endif
        index = where((*(_extra.alldist_ptr)).time eq nearest_time)
        return, (*(_extra.alldist_ptr))[index]
      endif
    endif
    
  endif

  if undefined(units) then units = 'flux'
  if undefined(level) then level = 'l2'
  level = strlowcase(level)

  name = (tnames(tname))[0]
  if name eq '' then begin
    dprint, 'Variable: "'+tname+'" not found!'
    return, 0
  endif

  ;; Extract some information from a tplot variable name
  ;; e.g., erg_lepi_l2_3dflux_FPDU
  vn_info = strsplit(/ext, name, '_')
  instrument = vn_info[1]
  level = vn_info[2]
  arrnm = vn_info[4]
  if undefined(species) then begin
    case arrnm of
      'FPDU': species = 'proton'
      'FHEDU': species = 'heplus'
      'FODU': species = 'oplus'
      
      else: begin
        dprint, 'ERROR: given an invalid tplot variable: '+name
        return, 0
      endelse
    endcase
  end
  
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

  ;; LEP-i Lv2 normal mode data for the wide channels
  ;; Array[3922(time), 30(energy), 8(anode: ch0-7), 16(spin phase)]
  ;; 
  
  ;; Dimensions
  dim = (size(*p.y, /dim))[1:*]
  dim = dim[ [0, 2, 1] ] ;; to [ energy, spin phase(azimuth), anode(elevation) ]
  base_arr = fltarr(dim)

  ;; Support data
  ;; Mass is given in eV/(km/s)^2 for compatibility with other
  ;; routines
  case strlowcase(species) of

    'hplus': begin
      mass = 1.04535e-2
      charge = 1.
      data_name = 'LEP-i Proton 3dflux'
    end
    'proton': begin
      mass = 1.04535e-2
      charge = 1.
      data_name = 'LEP-i Proton 3dflux'
    end
    'heplus': begin
      mass = 1.04535e-2 * 4
      charge = 1.
      data_name = 'LEP-i He+ ion 3dflux'
    end
    'oplus': begin
      mass = 1.04535e-2 * 16
      charge = 1.
      data_name = 'LEP-i O+ ion 3dflux'
    end
    
    else: begin
      dprint, 'given species is not supported by this routine.'
      return, 0
    endelse
    
  endcase

  integ_time = 7.99 / 32 / 16 ;; currently hard-coded

  ;; basic template structure compatible with spd_slice2d and other
  ;;routines
  template = $
     { $
     project_name: 'ERG', $
     spacecraft: 1, $           ; always 1 as a dummy value
     data_name: data_name, $
     units_name: 'flux', $      ; LEP-i data in [/keV/q-s-sr-cm2] 
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
     nbins: long(product(dim[1:*], /int)), $    ; # thetas * # phis
     phi: base_arr, $
     dphi: base_arr, $
     theta: base_arr, $
     dtheta: base_arr $
     }

  dist = replicate( template, n_times)
    
  ;; Then, fill in arrays in the data structure
  ;;   dim[ nenergy, nspinph(azimuth), nanode(elevation), ntime]
  
  dist.time = (*p.x)[index]
  dist.end_time = (*p.x)[index] + integ_time ;; currently hard-coded

  ;; Shuffle the original data array [time,energy, anode, spin phase] to
  ;; be energy-azimuth(spin phase)-elevation(anod)-time.
  ;; The factor 1e-3/charge is to convert [/keV/q-s-sr-cm2] (default
  ;; unit of LEP-i Lv2 flux data) to [eV-s-sr-cm2]. 
  dist.data = transpose( (*p.y)[index, *, *, *], [1, 3, 2, 0] ) * 1e-3 / abs(charge)

  ;; fishy negative flux values are all replaced with zero.
  dat = dist.data
  id = where( dat lt 0., nid )
  if nid gt 0 then dat[id] = 0.
  dist.data = temporary(dat)
  
  
  ;; Energy ch
  ;; Default unit of v in F?DU tplot variables [keV/q] should be
  ;; converted to [eV] by multiplying (1000 * charge number). 
  e0 = *p.v *1e3 * abs(charge) ;; [30] 
  dist.energy =  rebin( reform( e0, [dim[0], 1,  1, 1]), [dim, n_times] )

  ;; Energy bin width
  e0bnd = sqrt( e0 * e0[1:*] ) ;; [29]
  e0bnd_p = [ e0bnd[0], e0bnd ] ;; [30]  upper boundary of energy bin
  e0bnd_p[ [0, 1] ] = e0[1] + (e0[1]-e0bnd[1])
  e0bnd_m = [ e0bnd, e0bnd[28] ] ;; [30] lower boundary of energy bin
  e0bnd_m[0] = e0bnd_m[1]
  e0bnd_m[29] = e0[29] - (e0bnd[28]-e0[29])
  de = e0bnd_p-e0bnd_m ;; width of energy bin
  dist.denergy = rebin( reform(de, [dim[0], 1, 1, 1]), [dim, n_times] )
  
  ;; Array elements containing NaN are excluded from the further
  ;; calculations, by setting bins to be zero. 
  dist.bins = ( finite( dist.data ) and finite( dist.energy ) )
  dist.bins[0, *, *, *] = 0 ;; Energy ch. 0 is not used.. 
  
  ;; angle array of the flux (particle-going) directions
  angarr = get_lepi_flux_angle_in_sga()  ;;[elev/phi, min/cnt/max, (anode)] in SGA
  angarr = reform( angarr[*, 1, 0:7] )  ;; --> [elv/phi, ch0-7] 
  
  phissi = reform( angarr[1, *] ) - (90.+21.6) ;; [(anode)] 
  spinph_ofst = *p.v3 * 22.5
  phi0 = rebin( reform(phissi, [1, 1, dim[2], 1]), [dim, n_times] ) $
         + rebin( reform(spinph_ofst, [1, dim[1], 1, 1]), [dim, n_times] )

  ofst_sv = (findgen(dim[0])+0.5) * 22.5/32 ;; [(energy)]
  phi_ofst_for_sv = rebin( reform(ofst_sv, [dim[0], 1, 1, 1]), [dim, n_times] )
  ;;  phi angle for the start of each spin phase
  ;;    + offset angle foreach sv step
  dist.phi = ( phi0 + phi_ofst_for_sv + 360. ) mod 360 
  dist.dphi = replicate( 22.5, [dim, n_times] ) ;; 22.5 deg as a constant
  undefine, phi0, phi_ofst_for_sv  ;; Clean huge arrays

  ;; elevation angle
  elev = reform( angarr[0, *] ) ;; [(anode)]
  dist.theta = rebin( reform(elev, [1, 1, dim[2], 1]), [dim, n_times] )

  dist.dtheta = replicate( 22.5, [dim, n_times] ) ;; Fill all with 22.5 
    
  
  return, dist
end
