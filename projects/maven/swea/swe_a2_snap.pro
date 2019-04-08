;+
;PROCEDURE:   swe_a2_snap
;PURPOSE:
;  Plots PAD snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;
;  If housekeeping data exist (almost always the case), then they are displayed 
;  as text in a small separate window.
;
;USAGE:
;  swe_a2_snap
;
;INPUTS:
;
;KEYWORDS:
;       LAYOUT:        A named variable to specify window layouts.
;
;                        0 --> Default.  No fixed window positions.
;                        1 --> Macbook Air with Dell 1920x1200 external screen.
;                        2 --> HP Z220 with twin Dell 1920x1200 screens.
;
;                      This puts up snapshot windows in convenient, non-overlapping
;                      locations, depending on display hardware.
;
;       MODEL:         Plot a model of the PAD data product with the test pulser on in
;                      a separate window.  (An analytic approximation to the test pulser
;                      signal is used.  See 'swe_testpulser_model.pro' for details.)
;
;       DDD:           Calculate a pseudo-PAD data product from the nearest 3D spectrum,
;                      and plot in a separate window.  Better when A0 and A2 have the same
;                      energy grouping and time sampling.  Best when A0 and A2 are at max
;                      rate with no energy grouping.  There is always the limitation that
;                      3D spectra average adjacent anode bins at the highest upward and
;                      downward deflections (80 solid angle bins instead of 96), whereas 
;                      PAD spectra do not.
;
;       ENORM:         Normalize PAD at each energy step.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ZRANGE:        Sets color scale range.  Default = [1,3000].
;
;       ZLOG:          Sets log color scaling.  Default = 1.
;
;       ARCHIVE:       If set, show shapshots of archive data (A3).  Pseudo-PAD data is 
;                      calculated from 3D archive data (A1).
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_a2_snap.pro
;VERSION:   1.0
;LAST MODIFICATION:   07/24/12
;-
pro swe_a2_snap, layout=layout, model=model, ddd=ddd, keepwins=keepwins, zrange=zrange, zlog=zlog, $
                 archive=archive, burst=burst, enorm=enorm

  @mvn_swe_com
  @swe_snap_common
  if (size(snap_index,/type) eq 0) then swe_snap_layout, 0

  Twin = !d.window

  if (keyword_set(archive) or keyword_set(burst)) then aflg = 1 else aflg = 0
  if keyword_set(enorm) then begin
    nflg = 1
    zrange = [0.,1.]
    zlog = 0
  endif else nflg = 0

  if (aflg) then begin
    if (size(A3,/type) ne 8) then begin
      print,"No valid PAD survey data."
      return
    endif
  endif else begin
    if (size(A2,/type) ne 8) then begin
      print,"No valid PAD archive data."
      return
    endif
  endelse

  if keyword_set(model) then mflg=1 else mflg=0
  if keyword_set(ddd)   then dflg=1 else dflg=0
  if (size(swe_hsk,/type) ne 8) then hflg = 0 else hflg = 1

  if keyword_set(keepwins) then kflg = 0 else kflg = 1

  if (size(zrange,/type) eq 0) then zrange = [1.,3000.]
  if (size(zlog,/type) eq 0) then zlog = 1

  gudsum = ['C0'X, 'DE'X]

  if (aflg) then begin
    Baz = a3.Baz      ; MAG azimuth bin (anode containing projection of magnetic field)
    Bel = a3.Bel      ; MAG elevation bin
  endif else begin
    Baz = a2.Baz      ; MAG azimuth bin (anode containing projection of magnetic field)
    Bel = a2.Bel      ; MAG elevation bin
  endelse

; Determine the anode and deflector bins for each PAD bin

  Baz = (Baz + 0.5)*(360./256.)  ; MAG azimuth in SWEA coordinates, deg
  Bel = (Bel - 19.5)*(180./40.)  ; MAG elevation in SWEA coordinates, deg

; Integration time - PAD spectra are always sampled, so the only summing onboard
; is for energy averaging (group parameter)

  delta_t = swe_integ_t * 2D^a2.group

; Calculate anode-deflector index map for 3D solid angles
;   80 solid angle bins --> 96 anode/deflector bins

  dmap = intarr(16,6)
  dmap[*,0] = indgen(16)/2
  for i=1,4 do dmap[*,i] = indgen(16) + 16*i
  dmap[*,5] = indgen(16)/2 + 8

; Put up windows to hold the snapshot plot(s)

  window, /free, xsize=800, ysize=500, xpos=Popt.xpos, ypos=Popt.ypos
  Swin = !d.window
  
  if (hflg) then begin
    window, /free, xsize=225, ysize=545, xpos=Fopt.xpos, ypos=Fopt.ypos
    Hwin = !d.window
  endif

  if (mflg) then begin
    window, /free, xsize=800, ysize=500
    Mwin = !d.window
  endif

  if (dflg) then begin
    window, /free, xsize=800, ysize=500
    Dwin = !d.window
  endif

; Get the PAD closest the selected time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime2,trange,npoints=1,/silent,button=button

  if (size(trange,/type) eq 2) then begin
    wdelete,Swin
    if (hflg) then wdelete,Hwin
    if (mflg) then wdelete,Mwin
    if (dflg) then wdelete,Dwin
    wset,Twin
    return
  endif
  
  if (aflg) then dt = min(abs(a3.time - trange[0]), iref) $            ; closest PAD
            else dt = min(abs(a2.time - trange[0]), iref)
  if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)         ; closest HSK
  if (dflg) then begin
    if (aflg) then dt = min(abs(swe_3d_arc.time - trange[0]), kref) $  ; closest 3D
              else dt = min(abs(swe_3d.time - trange[0]), kref)
  endif
  
  ok = 1

  while (ok) do begin

    if (aflg) then begin
      pad = a3[iref]
      pmsg = "A3"
    endif else begin
      pad = a2[iref]
      pmsg = "A2"
    endelse

    pam = mvn_swe_padmap(pad)      ; pitch angle map
    n_e = swe_ne[pad.group]        ; number of energy channels
    zz = pad.data[*,0:(n_e-1)]     ; raw counts

    if (nflg) then for i=0,(n_e-1) do zz[*,i] = zz[*,i]/max(zz[*,i],/nan)

    x = findgen(18) - 0.5
    y = findgen(n_e + 2) - 0.5
    z = x # y
    z[1:16, 1:n_e] = zz
    z[1:16, 0] = z[1:16, 1]
    z[1:16, n_e+1] = z[1:16, n_e]
    z[0,*] = z[1,*]
    z[17,*] = z[16,*]
    
    wset, Swin

; Put up a PAD

    title = string(pmsg, time_string(pad.time), pad.group, pad.period, Baz[iref], Bel[iref], pad.npkt, $
            format='(a2,4x,a19,4x,"G ",i1,2x,"P ",i1,4x,"Baz = ",f6.1,2x,"Bel = ",f6.1,4x,"NPKT: ",i3)')
    lim = {x_no_interp:1, y_no_interp:1, xrange:[0,16], yrange:[0,n_e], zrange:zrange, $
           xmargin:[10,10], charsize:1.2, xtitle:'Pitch Angle Bin', ytitle:'Energy Bin', $
           ztitle:'Raw Counts', title:title, xstyle:1, ystyle:1, zlog:zlog, xticks:4, xminor:4, $
           yticks:4, yminor:4}

    indx = where(z eq 0., count)
    if (count gt 0L) then z[indx] = !values.f_nan

    specplot,x,y,z,limits=lim

; Put up test pulser model

    if (mflg) then begin
      wset, Mwin

      andx = pam.iaz
      dndx = pam.jel
      sndx = pam.k3d

      swe_testpulser_model,pam={andx:andx,dndx:dndx},group=pad.group,result=tpmod

      z[1:16, 1:n_e] = tpmod.a2[*,0:(n_e-1)]      ; raw counts
      z[1:16, 0] = z[1:16, 1]
      z[1:16, n_e+1] = z[1:16, n_e]
      z[0,*] = z[1,*]
      z[17,*] = z[16,*]

      title = 'Test Pulser Model: ' + pmsg
      lim = {x_no_interp:1, y_no_interp:1, xrange:[0,16], yrange:[0,n_e], zrange:zrange, $
             xmargin:[10,10], charsize:1.2, xtitle:'Pitch Angle Bin', ytitle:'Energy Bin', $
             ztitle:'Raw Counts', title:title, xstyle:1, ystyle:1, zlog:zlog, xticks:4, $
             xminor:4, yticks:4, yminor:4}

      specplot,x,y,z,limits=lim

      binlab = string(dndx,format='(i2)')
      for i=0,15 do xyouts,x[i],y[n_e-1]*0.95,binlab[i],align=0.5,color=0

      binlab = string(andx,format='(i2)')
      for i=0,15 do xyouts,x[i],y[n_e-1]*0.90,binlab[i],align=0.5,color=0

      binlab = string(sndx,format='(i2)')
      for i=0,15 do xyouts,x[i],y[n_e-1]*0.85,binlab[i],align=0.5,color=0

    endif

; Put up 3D to PAD forward calculation

    if (dflg) then begin
      wset, Dwin

;     Extract the anode-deflector bin pairs in the 3D that make up the PAD

      if (aflg) then ddd = swe_3d_arc[kref] else ddd = swe_3d[kref]
      ddd.data[0:15,*] = ddd.data[0:15,*]/2. ; correct for anode averaging

      pad_fc = fltarr(16,n_e)

      andx = pam.iaz
      dndx = pam.jel
      sndx = pam.k3d

      for j=0,(n_e-1) do begin
        ddat = ddd.data[dmap[andx,dndx],*]
        case (pad.group - ddd.group) of      ; sample or sum, depending on group parameters
          -2 : pad_fc[*,j] = ddat[*,j/4]/4.
          -1 : pad_fc[*,j] = ddat[*,j/2]/2.
           0 : pad_fc[*,j] = ddat[*,j]
           1 : pad_fc[*,j] = total(ddat[*,(j*2):(j*2 + 1)],2)
           2 : pad_fc[*,j] = total(ddat[*,(j*4):(j*4 + 3)],2)
        endcase
      endfor

      title = '3D to PAD Forward Calculation'
      lim = {x_no_interp:1, y_no_interp:1, xrange:[0,16], yrange:[0,n_e], zrange:zrange, $
             xmargin:[10,10], charsize:1.2, xtitle:'Pitch Angle Bin', ytitle:'Energy Bin', $
             ztitle:'Raw Counts', title:title, xstyle:1, ystyle:1, zlog:zlog, xticks:4, $
             xminor:4, yticks:4, yminor:4}

      zz = pad_fc
      indx = where(zz eq 0., count)
      if (count gt 0L) then zz[indx] = !values.f_nan
    
      if (nflg) then for i=0,(n_e-1) do zz[*,i] = zz[*,i]/max(zz[*,i],/nan)

      z[1:16, 1:n_e] = zz[*,0:(n_e-1)]      ; raw counts
      z[1:16, 0] = z[1:16, 1]
      z[1:16, n_e+1] = z[1:16, n_e]
      z[0,*] = z[1,*]
      z[17,*] = z[16,*]

      specplot,x,y,z,limits=lim

      binlab = string(dndx,format='(i2)')
      for i=0,15 do xyouts,x[i],y[n_e-1]*0.95,binlab[i],align=0.5,color=0

      binlab = string(andx,format='(i2)')
      for i=0,15 do xyouts,x[i],y[n_e-1]*0.90,binlab[i],align=0.5,color=0

      binlab = string(sndx,format='(i2)')
      for i=0,15 do xyouts,x[i],y[n_e-1]*0.85,binlab[i],align=0.5,color=0

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
      if (pad.lut ge 1 and pad.lut le 8) then col0 = 4 else col0 = 6
      xyouts,x2,y1[26],/normal,string(pad.lut,format=fmt4),charsize=csize,align=1.0,color=col0
;     xyouts,x2,y1[26],/normal,string(swe_hsk[j].CHKSUM[1],format=fmt3),charsize=csize,align=1.0,$
;                      color=col1
;     xyouts,x3,y1[26],/normal,string(swe_hsk[j].CHKSUM[0],format=fmt3),charsize=csize,align=1.0,$
;                      color=col0
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (size(trange,/type) eq 5) then begin
      if (aflg) then dt = min(abs(a3.time - trange[0]), iref) $
                else dt = min(abs(a2.time - trange[0]), iref)
      if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)
      if (dflg) then begin
        if (aflg) then dt = min(abs(swe_3d_arc.time - trange[0]), kref) $
                  else dt = min(abs(swe_3d.time - trange[0]), kref)
      endif
      ok = 1
    endif else ok = 0

  endwhile

  if (kflg) then begin
    wdelete, Swin
    if (hflg) then wdelete, Hwin
    if (mflg) then wdelete, Mwin
    if (dflg) then wdelete, Dwin
  endif

  wset, Twin

  return

end
