;+
;PROCEDURE:   mvn_swe_makespec
;PURPOSE:
;  Constructs ENGY data structure from raw data.
;
;USAGE:
;  mvn_swe_makespec
;
;INPUTS:
;
;KEYWORDS:
;
;       SUM:      Force sum mode for A4 and A5.  Not needed for EM or for FM post ATLO.
;                 Default = get mode from packet.
;
;       UNITS:    Convert data to these units.  Default = 'eflux'.
;
;       TPLOT:    Make a energy-time spectrogram and store in tplot.
;
;       SFLG:     If TPLOT is set, then this controls whether the panel
;                 is a color spectrogram or stacked line plots.
;                 Default = 1 (color spectrogram).
;
;       PAN:      Returns the name of the tplot variable.
;
;       LUT:      Do not recalculate the LUT.  Instead, use these values.  Must
;                 have the same number of elements as SPEC.  This allows the user
;                 to use custom settings in mvn_swe_getlut to handle the presence
;                 of hires data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-19 14:46:22 -0700 (Thu, 19 Jun 2025) $
; $LastChangedRevision: 33394 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makespec.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_makespec.pro
;-
pro mvn_swe_makespec, sum=sum, units=units, tplot=tplot, sflg=sflg, pan=ename, lut=lut

  @mvn_swe_com

  if not keyword_set(sum) then smode = 0 else smode = 1
  if (size(units,/type) ne 7) then units = 'eflux'
  if (size(sflg,/type) eq 0) then sflg = 1 else sflg = keyword_set(sflg)
  gotlut = n_elements(lut) eq (n_elements(a4)*16L)
  ename = ''

; Initialize the deflection scale factors, geometric factor, and MCP efficiency

  dsf = total(swe_hsk.dsf,1)/6.          ; unity when all the DSF's are unity
  gf = total(swe_gf[*,*,0],2)/16.        ; average over 16 anodes
  eff = total(swe_mcp_eff[*,*,0],2)/16.  ; average over 16 anodes

; SWEA SPEC survey data

  if (size(a4,/type) ne 8) then begin
    print,"No SPEC survey data."
  endif else begin
    npkt = n_elements(a4)         ; number of packets
    npts = 16L*npkt               ; 16 spectra per packet
    ones = replicate(1.,16)

    mvn_swe_engy = replicate(swe_engy_struct, npts)
    mvn_swe_engy.apid = 'A4'XB

    if (gotlut) then mvn_swe_engy.lut = lut else mvn_swe_getlut

    for i=0L,(npkt-1L) do begin
      delta_t = swe_dt[a4[i].period]*dindgen(16) + (1.95D/2D)  ; center time offset (sample mode)
      dt_arr0 = 16.*6.                                         ; 16 anode X 6 defl. (sample mode)
      if (a4[i].smode or smode) then begin
        delta_t = delta_t + (2D^a4[i].period - 1D)             ; center time offset (sum mode)
        dt_arr0 = dt_arr0*swe_dt[a4[i].period]/2.              ; # samples averaged (sum mode)
      endif

      j0 = i*16L
      for j=0,15 do begin
        tspec = a4[i].time + delta_t[j]
        dt = min(abs(tspec - swe_hsk.time),k)

        if (mvn_swe_engy[j0+j].lut ne swe_active_tabnum) then begin
          mvn_swe_calib, tabnum=mvn_swe_engy[j0+j].lut
          gf = total(swe_gf[*,*,0],2)/16.
          eff = total(swe_mcp_eff[*,*,0],2)/16.
        endif
        mvn_swe_engy[j0+j].chksum = mvn_swe_tabnum(swe_active_tabnum,/inverse)

        mvn_swe_engy[j0+j].time = a4[i].time + delta_t[j]                   ; center time
        mvn_swe_engy[j0+j].met  = a4[i].met  + delta_t[j]                   ; center met
        mvn_swe_engy[j0+j].end_time = a4[i].time + delta_t[j] + delta_t[0]  ; end time
        mvn_swe_engy[j0+j].delta_t = swe_dt[a4[i].period]                   ; cadence
        mvn_swe_engy[j0+j].integ_t = swe_integ_t                            ; integration time
        mvn_swe_engy[j0+j].dt_arr = dt_arr0*dsf[k]                          ; # bins averaged

        mvn_swe_engy[j0+j].energy = swe_energy                      ; avg. over 6 deflections
        mvn_swe_engy[j0+j].denergy = swe_denergy                    ; avg. over 6 deflections

        Ke = mvn_swe_esuppress(mvn_swe_engy[j0+j].time,/silent)     ; electron suppression
        dg = exp(-((1./swe_Ein) # Ke)^2.)                           ; use internal energy

        mvn_swe_engy[j0+j].gf = gf*dg                               ; avg. over 16 anodes
        mvn_swe_engy[j0+j].eff = eff                                ; avg. over 16 anodes

        mvn_swe_engy[j0+j].data = a4[i].data[*,j]                   ; raw counts
        mvn_swe_engy[j0+j].var = a4[i].var[*,j]                     ; variance
      endfor
    endfor

    mvn_swe_engy.units_name = 'counts'                              ; initial units = raw counts

; The measurement cadence can change while a 16-sample packet is being assembled.
; It is possible to correct the timing during mode changes (typically 10 per day)
; by comparing the nominal interval between packets (based on a4.period) with the
; actual interval.  No correction can be made if a data gap coincides with a mode 
; change, since the actual interval between packets cannot be determined.

    dt_mode = swe_dt[a4.period]*16D        ; nominal time interval between packets
    dt_pkt = a4.time - shift(a4.time,1)    ; actual time interval between packets
    dt_pkt[0] = dt_pkt[1]
    dn_pkt = a4.npkt - shift(a4.npkt,1)    ; look for data gaps
    dn_pkt[0] = 1B
    j = where((abs(dt_pkt - dt_mode) gt 0.5D) and (dn_pkt eq 1B), count)
    for i=0,(count-1) do begin
      dt1 = dt_mode[(j[i] - 1L) > 0L]/16D  ; cadence before mode change
      dt2 = dt_mode[j[i]]/16D              ; cadence after mode change
      if (abs(dt1 - dt2) gt 0.5D) then begin
        m = 16L*((j[i] - 1L) > 0L)
        n = round((dt_pkt[j[i]] - 16D*dt2)/(dt1 - dt2)) + 1L
        if ((n gt 0) and (n lt 16)) then begin
          dt_fix = (dt2 - dt1)*(dindgen(16-n) + 1D)
          mvn_swe_engy[(m+n):(m+15L)].time += dt_fix
          mvn_swe_engy[(m+n):(m+15L)].met += dt_fix
          mvn_swe_engy[(m+n):(m+15L)].delta_t = dt2
          mvn_swe_engy[(m+n):(m+15L)].end_time = mvn_swe_engy[(m+n):(m+15L)].time + dt2/2D
        endif
      endif
    endfor

; Correct for deadtime

    rate = mvn_swe_engy.data / (swe_integ_t * mvn_swe_engy.dt_arr)  ; raw count rate per anode
    mvn_swe_engy.dtc = swe_deadtime(rate)     ; corrected count rate = rate/dtc

; Apply cross calibration factor.  A new factor is calculated after each 
; MCP bias adjustment. See mvn_swe_config for these times.  Polynomial
; fits are used to track slow drift of MCP gain between adjustments.  See 
; mvn_swe_crosscal.

    cc = mvn_swe_crosscal(mvn_swe_engy.time)
    scale = replicate(1., 64) # cc

    mvn_swe_engy.gf /= scale

; Insert the secondary electron estimate

    if (max(mvn_swe_engy.bkg) lt 1e-30) then mvn_swe_secondary, mvn_swe_engy

; Electron rest mass [eV/(km/s)^2]

    mvn_swe_engy.mass = mass_e

; Validate the data
    
    mvn_swe_engy.valid = 1B               ; Yep, it's valid.

; Convert to the default or requested units
  
    mvn_swe_convert_units, mvn_swe_engy, units

; Make a tplot variable

    if keyword_set(tplot) then begin
      x = mvn_swe_engy.time
      y = transpose(mvn_swe_engy.data)
      dy = transpose(sqrt(mvn_swe_engy.var))
      i = where(mvn_swe_engy.lut eq 5B, n)
      if (n gt 0L) then v = mvn_swe_engy[i[0]].energy else v = swe_swp[*,0]
      Emin = min(v, max=Emax)
      i = where(mvn_swe_engy.lut gt 6B, n)
      if (n gt 0L) then y[i,*] = !values.f_nan  ; mask hires data

      ename = 'swe_a4'
      eunits = strupcase(mvn_swe_engy[0].units_name)
      store_data,ename,data={x:x, y:y, dy:dy, v:v}
      if (sflg) then begin
        options,ename,'spec',1
        ylim,ename,Emin,Emax,1
        options,ename,'ytitle','Energy (eV)'
        options,ename,'yticks',0
        options,ename,'yminor',0
        zlim,ename,0,0,1
        options,ename,'ztitle',eunits
        options,ename,'y_no_interp',1
        options,ename,'x_no_interp',1
      endif else begin
        options,ename,'spec',0
        ylim,ename,1,1e6,1
        options,ename,'ytitle',eunits
        options,ename,'yticks',0
        options,ename,'yminor',0
      endelse
    endif

  endelse

; SWEA SPEC archive data

  if (size(a5,/type) ne 8) then begin
;   print,"No SPEC archive data."         ; there should never be any SPEC archive data
  endif else begin
    print,"WARNING: SPEC archive data detected.  This should be impossible."
    npkt = n_elements(a5)                 ; number of packets
    npts = 16L*npkt                       ; 16 spectra per packet
    ones = replicate(1.,npts)

    mvn_swe_engy_arc = replicate(swe_engy_struct,npts)
    mvn_swe_engy_arc.apid = 'A5'XB

    for i=0L,(npkt-1L) do begin
      delta_t = swe_dt[a5[i].period]*dindgen(16) + (1.95D/2D)    ; center time offset (sample mode)
      dt_arr0 = 16.*6.                                           ; 16 anode X 6 defl. (sample mode)
      if (a5[i].smode or smode) then begin
        delta_t = delta_t + (2D^a5[i].period - 1D)               ; center time offset (sum mode)
        dt_arr0 = dt_arr0*swe_dt[a5[i].period]/2.                ; # samples averaged (sum mode)
      endif

      j0 = i*16L
      for j=0,15 do begin
        tspec = a5[i].time + delta_t[j]

        dt = min(abs(tspec - swe_hsk.time),k)                       ; look for config. changes
        if (swe_active_chksum ne swe_chksum[k]) then begin
          mvn_swe_calib, chksum=swe_chksum[k]
          gf = total(swe_gf[*,*,0],2)/16.
          eff = total(swe_mcp_eff[*,*,0],2)/16.
        endif

        mvn_swe_engy_arc[j0+j].chksum = swe_active_chksum                       ; sweep table
        mvn_swe_engy_arc[j0+j].time = a5[i].time + delta_t[j]                   ; center time
        mvn_swe_engy_arc[j0+j].met  = a5[i].met  + delta_t[j]                   ; center met
        mvn_swe_engy_arc[j0+j].end_time = a5[i].time + delta_t[j] + delta_t[0]  ; end time
        mvn_swe_engy_arc[j0+j].delta_t = swe_dt[a5[i].period]                   ; cadence
        mvn_swe_engy_arc[j0+j].integ_t = swe_integ_t                            ; integration time
        mvn_swe_engy_arc[j0+j].dt_arr = dt_arr0*dsf[k]                          ; # bins averaged

        mvn_swe_engy_arc[j0+j].energy = swe_energy                      ; avg. over 6 deflections
        mvn_swe_engy_arc[j0+j].denergy = swe_denergy                    ; avg. over 6 deflections

        Ke = mvn_swe_esuppress(mvn_swe_engy_arc[j0+j].time,/silent)     ; electron suppression
        dg = exp(-((1./swe_Ein) # Ke)^2.)                               ; use internal energy

        mvn_swe_engy_arc[j0+j].gf = gf*dg                               ; avg. over 16 anodes
        mvn_swe_engy_arc[j0+j].eff = eff                                ; avg. over 16 anodes

        mvn_swe_engy_arc[j0+j].data = a5[i].data[*,j]                   ; raw counts
        mvn_swe_engy_arc[j0+j].var = a5[i].var[*,j]                     ; variance
      endfor
    endfor
    
    mvn_swe_engy_arc.units_name = 'counts'                              ; initial units = raw counts

; The measurement cadence can change while a 16-sample packet is being assembled.
; It is possible to correct the timing during mode changes (typically 10 per day)
; by comparing the nominal interval between packets (based on a5.period) with the
; actual interval.  No correction can be made if a data gap coincides with a mode 
; change, since the actual interval between packets cannot be determined.

    dt_mode = swe_dt[a5.period]*16D        ; nominal time interval between packets
    dt_pkt = a5.time - shift(a5.time,1)    ; actual time interval between packets
    dt_pkt[0] = dt_pkt[1]
    dn_pkt = a5.npkt - shift(a5.npkt,1)    ; look for data gaps
    dn_pkt[0] = 1B
    j = where((abs(dt_pkt - dt_mode) gt 0.5D) and (dn_pkt eq 1B), count)
    for i=0,(count-1) do begin
      dt1 = dt_mode[(j[i] - 1L) > 0L]/16D  ; cadence before mode change
      dt2 = dt_mode[j[i]]/16D              ; cadence after mode change
      if (abs(dt1 - dt2) gt 0.5D) then begin
        m = 16L*((j[i] - 1L) > 0L)
        n = round((dt_pkt[j[i]] - 16D*dt2)/(dt1 - dt2)) + 1L
        if ((n gt 0) and (n lt 16)) then begin
          dt_fix = (dt2 - dt1)*(dindgen(16-n) + 1D)
          mvn_swe_engy_arc[(m+n):(m+15L)].time += dt_fix
          mvn_swe_engy_arc[(m+n):(m+15L)].met += dt_fix
          mvn_swe_engy_arc[(m+n):(m+15L)].delta_t = dt2
          mvn_swe_engy_arc[(m+n):(m+15L)].end_time = mvn_swe_engy_arc[(m+n):(m+15L)].time + dt2/2D
        endif
      endif
    endfor

; Correct for deadtime

    rate = mvn_swe_engy_arc.data / (swe_integ_t * mvn_swe_engy_arc.dt_arr)      ; raw count rate per anode
    mvn_swe_engy_arc.dtc = swe_deadtime(rate)  ; corrected count rate = rate/dtc

; Apply cross calibration factor.  A new factor is calculated after each 
; MCP bias adjustment. See mvn_swe_config for these times.  See 
; mvn_swe_crosscal for the cross calibration factors.

    cc = mvn_swe_crosscal(mvn_swe_engy_arc.time)
    scale = replicate(1., 64) # cc

    mvn_swe_engy_arc.gf /= scale

; Mask high-resolution data

  indx = where(mvn_swe_engy_arc.lut gt 6B, count)
  if (count gt 0L) then mvn_swe_engy_arc[indx].data = !values.f_nan

; Insert the secondary electron estimate

    mvn_swe_secondary, mvn_swe_engy_arc

; Electron rest mass [eV/(km/s)^2]

    mvn_swe_engy_arc.mass = mass_e

; Validate the data
    
    mvn_swe_engy_arc.valid = 1B               ; Yep, it's valid.

; Convert to the default or requested units
  
    if (size(units,/type) eq 7) then mvn_swe_convert_units, mvn_swe_engy_arc, units

  endelse

  return

end
