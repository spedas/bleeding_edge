;+
;PROCEDURE:   mvn_swe_getlut
;PURPOSE:
;  Determines the sweep lookup table used for each 2-sec measurement
;  cycle.  This information is stored in the SPEC, PAD, and 3D data
;  structures.  The vast majority of the time a single sweep table is
;  used, in which case this routine is trivial.  The exceptions are
;  power on, monthly calibrations (until late 2019) and high time
;  resolution campaigns.  The latter two use rapid mode toggling, so
;  that high cadence housekeeping is needed to keep track of the mode
;  changes.  Even then, there are occasional mismatches between the 
;  sweep table reported in housekeeping and the one actually used for 
;  measurements.  Three methods are provided (via keyword) to identify 
;  and correct these mismatches.  None is perfect, but at least one of
;  them, depending on the circumstances, has been able to identify all
;  table changes correctly ... so far.
;
;USAGE:
;  mvn_swe_getlut
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       TPLOT:    Make a tplot variable.
;
;       DT_LUT:   Time offset between housekeeping SSCTL values and
;                 science data.  Units: sec.  Default = 0D.
;
;       VOLT:     Use analyzer voltage to identify tables 7 and 8.
;
;       DV_MAX:   Maximum absolute difference between measured analyzer
;                 voltage and nominal voltage.  Two values: one for 50 eV
;                 one for 200 eV.  Default: [0.7, 2.0].
;
;       DIAG:     Make diagnostic plots.
;
;       FLUX:     Use constant flux to identify tables 7 and 8.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-08-11 14:04:13 -0700 (Wed, 11 Aug 2021) $
; $LastChangedRevision: 30201 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getlut.pro $
;-
pro mvn_swe_getlut, tplot=tplot, dt_lut=dt_lut, volt=volt, dv_max=dv, diag=diag, flux=flux

  @mvn_swe_com
  common lutcom, dtl, vflg, fflg

  if (size(dtl,/type) eq 0) then begin
    dtl = 0D
    vflg = 0
    fflg = 0
  endif

  if (n_elements(dt_lut) gt 0) then dtl = double(dt_lut[0])
  if (n_elements(volt) gt 0) then vflg = keyword_set(volt)
  case n_elements(dv) of
     1   : dv_max = [dv, 2.0]
     2   : dv_max = dv
    else : dv_max = [0.7, 2.0]
  endcase
  if (n_elements(flux) gt 0) then fflg = keyword_set(flux)
;  if (vflg or fflg) then dtl = 0D

  if (abs(dtl) gt 0D) then begin
    msg = strtrim(string(dtl, format='(f12.1)'),2)
    print,"MVN_SWE_GETLUT%  Using SSCTL offset: ",msg," sec"
  endif

; Make sure sufficient information is present

  mvn_swe_stat, npkt=npkt, /silent
  if (npkt[4] eq 0L) then begin
    print,"No science data."
    return
  endif
  if (npkt[7] eq 0L) then begin
    print,"No housekeeping."
    return
  endif

; Define arrays

  nhsk = n_elements(swe_hsk)
  lutnum = swe_hsk.ssctl

; Initialize with nominal sweep table (used almost all the time)

  tabnum = replicate(5B,nhsk)                    ; MOI and beyond
  indx = where(swe_hsk.time lt t_swp[1], count)
  if (count gt 0L) then tabnum[indx] = 3B        ; Cruise phase
  indx = where(swe_hsk.time lt t_swp[0], count)
  if (count gt 0L) then tabnum[indx] = 1B        ; Initial turn-on

; Identify table load during turn-on, when active LUT is set to 7
; (Only tables 0-3 are recognized by the PFDPU.)

  indx = where(lutnum gt 3, count)
  if (count gt 0L) then tabnum[indx] = 0B

; Use V0V to identify table 6.  This is reliable.

  indx = where(lutnum eq 1, count)
  if (count gt 0L) then begin
    indx = where(swe_hsk.v0v lt -0.1, count)
    if (count gt 0L) then tabnum[indx] = 6B  ; V0 enabled
  endif

; Use analyzer voltage to identify tables 7 and 8.  This method works
; in superthermal electron voids, but it can get confused when the 
; nominal sweep is sampled close to one of the hires energies.  This
; situation is worse in high current mode (see bi-stable ISA), where
; the noise level on the housekeeping values is larger.

  if (vflg) then begin
    print,"MVN_SWE_GETLUT%  Using analyzer voltage method."
    indx = where(lutnum eq 2 or lutnum eq 3, count)
    if (count gt 0L) then begin
      indx = where(abs(swe_hsk.analv - 8.13) lt dv_max[0], count)
      if (count gt 0L) then tabnum[indx] = 8B  ; hires @ 50 eV
      indx = where(abs(swe_hsk.analv - 32.5) lt dv_max[1], count)
      if (count gt 0L) then tabnum[indx] = 7B  ; hires @ 200 eV
    endif
  endif else begin
    indx = where(lutnum eq 2, count)
    if (count gt 0L) then tabnum[indx] = 7B  ; hires @ 200 eV
    indx = where(lutnum eq 3, count)
    if (count gt 0L) then tabnum[indx] = 8B  ; hires @ 50 eV
  endelse

  if keyword_set(diag) then begin
    store_data,'dv50',data={x:swe_hsk.time, y:abs(swe_hsk.analv - 8.13)}
    options,'dv50','psym',10
    options,'dv50','constant',dv_max[0]
    ylim,'dv50',0,2.*dv_max[0]

    store_data,'dv200',data={x:swe_hsk.time, y:abs(swe_hsk.analv - 32.5)}
    options,'dv200','psym',10
    options,'dv200','constant',dv_max[1]
    ylim,'dv200',0,2.*dv_max[1]
  endif

; Use flat spectral shape to identify tables 7 and 8.  This doesn't work
; in superthermal electron voids, where the signal is close to background
; at all energies.  It also gets confused when there are real flux
; variations within the 2-second measurement interval (as in the sheath).

  if (fflg) then begin
    print,"MVN_SWE_GETLUT%  Using constant flux method."
    cnts = reform(a4.data, 64L, 16L*n_elements(a4))
    loav = mean(cnts[45:60,*],dim=1,/nan)  ; low-energy average
    hiav = mean(cnts[ 5:20,*],dim=1,/nan)  ; high-energy average
    i7_8 = where(((hiav/loav) gt 0.1) and (loav gt 10.), n7_8, comp=i1_5, ncomp=n1_5)
  endif

; Get timing for a4 (see mvn_swe_makespec for more info)

  npkt = n_elements(a4)            ; number of SPEC packets
  npts = 16L*npkt                  ; 16 spectra per packet
  tspec = replicate(0D, 16L*npkt)  ; center time for each spectrum
  if (n_elements(mvn_swe_engy) ne npts) then begin
    mvn_swe_engy = replicate(swe_engy_struct, npts)

    for i=0L,(npkt-1L) do begin
      delta_t = swe_dt[a4[i].period]*dindgen(16) + (1.95D/2D)  ; center time offset (sample mode)
      if (a4[i].smode) then delta_t += (2D^a4[i].period - 1D)  ; center time offset (sum mode)

      j = i*16L
      tspec[j:(j+15L)] = a4[i].time + delta_t
    endfor

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
          tspec[(m+n):(m+15L)] += dt_fix
        endif
      endif
    endfor
    mvn_swe_engy.time = tspec
  endif

; Insert LUT information into data structures

  if (fflg) then begin
    jndx = where(tabnum le 6B, count)
    if (count gt 0L) then begin
      indx = nn2(swe_hsk[jndx].time + dtl, mvn_swe_engy[i1_5].time)
      mvn_swe_engy[i1_5].lut = tabnum[jndx[indx]]
    endif

    jndx = where(tabnum ge 7B, count)
    if (count gt 0L) then begin
      indx = nn2(swe_hsk[jndx].time + dtl, mvn_swe_engy[i7_8].time)
      mvn_swe_engy[i7_8].lut = tabnum[jndx[indx]]
    endif
  endif else begin
    indx = nn2(swe_hsk.time + dtl, mvn_swe_engy.time)
    mvn_swe_engy.lut = tabnum[indx]
  endelse

  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D

  if (size(a2,/type) eq 8) then begin
    indx = nn2(mvn_swe_engy.time, (a2.time + delta_t))
    a2.lut = mvn_swe_engy[indx].lut
  endif

  if (size(a3,/type) eq 8) then begin
    indx = nn2(mvn_swe_engy.time, (a3.time + delta_t))
    a3.lut = mvn_swe_engy[indx].lut
  endif

  if (size(swe_3d,/type) eq 8) then begin
    indx = nn2(mvn_swe_engy.time, (swe_3d.time + delta_t))
    swe_3d.lut = mvn_swe_engy[indx].lut
  endif

  if (size(swe_3d_arc,/type) eq 8) then begin
    indx = nn2(mvn_swe_engy.time, (swe_3d_arc.time + delta_t))
    swe_3d_arc.lut = mvn_swe_engy[indx].lut
  endif

; Make a tplot panel

  if keyword_set(tplot) then begin
    store_data,'TABNUM',data={x:mvn_swe_engy.time, y:mvn_swe_engy.lut}
    ylim,'TABNUM',4.5,8.5,0
    options,'TABNUM','panel_size',0.5
    options,'TABNUM','ytitle','SWE LUT'
    options,'TABNUM','yminor',1
    options,'TABNUM','psym',10
    options,'TABNUM','colors',[4]
    options,'TABNUM','constant',[5,7,8]
  endif

  return

end
