;+
;PROCEDURE:   mvn_spice_stat
;PURPOSE:
;  Reports the status of SPICE.  This is mainly a wrapper for spice_kernel_info(),
;  providing a concise summary of the key information.  The naming convention for 
;  C kernels (ck) includes a type string:
;
;    red  = reconstructed, daily
;    rec  = reconstructed, contact-to-contact (typically a few days)
;    rel  = reconstructed, long (typically one week)
;    pred = predicted
;
;USAGE:
;  mvn_spice_stat
;
;INPUTS:
;
;KEYWORDS:
;
;    LIST:          If set, list the kernels in use.
;
;    INFO:          Returns an array of structures providing detailed information
;                   about each kernel, including coverage in time.
;
;    TPLOT:         Makes a colored bar as a tplot variable, to visually show
;                   coverage:
;
;                      green  = all kernels available
;                      yellow = S/C spk and ck available, missing APP ck
;                      red    = S/C spk available, missing S/C ck
;                      blank  = missing S/C spk
;
;                   which translates to:
; 
;                      green  = spacecraft and all instruments
;                      yellow = spacecraft and body-mounted instruments only
;                      red    = spacecraft position only
;                      blank  = no geometry at all
;
;    SUMMARY:       Provides a concise summary.
;
;    FULL:          Provides additional details: time coverage and objects.
;
;    CHECK:         Set this keyword to a time array to test whether the loaded
;                   kernels are sufficient to cover the entire time range.  The
;                   time array can be in any format accepted by time_double.
;                   If CHECK is set, then keyword SUMMARY will include success
;                   flags (1 = sufficient coverage, 0 = insufficient coverage).
;
;    KEY:           Print out the color key and return.
;
;    SILENT:        Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-07-14 11:38:38 -0700 (Mon, 14 Jul 2025) $
; $LastChangedRevision: 33462 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_stat.pro $
;
;CREATED BY:    David L. Mitchell  09/14/18
;-
pro mvn_spice_stat, list=list, info=info, tplot=tplot, summary=summary, check=check, silent=silent, $
                    full=full, key=key

  blab = ~keyword_set(silent)

  summary = {all_exist     : 0       , $
             time_exists   : 0       , $
             planets_exist : 0       , $
             moons_exist   : 0       , $
             frames_exist  : 0       , $
             spk_exists    : 0       , $
             spk_trange    : [0D,0D] , $
             spk_ngaps     : 0       , $
             ck_sc_exists  : 0       , $
             ck_sc_trange  : [0D,0D] , $
             ck_sc_ngaps   : 0       , $
             ck_app_exists : 0       , $
             ck_app_trange : [0D,0D] , $
             ck_app_ngaps  : 0       , $
             trange_check  : [0D,0D] , $
             spk_check     : 0       , $
             ck_sc_check   : 0       , $
             ck_app_check  : 0       , $
             all_check     : 0          }

  if (blab) then print,''

  mk = spice_test('*',verbose=(blab+1))
  indx = where(mk ne '', n_ker)
  if (n_ker eq 0) then begin
    if (blab) then begin
      print,"  No SPICE kernels are loaded."
      print,''
    endif
    return
  endif

  if keyword_set(key) then goto, printkey

  loadlist = ['']
  for i=0,(n_ker-1) do loadlist = [loadlist, file_basename(mk[i])]
  loadlist = loadlist[1:*]
  str_element, summary, 'loadlist', loadlist, /add

  if (keyword_set(list) and blab) then begin
    print,"  SPICE kernels in use:"
    for i=0,(n_ker-1) do print,"    ",loadlist[i]
    print,''
  endif

  info = spice_kernel_info(verbose=0)
  if (keyword_set(full) and blab) then begin
    nobj = n_elements(info)
    print,"  SPICE coverage by object:"
    for i=0,(nobj-1) do begin
      print,i,time_string(info[i].trange,prec=-3),info[i].obj_name,file_basename(info[i].filename), $
              format='(3x,i3,2x,a10," to ",a10,2x,a-18,2x,a)'
    endfor
    print,''
  endif

; Check for time, planet, moon, and frame kernels

  ok = max(stregex(loadlist,'naif[0-9]{4}\.tls',/subexpr,/fold_case)) gt (-1)
  ok += max(stregex(loadlist,'MVN_SCLKSCET.[0-9]{5}\.tsc',/subexpr,/fold_case)) gt (-1)
  summary.time_exists = (ok eq 2)

  ok = max(stregex(loadlist,'pck[0-9]{5}\.tpc',/subexpr,/fold_case)) gt (-1)
  ok += max(stregex(loadlist,'de[0-9]{3}.*\.bsp',/subexpr,/fold_case)) gt (-1)
  summary.planets_exist = (ok eq 2)

  summary.moons_exist = max(stregex(loadlist,'mar[0-9]{3}\.bsp',/subexpr,/fold_case)) gt (-1)
  summary.frames_exist = max(stregex(loadlist,'maven_v[0-9]{2}\.tf',/subexpr,/fold_case)) gt (-1)

; Check for SPK and CK kernels

  dobar = 0
  cols = [3,4,6,!p.background] ; [green, yellow, red, blank]
  if keyword_set(tplot) then begin
    tplot_options, get=topt
    if (min(topt.trange_full) gt 1D) then begin
      npts = floor(topt.trange_full[1] - topt.trange_full[0]) + 1L
      x = topt.trange_full[0] + dindgen(npts)
      y = replicate(cols[0],npts,2)  ; start assuming all kernels available
      dobar = 1
    endif
  endif

  dt = time_double(info.trange[1]) - time_double(info.trange[0])
  indx = where((info.interval lt 1) or (abs(dt) gt 1D), count)
  if (count gt 0) then info = info[indx]  ; discard intervals of zero length

  if (blab) then print,"  MAVEN SPICE coverage:"
  fmt1 = '(4x,a3,2x,a3,2x,a19,2x,a19,$)'
  fmt2 = '(8x,4a,"  ",2a)'
  indx = where(info.obj_name eq 'MAVEN', nfiles)
  if (nfiles gt 0) then begin
    summary.spk_exists = 1
    summary.spk_trange = minmax(time_double(info[indx].trange))
    tsp = time_string(summary.spk_trange)
    i = indx[0]
    if (blab) then print,info[i].type,"S/C",tsp,format=fmt1
    if (dobar) then begin
      tt = time_double(tsp)
      kndx = where((x lt tt[0]) or (x gt tt[1]), count)
      if (count gt 0L) then y[kndx,*] = cols[3]
    endif

    jndx = indx[uniq(info[indx].filename,sort(info[indx].filename))]
    jndx = jndx[sort(jndx)]  ; back in the original order
    fnames = info[jndx].filename
    nfiles = n_elements(jndx)
    fgaps = 0
    ftsp = ['']
    for i=1,(nfiles-1) do begin
      j1 = where(info.filename eq fnames[i])
      j2 = where(info.filename eq fnames[i-1])
      t1 = min(time_double(info[j1].trange[0]))
      t0 = max(time_double(info[j2].trange[1]))
      if (t1 gt t0) then begin
        fgaps++
        ftsp = [ftsp, time_string([t0,t1])]
      endif
    endfor
    if (fgaps gt 0) then ftsp = ftsp[1:*]

    jndx = where(info[indx].interval gt 0, ngaps)
    if (blab) then if ((fgaps + ngaps) eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    summary.spk_ngaps = fgaps + ngaps
    gapnum = 1
    for j=0,(fgaps-1) do begin
      k = 2*j
      if (blab) then print,"  * GAP ",strtrim(gapnum++,2),": ",ftsp[k:k+1]," *",format=fmt2
      if (dobar) then begin
        tt = time_double(ftsp[k:k+1])
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = cols[3]
      endif
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      if (blab) then print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
      if (dobar) then begin
        tt = time_double(tsp)
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = cols[3]
      endif
    endfor
  endif else begin
    if (blab) then print,"    No S/C SPK coverage!"
    if (dobar) then y[*] = 0
  endelse

  indx = where(info.obj_name eq 'MAVEN_SC_BUS', nfiles)
  if (nfiles gt 0) then begin
    summary.ck_sc_exists = 1
    summary.ck_sc_trange = minmax(time_double(info[indx].trange))
    tsp = time_string(summary.ck_sc_trange)
    i = indx[0]
    if (blab) then print,info[i].type,"S/C",tsp,format=fmt1
    if (dobar) then begin
      tt = time_double(tsp)
      kndx = where(((x lt tt[0]) or (x gt tt[1])) and (y[*,0] ne 0), count)
      if (count gt 0L) then y[kndx,*] = cols[2]
    endif

    jndx = indx[uniq(info[indx].filename,sort(info[indx].filename))]
    jndx = jndx[sort(jndx)]  ; back in the original order
    fnames = info[jndx].filename
    nfiles = n_elements(jndx)
    fgaps = 0
    ftsp = ['']
    for i=1,(nfiles-1) do begin
      j1 = where(info.filename eq fnames[i])
      j2 = where(info.filename eq fnames[i-1])
      t1 = min(time_double(info[j1].trange[0]))
      t0 = max(time_double(info[j2].trange[1]))
      if (t1 gt t0) then begin
        fgaps++
        ftsp = [ftsp, time_string([t0,t1])]
      endif
    endfor
    if (fgaps gt 0) then ftsp = ftsp[1:*]

    jndx = where(info[indx].interval gt 0, ngaps)
    if (blab) then if ((fgaps + ngaps) eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    summary.ck_sc_ngaps = fgaps + ngaps
    gapnum = 1
    for j=0,(fgaps-1) do begin
      k = 2*j
      if (blab) then print,"  * GAP ",strtrim(gapnum++,2),": ",ftsp[k:k+1]," *",format=fmt2
      if (dobar) then begin
        tt = time_double(ftsp[k:k+1])
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = cols[2]
      endif
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      if (blab) then print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
      if (dobar) then begin
        tt = time_double(tsp)
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = cols[2]
      endif
    endfor
  endif else begin
    if (blab) then print,"    No S/C CK coverage!"
    if (dobar) then y[*] = 1
  endelse

  indx = where(info.obj_name eq 'MAVEN_APP_IG', nfiles)
  if (nfiles gt 0) then begin
    summary.ck_app_exists = 1
    summary.ck_app_trange = minmax(time_double(info[indx].trange))
    tsp = time_string(summary.ck_app_trange)
    i = indx[0]
    if (blab) then print,info[i].type,"APP",tsp,format=fmt1
    if (dobar) then begin
      tt = time_double(tsp)
      kndx = where(((x lt tt[0]) or (x gt tt[1])) and $
                   ((y[*,0] ne 0) and (y[*,0] ne cols[2])), count)
      if (count gt 0L) then y[kndx,*] = cols[1]
    endif

    jndx = indx[uniq(info[indx].filename,sort(info[indx].filename))]
    jndx = jndx[sort(jndx)]  ; back in the original order
    fnames = info[jndx].filename
    nfiles = n_elements(jndx)
    fgaps = 0
    ftsp = ['']
    for i=1,(nfiles-1) do begin
      j1 = where(info.filename eq fnames[i])
      j2 = where(info.filename eq fnames[i-1])
      t1 = min(time_double(info[j1].trange[0]))
      t0 = max(time_double(info[j2].trange[1]))
      if (t1 gt t0) then begin
        fgaps++
        ftsp = [ftsp, time_string([t0,t1])]
      endif
    endfor
    if (fgaps gt 0) then ftsp = ftsp[1:*]

    jndx = where(info[indx].interval gt 0, ngaps)
    if (blab) then if ((fgaps + ngaps) eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    summary.ck_app_ngaps = fgaps + ngaps
    gapnum = 1
    for j=0,(fgaps-1) do begin
      k = 2*j
      if (blab) then print,"  * GAP ",strtrim(gapnum++,2),": ",ftsp[k:k+1]," *",format=fmt2
      if (dobar) then begin
        tt = time_double(ftsp[k:k+1])
        kndx = where((x ge tt[0]) and (x le tt[1]) and (y[*,0] ne cols[2]), count)
        if (count gt 0L) then y[kndx,*] = cols[1]
      endif
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      if (blab) then print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
      if (dobar) then begin
        tt = time_double(tsp)
        kndx = where((x ge tt[0]) and (x le tt[1]) and (y[*,0] ne cols[2]), count)
        if (count gt 0L) then y[kndx,*] = cols[1]
      endif
    endfor
  endif else begin
    if (blab) then print,"    No APP CK coverage!"
    if (dobar) then y[*] = 1
  endelse

  if (blab) then print,''

  ok = summary.time_exists + summary.planets_exist + summary.moons_exist + $
       summary.frames_exist + summary.spk_exists + summary.ck_sc_exists + $
       summary.ck_app_exists
  summary.all_exist = (ok eq 7)

  if (n_elements(check) eq 0) then begin
    tplot_options, get=topt
    if (topt.trange_full[0] gt 0D) then check = topt.trange_full
  endif
  if (n_elements(check) gt 0) then begin
    tmin = min(time_double(check), max=tmax)
    summary.trange_check = [tmin,tmax]
    summary.spk_check = ((summary.spk_trange[0] le tmin) and (summary.spk_trange[1] ge tmax))
    summary.ck_sc_check = ((summary.ck_sc_trange[0] le tmin) and (summary.ck_sc_trange[1] ge tmax))
    summary.ck_app_check = ((summary.ck_app_trange[0] le tmin) and (summary.ck_app_trange[1] ge tmax))
    ok = summary.spk_check + summary.ck_sc_check + summary.ck_app_check
    summary.all_check = (ok eq 3)
  endif

  if (dobar) then begin
    indx = where(y eq 0, count)
    y = float(y)
    if (count gt 0L) then y[indx] = !values.f_nan

    bname = 'spice_bar'
    store_data,bname,data={x:x, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,6,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'color_table',43
    options,bname,'no_color_scale',1

    goto, printkey
  endif

  return

; Print out the color key

printkey:

  print,''
  print,'Spice status bar color key:'
  print,'  green  = all kernels available'
  print,'  yellow = missing APP ck'
  print,'  red    = missing APP ck and S/C ck'
  print,'  blank  = no geometry at all'
  print,''

end
