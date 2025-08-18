;+
;NAME:
; mvn_swe_l2gen5
;PURPOSE:
; Loads L0 data, creates L2 files for 1 day
;
;   WARNING: This routine is for use by the SWEA instrument team only.
;
;CALLING SEQUENCE:
; mvn_swe_l2gen5, date=date
;INPUT:
;   None.
;KEYWORDS:
;   DATE:      If set, the input date. The default is today.
;
;   DIRECTORY: If set, output into this directory, for testing
;               purposes, don't forget a slash '/'  at the end.
;
;   L2ONLY:    If set, only generate PAD L2 data if MAG L2 data are available.
;
;   NOL2:      If set, do not generate SWEA L2 data.  Takes precedence over the
;              next three keywords.
;
;   DOSPEC:    Process the SPEC data.  Default = 1 (yes).
;
;   DOPAD:     Process the PAD data.  Default = 1 (yes).
;
;   DO3D:      Process the 3D data.  Default = 1 (yes).
;
;   DOKP:      Process the KP data.  Default = 1 (yes).
;
;   ABINS:     Anode bin mask -> 16 elements (0 = off, 1 = on)
;              Default = replicate(1,16)
;
;   DBINS:     Deflector bin mask -> 6 elements (0 = off, 1 = on)
;              Default = replicate(1,6)
;
;   OBINS:     3D solid angle bin mask -> 96 elements (0 = off, 1 = on)
;              Default = reform(ABINS # DBINS)
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking defined by the ABINS, DBINS, and OBINS.
;              Default = 1 (yes).  Set this to 0 to disable and use the
;              above 3 keywords only (not recommended!).
;
;   KP_QLEV:   Minimum quality level for calculating key parameters.  Filters out
;              the vast majority of spectra affected by the sporadic low energy
;              anomaly below 28 eV.  The validity levels are:
;
;                0B = Data are affected by the low-energy anomaly.  There
;                     are significant systematic errors below 28 eV.
;                1B = Unknown because: (1) the variability is too large to 
;                     confidently identify anomalous spectra, as in the 
;                     sheath, or (2) secondary electrons mask the anomaly,
;                     as in the sheath just downstream of the bow shock.
;                2B = Data are not affected by the low-energy anomaly.
;                     Caveat: There is increased noise around 23 eV, even 
;                     for "good" spectra.
;
;              Default for this procedure is 1B.
;
;HISTORY:
; Hacked from Matt F's crib_l0_to_l2.txt, 2014-11-14: jmm
; Better memory management and added keywords to control processing: dlm
; Development code for data version 5; DLM: 2023-08
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-22 12:48:17 -0700 (Tue, 22 Aug 2023) $
; $LastChangedRevision: 32051 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/Test/mvn_swe_l2gen5.pro $
;- 
pro mvn_swe_l2gen5, date=date, directory=directory, l2only=l2only, dokp=dokp, $
                   nol2=nol2, abins=abins, dbins=dbins, obins=obsin, mask_sc=mask_sc, $
                   kp_qlev=kp_qlev, dospec=dospec, dopad=dopad, do3d=do3d, _extra=_extra

  @mvn_swe_com
  
  uinfo = get_login_info()
  if ((uinfo.user_name ne 'mitchell') and (uinfo.user_name ne 'shaosui.xu')) then begin
    print,'This routine is for development only.  It is not intended for public use.'
    return
  endif

  l2only = keyword_set(l2only)
  kp_qlev = (n_elements(kp_qlev) gt 0) ? byte(kp_qlev[0]) < 2B : 1B
  dospec = (n_elements(dospec) gt 0) ? keyword_set(dospec) : 1
  dopad = (n_elements(dopad) gt 0) ? keyword_set(dopad) : 1
  do3d = (n_elements(do3d) gt 0) ? keyword_set(do3d) : 1
  dokp = (n_elements(dokp) gt 0) ? keyword_set(dokp) : 1
  if keyword_set(nol2) then begin
    dospec = 0
    dopad = 0
    do3d = 0
  endif
  oneday = 86400D

  if ((dospec + dopad + do3d + dokp) eq 0) then begin
    print,'Nothing to do.'
    return
  endif

; Construct FOV masking arrays
;   96 solid angles X 2 boom states

  if (size(swe_sc_mask,/type) eq 0) then mvn_swe_calib, tab=5  
  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins

; Set version - hard-coded for version 5

  version = 5

; PAD mask

  pmask = replicate(1.,96,2)
  indx = where(obins eq 0B, count)
  if (count gt 0L) then pmask[indx] = !values.f_nan
  pmask = reform(replicate(1.,64) # reform(pmask, 96*2), 64, 96, 2)
  pmask0 = pmask[*,*,0]  ; 64E X 96A, boom stowed
  pmask1 = pmask[*,*,1]  ; 64E X 96A, boom deployed

; 3D mask

  dmask = reform(pmask,64*96,2)
  dmask0 = dmask[*,0]    ; 64*96 EA, boom stowed
  dmask1 = dmask[*,1]    ; 64*96 EA, boom deployed

; Root data directory, sometimes isn't defined

  setenv, 'ROOT_DATA_DIR=/disks/data/'

; Pick a day (include previous day to get SPEC data that belong with current date)

  if (keyword_set(date)) then time = time_string(date[0], /date_only) $
                         else time = time_string(systime(/sec,/utc), /date_only)

  t0 = time_double(time)
  tm1 = t0 - oneday
  tp1 = t0 + oneday

; Added to assure that pre-orbit files are not processed
  If(t0 Lt time_double('2014-10-13')) Then Begin
     dprint, 'Old File Date: '+time_string(d0)
     Return
  Endif

  message, /info, 'PROCESSING: '+time_string(t0)
  timespan, [tm1,tp1]

; get SPICE time, frames, and SPK kernels

  if (l2only) then mvn_swe_spice_init, /force, /list $
              else mvn_swe_spice_init, /nock, /force, /list

; Load L0 SWEA data

  mvn_swe_load_l0, /nospice

; Load highest level MAG data available (for pitch angle sorting)
;   L0 --> MAG angles computed onboard (stored in A2/A3 packets)
;   L1 --> MAG data processed on ground with nominal gains and offsets
;   L2 --> MAG data processed on ground with all corrections

  mvn_swe_addmag, l2only=l2only
  if (size(swe_mag1,/type) eq 8) then maglev = swe_mag1[0].level else maglev = 0B
  if (l2only and (maglev lt 2B)) then dopad = 0

; Determine quality flags

  mvn_swe_quality_daily, t0, /noload
  mvn_swe_set_quality, missing=missing, /silent

; Create CDF files (up to 6 of them)

  print,""

  if (do3d) then begin
    timer_start = systime(/sec)
    print,"Generating 3D Survey data"
    ddd = mvn_swe_get3d([t0,tp1], /all)
    if (size(ddd,/type) eq 8) then begin
      indx = where(ddd.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
      if (icnt gt 0L) then ddd[indx].data *= reform(dmask1 # replicate(1.,icnt),64,96,icnt)
      if (jcnt gt 0L) then ddd[jndx].data *= reform(dmask0 # replicate(1.,jcnt),64,96,jcnt)
      mvn_swe_secondary, ddd
      mvn_swe_makecdf_3d5, ddd, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    ddd = 0
    print,""

    timer_start = systime(/sec)
    print,"Generating 3D Archive data"
    ddd = mvn_swe_get3d([t0,tp1], /all, /archive)
    if (size(ddd,/type) eq 8) then begin
      indx = where(ddd.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
      if (icnt gt 0L) then ddd[indx].data *= reform(dmask1 # replicate(1.,icnt),64,96,icnt)
      if (jcnt gt 0L) then ddd[jndx].data *= reform(dmask0 # replicate(1.,jcnt),64,96,jcnt)
      mvn_swe_secondary, ddd
      mvn_swe_makecdf_3d5, ddd, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    ddd = 0
    print,""
  endif

  if (dopad) then begin
    if (maglev eq 2B) then begin
      mfile = 'maven/data/sci/mag/l2/YYYY/MM/mvn_mag_l2_YYYY???pl_YYYYMMDD_v??_r??.xml'
      mname = mvn_pfp_file_retrieve(mfile,trange=trange,/daily,/valid,verbose=-1)
      mname = file_basename(mname[0])
      i = strpos(mname,'.xml')
      if (i gt 0) then mname = strmid(mname,0,i) + '.sts' else mname = 'mag_level_2'
    endif else mname = 'mag_level_1'

    timer_start = systime(/sec)
    print,"Generating PAD Survey data"
    pad = mvn_swe_getpad([t0,tp1], /all)
    if (size(pad,/type) eq 8) then begin
      indx = where(pad.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
      if (icnt gt 0L) then pad[indx].data *= reform(pmask1[*,pad[indx].k3d],64,16,icnt)
      if (jcnt gt 0L) then pad[jndx].data *= reform(pmask0[*,pad[jndx].k3d],64,16,jcnt)
      mvn_swe_secondary, pad
      mvn_swe_makecdf_pad5, pad, directory=directory, mname=mname
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    pad = 0
    print,""

    timer_start = systime(/sec)
    print,"Generating PAD Archive data"
    pad = mvn_swe_getpad([t0,tp1], /all, /archive)
    if (size(pad,/type) eq 8) then begin
      indx = where(pad.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
      if (icnt gt 0L) then pad[indx].data *= reform(pmask1[*,pad[indx].k3d],64,16,icnt)
      if (jcnt gt 0L) then pad[jndx].data *= reform(pmask0[*,pad[jndx].k3d],64,16,jcnt)
      mvn_swe_secondary, pad
      mvn_swe_makecdf_pad5, pad, directory=directory, mname=mname
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    pad = 0
    print,""
  endif

  if (dospec) then begin
    timer_start = systime(/sec)
    print,"Generating SPEC Survey data"
    spec = mvn_swe_getspec([t0,tp1])
    if (size(spec,/type) eq 8) then begin
      mvn_swe_secondary, spec
      mvn_swe_makecdf_spec5, spec, directory=directory, version=version
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    spec = 0
    print,""

    timer_start = systime(/sec)
    print,"Generating SPEC Archive data"
    spec = mvn_swe_getspec([t0,tp1], /archive)
    if (size(spec,/type) eq 8) then begin
      mvn_swe_secondary, spec
      mvn_swe_makecdf_spec5, spec, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    spec = 0
    print,""
  endif

  if (dokp) then begin
    timer_start = systime(/sec)
    print,"Generating Key Parameters"
    mvn_swe_kp5, trange=[t0,tp1], l2only=l2only, qlevel=kp_qlev
    dt = systime(/sec) - timer_start
    print,dt/60D,format='("Time to process (min): ",f6.2)'
    print,""
  endif

; Clean up

  store_data, '*', /delete 

  return

end

