;+
;PROCEDURE:   swe_3d_snap
;PURPOSE:
;  Plots 3D snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;  This version uses plot3d and spec3d on packaged 3D data.
;
;USAGE:
;  swe_3d_snap
;
;INPUTS:
;
;KEYWORDS:
;       EBINS:         Energy bins to plot (passed to plot3d).  Default = 16 evenly
;                      spaced bins.
;
;       CENTER:        Longitude and latitude of the center [lon, lat].
;
;       MAP:           Mapping projection.  See plot3d_options for details.
;
;       ZLOG:          If set, use a log color scale.
;
;       ZRANGE:        Range for color bar.
;
;       SPEC:          Plot energy spectra using spec3d.
;
;       POT:           Plot the spacecraft potential on the SPEC plots.
;
;       UNITS:         Units for the spec3d.
;
;       ENERGY:        One or more energies to plot.  Overrides EBINS.
;
;       ESUM:          Sum over the energies or channels specified by EBINS or
;                      ENERGY.
;
;       PADMAG:        If set, use the MAG angles in the PAD data to show the 
;                      magnetic field direction.
;
;       DDD:           Named variable to hold a 3D structure at the last time
;                      selected.  If this is a 3D structure, then plot a snapshot
;                      of this instead of using the tplot window to select a time.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       TSMO:          Smoothing interval, in seconds.  Default is no smoothing.
;
;       SMO:           Set smoothing in energy and angle.  Since there are only six
;                      theta bins, smoothing in that dimension is not recommended.
;
;                        smo = [n_energy, n_phi, n_theta]  ; default = [1,1,1]
;
;                      This routine takes into account the 360-0 degree wrap when 
;                      smoothing.
;
;       SYMDIR:        Calculate and overplot the symmetry direction of the 
;                      electron distribution.
;
;       SYMENERGY:     Energy at which to calculate the symmetry direction.  Should
;                      be > 100 eV.  Using the SMO keyword also helps.
;
;       POWER:         Weighting function is proportional to eflux^power.  Higher
;                      powers emphasize the peak of the distribution; lower powers
;                      give more weight to surrounding cells.  Default = 2.
;
;       SYMDIAG:       Plot symmetry weighting function in separate window.
;
;       SUNDIR:        Plot the direction of the Sun in SWEA coordinates.
;
;       LABEL:         If set, label the 3D angle bins.
;
;       LABSIZE:       Character size for the labels.  Default = 1.
;
;       WSCALE:        Window size scale factor.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       MONITOR:       Put snapshot windows in this monitor.  Monitors are numbered
;                      from 0 to N-1, where N is the number of monitors recognized
;                      by the operating system.  See win.pro for details.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
;       BURST:         Synonym for ARCHIVE.
;
;       MASK_SC:       Mask solid angle bins that are blocked by the spacecraft.
;
;       PLOT_SC:       Draw an outline of the spacecraft as seen from SWEA on 
;                      the 3D plot.
;
;       PLOT_FOV:      Replace the data with a "chess board" pattern to show the
;                      field of view.  FOV masking, if any, will be shown.
;
;       PADMAP:        Show the pitch angle map for the current spectrum.
;                      Boundaries for the 3D solid angle bins are shown.  Bins 
;                      blocked by the spacecraft are marked with a yellow 'X'.
;
;       TRANGE:        Plot snapshot for this time range.  Can be in any
;                      format accepted by time_double.  (This disables the
;                      interactive time range selection.)
;
;       COLOR_TABLE:  Use this color table for all plots.
;
;       REVERSE_COLOR_TABLE:  Reverse the color table (except for fixed colors).
;
;       QLEVEL:       Minimum quality level to plot (0-2, default=0):
;                        2B = good
;                        1B = uncertain
;                        0B = affected by low-energy anomaly
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-07-04 13:40:37 -0700 (Tue, 04 Jul 2023) $
; $LastChangedRevision: 31935 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_3d_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_3d_snap, spec=spec, keepwins=keepwins, archive=archive, ebins=ebins, $
                 center=center, units=units, ddd=ddd, sum=sum, padmag=padmag, $
                 energy=energy, label=label, smo=smo, symdir=symdir, sundir=sundir, $
                 symenergy=symenergy, symdiag=symdiag, power=power, map=map, $
                 abins=abins, dbins=dbins, obins=obins, mask_sc=mask_sc, burst=burst, $
                 plot_sc=plot_sc, padmap=padmap, pot=pot, plot_fov=plot_fov, $
                 labsize=labsize, trange=trange2, tsmo=tsmo, wscale=wscale, zlog=zlog, $
                 zrange=zrange, monitor=monitor, esum=esum, color_table=color_table, $
                 reverse_color_table=reverse_color_table, line_colors=line_colors, $
                 qlevel=qlevel

  @mvn_swe_com
  @putwin_common

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  csize1 = 1.2
  csize2 = 1.4
  tiny = 1.e-31

  bad3d = swe_3d_struct
  bad3d.energy = swe_swp[*,0] # replicate(1.,96)
  bad3d.data = tiny
  bad3d.quality = 255B

  if (size(windex,/type) eq 0) then win, config=0  ; win acts like window

; Load any keyword defaults

  swe_snap_options, get=key, /silent
  ktag = tag_names(key)
  tlist = ['SPEC','KEEPWINS','ARCHIVE','EBINS','CENTER','UNITS','SUM', $
           'PADMAG','ENERGY','LABEL','SMO','SYMDIR','SUNDIR','SYMENERGY', $
           'SYMDIAG','POWER','MAP','ABINS','DBINS','OBINS','MASK_SC','BURST', $
           'PLOT_SC','PADMAP','POT','PLOT_FOV','LABSIZE','TRANGE2','TSMO', $
           'WSCALE','ZLOG','ZRANGE','MONITOR','ESUM','COLOR_TABLE', $
           'REVERSE_COLOR_TABLE','QLEVEL']
  for j=0,(n_elements(ktag)-1) do begin
    i = strmatch(tlist, ktag[j]+'*', /fold)
    case (total(i)) of
        0  : ; keyword not recognized -> do nothing
        1  : begin
               kname = (tlist[where(i eq 1)])[0]
               ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
               if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
             end
      else : print, "Keyword ambiguous: ", ktag[j]
    endcase
  endfor

; Process keywords

  if keyword_set(archive) then aflg = 1 else aflg = 0
  if keyword_set(burst) then aflg = 1

  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  if keyword_set(plot_sc) then plot_sc = 1 else plot_sc = 0
  if keyword_set(plot_fov) then fov = 1 else fov = 0
  if not keyword_set(labsize) then labsize = 1.
  if (size(wscale,/type) eq 0) then wscale = 1.

  omask = replicate(1.,96,2)
  indx = where(obins eq 0B, count)
  if (count gt 0L) then omask[indx] = !values.f_nan
  omask = reform(replicate(1.,64) # reform(omask, 96*2), 64, 96, 2)

  if (size(units,/type) ne 7) then units = 'crate'
  if (size(map,/type) ne 7) then map = 'ait'
  if not keyword_set(zrange) then zrange = [0.,0.]
  plot3d_options, map=map
  
  case strupcase(units) of
    'COUNTS' : yrange = [1.,1.e5]
    'RATE'   : yrange = [1.,1.e5]
    'CRATE'  : yrange = [1.,1.e6]
    'FLUX'   : yrange = [1.,1.e8]
    'EFLUX'  : yrange = [1.e4,1.e9]
    'DF'     : yrange = [1.e-19,1.e-8]
    else     : yrange = [0.,0.]
  endcase

  case n_elements(center) of
    0 : begin
          lon = 180.
          lat = 0.
        end
    1 : begin
          lon = center[0]
          lat = 0.
        end
    else : begin
             lon = center[0]
             lat = center[1]
           end
  endcase

  if keyword_set(spec) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if (keyword_set(padmag) and (size(a2,/type) eq 8)) then pflg = 1 else pflg = 0
  if (size(ebins,/type) eq 0) then ebins = reverse(4*indgen(16))
  if not keyword_set(symenergy) then symenergy = 130.
  if not keyword_set(power) then power = 3.
  if keyword_set(symdiag) then dflg = 1 else dflg = 0
  if keyword_set(padmap) then dopam = 1 else dopam = 0
  esum = keyword_set(esum)
  qlevel = (n_elements(qlevel) gt 0L) ? byte(qlevel[0]) : 0B

  case n_elements(trange2) of
       0 : tflg = 0
       1 : begin
             trange2 = time_double(trange2)
             tflg = 1
             kflg = 0
           end
    else : begin
             trange2 = minmax(time_double(trange2))
             tflg = 1
             kflg = 0
           end
  endcase

  if (n_elements(smo) gt 0) then begin
    nsmo = [1,1,1]
    for i=0,(n_elements(smo)-1) do nsmo[i] = round(smo[i])
    dosmo = 1
  endif else dosmo = 0

  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse

  if keyword_set(tsmo) then begin
    npts = 1
    doall = 1
    dotsmo = 1
    dtsmo = double(tsmo)/2D
  endif else dotsmo = 0

  if keyword_set(sundir) then begin
    t = [0D]
    the = [0.]
    phi = [0.]
    get_data,'Sun_MAVEN_SWEA_STOW',data=sun,index=i
    if (i gt 0) then begin
      t = [temporary(t), sun.x]
      xyz_to_polar, sun, theta=th, phi=ph, /ph_0_360
      the = [temporary(the), th.y]
      phi = [temporary(phi), ph.y]
    endif
    get_data,'Sun_MAVEN_SWEA',data=sun,index=i
    if (i gt 0) then begin
      t = [temporary(t), sun.x]
      xyz_to_polar, sun, theta=th, phi=ph, /ph_0_360
      the = [temporary(the), th.y]
      phi = [temporary(phi), ph.y]
    endif
    if (n_elements(t) gt 1) then begin
      sun = {time:t[1L:*], the:the[1L:*], phi:phi[1L:*]}
    endif else sundir = 0
  endif

; Put up snapshot window(s)

  Twin = !d.window

  undefine, mnum
  if (size(monitor,/type) gt 0) then begin
    if (~windex) then win, /config
    mnum = fix(monitor[0])
  endif else begin
    if (size(secondarymon,/type) gt 0) then mnum = secondarymon
  endelse

  win, /free, monitor=mnum, xsize=800, ysize=600, dx=10, dy=10, scale=wscale
  Dwin = !d.window

  if (sflg) then begin
    win, /free, xsize=450, ysize=600, rel=Dwin, dx=10, scale=wscale
    Swin = !d.window
  endif
  
  if (dflg) then begin
    win, /free, xsize=450, ysize=600, rel=!d.window, dx=10, scale=wscale
    Fwin = !d.window
  endif
  
  if (dopam) then begin
    win, /free, monitor=mnum, xsize=600, ysize=450, dx=10, dy=-10, scale=wscale
    Pwin = !d.window
  endif

; Use a better color table for 3D plots

  ctab = keyword_set(color_table) ? fix(color_table[0]) : 34
  crev = keyword_set(reverse_color_table)
  initct, ctab, reverse=crev, previous_ct=pct, previous_rev=prev

  lines = -1 & plines = -1
  if keyword_set(line_colors) then begin
    lines = line_colors
    line_colors, lines, previous_lines=plines
  endif

  cols = get_colors()
  if (cols.color_table ge 1000) then cols = get_qualcolors()
  cbot = (cols.bottom_c ge 0) ? cols.bottom_c : 7
  ctop = (cols.top_c ge 0) ? cols.top_c : 254

  got3d = 0
  if (size(ddd,/type) eq 8) then begin
    str_element, ddd[0], 'apid', apid, success=ok
    if (ok) then if ((apid eq 'A0'X) or (apid eq 'A1'X)) then got3d = 1
  endif
  if (got3d) then kflg = 0  ; don't delete windows on exit for this mode

; Select the first time, then get the 3D spectrum closest that time

  if (~got3d) then begin
    print,'Use button 1 to select time; button 3 to quit.'

    wset,Twin
    if (~tflg) then begin
      ctime,trange,npoints=npts,/silent
      if (npts gt 1) then cursor,cx,cy,/norm,/up  ; Make sure mouse button released
    endif else trange = trange2

    if (size(trange,/type) eq 2) then begin  ; Abort before first time select.
      wdelete,Dwin                           ; Don't keep empty windows.
      if (sflg) then wdelete,Swin
      if (dflg) then wdelete,Fwin
      if (dopam) then wdelete,Pwin
      wset,Twin
      if ((ctab ne pct) or (crev ne prev)) then initct, pct, reverse=prev
      if (max(abs(lines - plines)) gt 0) then line_colors, plines
      return
    endif
  endif

  ok = 1

  while (ok) do begin

    if (dotsmo) then begin
      tmin = min(trange, max=tmax)
      trange = [(tmin - dtsmo), (tmax + dtsmo)]
    endif

; Put up a 3D spectrogram
 
    wset, Dwin

    if (~got3d) then begin
      ddd = mvn_swe_get3d(trange,archive=aflg,all=doall,/sum,units=units,qlevel=qlevel)
      if (size(ddd,/type) ne 8) then begin
        ddd = bad3d
        ddd.time = mean(trange)
        ddd.end_time = max(trange)
      endif
    endif

    if (size(ddd,/type) eq 8) then begin
      data = ddd.data
      if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0

      if keyword_set(energy) then begin
        n_e = n_elements(energy)
        ebins = intarr(n_e)
        for k=0,(n_e-1) do begin
          de = min(abs(ddd.energy[*,0] - energy[k]), j)
          ebins[k] = j
        endfor
      endif

      if (esum) then begin
        dsum = total(data[ebins,*,*],1)
        ebins = max(ebins)
        data[ebins,*,*] = dsum
      endif

      nbins = float(n_elements(ebins))

      if (dosmo) then begin
        ddat = reform(data*omask[*,*,boom],64,16,6)
        dat = fltarr(64,32,6)
        dat[*,8:23,*] = ddat
        dat[*,0:7,*] = ddat[*,8:15,*]
        dat[*,24:31,*] = ddat[*,0:7,*]
        dats = smooth(dat,nsmo,/nan)
        ddd.data = reform(dats[*,8:23,*],64,96)
      endif else ddd.data = ddd.data*omask[*,*,boom]
      
      if (fov) then begin
        checker = fltarr(16)
        checker[2*indgen(8)] = 4.
        checker[2*indgen(8) + 1] = 6.
        pattern = fltarr(96)
        for i=0,4,2 do pattern[(i*16):(i*16 + 15)] = checker
        for i=1,5,2 do pattern[(i*16):(i*16 + 15)] = reverse(checker)
        for i=0,63 do ddd.data[i,*] = pattern
        ddd.data = ddd.data*omask[*,*,boom]
        ddd.dt_arr[*,*] = 1.
        ddd.eff[*,*] = 1.
        ddd.gf[*,*] = 1.
        ddd.dtc[*,*] = 1.
        ddd.bkg[*,*] = 0.
        ddd.var[*,*] = 0.
        ddd.theta = replicate(1.,64) # reform(ddd.theta[min(ebins),*])
        ddd.dtheta = replicate(1.,64) # reform(ddd.dtheta[min(ebins),*])
      endif

      delta_t = ddd.end_time - ddd.time
      str_element, ddd, 'trange', [(ddd.time - delta_t), ddd.end_time], /add
      if (ddd.quality eq 255B) then begin
        tsp = time_string(trange)
        if (n_elements(tsp) gt 1) then tsp = tsp[0] + ' - ' + strmid(tsp[1],11)
        plot,[-1],[-1],xrange=[0,1],yrange=[0,1],xsty=5,ysty=5
        xyouts,0.5,0.4,tsp,/norm,align=0.5,charsize=csize2*1.5
        xyouts,0.5,0.5,"NO VALID DATA",/norm,align=0.5,charsize=csize2*1.5
      endif else plot3d_new, ddd, lat, lon, ebins=ebins, zrange=zrange, log=keyword_set(zlog)

      if (pflg) then begin
        dt = min(abs(a2.time - mean(ddd.time)),j)
        mvn_swe_magdir, a2[j].time, a2[j].Baz, a2[j].Bel, Baz, Bel
        Baz = Baz*!radeg
        Bel = Bel*!radeg
        if (abs(Bel) gt 61.) then col=255 else col=0
        oplot,[Baz],[Bel],psym=1,color=col,thick=2,symsize=1.7
        oplot,[Baz+180.],[-Bel],psym=4,color=col,thick=2,symsize=1.7
      endif
      
      if (ddd.maglev gt 0B) then begin
        magf = ddd.magf
        Bamp = sqrt(total(magf*magf))
        Baz = atan(magf[1],magf[0])*!radeg
        Bel = asin(magf[2]/Bamp)*!radeg
        if (abs(Bel) gt 61.) then col=255 else col=0
        oplot,[Baz],[Bel],psym=1,color=col,thick=2,symsize=1.7
        oplot,[Baz+180.],[-Bel],psym=4,color=col,thick=2,symsize=1.7
      endif

      if keyword_set(label) then begin
        lab=strcompress(indgen(ddd.nbins),/rem)
        xyouts,reform(ddd.phi[63,*]),reform(ddd.theta[63,*]),lab,align=0.5,$
               charsize=labsize
      endif
      
      if keyword_set(sundir) then begin
        dt = min(abs(sun.time - mean(ddd.time)),j)
        Saz = sun.phi[j]
        Sel = sun.the[j]
        if (abs(Sel) gt 61.) then col=!p.color else col=!p.color
        oplot,[Saz],[Sel],psym=8,color=5,thick=2,symsize=2.0
;        Saz = (Saz + 180.) mod 360.
;        Sel = -Sel
;        oplot,[Saz],[Sel],psym=7,color=col,thick=2,symsize=1.2
      endif
      
      if keyword_set(symdir) then begin
        de = min(abs(ddd.energy[*,0] - symenergy), sbin)
        f = reform(data[sbin,*],16,6)
        phi = (reform(ddd.phi[sbin,*],16,6))[*,0]
        the = (reform(ddd.theta[sbin,*],16,6))[0,*]
        
        fmax = max(f,k)
        k = k mod 16

        faz = total((f/fmax)^power,2)
        faz = (faz - mean(faz)) > 0.
        k = (k + 9) mod 16
        az = shift(phi,-k)
        if (k gt 0) then az[16-k:*] = az[16-k:*] + 360.
        faz = shift(faz,-k)
        m = indgen(9) + 3
        az0 = (total(az[m]*faz[m])/total(faz[m]) + 360.) mod 360.

        el = reform(the,6)
        f = shift(f,-k,0)
        fel = total((f[m,*]/fmax)^power,1)
        fel = (fel - mean(fel)) > 0.
        el0 = total(el*fel)/total(fel)

        oplot,[az0],[el0],psym=5,color=0,thick=2,symsize=1.2
        
        if (dflg) then begin
          wset, Fwin
          !p.multi = [0,1,2]
          x = az[m]
          if (min(x) gt 270.) then x = x - 360.
          plot,x,faz[m],xtitle='Azimuth',title='Symmetry Function',psym=10
          oplot,[az0,az0],[0.,2.*max(faz[m])], line=2, color=6
          oplot,[az0,az0]-360.,[0.,2.*max(faz[m])], line=2, color=6
          oplot,[az0,az0]+360.,[0.,2.*max(faz[m])], line=2, color=6

          plot,el,fel,xtitle='Elevation',psym=10
          if (min(ddd.time) lt t_mtx[2]) then j = 2 else j = 0
          oplot,[el[j],el[j]],[0.,2.*max(fel)], line=2, color=4
          oplot,[el[5],el[5]],[0.,2.*max(fel)], line=2, color=4
          oplot,[el0,el0],[0.,2.*max(fel)], line=2, color=6
          !p.multi = 0
        endif
      endif
      
      if (plot_sc) then  mvn_spc_fov_blockage, clr=200, /swea, /invert_phi, /invert_theta

      if (dopam) then begin
        wset, Pwin

        Bamp = sqrt(total(ddd.magf^2.))
        Baz = atan(ddd.magf[1],ddd.magf[0])
        Bel = asin(ddd.magf[2]/Bamp)
        if (Baz lt 0.) then Baz += 2.*!pi

        Naz = 256
        daz = 2.*!pi/float(Naz)
        az = daz*findgen(Naz + 1)

        Nel = 128
        elmin = (swe_el[0,63,ddd.group] - 0.5*swe_del[0,63,ddd.group])*!dtor
        elmax = (swe_el[5,63,ddd.group] + 0.5*swe_del[5,63,ddd.group])*!dtor
        del = (elmax - elmin)/float(Nel)
        el = elmin + del*findgen(Nel + 1)

        azm = az # replicate(1.,Nel+1)
        elm = replicate(1.,Naz+1) # el
        pam = acos(cos(azm - Baz)*cos(elm)*cos(Bel) + sin(elm)*sin(Bel))

        contour,pam*!radeg,az*!radeg,el*!radeg,levels=10*indgen(19),c_labels=replicate(1,19),$
                xrange=[0,360],xstyle=9,xticks=4,xminor=3,yrange=[-90,90],ystyle=9,$
                yticks=6,yminor=3,xmargin=[10,10],ymargin=[6,6],$
                xtitle='SWEA Azimuth',ytitle='SWEA Elevation',charsize=csize2,$
                c_charsize=csize1

        axis,/yaxis,yrange=[1,181],charsize=csize2,ystyle=1,ytitle='Elevation Bin',$
                 yticks=6,yminor=0,yticklen=-0.00001,ytickv=(swe_el[*,63,0] + 91.),$
                 ytickname=string(indgen(6),format='(" ",i1," ")'),color=4

        axis,/xaxis,xrange=[1,361],charsize=csize2,xstyle=1,xtitle='Azimuth Bin',$
                 xticks=16,xminor=0,xticklen=-0.00001,xtickv=(swe_az + 1.),$
                 xtickname=string(indgen(16),format='(i2)'),color=4

        az = 22.5*findgen(17)
        for i=1,15 do oplot,[az[i],az[i]],[elmin,elmax]*!radeg,color=4,linestyle=1
        el = [swe_el[*,63,ddd.group] - (swe_del[*,63,ddd.group]/2.), elmax*!radeg]
        for i=0,6 do oplot,[0,360],[el[i],el[i]],color=4,linestyle=1

        kb = where(swe_sc_mask[*,boom] eq 0, count)
        ib = kb mod 16
        jb = kb / 16
        for k=0,(count-1) do begin
          i = ib[k]
          j = jb[k]
          oplot,[mean(az[i:i+1])],[mean(el[j:j+1])],psym=7,color=5
        endfor

        az = Baz*!radeg
        el = Bel*!radeg
        oplot,[az],[el],psym=1,symsize=2
        if (az gt 180.) then az -= 180. else az += 180.
        el = -el
        oplot,[az],[el],psym=4,symsize=2
      endif

      if (sflg) then begin
        wset, Swin
        bins = where(obins eq 1B, count)
        spec3d, ddd, units=units, limits={yrange:yrange, ystyle:1, ylog:1, psym:10},bins=bins
        if keyword_set(pot) then oplot, [ddd.sc_pot, ddd.sc_pot], yrange, line=1, color=6
      endif
    endif

; Get the next button press

    if (~got3d and ~tflg) then begin
      wset,Twin
      ctime,trange,npoints=npts,/silent
      if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
      if (size(trange,/type) eq 5) then ok = 1 else ok = 0
    endif else ok = 0

  endwhile

; Restore the previous color table

  if ((ctab ne pct) or (crev ne prev)) then initct, pct, reverse=prev
  if (max(abs(lines - plines)) gt 0) then line_colors, plines

  if (kflg) then begin
    wdelete, Dwin
    if (sflg) then wdelete, Swin
    if (dflg) then wdelete, Fwin
    if (dopam) then wdelete, Pwin
  endif

  wset, Twin

  return

end
