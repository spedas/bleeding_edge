;+
;FUNCTION:   mvn_swe_get3d
;PURPOSE:
;  Returns a SWEA 3D data structure constructed from L0 data or extracted
;  from L2 data.  This routine automatically determines which data are loaded.
;  Optionally sums the data over a time range, propagating uncertainties.
;
;USAGE:
;  ddd = mvn_swe_get3d(time)
;
;INPUTS:
;       time:          An array of times for extracting one or more 3D data structure(s)
;                      from survey data (APID A0).  Can be in any format accepted by
;                      time_double.
;
;KEYWORDS:
;       ARCHIVE:       Get 3D data from archive instead (APID A1).
;
;       BURST:         Synonym for ARCHIVE.
;
;       ALL:           Get all 3D spectra bounded by the earliest and latest times in
;                      the input time array.  If no time array is specified, then get
;                      all available spectra from the currently loaded data.
;
;       SUM:           If set, then sum all 3D's selected.
;
;       UNITS:         Convert data to these units.  (See mvn_swe_convert_units)
;
;       SHIFTPOT:      Correct for spacecraft potential.
;
;       QLEVEL:        Minimum quality level to load (0-2, default=0):
;                        2B = good
;                        1B = uncertain
;                        0B = affected by low-energy anomaly
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-04-17 15:22:14 -0700 (Thu, 17 Apr 2025) $
; $LastChangedRevision: 33264 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_get3d.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_get3d.pro
;-
function mvn_swe_get3d, time, archive=archive, all=all, sum=sum, units=units, burst=burst, $
                        shiftpot=shiftpot, qlevel=qlevel

  @mvn_swe_com

  if keyword_set(burst) then archive = 1
  delta_t = 1.95D/2D  ; start time to center time
  qlevel = (n_elements(qlevel) gt 0L) ? byte(qlevel[0]) : 0B

  if (size(time,/type) eq 0) then begin
    if not keyword_set(all) then begin
      print,"You must specify a time."
      return, 0
    endif else begin
      if keyword_set(archive) then begin
        str_element, swe_3d_arc, 'time', time, success=ok  ; L0
        if (ok) then time += delta_t ; center times
        if (not ok) then str_element, mvn_swe_3d_arc, 'time', time, success=ok  ; L2
      endif else begin
        str_element, swe_3d, 'time', time, success=ok  ; L0
        if (ok) then time += delta_t ; center times
        if (not ok) then str_element, mvn_swe_3d, 'time', time, success=ok  ; L2
      endelse
      if (not ok) then begin
        print,"Cannot get 3D times."
        return, 0
      endif
    endelse
  endif

  time = time_double(time)

  if (size(units,/type) ne 7) then units = 'EFLUX'
  if keyword_set(shiftpot) then if (n_elements(swe_sc_pot) lt 2) then mvn_scpot

  if (size(swe_mag1,/type) eq 8) then addmag = 1 else addmag = 0
  if (size(swe_sc_pot,/type) eq 8) then addpot = 1 else addpot = 0

; First attempt to get extract 3D(s) from L2 data

  if keyword_set(archive) then begin
    if (size(mvn_swe_3d_arc,/type) eq 8) then begin
      if keyword_set(all) then begin
        if (n_elements(time) eq 1) then begin
          indx = nn2(mvn_swe_3d_arc.time, time, maxdt=32D)
          if (indx eq -1) then npts = 0L else npts = 1L
        endif else begin
          tmin = min(time, max=tmax, /nan)
          indx = where((mvn_swe_3d_arc.time ge tmin) and (mvn_swe_3d_arc.time le tmax), npts)
        endelse
        if (npts gt 0L) then time = mvn_swe_3d_arc[indx].time $
                        else print,"No 3D archive data at specified time(s)."        
      endif else npts = n_elements(time)
      
      if (npts gt 0L) then begin
        ddd = replicate(swe_3d_struct, npts)
        aflg = 1
      endif
    endif else npts = 0L
  endif else begin
    if (size(mvn_swe_3d,/type) eq 8) then begin
      if keyword_set(all) then begin
        if (n_elements(time) eq 1) then begin
          indx = nn2(mvn_swe_3d.time, time, maxdt=32D)
          if (indx eq -1) then npts = 0L else npts = 1L
        endif else begin
          tmin = min(time, max=tmax, /nan)
          indx = where((mvn_swe_3d.time ge tmin) and (mvn_swe_3d.time le tmax), npts)
        endelse
        if (npts gt 0L) then time = mvn_swe_3d[indx].time $
                        else print,"No 3D survey data at specified time(s)."
      endif else npts = n_elements(time)

      if (npts gt 0L) then begin
        ddd = replicate(swe_3d_struct, npts)
        aflg = 0
      endif
    endif else npts = 0L
  endelse

  for n=0L,(npts-1L) do begin
    if (aflg) then begin
      tgap = min(abs(mvn_swe_3d_arc.time - time[n]), i)
      ddd[n] = mvn_swe_3d_arc[i]
    endif else begin
      tgap = min(abs(mvn_swe_3d.time - time[n]), i)
      ddd[n] = mvn_swe_3d[i]
    endelse

    if (addmag) then begin
      dt = min(abs(ddd[n].time - swe_mag1.time),j)
      if (dt lt 1D) then begin
        ddd[n].magf = swe_mag1[j].magf
        ddd[n].maglev = swe_mag1[j].level
      endif else begin
        ddd[n].magf = 0.
        ddd[n].maglev = 0B
      endelse
    endif

    if (addpot) then begin
      dt = min(abs(ddd[n].time - swe_sc_pot.time),j)
      if (dt lt ddd[n].delta_t) then ddd[n].sc_pot = swe_sc_pot[j].potential $
                                else ddd[n].sc_pot = !values.f_nan
    endif
  endfor

  if (npts gt 0L) then begin
    if (keyword_set(sum) and (npts gt 1)) then ddd = mvn_swe_3dsum(ddd)

; Correct for spacecraft potential and convert units

    if keyword_set(shiftpot) then begin
      if (stregex(units,'flux',/boo,/fold)) then begin
        mvn_swe_convert_units, ddd, 'df'
        for n=0,(npts-1) do ddd[n].energy -= ddd[n].sc_pot
        mvn_swe_convert_units, ddd, units
      endif else for n=0,(npts-1) do ddd[n].energy -= ddd[n].sc_pot
    endif else mvn_swe_convert_units, ddd, units

    return, ddd
  endif

; If necessary (npts = 0), extract 3D(s) from L0 data

  delta_t = 1.95D/2D  ; start time to center time
  time -= delta_t     ; packet times

  if keyword_set(archive) then begin
    if (size(swe_3d_arc,/type) ne 8) then begin
      print,"No 3D archive data."
      return, 0
    endif
    
    if keyword_set(all) then begin
      if (n_elements(time) eq 1) then begin
        indx = nn2(swe_3d_arc.time, time, maxdt=32D)
        if (indx eq -1) then npts = 0L else npts = 1L
      endif else begin
        tmin = min(time, max=tmax, /nan)
        indx = where((swe_3d_arc.time ge tmin) and (swe_3d_arc.time le tmax), npts)
      endelse
      if (npts eq 0L) then begin
        print,"No 3D archive data at specified time(s)."
        return, 0
      endif
      time = swe_3d_arc[indx].time
    endif

    npts = n_elements(time)
    ddd = replicate(swe_3d_struct, npts)
    ddd.data_name = "SWEA 3D Archive"
    ddd.apid = 'A1'XB
    
    aflg = 1
  endif else begin
    if (size(swe_3d,/type) ne 8) then begin
      print,"No 3D survey data."
      return, 0
    endif

    if keyword_set(all) then begin
      if (n_elements(time) eq 1) then begin
        indx = nn2(swe_3d.time, time, maxdt=32D)
        if (indx eq -1) then npts = 0L else npts = 1L
      endif else begin
        tmin = min(time, max=tmax, /nan)
        indx = where((swe_3d.time ge tmin) and (swe_3d.time le tmax), npts)
      endelse
      if (npts eq 0L) then begin
        print,"No 3D survey data at specified time(s)."
        return, 0
      endif
      time = swe_3d[indx].time
    endif

    npts = n_elements(time)
    ddd = replicate(swe_3d_struct, npts)
    ddd.data_name = "SWEA 3D Survey"
    ddd.apid = 'A0'XB

    aflg = 0
  endelse

  if (npts eq 0L) then begin
    print,"No 3D data at specified times(s)."
    return, 0
  endif

; Initialize calibration

  if (aflg) then begin
    tgap = min(abs(swe_3d_arc.time - time[0]), i)
    tabnum = swe_3d_arc[i].lut
  endif else begin
    tgap = min(abs(swe_3d.time - time[0]), i)
    tabnum = swe_3d[i].lut
  endelse

; Locate the 3D data closest to the desired time

  for n=0L,(npts-1L) do begin

    if (aflg) then begin
      tgap = min(abs(swe_3d_arc.time - time[n]), i)
      pkt = swe_3d_arc[i]
    endif else begin
      tgap = min(abs(swe_3d.time - time[n]), i)
      pkt = swe_3d[i]
    endelse

; Recalculate calibration factors if LUT changes

    if (pkt.lut ne swe_active_tabnum) then mvn_swe_calib, tabnum=pkt.lut
    ddd[n].lut = pkt.lut
    ddd[n].chksum = mvn_swe_tabnum(pkt.lut,/inverse)

; Timing

    dt = 1.95D                            ; measurement span
    ddd[n].time = pkt.time + (dt/2D)      ; center time
    ddd[n].met = pkt.met + (dt/2D)        ; center time
    ddd[n].end_time = pkt.time + dt       ; end time
    ddd[n].delta_t = swe_dt[pkt.period]   ; sample cadence

; Integration time per energy/angle bin prior to summing bins
; There are 7 deflection bins for each of 64 energy bins spanning
; 1.95 sec.  The first deflection bin is for settling and is
; discarded.

    ddd[n].integ_t = swe_integ_t

; There are 80 angular bins to span 16 anodes (az) X 6 deflections (el).
; Adjacent anodes are summed at the largest upward and downward elevations,
; so that the 16 x 6 = 96 bins are reduced to 80.  However, I will maintain
; 96 bins and duplicate data at the highest deflections.  Then dt_arr is
; used to renormalize and effectively divide the counts evenly between each 
; pair of duplicated bins.

    ddd[n].dt_arr[*, 0:15] = 2.        ; adjacent anode (azimuth) bins summed
    ddd[n].dt_arr[*,16:79] = 1.        ; no summing for mid-elevations
    ddd[n].dt_arr[*,80:95] = 2.        ; adjacent anode (azimuth) bins summed

; Energy bins are summed according to the group parameter.

    g = pkt.group
    ddd[n].group = g

    ddd[n].dt_arr = (2.^g)*ddd[n].dt_arr  ; 2^g energy bins summed

; Energy resolution in the standard 3D structure allows for the possibility of
; variation with elevation angle.  SWEA calibrations show that this variation
; is modest (< 1% from +55 to -30 deg, increasing to ~4% at -45 deg).  For
; now, I will not include elevation variation.

    energy = swe_swp[*,0] # replicate(1.,96)
    ddd[n].energy = energy
    
    ddd[n].denergy[0,*] = abs(energy[0,*] - energy[1,*])
    for i=1,62 do ddd[n].denergy[i,*] = abs(energy[i-1,*] - energy[i+1,*])/2.
    ddd[n].denergy[63,*] = abs(energy[62,*] - energy[63,*])

; Geometric factor.  When using V0, the geometric factor is a function of
; energy.  The dgf term is a elevation-only correction.  The ogf term corrects 
; variations in the angular sensitivity as a function of azimuth and 
; elevation (see mvn_swe_flatfield).

    egf = swe_gf[*,*,g]
    dgf = swe_dgf[*,*,g]
    ogf = mvn_swe_flatfield(ddd[n].time,/silent)

    for i=0,95 do ddd[n].gf[*,i] = egf[*,(i mod 16)] * dgf[*,(i/16)] * ogf[i]

; Electron suppression correction

    Ke = mvn_swe_esuppress(ddd[n].time,/silent)
    dg = exp(-((1./swe_Ein) # Ke)^2.)
    case ddd[n].group of
        1  : for i=0,63,2 do dg[i:(i+1)] = mean(dg[i:(i+1)])
        2  : for i=0,63,4 do dg[i:(i+3)] = mean(dg[i:(i+3)])
      else : ; do nothing
    endcase

    ddd[n].gf *= (dg # replicate(1.,96))

; Relative MCP efficiency.  Depends on energy and azimuth (anode).
;   Energy term is MCP efficiency (from literature); azimuth term
;   is MCP gain variations and geometric blockage from ribs.
;   Average the azimuth sensitivity in adjacent anode bins at the
;   maximum upward and downward deflections.

    eff_arr = swe_mcp_eff[*,*,g]
    for i=0,95 do ddd[n].eff[*,i] = eff_arr[*,(i mod 16)]
    
    i = 2*indgen(8)
    i = [i,i+80]
    ddd[n].eff[*,i] = (ddd[n].eff[*,i] + ddd[n].eff[*,i+1])/2.
    ddd[n].eff[*,i+1] = ddd[n].eff[*,i]

; Fill in the elevation array (units = deg)

    elev = transpose(swe_el[*,*,g])
    delev = transpose(swe_del[*,*,g])

    for i=0,95 do begin
      k = i/16
      ddd[n].theta[*,i] = elev[*,k]
      ddd[n].dtheta[*,i] = delev[*,k]
    endfor

; Fill in the azimuth array - no energy dependance (units = deg)
;   I am duplicating azimuth bins at the highest and lowest deflections.

    for i=0,95 do begin
      k = i mod 16
      ddd[n].phi[*,i] = swe_az[k]
      ddd[n].dphi[*,i] = swe_daz[k]
    endfor

; Calculate solid angles from elevation and azimuth

    ddd[n].domega = (2.*!dtor)*ddd[n].dphi *    $
                    cos(ddd[n].theta*!dtor) *   $
                    sin(ddd[n].dtheta*!dtor/2.)

; Fill in the data array, duplicating values as needed  (I have to swap the
; first two dimensions of pkt.data.)

    rawcnts = transpose(pkt.data)     ; [64,32,16] energies X 80 angles
    rawvar = transpose(pkt.var)       ; [64,32,16] energies X 80 angles

    counts = fltarr(64,96)            ; 64 energies X 96 angles
    var = fltarr(64,96)               ; 64 energies X 96 angles

    for i=0,15 do begin                       ; duplicate azimuth bins at high elev.
      k = i/2                                 ; (stored first in raw data array)
      counts[*,i] = rawcnts[*,k]
      counts[*,(i+80)] = rawcnts[*,(k+8)]
      var[*,i] = rawvar[*,k]
      var[*,(i+80)] = rawvar[*,(k+8)]
    endfor
    counts[*,16:79] = rawcnts[*,16:79]        ; copy mid-elevations straight over
    var[*,16:79] = rawvar[*,16:79]

    rawcnts = counts                          ; get ready to duplicate energy bins
    rawvar = var

    case g of
      1 : for i=0,63 do begin
            counts[i,*] = rawcnts[i/2,*]
            var[i,*] = rawvar[i/2,*]
          endfor
      2 : for i=0,63 do begin
            counts[i,*] = rawcnts[i/4,*]
            var[i,*] = rawvar[i/4,*]
          endfor
      else : ; do nothing
    endcase

; Calculate the deadtime correction, since the units are conveniently COUNTS.
; This makes it possible to convert back and forth between RATE, COUNTS and 
; other units.

    rate = counts/(swe_integ_t*ddd[n].dt_arr)  ; raw count rate
    ddd[n].dtc = swe_deadtime(rate)            ; corrected count rate = rate/dtc
    
; Insert MAG1 data, if available

    if (addmag) then begin
      dt = min(abs(ddd[n].time - swe_mag1.time),i)
      if (dt lt 1D) then begin
        magf = swe_mag1[i].magf
        magl = swe_mag1[i].level
      endif else begin
        magf = 0.
        magl = 0B
      endelse
      ddd[n].magf = magf
      ddd[n].maglev = magl
    endif

; Insert spacecraft potential, if available

    if (addpot) then begin
      dt = min(abs(ddd[n].time - swe_sc_pot.time),i)
      if (dt lt ddd[n].delta_t) then ddd[n].sc_pot = swe_sc_pot[i].potential $
                                else ddd[n].sc_pot = !values.f_nan
    endif

; Electron rest mass [eV/(km/s)^2]

    ddd[n].mass = mass_e

; And last, but not least, the data

    ddd[n].data = counts                       ; raw counts
    ddd[n].var = var                           ; variance

; Validate the data

    if (tgap gt 1.1D*ddd[n].delta_t) then begin
      msg = strtrim(string(round(tgap)),2)
      print,"data gap: ",msg," sec"
    endif

    ddd[n].valid = 1B                          ; Yep, it's valid.

; Quality flag

    str_element, pkt, 'quality', quality, success=ok
    if (ok) then ddd[n].quality = quality

  endfor

; Filter the quality

  str_element, ddd, 'quality', quality, success=ok
  if (ok) then begin
    indx = where(quality ge qlevel, npts)
    if (npts gt 0L) then ddd = ddd[indx] else return, 0
  endif else print,"Quality level not defined."

; Apply cross calibration factor.  A new factor is calculated after each 
; MCP bias adjustment. See mvn_swe_config for these times.  Polynomial
; fits are used to track slow drift of MCP gain between adjustments.  See 
; mvn_swe_crosscal.

  cc = mvn_swe_crosscal(ddd.time,/silent)
  scale = reform((replicate(1., 64*96) # cc), 64, 96, npts)
  
  ddd.gf /= scale

; Insert an estimate for the secondary contamination

  if (max(ddd.bkg) lt 1.e-30) then mvn_swe_secondary, ddd

; Sum the data.  This is done by summing raw counts corrected by deadtime
; and then setting dtc to unity.  Also, note that summed 3D's can be 
; "blurred" by a changing magnetic field direction, so summing only makes 
; sense for short intervals.

  if keyword_set(sum) then ddd = mvn_swe_3dsum(ddd)

; Correct for spacecraft potential and convert units

  if keyword_set(shiftpot) then begin
    if (stregex(units,'flux',/boo,/fold)) then mvn_swe_convert_units, ddd, 'df'
    for n=0L,(n_elements(ddd)-1L) do ddd[n].energy -= ddd[n].sc_pot
  endif

  mvn_swe_convert_units, ddd, units

  return, ddd

end
