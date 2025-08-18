;+
;Procedure:
;  erg_xep_get_dist
;
;Purpose:
;  The helper function to put all necesssary data and parameters
;  in a 2-D data structure common to part_products libraries. 
;
;Note:
;One needs to have 2-D XEP flux data loaded as a tplot variable
;"erg_xep_l2_FEDU" and spin phase times loaded as
;"erg_xep_l2_each_phase_time" both of which can be obtained from
;erg_xepe_l2_YYYYMMDD_p???.cdf.
;
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
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-
function erg_xep_get_dist $
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
  
  if undefined(units) then units = 'flux'
  if undefined(level) then level = 'l2'
  level = strlowcase(level)

  name = (tnames(tname))[0]
  if name eq '' then begin
    dprint, 'Variable: "'+tname+'" not found!'
    return, 0
  endif

  ;; Extract some information from a tplot variable name
  ;; e.g., erg_xep_l2_FEDU_SSD
  vn_info = strsplit(/ext, name, '_')
  instrument = vn_info[1]
  level = vn_info[2]
  case instrument of
    'xep': species = 'e'
    else: begin
      dprint, 'ERROR: given an invalid tplot variable: '+name
      return, 0
    endelse
  endcase
  
  ;; Get a reference to data and metadata
  get_data, name, ptr=p, dlimits=dl
  if ~is_struct(p) then begin
    dprint, 'Variable: "'+name+'" contains invalid data or no data!'
    return, 0
  endif
  if size(*p.y, /n_dim) ne 3 then begin
    dprint, 'Variable: "'+name+'" contains wrong number of elements!'
    return, 0
  endif
    
  ;; Estimate the spin periods
  ;;;;get_data, 'erg_xep_l2_each_phase_time', t_phtime, phtime

  t_phtime = *p.x 
  sc0_dt = t_phtime[1:*]-t_phtime & sc0_dt = [ sc0_dt, sc0_dt[-1] ]
  n_times = n_elements(t_phtime)
  phtime = dblarr( n_times, 16 )
  phtime = rebin( t_phtime, [n_times, 16] ) + rebin( sc0_dt/16, [n_times, 16] ) * rebin( transpose(dindgen(16)), [n_times, 16] )

  
  ;; The last value is not the real one: currently the 2nd last period is just duplicated. 

  sctintgt = fltarr( n_elements(t_phtime), 16 )
  sctintgt = rebin( sc0_dt/16, [n_times, 16] )
  ;;sctintgt[*, 0:14] = phtime[*, 1:*] - phtime                                    ;;; [ time, 16]
  ;;sctintgt[*, 15] = sc0_dt - phtime[*, 15]  

  if debug then begin
    help, *p.y,  sc0_dt, sctintgt
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

  ;; XEP data arr: [10080(time), 9(energy), 16(spin ph)]
  ;; Dimensions
  dim = (size(*p.y, /dim))[1:*]  ;; [energy, spin phase(azimuth) ]
  ;;dim[0] = 12 ;; Use only the SSD channels for now
  base_arr = fltarr(dim)

  ;; Support data
  ;; Mass is given in eV/(km/s)^2 for compatibility with other
  ;; routines
  case strlowcase(species) of

    'e': begin
      mass = 5.68566e-06
      charge = -1.
      data_name = 'XEP Electron 2dflux'
      integ_time = 7.99 / 16 ;; currently hard-coded
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
     nbins: long( product( dim[1:*], /int) ), $    ; # thetas * # phis
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

  ;; Shuffle the original data array [time,energy,spin phase] to
  ;; be energy-azimuth-time.
  ;; The factor 1d-3 is to convert [/keV-s-sr-cm2] (default unit of
  ;; XEP Lv2 2dflux data) to [/eV-s-sr-cm2].
  ;; Again only SSD channels are used (0:11 for ene. ch.). 
  dist.data = transpose( (*p.y)[index, *, *], [1, 2, 0] ) * 1d-3
  
  ;; No invalid ch is set for XEP currently. 
  ;;dist.bins[0, *, *, *] =  0
  
  ;; Energy ch
  e0 = (*p.v)* 1e3  ;; [MeV] (default of XEP Lv2 FEDU tplot var) to [eV]
  dist.energy = rebin( reform(e0, [dim[0], 1, 1]), [dim, n_times] )
  ;; Energy bin width
  e0bnd = sqrt( e0 * e0[1:*] )  ;; [8]
  e0bnd_p = [ e0bnd, e0bnd[7] ] ;; [9]  upper boundary of energy bin
  e0bnd_p[ 8 ] = e0[8] + (e0[8]-e0bnd[7])
  e0bnd_m = [ e0bnd[0], e0bnd ] ;; [9] lower boundary of energy bin
  e0bnd_m[0] = e0[0] - (e0bnd[0]-e0[0])
  de = e0bnd_p-e0bnd_m ;; width of energy bin [9]
  dist.denergy = rebin( reform(de, [dim[0], 1, 1]), [dim, n_times] )
  
  ;; azimuthal angle in spin direction 
  ;;angarr = get_mepe_flux_angle_in_sga() ;;[elev/phi, min/cnt/max, (apd)] in SGA
  angarr = fltarr( 2, 3 )  ;; [elev/phi, min/cnt/max]
  angarr[0, *] = 0.
  angarr[1, *] = 90.-10.  ;; these angles should be given as particle flux dirs.

  spinper = sc0_dt[index] ;; spin period [n_times]
  if n_elements(spinper) eq 1 then spinper = [ spinper ]
  rel_sct_time = fltarr( n_times, 16 )
  rel_sct_time = phtime[index, *] + sctintgt[index, *]/2 - rebin( reform( phtime[index, 0], [n_times, 1] ), [n_times, 16] ) ;; [n_times,16]
  
  phissi = reform( angarr[1, 1] ) - (90.+21.6) ;; [(1)] 
  spinph_ofst = transpose( rel_sct_time / rebin(spinper, [n_times, 16]) *360.   ) ;; [16, time]
  phi0 = rebin( reform(phissi, [1, 1, 1]), [dim, n_times] ) $
         + rebin( reform(spinph_ofst, [1, dim[1], n_times]), [dim, n_times] )

  ;;  phi angle for the start of each spin phase
  ;;    + offset angle for each spin phase
  dist.phi = ( phi0 + 360. ) mod 360 
  dist.dphi = replicate( 22.5, [dim, n_times] ) ;; 22.5 deg as a constant
  undefine, phi0  ;; Clean huge arrays

  ;; elevation angle
  elev = reform( angarr[0, 1] ) ;; [(1)]
  dist.theta = rebin( reform(elev, [1, 1, 1]), [dim, n_times] )
  dist.dtheta = replicate( 20., [dim, n_times] ) ;; 20 deg (+/- 10 deg)  as a constant
  
  
  return, dist
end
