;+
;PROCEDURE:   swe_hsk_snap
;PURPOSE:
;  Plots housekeeping snapshots for times selected with the cursor in a tplot
;  window.
;
;USAGE:
;  swe_hsk_snap, hsk=hsk
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_hsk_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-25-12
;-
pro swe_hsk_snap

  @mvn_swe_com

  if (size(swe_hsk,/type) ne 8) then begin
    print,"No valid HSK structure in common block."
    return
  endif
  
  hsk = swe_hsk
    
  Twin = !d.window
  
  gudsum = ['C0'X, 'DE'X]

; Text size and positioning (normalized coordinates)

  csize = 1.4
  x1 = 0.05
  x2 = 0.75
  x3 = x2 - 0.12
  y1 = 0.95 - 0.035*findgen(28)
  
  fmt1 = '(f7.2," V")'
  fmt2 = '(f7.2," C")'
  fmt3 = '(Z2.2)'

; Get the 3D spectrum closest the selected time

  print,'Use button 1 to select time; button 3 to quit.'

  window, 26, xsize=225, ysize=545
  Hwin = !d.window

  wset,Twin
  ctime2,trange,npoints=1,/silent,button=button

  if (size(trange,/type) eq 2) then begin
    wdelete,Hwin
    wset,Twin
    return
  endif
  
  dt = min(abs(hsk.time - trange[0]), j)
    
  ok = 1

  while (ok) do begin

; Print out housekeeping in a window

    wset, Hwin
    
    if (hsk[j].CHKSUM[0] eq gudsum[0]) then col0 = 4 else col0 = 6
    if (hsk[j].CHKSUM[1] eq gudsum[1]) then col1 = 4 else col1 = 6
    
    erase
    xyouts,x1,y1[0],/normal,"SWEA Housekeeping",charsize=csize
    xyouts,x1,y1[1],/normal,time_string(hsk[j].time),charsize=csize
    xyouts,x1,y1[3],/normal,"P28V",charsize=csize
    xyouts,x2,y1[3],/normal,string(hsk[j].P28V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[4],/normal,"MCP28V",charsize=csize
    xyouts,x2,y1[4],/normal,string(hsk[j].MCP28V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[5],/normal,"NR28V",charsize=csize
    xyouts,x2,y1[5],/normal,string(hsk[j].NR28V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[6],/normal,"MCPHV",charsize=csize
    xyouts,x2,y1[6],/normal,string(hsk[j].MCPHV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[7],/normal,"NRV",charsize=csize
    xyouts,x2,y1[7],/normal,string(hsk[j].NRV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[9],/normal,"P12V",charsize=csize
    xyouts,x2,y1[9],/normal,string(hsk[j].P12V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[10],/normal,"N12V",charsize=csize
    xyouts,x2,y1[10],/normal,string(hsk[j].N12V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[11],/normal,"P5AV",charsize=csize
    xyouts,x2,y1[11],/normal,string(hsk[j].P5AV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[12],/normal,"N5AV",charsize=csize
    xyouts,x2,y1[12],/normal,string(hsk[j].N5AV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[13],/normal,"P5DV",charsize=csize
    xyouts,x2,y1[13],/normal,string(hsk[j].P5DV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[14],/normal,"P3P3DV",charsize=csize
    xyouts,x2,y1[14],/normal,string(hsk[j].P3P3DV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[15],/normal,"P2P5DV",charsize=csize
    xyouts,x2,y1[15],/normal,string(hsk[j].P2P5DV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[17],/normal,"ANALV",charsize=csize
    xyouts,x2,y1[17],/normal,string(hsk[j].ANALV,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[18],/normal,"DEF1V",charsize=csize
    xyouts,x2,y1[18],/normal,string(hsk[j].DEF1V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[19],/normal,"DEF2V",charsize=csize
    xyouts,x2,y1[19],/normal,string(hsk[j].DEF2V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[20],/normal,"V0V",charsize=csize
    xyouts,x2,y1[20],/normal,string(hsk[j].V0V,format=fmt1),charsize=csize,align=1.0
    xyouts,x1,y1[22],/normal,"ANALT",charsize=csize
    xyouts,x2,y1[22],/normal,string(hsk[j].ANALT,format=fmt2),charsize=csize,align=1.0
    xyouts,x1,y1[23],/normal,"LVPST",charsize=csize
    xyouts,x2,y1[23],/normal,string(hsk[j].LVPST,format=fmt2),charsize=csize,align=1.0
    xyouts,x1,y1[24],/normal,"DIGT",charsize=csize
    xyouts,x2,y1[24],/normal,string(hsk[j].DIGT,format=fmt2),charsize=csize,align=1.0
    xyouts,x1,y1[26],/normal,"CHKSUM",charsize=csize
    xyouts,x2,y1[26],/normal,string(hsk[j].CHKSUM[1],format=fmt3),charsize=csize,align=1.0,$
                     color=col1
    xyouts,x3,y1[26],/normal,string(hsk[j].CHKSUM[0],format=fmt3),charsize=csize,align=1.0,$
                     color=col0

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (size(trange,/type) eq 5) then begin
      dt = min(abs(hsk.time - trange[0]), j)
      ok = 1
    endif else ok = 0

  endwhile

  wdelete, Hwin
  wset, Twin

  return

end
