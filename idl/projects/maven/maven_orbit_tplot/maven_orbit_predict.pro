;+
;PROCEDURE:   maven_orbit_predict
;PURPOSE:
;  Specialized version of maven_orbit_tplot that makes predict ephemeris
;  plots suitable for short- and long-term planning, including identification
;  of Fly-Y/Z calibration opportunities, conjunction periods, and dust storm 
;  seasons.
;
;  Warnings:
;
;   (1) This routine will reset timespan to cover the specified extended
;       ephemeris, overwriting any existing timespan.  This will affect any
;       routines that use timespan for determining what data to process.
;
;   (2) This routine can reset the SPICE loadlist.
;
;   (3) The extended ephemerides span about a decade, with peak RAM consumption
;       of ~6 GB.  Most modern computers have at least 16 GB of RAM, but this is
;       something to be aware of.
;
;  It's best to use this routine in its own IDL session.
;
;USAGE:
;  maven_orbit_predict, extended=1, eph=eph
;
;INPUTS:
;
;KEYWORDS:
;       EXTENDED: If set to a value from 1 to 8, loads one of eight long-term predict
;                 ephemerides.  Most have a density scale factor (DSF) of 2.5, which
;                 is a weighted average over several Mars years.  They differ in the
;                 number and timing of apoapsis, periapsis, and inclination maneuvers
;                 (arm, prm, inc) and total fuel usage (meters per second, or ms).
;                 The date when the ephemeris was generated is given at the end of 
;                 the filename (YYMMDD).  More recent dates better reflect actual 
;                 past perfomance and current mission goals.  When in doubt, use the
;                 most recent.
;
;                   0 : use timerange() to load short-term predicts
;                   1 : trj_orb_250407-350702_dsf2.0_prm_4.4ms_250402.bsp
;                   2 : trj_orb_240821-331231_dsf2.0_prm_4.4ms_240820.bsp
;                   3 : trj_orb_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.bsp
;                   4 : trj_orb_230322-320101_dsf1.5-prm-3.5ms_230320.bsp
;                   5 : trj_orb_220810-320101_dsf2.5_arm_prm_19.2ms_220802.bsp
;                   6 : trj_orb_220101-320101_dsf2.5_arms_18ms_210930.bsp
;                   7 : trj_orb_220101-320101_dsf2.5_arm_prm_13.5ms_210908.bsp
;                   8 : trj_orb_210326-301230_dsf2.5-otm0.4-arms-prm-13.9ms_210330.bsp
;
;                 Default = 1 (most recent long-term predict).
;
;                 You can set this keyword to zero, so that none of the extended predicts
;                 is used.  In that case, the routine will attempt to load ephemeris data
;                 based on the value of timerange().  This can be used to load the short-
;                 term predict ephemeris, which provides a more accurate estimate of how
;                 the orbit will evolve over the next 3-4 months.
;
;       EPH:      Named variable to hold the MSO and GEO state vectors along with 
;                 some calculated values.
;
;       LINE_COLORS: Line color scheme for altitude panel.  This can be an integer [0-10]
;                 to select one of 11 pre-defined line color schemes.  It can also be array
;                 of 24 (3x8) RGB values: [[R,G,B], [R,G,B], ...] that defines the first 7
;                 colors (0-6) and the last (255).  For details, see line_colors.pro and 
;                 color_table_crib.pro.  Default = 5.
;
;       COLORS:   An array with up to 3 elements to specify color indices for the
;                 plasma regimes: [sheath, pileup, wake].  Defaults are:
;
;                   regime       index       LINE_COLORS=5
;                   -----------------------------------------
;                   sheath         4         green
;                   pileup         5         orange
;                   wake           2         blue
;                   -----------------------------------------
;
;                 The colors you get depend on your line color scheme.  The solar wind
;                 is always displayed in the foreground color (usually white or black).
;
;                 Note: Setting LINE_COLORS and COLORS here is local to this routine and
;                       affects only the altitude panel.
;
;       PDS:      Plot vertical dashed lines separating the PDS release dates.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-25 09:53:09 -0700 (Sun, 25 May 2025) $
; $LastChangedRevision: 33337 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_predict.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro maven_orbit_predict, extended=extended, eph=eph, line_colors=lcol, colors=col, pds=pds

  ext = n_elements(extended) ? fix(extended[0]) : 1
  if (ext eq 0) then begin
    tplot_options, get=topt
    if (topt.trange_full[1] lt 0.1D) then begin
      print,"You must specify a time range."
      return
    endif
  endif

  if keyword_set(pds) then begin
    nmon = 100  ; extends to 2040-02-15
    pds_rel = replicate(time_struct('2015-05-15'),nmon)
    pds_rel.month += 3*indgen(nmon)
    pds_rel = time_double(pds_rel)
    pflg = 1
  endif else pflg = 0

  mvn_spice_stat, summary=sstat, /silent
  if (~sstat.frames_exist) then mvn_swe_spice_init, /base

  maven_orbit_tplot, /shadow, /loadonly, result=dat, eph=eph, extended=ext, line_colors=lcol, colors=col

  ylim,'period',3.5,4.5,0
  options,'period','yticks',2
  options,'period','yminor',5
  options,'period','constant',[3.7,3.9,4.1,4.3]
  options,'plat','constant',[0]
  options,'plat','ytitle','Periapsis Lat'
  options,'psza','ytitle','Periapsis SZA'
  options,['plat','psza','Lss'],'thick',2
  Vx = eph.mso_v[*,0]
  Vmag = sqrt(total(eph.mso_v^2.,2))
  Rthe = asin(Vx/Vmag)*!radeg

  store_data,'Rthe',data={x:eph.time, y:Rthe}
  ylim,'Rthe',-90,90,0
  options,'Rthe','yticks',2
  options,'Rthe','yminor',3
  options,'Rthe','constant',[3]
  options,'Rthe','ytitle','RAM PL Elev.!cSun-Vel'

  get_data,'palt',data=palt
  Vxp = interpol(Vx, eph.time, palt.x)
  Vmagp = interpol(Vmag, eph.time, palt.x)
  Rthep = asin(Vxp/Vmagp)*!radeg

; below 300 km outside of EUV shadow with RAM flow onto fronts of panels

  get_data,'wake',data=wake
  flag = replicate(3, n_elements(wake.x), 2)
  indx = where((dat.hgt lt 300.) and (~finite(wake.y)) and (Rthe gt 3.), count)
  if (count gt 0L) then flag[indx,*] = 6

; flag = 6 -> red bar -> bad for charging in Sun-V or Fly+Z

  bname = 'cbar'
  store_data,bname,data={x:wake.x, y:flag, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,6,0 ; optimized for color table 43
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1
  options,bname,'color_table',43

  indx = where(flag[*,0] eq 6, count)
  time2 = wake.x[indx]
  flag2 = flag[indx,*]
  indx = nn2(time2, palt.x, maxdt=900D)
  flagp = replicate(!values.f_nan, n_elements(palt.x), 2)
  jndx = where(indx ge 0, count)
  flagp[jndx,*] = 6

  bname = 'cbarp'
  store_data,bname,data={x:palt.x, y:flagp, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,6,0 ; optimized for color table 43
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1
  options,bname,'color_table',43

  store_data,'Vx',data={x:palt.x, y:Vxp}
  options,'Vx','ytitle','Vx (km/s)!cMSO'
  options,'Vx','constant',[0]
  store_data,'Rthep',data={x:palt.x, y:Rthep}
  ylim,'Rthep',-90,90,0
  options,'Rthep','yticks',2
  options,'Rthep','yminor',3
  options,'Rthep','constant',[3]
  options,'Rthep','ytitle','RAM PL Elev.!cSun-Vel'
  timespan,[minmax(palt.x)]
  time_stamp,/off

; Sun elevation in Fly-Y
;   Unit vectors: Ysc = Vmso, Xsc = -Smso, Xmso --> Sun
;   Zsc = Xsc x Ysc = -Smso x Vmso
;   (-Smso x Vmso) dot Xmso = cosine of angle between Zsc and Sun direction
;   cos(phi) = Sz*Vy - Sy*Vz
;   always keep phi < 90 deg by using either Fly+Y or Fly-Y
;   S/C elevation of Sun: th = 90 - phi
;
; This is approximate, since Ysc = Vgeo  (Vmso is close to Vgeo at periapsis)

  get_data,'palt',data=palt
  indx = nn2(eph.time, palt.x)

  S = eph.mso_x/(eph.R # replicate(1.,3))
  V = eph.mso_v/(eph.vmag_mso # replicate(1.,3))
  costh = S[*,2]*V[*,1] - S[*,1]*V[*,2]
  th = 90. - acos(costh)*!radeg  ; Fly+Y
  jndx = where(th lt 0., count)
  if (count gt 0L) then th[jndx] = !values.f_nan
  store_data,'Sel_fly_py',data={x:eph.time[indx], y:th[indx]}

  th = acos(costh)*!radeg - 90.  ; Fly-Y
  jndx = where(th lt 0., count)
  if (count gt 0L) then th[jndx] = !values.f_nan
  store_data,'Sel_fly_my',data={x:eph.time[indx], y:th[indx]}

  store_data,'Sel_fly_y',data=['Sel_fly_py','Sel_fly_my']
  options,'Sel_fly_y','ytitle','Sun PL Elev.!cFly-Y'
  ylim,'Sel_fly_y',0,90,0
  options,'Sel_fly_y','yticks',3
  options,'Sel_fly_y','yminor',3
  options,'Sel_fly_y','colors',[2,6]
  options,'Sel_fly_y','labels',['+Y','-Y']
  options,'Sel_fly_y','labflag',1
  options,'Sel_fly_y','constant',[22]

  options,'psza','constant',75.
  options,'palt','constant',190.

  get_data,'palt',data=palt
  get_data,'psza',data=psza
  get_data,'Sel_fly_py',data=selp
  get_data,'Sel_fly_my',data=selm
  indx = where((palt.y lt 190.) and (psza.y lt 75.) and ((selp.y gt 22.) or (selm.y gt 22.)))
  flagc = replicate(!values.f_nan, n_elements(palt.x))
  flagc[indx] = 5.

  bname = 'calbar'
  store_data,bname,data={x:palt.x, y:flagc}
  ylim,bname,0,8,0
  options,bname,'ytitle',''
  options,bname,'no_interp',1
  options,bname,'thick',8
  options,bname,'xstyle',4
  options,bname,'ystyle',4

  mvn_flyz_bar  ; Fly+Z periods from the constraints spreadsheet
  ylim,'mvn_flyz_bar',0,8,0

  get_data,'palt',data=palt
  get_data,'lst',data=lst,index=i
  if (i eq 0) then begin
    str_element, eph, 'lst', success=ok
    if (ok) then begin
      store_data,'lst',data={x:eph.time, y:eph.lst}
      ylim,'lst',0,24,0
      options,'lst','yticks',4
      options,'lst','yminor',6
      options,'lst','psym',3
      options,'lst','ytitle','LST (hrs)'
  
      store_data,'Lss',data={x:eph.time, y:eph.slat}
      options,'Lss','ytitle','Sub-solar!CLat (deg)'
      options,'Lss','thick',2
    endif else mvn_mars_localtime
    get_data,'lst',data=lst,index=i
  endif
  if (i gt 0) then begin
    indx = where(finite(lst.y), count)
    if (count gt 0) then begin
      tt = lst.x[indx]
      lst = lst.y[indx]
      tsp = minmax(tt)
      tndx = where(palt.x ge tsp[0] and palt.x le tsp[1], count)
      if (count gt 0) then begin
        lx = cos(lst*(!pi/12.))
        ly = sin(lst*(!pi/12.))
        plx = interpol(lx, tt, palt.x[tndx], /nan)
        ply = interpol(ly, tt, palt.x[tndx], /nan)
        plst = atan(ply,plx)*(12./!pi)
        indx = where(plst lt 0., count)
        if (count gt 0) then plst[indx] += 24.
        store_data,'plst',data={x:palt.x[tndx], y:plst}
        ylim,'plst',0,24,0
        options,'plst','ytitle','Periapsis!cLST (hr)'
        options,'plst','yticks',4
        options,'plst','yminor',6
        options,'plst','constant',[6,12,18]
        phi = findgen(49)*(2.*!pi/49.)
        usersym,cos(phi),sin(phi),/fill
        options,'plst','psym',8
        options,'plst','symsize',0.5
      endif
    endif
  endif

  options,'alt2','ytitle','Altitude!c(km)'
  options,'palt','ytitle','Periapsis!cALT (km)'
  options,'plat','ytitle','Periapsis!cLAT (deg)'
  options,'psza','ytitle','Periapsis!cSZA (deg)'
  options,'plst','ytitle','Periapsis!cLST (hrs)'

  get_data,'Lss',data=lss,index=i
  if (i gt 0) then begin
    options,'Lss','constant',0
    mars_season = mvn_ls(lss.x, /all, /silent)
    L_s = mars_season.ls
    store_data,'L_s',data={x:lss.x, y:L_s}
;   tplot_options,'var_label','L_s'

    bname = 'dustbar'
    dust = replicate(!values.f_nan, n_elements(lss.x))
    indx = where((L_s gt 180.) and (L_s lt 320.), count)
    if (count gt 0L) then dust[indx] = 1.
    store_data,bname,data={x:lss.x, y:dust}
    ylim,bname,0,8,0
    options,bname,'ytitle',''
    options,bname,'no_interp',1
    options,bname,'thick',8
    options,bname,'xstyle',4
    options,bname,'ystyle',4
  endif

; ROSE bar (works only for EM6)

  trose = ['2025-10-01','2025-12-24','2026-02-04','2026-04-25','2026-06-03','2026-08-23', $
           '2026-10-02','2026-11-14','2027-04-12','2027-09-25','2027-11-28','2028-01-19', $
           '2028-03-16','2028-05-13','2028-06-30','2028-09-19']
  trose = time_double(trose)

  bname = 'rosebar'
  ndays = round((time_double('2028-10-01') - time_double('2025-10-01'))/86400D) + 1L
  time2 = time_double('2025-10-01') + 86400D*dindgen(ndays)
  rose = replicate(!values.f_nan, ndays)
  for i=0,(n_elements(trose)-1),2 do begin
    indx = where((time2 ge trose[i]) and (time2 le trose[i+1]), count)
    if (count gt 0L) then rose[indx] = 7.
  endfor
  store_data,bname,data={x:time2, y:rose}
  ylim,bname,0,8,0
  options,bname,'ytitle',''
  options,bname,'no_interp',1
  options,bname,'thick',8
  options,bname,'xstyle',4
  options,bname,'ystyle',4

  bname = 'bars'
  store_data,bname,data=['dustbar','mvn_flyz_bar','calbar','rosebar']
  ylim,bname,0.7,7.3,0
  mylines = get_line_colors(5, mycolors={ind:1, rgb:[242,59,67]})
  options,bname,'line_colors',mylines

  options,bname,'colors',[5,4,2,1]  ; [orange, green, blue, rose]
  options,bname,'labels',['DUST','FLY+Z','FLY Y/Z','ROSE']
  options,bname,'labflag',2
  options,bname,'xstyle',5
  options,bname,'ystyle',5
  options,bname,'ytitle',''
  options,bname,'panel_size',0.4
  lflg = 0

  get_data,'twake',data=twake,index=i
  if (i gt 0) then begin
    ratio = (1. - twake.y)/twake.y
    store_data,'ratio',data={x:twake.x, y:ratio}
    ylim,'ratio',2,4,0
    options,'ratio','constant',2.6  ; MAVEN survivability criterion: ratio > 2.6
    options,'ratio','ytitle','Sun/Shadow'
  endif

; Add conjunction panel
;   Solar thermal noise and scintillation degrade and disrupt communications
;   SEM = Sun-Earth-Mars angle (deg)
;     SEM < 3 --> comm disruptions often but brief (manage downlink rates)
;     SEM < 2 --> more frequent and longer disruptions (command moratorium)
;     SEM < 1 --> nearly constant comm outages
;     SEM < 0.266 --> s/c behind the Sun (photosphere)

  orrery, /tplot, /noplot
  bname = 'SEM'
  ylim,bname,0.1,10,1
  options,bname,'thick',2
  Asun = (6.957e10/1.496e13)*!radeg
  options,bname,'constant',[Asun,3.0]

; Identify ephemeris gaps and plot

  dt = median(palt.x - shift(palt.x,1))
  options,['alt2','palt','psza','plst','Lss'],'datagap',3D*dt  ; 3 median orbits = data gap
  tplot_options,'var_label','MarsYear'

  tplot,['alt2','SEM','palt','psza','bars','plst','Lss']
  if (lflg) then begin
    xs = 0.927
    ys = 0.431
    dys = 0.018
    xyouts,xs,ys,'ROSE',color=6,/norm,charsize=1.8
    ys -= dys
    xyouts,xs,ys,'FLY Y/Z',color=2,/norm,charsize=1.8
    ys -= dys
    xyouts,xs,ys,'FLY +Z',color=4,/norm,charsize=1.8
    ys -= dys
    xyouts,xs,ys,'DUST',color=5,/norm,charsize=1.8
  endif
  if (pflg) then timebar,pds_rel,line=2

  return

end
