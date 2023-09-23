;+
;PROCEDURE:   maven_orbit_predict
;PURPOSE:
;  Specialized version of maven_orbit_tplot that makes predict ephemeris
;  plots suitable for long-range planning, including identification of Fly-Y/Z
;  calibration opportunities.  This routine can reset the SPICE loadlist, so
;  use with caution.
;
;  Warning: This routine will reset timespan to cover the specified extended
;  ephemeris, overwriting any existing timespan.  This will affect any routines
;  that use timespan for determining what data to process.
;
;USAGE:
;  maven_orbit_tplot, extended=1, eph=eph
;
;INPUTS:
;
;KEYWORDS:
;       EXTENDED: If set, load one of six long-term predict ephemerides.  All but one
;                 have a density scale factor (DSF) of 2.5, which is a weighted average
;                 over several Mars years.  They differ in the number and timing of
;                 apoapsis, periapsis, and inclination maneuvers (arm, prm, inc) and total
;                 fuel usage (meters per second, or ms).  The date when the ephemeris was
;                 generated is given at the end of the filename (YYMMDD).  More recent
;                 dates better reflect current mission goals.  When in doubt, use the
;                 most recent.
;
;                   1 : trj_orb_230322-320101_dsf2.5-arm-prm-inc-17.5ms_230320.bsp
;                   2 : trj_orb_230322-320101_dsf1.5-prm-3.5ms_230320.bsp
;                   3 : trj_orb_220810-320101_dsf2.5_arm_prm_19.2ms_220802.bsp
;                   4 : trj_orb_220101-320101_dsf2.5_arms_18ms_210930.bsp
;                   5 : trj_orb_220101-320101_dsf2.5_arm_prm_13.5ms_210908.bsp
;                   6 : trj_orb_210326-301230_dsf2.5-otm0.4-arms-prm-13.9ms_210330.bsp
;
;                 Default = 1 (most recent).
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
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-27 13:10:57 -0700 (Sun, 27 Aug 2023) $
; $LastChangedRevision: 32069 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_predict.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro maven_orbit_predict, extended=extended, eph=eph, line_colors=lcol, colors=col

  ext = n_elements(extended) ? fix(extended[0]) : 1
  if (ext eq 0) then begin
    tplot_options, get=topt
    if (topt.trange_full[1] lt 0.1D) then begin
      print,"You must specify a time range."
      return
    endif
  endif

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
  ylim,bname,0,6,0
  options,bname,'ytitle',''
  options,bname,'no_interp',1
  options,bname,'thick',8
  options,bname,'xstyle',4
  options,bname,'ystyle',4

  mvn_flyz_bar  ; Fly+Z periods from the constraints spreadsheet

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
    L_s = mvn_ls(lss.x)
    store_data,'L_s',data={x:lss.x, y:L_s}
;   tplot_options,'var_label','L_s'

    bname = 'dustbar'
    dust = replicate(!values.f_nan, n_elements(lss.x))
    indx = where((L_s gt 180.) and (L_s lt 320.), count)
    if (count gt 0L) then dust[indx] = 1.
    store_data,bname,data={x:lss.x, y:dust}
    ylim,bname,0,6,0
    options,bname,'ytitle',''
    options,bname,'no_interp',1
    options,bname,'thick',8
    options,bname,'xstyle',4
    options,bname,'ystyle',4
  endif

  bname = 'bars'
  store_data,bname,data=['dustbar','mvn_flyz_bar','calbar']
  ylim,bname,0.7,5.3,0
  options,bname,'line_colors',5
  options,bname,'colors',[5,4,6]  ; [orange, green, red]
  options,bname,'labels',['DUST','FLY+Z','FLY Y/Z']
  options,bname,'labflag',2
  options,bname,'xstyle',5
  options,bname,'ystyle',5
  options,bname,'ytitle',''
  options,bname,'panel_size',0.4

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
  tplot_options,'var_label',''

  tplot,['alt2','SEM','palt','psza','bars','plst','Lss']

  return

end
