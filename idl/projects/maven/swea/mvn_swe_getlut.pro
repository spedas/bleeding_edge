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
;  Method 1: Use SSCTL values in housekeeping to identify the table.
;    This requires high-cadence housekeeping.  The SSCTL values are
;    not accurately synced with the data, and it is possible for the
;    timing to be off by a second or more.  Thus, this method can 
;    assign incorrect sweep tables.  Keyword DT_LUT can be used to 
;    shift SSCTL times by a constant amount to align with the data.
;
;  Method 2: Use analyzer voltage readback in housekeeping to identify
;    tables 7-9.  This works well much of the time, but can get
;    confused when the sweep in normal operation is sampled near one
;    of the high-cadence energies.
;
;  Method 3: Use a constant count rate at all energy steps to detect
;    one of the high-cadence tables.  This assumes that the signal
;    changes slowly during the 2-second measurement cycle.  This is 
;    used in conjunction with Method 1 to correct SSCTL timing errors.
;    This is the least effective method, because during interesting 
;    times, the signal can change significantly within a measurement 
;    cycle.  It also fails within superthermal electron voids, where 
;    the flux at all energy channels is near background.
;
;  Sweep tables are identified using two different numbering systems,
;  LUTNUM and TABNUM.  The first is the table number used onboard in
;  flight software, corresponding to the table number in SWEA memory.
;  There are 8 LUT registers, numbered 0 through 7.  Of these, only
;  the first four (0-3) are recognized by flight software.  Sweep
;  tables are uploaded to the PFDPU and stored in non-volatile memory
;  (survives power cycle).  When SWEA is powered on, the PFDPU tranfers
;  these four tables to the SWEA's volatile memory.
;
;  Once you set a method or SSCTL timing offset, it remains persistent
;  for subsequent calls.
;
;  SWEA configuration changes:
;
;       i        t_swp[i]              configuration change
;     --------------------------------------------------------------------
;       0    2014-03-19/14:00:00    sweep tables 3 and 4 upload (cruise)
;       1    2014-09-22/00:00:00    sweep tables 5 and 6 upload (MOI)
;       2    2018-08-28/14:02:38    sweep table 8 upload (32-Hz,  50 eV)
;       3    2018-11-09/17:57:56    sweep table 7 upload (32-Hz, 200 eV)
;       4    2022-04-22/00:00:00    sweep table 9 upload (32-Hz, 125 eV)
;     --------------------------------------------------------------------
;
;  2014-09-22 (t_swp[1]) to 2018-08-28 (t_swp[2]):
;
;       LUTNUM   TABNUM     Description
;     -------------------------------------------------------------
;         0         5       nominal ops: 3-4627.5 eV, V0 disabled
;         1         6       nominal ops: 3-4652.5 eV, V0 enabled
;         2         5       backup in case of checksum error
;         3         6       backup in case of checksum error
;     -------------------------------------------------------------
;
;  2018-08-28 (t_swp[2]) to 2018-11-09 (t_swp[3]):
;    There are no longer backups in case of checksum errors.
;    That capability is now disabled in flight software.
;
;       LUTNUM   TABNUM     Description
;     -------------------------------------------------------------
;         0         5       nominal ops: 3-4627.5 eV, V0 disabled
;         1         6       nominal ops: 3-4652.5 eV, V0 enabled
;         2                 unused
;         3         8       hires at 50 eV
;     -------------------------------------------------------------
;
;  2018-11-09 (t_swp[3]) to 2022-04-22 (t_swp[4]):
;    First hires test observation: 2019-01-27
;    Aerobraking begins 2019-02-12
;
;       LUTNUM   TABNUM     Description
;     -------------------------------------------------------------
;         0         5       nominal ops: 3-4627.5 eV, V0 disabled
;         1         6       nominal ops: 3-4652.5 eV, V0 enabled
;         2         7       hires at 200 eV
;         3         8       hires at 50 eV
;     -------------------------------------------------------------
;
;  After 2022-04-22 (t_swp[4]):
;    Note that the V0 table is replaced with a hires table.
;    Upstream/shock/sheath hires observations: 2020-04-30
;    Crustal field observations: 2020-05-27 to 2020-06-01
;
;       LUTNUM   TABNUM     Description
;     -------------------------------------------------------------
;         0         5       nominal ops: 3-4627.5 eV, V0 disabled
;         1         9       hires at 125 eV
;         2         7       hires at 200 eV
;         3         8       hires at 50 eV
;     -------------------------------------------------------------
;
;  Table numbers (TABNUM) are defined in ground software.  This routine
;  makes the connection between LUTNUM and TABNUM.
;
;USAGE:
;  mvn_swe_getlut
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       DT_LUT:   Time offset between housekeeping SSCTL values and
;                 science data.  Units: sec.  Default = 0D.
;
;       VOLT:     Use analyzer voltage readback in housekeeping to 
;                 identify tables 7-9.
;
;       VMEAN:    Mean values of the ANALV readback for 50, 125, and
;                 200 eV, as recorded in flight.
;
;                    Ideal   = [ 7.97, 20.24, 32.26]
;                    Actual  = [ 8.23, 20.52, 32.50]  <-- default
;                    Stddev  = [ 0.30,  0.22,  0.25]
;                    Spacing = [ 0.88,  2.22,  3.55]  ; step spacing (Volts)
;                    Spacing = [ 2.93, 10.09, 14.20]  ; step spacing (sigma)
;
;                 The ANALV readback is systematically high by about
;                 0.25 Volts, or one standard deviation.
;
;       DV_MAX:   Maximum absolute difference between measured analyzer
;                 voltage and nominal voltage.  Three values: one each
;                 for 50, 125, and 200 eV.  Default: [0.7, 1.5, 2.0].
;
;       FLUX:     Use constant flux at all energy steps to determine if
;                 one of the high-cadence tables (7-9) is in use.  If so,
;                 then the nearest housekeeping SSCTL value uniquely 
;                 identifies which table is in use.  Default.
;
;       RESULT:   Table number for each SPEC.
;
;       TPLOT:    Make a tplot variable of LUT vs time.
;
;       DIAG:     Make diagnostic plots to evaluate and tune VOLT method.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-11-05 13:23:25 -0800 (Wed, 05 Nov 2025) $
; $LastChangedRevision: 33830 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getlut.pro $
;-
pro mvn_swe_getlut, dt_lut=dt_lut, volt=volt, vmean=vmean, dv_max=dv, flux=flux, diag=diag, tplot=tplot, $
                    result=lspec

  @mvn_swe_com
  common lutcom, dtl, vflg, fflg

  if (size(dtl,/type) eq 0) then begin
    dtl = 0D
    vflg = 0
    fflg = 1  ; default method when hires tables are present
  endif

  if (n_elements(dt_lut) gt 0) then dtl = double(dt_lut[0])
  if (n_elements(volt) gt 0) then begin
    vflg = keyword_set(volt)
    if (vflg) then fflg = 0
  endif
  if (n_elements(flux) gt 0) then begin
    fflg = keyword_set(flux)
    if (fflg) then vflg = 0
  endif

  case n_elements(dv) of
     0   : dv_max = [0.7, 1.5, 2.0]  ; 50, 125, 200 eV
     1   : dv_max = [dv, 1.5, 2.0]
     2   : dv_max = [dv, 2.0]
    else : dv_max = dv[0:2]
  endcase
  dv_max = abs(dv_max)
  case n_elements(vmean) of
     0   : vmean = [ 8.23, 20.52, 32.50]  ; 50, 125, 200 eV
     1   : vmean = [vmean, 20.52, 32.50]
     2   : vmean = [vmean, 32.50]
    else : vmean = vmean[0:2]
  endcase

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
  lutnum = swe_hsk.ssctl                         ; value from 0 to 3

  dt_hsk = swe_hsk.time - shift(swe_hsk.time,1)
  dt_hsk[0] = dt_hsk[1]

; Initialize with nominal sweep table (used almost all the time)

  tabnum = replicate(5B,nhsk)                    ; MOI and beyond
  indx = where(swe_hsk.time lt t_swp[1], count)
  if (count gt 0L) then tabnum[indx] = 3B        ; Cruise phase
  indx = where(swe_hsk.time lt t_swp[0], count)
  if (count gt 0L) then tabnum[indx] = 1B        ; Initial turn-on

; Get SPEC timing (see mvn_swe_makespec)

  npkt = n_elements(a4)            ; number of SPEC packets
  npts = 16L*npkt                  ; 16 spectra per packet
  tspec = replicate(0D, npts)      ; center time for each SPEC
  lspec = replicate(0B, npts)      ; tabnum for each SPEC

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

; Identify table load during turn-on, when active LUT is set to 7
; (Only tables 0-3 are recognized by the PFDPU.)

  indx = where(lutnum gt 3, count)
  if (count gt 0L) then tabnum[indx] = 0B

; Use V0V to identify table 6.  This is reliable.

  indx = where((lutnum eq 1) and (swe_hsk.time lt t_swp[4]), count)
  if (count gt 0L) then begin
    indx = where(swe_hsk.v0v lt -0.1, count)
    if (count gt 0L) then tabnum[indx] = 6B  ; V0 enabled
  endif

; Inspect housekeeping to see if there are any hires observations.
; Default is to use the table provided by the nearest housekeeping 
; packet, but this is not very reliable.  Two other methods are 
; provided that can work much better in certain situations.

  indx = where(((swe_hsk.time gt t_swp[2]) and ((lutnum ge 2) and (lutnum le 3))) or $
               ((swe_hsk.time gt t_swp[4]) and ((lutnum ge 1) and (lutnum le 3))), count)

  if (count eq 0L) then begin  ; disable hires methods: not needed
    vflg = 0
    fflg = 0
    gotlut = 1
  endif else begin
    print,"MVN_SWE_GETLUT%  Hires tables detected in housekeeping."
    gotlut = 0
  endelse

; Use analyzer voltage to identify tables 7-9.  This method works
; in superthermal electron voids, but it can get confused when the 
; nominal sweep is sampled close to one of the hires energies.  This
; situation is worse in high current mode (see bi-stable ISA), where
; the noise level on the housekeeping values is larger.

  if (vflg) then begin
    print,"MVN_SWE_GETLUT%  Using analyzer voltage method for hires tables."
    indx = where(lutnum eq 2 or lutnum eq 3, count)
    if (count gt 0L) then begin
      indx = where(abs(swe_hsk.analv - vmean[0]) lt dv_max[0], count)
      if (count gt 0L) then tabnum[indx] = 8B  ; hires @ 50 eV
      indx = where(abs(swe_hsk.analv - vmean[2]) lt dv_max[2], count)
      if (count gt 0L) then tabnum[indx] = 7B  ; hires @ 200 eV
    endif
    indx = where((lutnum eq 1) and (swe_hsk.time gt t_swp[4]), count)
    if (count gt 0L) then begin
      indx = where(abs(swe_hsk.analv - vmean[1]) lt dv_max[1], count)
      if (count gt 0L) then tabnum[indx] = 9B  ; hires @ 125 eV
    endif
    gotlut = 1
  endif else begin
    indx = where((lutnum eq 1) and (swe_hsk.time gt t_swp[4]), count)
    if (count gt 0L) then tabnum[indx] = 9B  ; hires @ 125 eV
    indx = where(lutnum eq 2, count)
    if (count gt 0L) then tabnum[indx] = 7B  ; hires @ 200 eV
    indx = where(lutnum eq 3, count)
    if (count gt 0L) then tabnum[indx] = 8B  ; hires @ 50 eV
  endelse

  if (vflg and keyword_set(diag)) then begin
    store_data,'dv50',data={x:swe_hsk.time, y:abs(swe_hsk.analv - vmean[0])}
    options,'dv50','psym',10
    options,'dv50','constant',dv_max[0]
    ylim,'dv50',0,2.*dv_max[0]

    store_data,'dv125',data={x:swe_hsk.time, y:abs(swe_hsk.analv - vmean[1])}
    options,'dv125','psym',10
    options,'dv125','constant',dv_max[1]
    ylim,'dv125',0,2.*dv_max[1]

    store_data,'dv200',data={x:swe_hsk.time, y:abs(swe_hsk.analv - vmean[2])}
    options,'dv200','psym',10
    options,'dv200','constant',dv_max[2]
    ylim,'dv200',0,2.*dv_max[2]
  endif

; Use flat spectral shape to identify tables 7-9.  To identify flat spectra,
; compare the counts above 1400 eV to the counts below 20 eV.  (The low-energy
; anomaly is irrelevant for this comparison.)  If the counts in both energy
; ranges are above background and the ratio is above a certain threshold (to
; allow for real flux variations) then a hires table is in use.  This will 
; work unless there are large, rapid flux variations.  Also, if the counts 
; below 20 eV are near background, then a hires table is being used inside a
; suprathermal electron void.  (Note that these voids correspond to closed
; crustal magnetic loops with both footpoints on the night hemisphere.  In this
; case, there will be a residual electron population below 10 eV that is well
; above background, while the >1400-eV signal is at background.)

  if (fflg) then begin
    mvn_swe_sweep, tab=5, result=swp
    hndx = where(swp.e gt 1400.)
    lndx = where(swp.e lt 20.)
    print,"MVN_SWE_GETLUT%  Using constant flux method for hires tables."
    cnts = reform(a4.data, 64L, 16L*n_elements(a4))
    loav = mean((cnts[lndx,*]),dim=1,/nan)  ; low-energy average
    hiav = mean((cnts[hndx,*]),dim=1,/nan)  ; high-energy average
    cratio = hiav/loav

    hndx = where(((lutnum eq 1) and (swe_hsk.time gt t_swp[4])) or (lutnum eq 2) or (lutnum eq 3), count)
    if (count gt 0L) then begin
      indx = nn2(swe_hsk[hndx].time, tspec)
      dt_v = abs(swe_hsk[hndx[indx]].time - tspec)
      inrange = abs(swe_hsk[hndx[indx]].time - tspec) lt 1.25*min(dt_hsk)  ; hires data is near hires hsk
    endif else inrange = 0

    i7_9 = where((((cratio gt 0.1) and (hiav ge 0.5) and (loav ge 0.5)) or $
                  (loav lt 1.0)) and inrange, n7_9, comp=i1_5, ncomp=n1_5)
    gotlut = 1
  endif

; Use housekeeping to identify tables 7-9.

  if (~gotlut) then begin
    print,"MVN_SWE_GETLUT%  Using housekeeping method for hires tables."
    if (abs(dtl) gt 0D) then begin
      msg = strtrim(string(dtl, format='(f12.1)'),2)
      print,"MVN_SWE_GETLUT%  Using SSCTL timing offset: ",msg," sec"
    endif
  endif

  if (fflg and keyword_set(diag)) then begin
    store_data,'cratio',data={x:tspec, y:cratio}
    options,'cratio','psym',4
    options,'cratio','symsize',1.0
    options,'cratio','constant',[0.1, 1.0]
    options,'cratio','line_colors',5
    options,'cratio','const_color',[6,4]
    ylim,'cratio',0.01,100.,1

    store_data,'loav',data={x:tspec, y:loav}
    ylim,'loav',0.1,1e5,1
    options,'loav','psym',4

    store_data,'hiav',data={x:tspec, y:hiav}
    ylim,'hiav',0.1,1e5,1
    options,'hiav','psym',4

    options,['loav','hiav'],'constant',[0.5,1.0]
    options,['loav','hiav'],'line_colors',5
    options,['loav','hiav'],'const_color',[6,4]

    store_data,'valid',data={x:tspec, y:inrange}
    ylim,'valid',-0.5,1.5,0
    options,'valid','psym',10
    options,'valid','panel_size',0.5

    store_data,'dt_v',data={x:tspec, y:dt_v}
    options,'dt_v','psym',4

    store_data,'dt_hsk',data={x:swe_hsk.time, y:dt_hsk}
    options,'dt_hsk','psym',4
    options,'dt_hsk','ytitle','dT (28)'
    store_data,'dt_hires',data={x:swe_hsk[hndx].time, y:dt_hsk[hndx]}
    options,'dt_hires','psym',4
    options,'dt_hires','colors',6
    store_data,'dt_all',data=['dt_hsk','dt_hires']
  endif

; Insert LUT information into data structures

  if (fflg) then begin
    lutcut = replicate(6B, nhsk)
    jndx = where(swe_hsk.time gt t_swp[4], count)
    if (count gt 0L) then lutcut[jndx] = 5B

    jndx = where(tabnum le lutcut, count)
    if (count gt 0L) then begin
      indx = nn2(swe_hsk[jndx].time + dtl, tspec[i1_5])
      lspec[i1_5] = tabnum[jndx[indx]]
    endif

    jndx = where(tabnum gt lutcut, count)
    if (count gt 0L) then begin
      indx = nn2(swe_hsk[jndx].time + dtl, tspec[i7_9])
      lspec[i7_9] = tabnum[jndx[indx]]
    endif
  endif else begin
    indx = nn2(swe_hsk.time + dtl, tspec)
    lspec = tabnum[indx]
  endelse

  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D

  if (size(a0,/type) eq 8) then begin
    indx = nn2(tspec, (a0.time + delta_t))
    a0.lut = lspec[indx]
  endif

  if (size(a1,/type) eq 8) then begin
    indx = nn2(tspec, (a1.time + delta_t))
    a1.lut = lspec[indx]
  endif

  if (size(a2,/type) eq 8) then begin
    indx = nn2(tspec, (a2.time + delta_t))
    a2.lut = lspec[indx]
  endif

  if (size(a3,/type) eq 8) then begin
    indx = nn2(tspec, (a3.time + delta_t))
    a3.lut = lspec[indx]
  endif

; The PFDPU assigns a LUT value to each a4 packet.  However, the LUT can change
; while an a4 packet is being accumulated, so it doesn't make sense to update
; the LUT values for a4 packets.

  if (size(swe_3d,/type) eq 8) then begin
    indx = nn2(tspec, (swe_3d.time + delta_t))
    swe_3d.lut = lspec[indx]
  endif

  if (size(swe_3d_arc,/type) eq 8) then begin
    indx = nn2(tspec, (swe_3d_arc.time + delta_t))
    swe_3d_arc.lut = lspec[indx]
  endif

; Make a tplot panel

  if keyword_set(tplot) then begin
    store_data,'TABNUM',data={x:tspec, y:lspec}
    ylim,'TABNUM',4.5,9.5,0
    options,'TABNUM','panel_size',0.5
    options,'TABNUM','ytitle','SWE LUT'
    options,'TABNUM','yminor',1
    options,'TABNUM','psym',10
    options,'TABNUM','colors',[4]
    options,'TABNUM','constant',[5,7,8,9]
  endif

end
