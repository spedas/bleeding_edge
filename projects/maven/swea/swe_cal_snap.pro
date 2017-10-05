;+
;PROCEDURE:   swe_cal_snap
;PURPOSE:
;  Plots snapshots of calibration data in a separate window for times selected 
;  with the cursor in a tplot window.  Hold down the left mouse button and slide
;  for a movie effect.
;
;  Calibration data can be extracted from 3D, PAD, or SPEC data.
;
;USAGE:
;  swe_cal_snap
;
;INPUTS:
;
;KEYWORDS:
;       DDD:           Get calibration from 3D data.
;
;       PAD:           Get calibration from PAD data.
;
;       SPEC:          Get calibration from SPEC data.
;
;       UNITS:         Data units.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-10-18 15:23:51 -0700 (Tue, 18 Oct 2016) $
; $LastChangedRevision: 22133 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_cal_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_cal_snap, ddd=ddd, pad=pad, spec=spec, keepwins=keepwins, units=units, $
                  archive=archive

  @mvn_swe_com
  @swe_snap_common

  if (size(snap_index,/type) eq 0) then swe_snap_layout, 0

  if not keyword_set(units) then units = 'rate'
  if keyword_set(archive) then aflg = 1 else aflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  
  if keyword_set(ddd) then doddd = 1 else doddd = 0
  if keyword_set(pad) then dopad = 1 else dopad = 0
  if keyword_set(spec) then begin
    if (size(mvn_swe_engy,/type) ne 8) then mvn_swe_makespec
    dospec = 1
  endif else dospec = 0
  
  if ((doddd + dopad + dospec) eq 0) then begin
    print,"You must set a data type keyword: DDD, PAD, SPEC"
    return
  endif

; Put up snapshot window

  Twin = !d.window

  if (size(Dopt,/type) ne 8) then swe_snap_layout, 0

  window, /free, xsize=1440, ysize=850, xpos=240, ypos=-860
  Cwin = !d.window

  limits = {no_interp:1, xrange:[3,5000], xstyle:1, yrange:[0,95], ystyle:1, $
            xmargin:[10,10], xtitle:'Energy (eV)', ytitle:'Angle Bin', $
            zlog:0, ztitle:'', xlog:1, ylog:0, charsize:1.2, title:''}

; Select the first time, then get the data closest that time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime,trange,npoints=1,/silent
; cursor,cx,cy,/norm,/up  ; make sure mouse button is released

  if (size(trange,/type) eq 2) then begin  ; Abort before first time select.
    wdelete,Cwin                          ; Don't keep empty windows.
    wset,Twin
    return
  endif
  
  ok = 1

  while (ok) do begin

; Calibration Plots
 
    wset, Cwin

    if (doddd) then begin
      dat = mvn_swe_get3d(trange[0],archive=aflg)

      if (size(dat,/type) eq 8) then begin
        mvn_swe_convert_units, dat, units

        x = dat.energy[*,0]
        y = findgen(dat.nbins)
        z1 = dat.data
        z2 = dat.gf
        z3 = dat.eff
        z4 = dat.dtc
        
        dz2 = max(abs(z2 - z2[0]))
        
        limits.xrange = [min(x),max(x)]
        limits.yrange = [min(y),max(y)]

        !p.multi = [0,2,2]
        limits.title = 'Data'
        limits.zlog = 1
        limits.ztitle = strupcase(dat.units_name)
        specplot,x,y,z1,limits=limits
        limits.title = 'Geometric Factor (x10!u4!n)'
        limits.zlog = 0
        limits.ztitle = ''
        if (dz2 lt 1e-5) then begin
          plot_oi,x,z2[*,0], xrange=limits.xrange, xstyle=limits.xstyle, $
            xmargin=limits.xmargin, xtitle=limits.xtitle, $
            ytitle='Geometric Factor (x10!u4!n)', $
            charsize=limits.charsize, title=limits.title
        endif else specplot,x,y,z2,limits=limits
        limits.title = 'MCP Efficiency'
        specplot,x,y,z3,limits=limits
        limits.title = 'Deadtime Correction'
        specplot,x,y,z4,limits=limits
        !p.multi = 0
      endif
    endif
    
    if (dopad) then begin
      dat = mvn_swe_getpad(trange[0],archive=aflg)

      if (size(dat,/type) eq 8) then begin
        mvn_swe_convert_units, dat, units
        x = dat.energy[*,0]
        y = findgen(dat.nbins)
        z1 = dat.data
        z2 = dat.gf * 1.e4
        z3 = dat.eff
        z4 = dat.dtc
        
        dz2 = max(abs(z2 - z2[0]))
        
        limits.xrange = [min(x),max(x)]
        limits.yrange = [min(y),max(y)]

        !p.multi = [0,2,2]
        limits.title = 'Data'
        limits.zlog = 1
        limits.ztitle = strupcase(dat.units_name)
        specplot,x,y,z1,limits=limits
        limits.title = 'Geometric Factor (x10!u4!n)'
        limits.zlog = 0
        limits.ztitle = ''
        if (dz2 lt 1e-5) then begin
          plot_oi,x,z2[*,0], xrange=limits.xrange, xstyle=limits.xstyle, $
            xmargin=limits.xmargin, xtitle=limits.xtitle, $
            ytitle='Geometric Factor (x10!u4!n)', $
            charsize=limits.charsize, title=limits.title
        endif else specplot,x,y,z2,limits=limits
        limits.title = 'MCP Efficiency'
        specplot,x,y,z3,limits=limits
        limits.title = 'Deadtime Correction'
        specplot,x,y,z4,limits=limits
        !p.multi = 0
      endif
    endif
    
    if (dospec) then begin
      dat = mvn_swe_getspec(trange[0],archive=aflg)

      if (size(dat,/type) eq 8) then begin
        mvn_swe_convert_units, dat, units

        x = dat.energy
        y1 = dat.data
        y2 = dat.gf * 1.e4
        y3 = dat.eff
        y4 = dat.dtc

        !p.multi = [0,2,2]
        plot_oo,x,y1,xtitle='Energy (eV)',ytitle=strupcase(dat.units_name),$
                     yrange=[1.,1.e5],psym=10
        plot_oi,x,y2,xtitle='Energy (eV)',ytitle='Geometric Factor (x10!u4!n)',psym=10
        plot_oi,x,y3,xtitle='Energy (eV)',ytitle='MCP Efficiency',psym=10
        plot_oi,x,y4,xtitle='Energy (eV)',ytitle='Deadtime Correction',psym=10
        !p.multi = 0
      endif
    endif

; Get the next button press

    wset,Twin
    ctime,trange,npoints=1,/silent
;   cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(trange,/type) eq 5) then ok = 1 else ok = 0

  endwhile

  if (kflg) then wdelete, Cwin

  wset, Twin

  return

end
