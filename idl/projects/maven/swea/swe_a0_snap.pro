;+
;PROCEDURE:   swe_a0_snap
;PURPOSE:
;  Plots 3D snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;
;  If housekeeping data exist (almost always the case), then they are displayed 
;  as text in a small separate window.
;
;USAGE:
;  swe_3d_snap
;
;INPUTS:
;
;KEYWORDS:
;       MODEL:         Plot a model of the 3D data product with the test pulser on in a
;                      separate window.  (An analytic approximation to the test pulser
;                      signal is used.  See 'swe_testpulser_model.pro' for details.)
;
;       ZRANGE:        Sets color scale range.  Default = [1,3000].
;
;       ZLOG:          Sets log color scaling.  Default = 1.
;
;       WSCALE:        Scale factor for snapshot window sizes.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       MONITOR:       Put snapshot windows in this monitor.  Monitors are numbered
;                      from 0 to N-1, where N is the number of monitors recognized
;                      by the operating system.  See win.pro for details.
;
;       ARCHIVE:       If set, show snapshots of archive data (A1).
;
;       BURST:         Synonym for ARCHIVE.
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_a0_snap.pro
;VERSION:   1.0
;LAST MODIFICATION:   07/24/12
;-
pro swe_a0_snap, model=model, keepwins=keepwins, zrange=zrange, zlog=zlog, $
                 archive=archive, burst=burst, monitor=monitor, wscale=wscale

  @mvn_swe_com
  @putwin_common

  if (size(windex,/type) eq 0) then win, config=0  ; win acts like window

  if (keyword_set(archive) or keyword_set(burst)) then aflg = 1 else aflg = 0

  if keyword_set(wscale) then scale = wscale[0] else scale = 1.

  if (aflg) then begin
    if (size(swe_3d_arc,/type) ne 8) then begin
      print,"No valid 3D archive data."
      return
    endif
  endif else begin
    if (size(swe_3d,/type) ne 8) then begin
      print,"No valid 3D survey data."
      return
    endif
  endelse

  if keyword_set(model) then mflg = 1 else mflg = 0
  if (size(swe_hsk,/type) ne 8) then hflg = 0 else hflg = 1

  if keyword_set(keepwins) then kflg = 0 else kflg = 1

  if (size(zrange,/type) eq 0) then zrange = [1.,3000.]
  if (size(zlog,/type) eq 0) then zlog = 1

;  gudsum = ['CC'X, '1E'X]        ; up to early cruise
  gudsum = ['C0'X, 'DE'X]        ; once the new sweep tables are uploaded
  
  nchan = [64, 32, 16]           ; number of energy channels, indexed by the GROUP tag in A0
  period = 2D^(dindgen(6) + 1D)  ; sampling interval (sec), indexed by the PERIOD tag in A0

; Put up snapshot window(s)

  Twin = !d.window

  undefine, mnum
  if (size(monitor,/type) gt 0) then begin
    if (~windex) then win, /config
    mnum = fix(monitor[0])
  endif else begin
    if (size(secondarymon,/type) gt 0) then mnum = secondarymon
  endelse

  win, /free, monitor=mnum, xsize=800, ysize=500, dx=10, dy=10, scale=scale
  Swin = !d.window
  
  if (hflg) then begin
    win, /free, rel=Swin, xsize=225, ysize=545, dx=10
    Hwin = !d.window
  endif

  if (mflg) then begin
    win, /free, rel=Swin, xsize=800, ysize=500, dy=-55, scale=scale
    Mwin = !d.window
  endif

; Select the first time, then get the 3D spectrum closest that time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime2,trange,npoints=1,/silent,button=button

  if (size(trange,/type) eq 2) then begin  ; Abort before first time select.
    wdelete,Swin                          ; Don't keep empty windows.
    if (hflg) then wdelete,Hwin
    if (mflg) then wdelete,Mwin
    wset,Twin
    return
  endif
  
  if (aflg) then dt = min(abs(swe_3d_arc.time - trange[0]), iref) $
            else dt = min(abs(swe_3d.time - trange[0]), iref)

  if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)
  
  ok = 1

  while (ok) do begin

    if (aflg) then begin
      ddd = swe_3d_arc[iref]
      pmsg = "A1"
    endif else begin
      ddd = swe_3d[iref]
      pmsg = "A0"
    endelse

    n_e = ddd.n_e
 
    x = findgen(82) - 0.5
    y = findgen(n_e+2) - 0.5
    zz = ddd.data[*,0:(n_e-1)]

    z = x # y
    z[1:80, 1:n_e] = zz
    z[1:80, 0] = z[1:80, 1]
    z[1:80, n_e+1] = z[1:80, n_e]
    z[0,*] = z[1,*]
    z[81,*] = z[80,*]

    wset, Swin

; Put up a 3D spectrogram

    title = string(pmsg, time_string(ddd.time), ddd.group, ddd.period, ddd.lut, ddd.npkt, $
                   format='(a2,4x,a19,4x,"G ",i1,2x,"P ",i1,4x,"LUT: ",i1,4x,"NPKT: ",i3)')
    lim = {x_no_interp:1, y_no_interp:1, xrange:[0,80], yrange:[0,n_e], zrange:zrange, $
           xmargin:[10,10], charsize:1.2, xtitle:'Angle Bin', ytitle:'Energy Bin', $
           ztitle:'Counts', title:title, xstyle:1, ystyle:1, zlog:zlog, xticks:5, xminor:4, $
           yticks:4, yminor:4}

    indx = where(z eq 0.,count)
    if (count gt 0L) then z[indx] = !values.f_nan
    specplot,x,y,z,limits=lim

; Put up test pulser model

    if (mflg) then begin
      wset, Mwin
      swe_testpulser_model,group=ddd.group,result=tpmod

      zz = tpmod.a0
      z = x # y
      z[1:80, 1:n_e] = zz
      z[1:80, 0] = z[1:80, 1]
      z[1:80, n_e+1] = z[1:80, n_e]
      z[0,*] = z[1,*]
      z[81,*] = z[80,*]

      title = 'Test Pulser Model: ' + pmsg
      lim = {x_no_interp:1, y_no_interp:1, xrange:[0,80], yrange:[0,n_e], zrange:zrange, $
             xmargin:[10,10], charsize:1.2, xtitle:'Angle Bin', ytitle:'Energy Bin', $
             ztitle:'Counts', title:title, xstyle:1, ystyle:1, zlog:zlog, xticks:5, xminor:4, $
             yticks:4, yminor:4}

      specplot,x,y,z,limits=lim
    endif

; Print out housekeeping in another window

    if (hflg) then begin
      wset, Hwin
      
      csize = 1.4
      nlines = 28
      x1 = 0.05
      x2 = 0.75
      x3 = x2 - 0.12
      y1 = 0.95 - (0.9/(float(nlines-1)))*findgen(nlines)
  
      fmt1 = '(f7.2," V")'
      fmt2 = '(f7.2," C")'
      fmt3 = '(i2)'
      
      j = jref
    
      if (swe_hsk[j].CHKSUM[0] eq gudsum[0]) then col0 = 4 else col0 = 6
      if (swe_hsk[j].CHKSUM[1] eq gudsum[1]) then col1 = 4 else col1 = 6

      k = 0
      erase
      xyouts,x1,y1[k++],/normal,"SWEA Housekeeping",charsize=csize
      xyouts,x1,y1[k++],/normal,time_string(swe_hsk[j].time),charsize=csize
      xyouts,x1,y1[k],/normal,"NPKT",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].NPKT,format='(i3)'),charsize=csize,align=1.0
      k++
      xyouts,x1,y1[k],/normal,"P28V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].P28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"MCP28V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].MCP28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"NR28V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].NR28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"MCPHV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].MCPHV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"NRV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].NRV,format=fmt1),charsize=csize,align=1.0
      k++
      xyouts,x1,y1[k],/normal,"P12V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].P12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"N12V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].N12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"P5AV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].P5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"N5AV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].N5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"P5DV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"P3P3DV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].P3P3DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"P2P5DV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].P2P5DV,format=fmt1),charsize=csize,align=1.0
      k++
      xyouts,x1,y1[k],/normal,"ANALV",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].ANALV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"DEF1V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].DEF1V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"DEF2V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].DEF2V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"V0V",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].V0V,format=fmt1),charsize=csize,align=1.0
      k++
      xyouts,x1,y1[k],/normal,"ANALT",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].ANALT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"LVPST",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].LVPST,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[k],/normal,"DIGT",charsize=csize
      xyouts,x2,y1[k++],/normal,string(swe_hsk[j].DIGT,format=fmt2),charsize=csize,align=1.0
      k++
      xyouts,x1,y1[k],/normal,"TABNUM",charsize=csize
      if (ddd.lut ge 1 and ddd.lut le 8) then col0 = 4 else col0 = 6
      xyouts,x2,y1[k],/normal,string(ddd.lut,format=fmt3),charsize=csize,align=1.0,$
                       color=col0
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (size(trange,/type) eq 5) then begin
      if (aflg) then dt = min(abs(swe_3d_arc.time - trange[0]), iref) $
                else dt = min(abs(swe_3d.time - trange[0]), iref)
      if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)
      ok = 1
    endif else ok = 0

  endwhile

  if (kflg) then begin
    wdelete, Swin
    if (hflg) then wdelete, Hwin
    if (mflg) then wdelete, Mwin
  endif

  wset, Twin

  return

end
