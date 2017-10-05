;+
;NAME:
; mvn_swe_l2gen
;PURPOSE:
; Loads L0 data, creates L2 files for 1 day
;CALLING SEQUENCE:
; mvn_swe_l2gen, date=date
;INPUT:
;   None.
;KEYWORDS:
;   DATE:       If set, the input date. The default is today.
;
;   DIRECTORY:  If set, output into this directory, for testing
;               purposes, don't forget a slash '/'  at the end.
;
;   L2ONLY:     If set, only generate PAD L2 data if MAG L2 data are available.
;
;   NOKP:       If set, do not generate SWEA KP data.
;
;   NOL2:       If set, do not generate SWEA L2 data.
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
;HISTORY:
; Hacked from Matt F's crib_l0_to_l2.txt, 2014-11-14: jmm
; Better memory management and added keywords to control processing: dlm
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-06-04 11:45:17 -0700 (Thu, 04 Jun 2015) $
; $LastChangedRevision: 17805 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_swe_l2gen.pro $
;- 
pro mvn_swe_l2gen, date=date, directory=directory, l2only=l2only, nokp=nokp, $
                   nol2=nol2, abins=abins, dbins=dbins, obins=obsin, mask_sc=mask_sc, $
                   _extra=_extra

  @mvn_swe_com
  
  if keyword_set(l2only) then l2only = 1 else l2only = 0

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

; Pick a day

  if (keyword_set(date)) then time = time_string(date[0], /date_only) $
                         else time = time_string(systime(/sec,/utc), /date_only)

  t0 = time_double(time)
  t1 = t0 + 86400D

  message, /info, 'PROCESSING: '+time_string(t0)
  timespan, t0, 1

; get SPICE kernels

  mvn_swe_spice_init, /force

; Load L0 SWEA data

  mvn_swe_load_l0

; Load highest level MAG data available (for pitch angle sorting)
;   L0 --> MAG angles computed onboard (stored in A2/A3 packets)
;   L1 --> MAG data processed on ground with nominal gains and offsets
;   L2 --> MAG data processed on ground with all corrections

  mvn_swe_addmag
  if (size(swe_mag1,/type) eq 8) then maglev = swe_mag1[0].level else maglev = 0B
  if (l2only and (maglev lt 2B)) then dopad = 0 else dopad = 1

; Create CDF files (up to 6 of them)

  if ~keyword_set(nol2) then begin
    print,""

    timer_start = systime(/sec)
    print,"Generating 3D Survey data"
    ddd = mvn_swe_get3d([t0,t1], /all)
    if (size(ddd,/type) eq 8) then begin
      indx = where(ddd.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
      if (icnt gt 0L) then ddd[indx].data *= reform(dmask1 # replicate(1.,icnt),64,96,icnt)
      if (jcnt gt 0L) then ddd[jndx].data *= reform(dmask0 # replicate(1.,jcnt),64,96,jcnt)
      mvn_swe_makecdf_3d, ddd, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    ddd = 0
    print,""

    timer_start = systime(/sec)
    print,"Generating 3D Archive data"
    ddd = mvn_swe_get3d([t0,t1], /all, /archive)
    if (size(ddd,/type) eq 8) then begin
      indx = where(ddd.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
      if (icnt gt 0L) then ddd[indx].data *= reform(dmask1 # replicate(1.,icnt),64,96,icnt)
      if (jcnt gt 0L) then ddd[jndx].data *= reform(dmask0 # replicate(1.,jcnt),64,96,jcnt)
      mvn_swe_makecdf_3d, ddd, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    ddd = 0
    print,""

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
      pad = mvn_swe_getpad([t0,t1], /all)
      if (size(pad,/type) eq 8) then begin
        indx = where(pad.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
        if (icnt gt 0L) then pad[indx].data *= reform(pmask1[*,pad[indx].k3d],64,16,icnt)
        if (jcnt gt 0L) then pad[jndx].data *= reform(pmask0[*,pad[jndx].k3d],64,16,jcnt)
        mvn_swe_makecdf_pad, pad, directory=directory, mname=mname
        dt = systime(/sec) - timer_start
        print,dt/60D,format='("Time to process (min): ",f6.2)'
      endif
      pad = 0
      print,""

      timer_start = systime(/sec)
      print,"Generating PAD Archive data"
      pad = mvn_swe_getpad([t0,t1], /all, /archive)
      if (size(pad,/type) eq 8) then begin
        indx = where(pad.time gt t_mtx[2], icnt, complement=jndx, ncomplement=jcnt)
        if (icnt gt 0L) then pad[indx].data *= reform(pmask1[*,pad[indx].k3d],64,16,icnt)
        if (jcnt gt 0L) then pad[jndx].data *= reform(pmask0[*,pad[jndx].k3d],64,16,jcnt)
        mvn_swe_makecdf_pad, pad, directory=directory, mname=mname
        dt = systime(/sec) - timer_start
        print,dt/60D,format='("Time to process (min): ",f6.2)'
      endif
      pad = 0
      print,""

    endif

    timer_start = systime(/sec)
    print,"Generating SPEC Survey data"
    spec = mvn_swe_getspec([t0,t1])
    if (size(spec,/type) eq 8) then begin
      mvn_swe_makecdf_spec, spec, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    spec = 0
    print,""

    timer_start = systime(/sec)
    print,"Generating SPEC Archive data"
    spec = mvn_swe_getspec([t0,t1], /archive)
    if (size(spec,/type) eq 8) then begin
      mvn_swe_makecdf_spec, spec, directory=directory
      dt = systime(/sec) - timer_start
      print,dt/60D,format='("Time to process (min): ",f6.2)'
    endif
    spec = 0
    print,""

  endif

; Create KP save file

  if ~keyword_set(nokp) then begin
    timer_start = systime(/sec)
    print,"Generating Key Parameters"
    mvn_swe_kp, l2only=l2only
    dt = systime(/sec) - timer_start
    print,dt/60D,format='("Time to process (min): ",f6.2)'
    print,""
  endif

; Clean up

  store_data, '*', /delete 

  return

end

