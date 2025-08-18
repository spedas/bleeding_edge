;+
;PROCEDURE:   swe_a4_snap
;PURPOSE:
;  Plots SPEC snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;
;  If housekeeping data exist (almost always the case), then they are displayed 
;  as text in a small separate window.
;
;USAGE:
;  swe_a4_snap
;
;INPUTS:
;
;KEYWORDS:
;       MODEL:         Plot a model of the SPEC data product with the test pulser on in
;                      a separate window.  (An analytic approximation to the test pulser
;                      signal is used.  See 'swe_testpulser_model.pro' for details.)
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       MONITOR:       Put snapshot windows in this monitor.  Monitors are numbered
;                      from 0 to N-1, where N is the number of monitors recognized
;                      by the operating system.  See win.pro for details.
;
;       YRANGE:        Sets raw counts scale range.  Default = [1,3000].
;
;       YLOG:          Sets log scaling.  Default = 1.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-19 14:52:42 -0700 (Thu, 19 Jun 2025) $
; $LastChangedRevision: 33396 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_a4_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_a4_snap.pro
;-
pro swe_a4_snap, model=model, keepwins=keepwins, yrange=yrange, ylog=ylog, monitor=monitor

  @mvn_swe_com
  @putwin_common

  if (size(windex,/type) eq 0) then win, config=0  ; win acts like window

  aflg = 0
  nflg = 0
  dflg = 0

  if (size(A4,/type) ne 8) then begin
    print,"No valid SPEC survey data."
    return
  endif

  if keyword_set(model) then mflg=1 else mflg=0
  if (size(swe_hsk,/type) ne 8) then hflg = 0 else hflg = 1

  if keyword_set(keepwins) then kflg = 0 else kflg = 1

  if (size(yrange,/type) eq 0) then yrange = [1.,50000.]
  if (size(ylog,/type) eq 0) then ylog = 1

  gudsum = ['C0'X, 'DE'X]

; Timing

  npkt = n_elements(a4)
  tspec = dblarr(npkt*16L)
  delta_t = tspec
  for i=0L,(npkt-1L) do begin
    j = i*16L
    delta_t[j:(j+15L)] = swe_dt[a4[i].period]*dindgen(16) + (1.95D/2D)  ; center time offset (sample mode)
    tspec[j:(j+15L)] = a4[i].time + delta_t[j:(j+15L)]
  endfor
  dt_arr0 = 16.*6.  ; 16 anode X 6 defl. (sample mode)

; Put up windows to hold the snapshot plot(s)

  Twin = !d.window

  undefine, mnum
  if (size(monitor,/type) gt 0) then begin
    if (~windex) then win, /config
    mnum = fix(monitor[0])
  endif else begin
    if (size(secondarymon,/type) gt 0) then mnum = secondarymon
  endelse

  win, /free, monitor=mnum, xsize=800, ysize=500, dx=10, dy=10
  Swin = !d.window
  
  if (hflg) then begin
    win, /free, rel=Swin, xsize=225, ysize=545, dx=10
    Hwin = !d.window
  endif

  if (mflg) then begin
    win, /free, rel=Swin, xsize=800, ysize=500, dy=-55
    Mwin = !d.window
  endif

; Get the SPEC data closest the selected time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime2,trange,npoints=1,/silent,button=button

  if (size(trange,/type) eq 2) then begin
    wdelete,Swin
    if (hflg) then wdelete,Hwin
    if (mflg) then wdelete,Mwin
    wset,Twin
    return
  endif
  
  dt = min(abs(tspec - trange[0]), iref)                        ; closest SPEC
  kref = iref/16L                                               ; closest A4 packet
  iref = iref mod 16L                                           ; closest spec within packet
  if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)  ; closest HSK

  x = swe_energy  ; energy channels
  ok = 1

  while (ok) do begin

    spec = a4[kref]
    pmsg = "A4"

    t = tspec[kref*16L + iref]  ; time
    y = spec.data[*,iref]       ; raw counts

    wset, Swin

; Put up a SPEC

    title = string(pmsg, time_string(t), spec.period, spec.npkt, iref, $
            format='(a2,4x,a19,4x,"P ",i1,4x,"NPKT: ",i3,4x,"NSPEC: ",i2)')

    indx = where(y eq 0., count)
    if (count gt 0L) then y[indx] = !values.f_nan

    plot, x, y, xrange=[1,5000], xlog=1, /xsty, yrange=yrange, ylog=ylog, /ysty, xmargin=[10,10], $
                charsize=1.2, xtitle='Energy (eV)', ytitle='Raw Counts', title=title, $
                psym=10

; Put up test pulser model

    if (mflg) then begin
      wset, Mwin

      swe_testpulser_model, result=tpmod
      y = tpmod.a4  ; raw counts

      title = 'Test Pulser Model: ' + pmsg

      plot, x, y, xrange=[1,5000], xlog=1, /xsty, yrange=yrange, ylog=ylog, /ysty, xmargin=[10,10], $
                charsize=1.2, xtitle='Energy (eV)', ytitle='Raw Counts', title=title, $
                psym=10

    endif

; Print out housekeeping in another window

    if (hflg) then begin
      wset, Hwin
      
      csize = 1.4
      x1 = 0.05
      x2 = 0.75
      x3 = x2 - 0.12
      y1 = 0.95 - 0.035*findgen(28)
  
      fmt1 = '(f7.2," V")'
      fmt2 = '(f7.2," C")'
      fmt3 = '(Z2.2)'
      fmt4 = '(i2)'
      
      j = jref
    
      if (swe_hsk[j].CHKSUM[0] eq gudsum[0]) then col0 = 4 else col0 = 6
      if (swe_hsk[j].CHKSUM[1] eq gudsum[1]) then col1 = 4 else col1 = 6
    
      erase
      xyouts,x1,y1[0],/normal,"SWEA Housekeeping",charsize=csize
      xyouts,x1,y1[1],/normal,time_string(swe_hsk[j].time),charsize=csize
      xyouts,x1,y1[3],/normal,"P28V",charsize=csize
      xyouts,x2,y1[3],/normal,string(swe_hsk[j].P28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[4],/normal,"MCP28V",charsize=csize
      xyouts,x2,y1[4],/normal,string(swe_hsk[j].MCP28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[5],/normal,"NR28V",charsize=csize
      xyouts,x2,y1[5],/normal,string(swe_hsk[j].NR28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[6],/normal,"MCPHV",charsize=csize
      xyouts,x2,y1[6],/normal,string(swe_hsk[j].MCPHV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[7],/normal,"NRV",charsize=csize
      xyouts,x2,y1[7],/normal,string(swe_hsk[j].NRV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[9],/normal,"P12V",charsize=csize
      xyouts,x2,y1[9],/normal,string(swe_hsk[j].P12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[10],/normal,"N12V",charsize=csize
      xyouts,x2,y1[10],/normal,string(swe_hsk[j].N12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[11],/normal,"P5AV",charsize=csize
      xyouts,x2,y1[11],/normal,string(swe_hsk[j].P5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[12],/normal,"N5AV",charsize=csize
      xyouts,x2,y1[12],/normal,string(swe_hsk[j].N5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[13],/normal,"P5DV",charsize=csize
      xyouts,x2,y1[13],/normal,string(swe_hsk[j].P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[14],/normal,"P3P3DV",charsize=csize
      xyouts,x2,y1[14],/normal,string(swe_hsk[j].P3P3DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[15],/normal,"P2P5DV",charsize=csize
      xyouts,x2,y1[15],/normal,string(swe_hsk[j].P2P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[17],/normal,"ANALV",charsize=csize
      xyouts,x2,y1[17],/normal,string(swe_hsk[j].ANALV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[18],/normal,"DEF1V",charsize=csize
      xyouts,x2,y1[18],/normal,string(swe_hsk[j].DEF1V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[19],/normal,"DEF2V",charsize=csize
      xyouts,x2,y1[19],/normal,string(swe_hsk[j].DEF2V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[20],/normal,"V0V",charsize=csize
      xyouts,x2,y1[20],/normal,string(swe_hsk[j].V0V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[22],/normal,"ANALT",charsize=csize
      xyouts,x2,y1[22],/normal,string(swe_hsk[j].ANALT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[23],/normal,"LVPST",charsize=csize
      xyouts,x2,y1[23],/normal,string(swe_hsk[j].LVPST,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[24],/normal,"DIGT",charsize=csize
      xyouts,x2,y1[24],/normal,string(swe_hsk[j].DIGT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[26],/normal,"LUT",charsize=csize
;     chksum = swe_hsk[j].CHKSUM[swe_hsk[j].SSCTL]
      if (spec.lut ge 1 and spec.lut le 8) then col0 = 4 else col0 = 6
      xyouts,x2,y1[26],/normal,string(spec.lut,format=fmt4),charsize=csize,align=1.0,color=col0
;     xyouts,x2,y1[26],/normal,string(swe_hsk[j].CHKSUM[1],format=fmt3),charsize=csize,align=1.0,$
;                      color=col1
;     xyouts,x3,y1[26],/normal,string(swe_hsk[j].CHKSUM[0],format=fmt3),charsize=csize,align=1.0,$
;                      color=col0
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (size(trange,/type) eq 5) then begin
      dt = min(abs(tspec - trange[0]), iref)                        ; closest SPEC
      kref = iref/16L                                               ; closest A4 packet
      iref = iref mod 16L                                           ; closest spec within packet
      if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)  ; closest HSK
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
