;+
;PROCEDURE:   mvn_sta_cio_tplot
;PURPOSE:
;
;USAGE:
;  mvn_sta_cio_tplot
;
;INPUTS:
;
;KEYWORDS:
;       PANS:          Tplot panel names created when DOPLOT is set.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-01-20 10:15:19 -0800 (Tue, 20 Jan 2026) $
; $LastChangedRevision: 34039 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_tplot.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_plot.pro
;-
pro mvn_sta_cio_tplot, pans=pans

    common coldion, cio_h, cio_o1, cio_o2

    a = 0.8
    phi = findgen(49)*(2.*!pi/49)
    usersym,a*cos(phi),a*sin(phi),/fill

    species = ['i+','e-','H+','O+','O2+']
    cols = get_colors()
    icols = [!p.color,cols.magenta,cols.blue,cols.green,cols.red]  ; color for each species

    doh  = size(cio_h,/type)  eq 8
    doo1 = size(cio_o1,/type) eq 8
    doo2 = size(cio_o2,/type) eq 8

; Density

    first = 1
    vars = ['den_t']
    cols = [icols[0]]
    spec = [species[0]]
    if (doh) then begin
      store_data,'den_h',data={x:cio_h.time, y:cio_h.den_i}
      store_data,'den_e',data={x:cio_h.time, y:cio_h.den_e}
      den_h = cio_h.den_i
      indx = where(~finite(den_h), count)
      if (count gt 0L) then den_h[indx] = 0.
      den_t = den_h
      vars = [vars,'den_e','den_h']
      cols = [cols,icols[1:2]]
      spec = [spec,species[1:2]]
      time = cio_h.time
      npts = n_elements(time)
      first = 0
    endif
    if (doo1) then begin
      store_data,'den_o1',data={x:cio_o1.time, y:cio_o1.den_i}
      den_o = cio_o1.den_i
      indx = where(~finite(den_o), count)
      if (count gt 0L) then den_o[indx] = 0.
      if (first) then begin
        store_data,'den_e',data={x:cio_o1.time, y:cio_o1.den_e}
        vars = [vars,'den_e']
        cols = [cols,icols[1]]
        spec = [spec,species[1]]
        den_t = den_o
        time = cio_o1.time
        npts = n_elements(time)
        first = 0
      endif else den_t += den_o
      vars = [vars,'den_o1']
      cols = [cols,icols[3]]
      spec = [spec,species[3]]
    endif
    if (doo2) then begin
      store_data,'den_o2',data={x:cio_o2.time, y:cio_o2.den_i}
      den_o2 = cio_o2.den_i
      indx = where(~finite(den_o2), count)
      if (count gt 0L) then den_o2[indx] = 0.
      if (first) then begin
        store_data,'den_e',data={x:cio_o2.time, y:cio_o2.den_e}
        vars = [vars,'den_e']
        cols = [cols,icols[1]]
        spec = [spec,species[1]]
        den_t = den_o2
        time = cio_o2.time
        npts = n_elements(time)
        first = 0
      endif else den_t += den_o2
      vars = [vars,'den_o2']
      cols = [cols,icols[4]]
      spec = [spec,species[4]]
    endif

    if (first) then begin
      print,"No data to make tplot variables for!"
      return
    endif

    store_data,'den_t',data={x:cio_h.time, y:den_t}

    store_data,'den_i+',data=vars
    ylim,'den_i+',0.1,100,1
    options,'den_i+','constant',[1,10]
    options,'den_i+','ytitle','Ion Density!c1/cc'
    options,'den_i+','colors',cols
    options,'den_i+','labels',spec
    options,'den_i+','labflag',1
    pans = ['den_i+']

; Temperature

    vars = ['']
    cols = [-1]
    spec = ['']
    if (doh) then begin
      store_data,'temp_h',data={x:cio_h.time, y:cio_h.temp}
      vars = [vars,'temp_h']
      cols = [cols,icols[2]]
      spec = [spec,species[2]]
    endif
    if (doo1) then begin
      store_data,'temp_o1',data={x:cio_o1.time, y:cio_o1.temp}
      vars = [vars,'temp_o1']
      cols = [cols,icols[3]]
      spec = [spec,species[3]]
    endif
    if (doo2) then begin
      store_data,'temp_o2',data={x:cio_o2.time, y:cio_o2.temp}
      vars = [vars,'temp_o2']
      cols = [cols,icols[4]]
      spec = [spec,species[4]]
    endif
    store_data,'temp_i+',data=vars[1:*]
    ylim,'temp_i+',0.1,100,1
    options,'temp_i+','constant',[1,10]
    options,'temp_i+','ytitle','Ion Temp!ceV'
    options,'temp_i+','colors',cols[1:*]
    options,'temp_i+','labels',spec[1:*]
    options,'temp_i+','labflag',1
    pans = [pans, 'temp_i+']

; Vector Velocity (make variables but don't include in default list)

    if (doh) then begin
      store_data,'velocity_h',data={x:cio_h.time, y:transpose(cio_h.v_mso), v:[0,1,2]}
      options,'velocity_h','ytitle','H Vel!ckm/s'
      options,'velocity_h','colors',[2,4,6]
      options,'velocity_h','labels',['Vx','Vy','Vz']
      options,'velocity_h','labflag',1

      sc = transpose(cio_h.mso)
      sc /= (sqrt(total(sc*sc,2)) # replicate(1.,3))
      bname = 'Vr_h'
      y = total(sc*transpose(cio_h.v_mso),2)
      store_data,bname,data={x:cio_h.time, y:y}
      ylim,bname,0,0,0
      options,bname,'spec',0
      options,bname,'panel_size',0.5
      options,bname,'ytitle','Vr [H]'
      options,bname,'yticks',0
      options,bname,'yminor',0
      options,bname,'constant',[0.]

      ybar = replicate(!values.f_nan,n_elements(cio_h.time),2)
      indx = where(y gt 0., count)
      if (count gt 0L) then ybar[indx,0] = 2.
      indx = where(y lt 0., count)
      if (count gt 0L) then ybar[indx,0] = 0.5
      ybar[*,1] = ybar[*,0]
      bname = 'Vr_h_bar'
      store_data,bname,data={x:cio_h.time, y:ybar, v:[0,1]}
      ylim,bname,0,1,0
      zlim,bname,0,2,0
      options,bname,'spec',1
      options,bname,'panel_size',0.05
      options,bname,'ytitle',''
      options,bname,'yticks',1
      options,bname,'yminor',1
      options,bname,'no_interp',1
      options,bname,'xstyle',4
      options,bname,'ystyle',4
      options,bname,'no_color_scale',1
    endif
    if (doo1) then begin
      store_data,'velocity_o1',data={x:cio_o1.time, y:transpose(cio_o1.v_mso), v:[0,1,2]}
      options,'velocity_o1','ytitle','O Vel!ckm/s'
      options,'velocity_o1','colors',[2,4,6]
      options,'velocity_o1','labels',['Vx','Vy','Vz']
      options,'velocity_o1','labflag',1

      sc = transpose(cio_o1.mso)
      sc /= (sqrt(total(sc*sc,2)) # replicate(1.,3))
      bname = 'Vr_o1'
      y = total(sc*transpose(cio_o1.v_mso),2)
      store_data,bname,data={x:cio_o1.time, y:y}
      ylim,bname,0,0,0
      options,bname,'spec',0
      options,bname,'panel_size',0.5
      options,bname,'ytitle','Vr [O]'
      options,bname,'yticks',0
      options,bname,'yminor',0
      options,bname,'constant',[0.]

      ybar = replicate(!values.f_nan,n_elements(cio_o1.time),2)
      indx = where(y gt 0., count)
      if (count gt 0L) then ybar[indx,0] = 2.
      indx = where(y lt 0., count)
      if (count gt 0L) then ybar[indx,0] = 0.5
      ybar[*,1] = ybar[*,0]
      bname = 'Vr_o1_bar'
      store_data,bname,data={x:cio_o1.time, y:ybar, v:[0,1]}
      ylim,bname,0,1,0
      zlim,bname,0,2,0
      options,bname,'spec',1
      options,bname,'panel_size',0.05
      options,bname,'ytitle',''
      options,bname,'yticks',1
      options,bname,'yminor',1
      options,bname,'no_interp',1
      options,bname,'xstyle',4
      options,bname,'ystyle',4
      options,bname,'no_color_scale',1
    endif
    if (doo2) then begin
      store_data,'velocity_o2',data={x:cio_o2.time, y:transpose(cio_o2.v_mso), v:[0,1,2]}
      options,'velocity_o2','ytitle','O2 Vel!ckm/s'
      options,'velocity_o2','colors',[2,4,6]
      options,'velocity_o2','labels',['Vx','Vy','Vz']
      options,'velocity_o2','labflag',1

      sc = transpose(cio_o2.mso)
      sc /= (sqrt(total(sc*sc,2)) # replicate(1.,3))
      bname = 'Vr_o2'
      y = total(sc*transpose(cio_o2.v_mso),2)
      store_data,bname,data={x:cio_o2.time, y:y}
      ylim,bname,0,0,0
      options,bname,'spec',0
      options,bname,'panel_size',0.5
      options,bname,'ytitle','Vr [O2]'
      options,bname,'yticks',0
      options,bname,'yminor',0
      options,bname,'constant',[0.]

      ybar = replicate(!values.f_nan,n_elements(cio_o2.time),2)
      indx = where(y gt 0., count)
      if (count gt 0L) then ybar[indx,0] = 2.
      indx = where(y lt 0., count)
      if (count gt 0L) then ybar[indx,0] = 0.5
      ybar[*,1] = ybar[*,0]
      bname = 'Vr_o2_bar'
      store_data,bname,data={x:cio_o2.time, y:ybar, v:[0,1]}
      ylim,bname,0,1,0
      zlim,bname,0,2,0
      options,bname,'spec',1
      options,bname,'panel_size',0.05
      options,bname,'ytitle',''
      options,bname,'yticks',1
      options,bname,'yminor',1
      options,bname,'no_interp',1
      options,bname,'xstyle',4
      options,bname,'ystyle',4
      options,bname,'no_color_scale',1
    endif

; Bulk Velocity

    first = 1
    vars = ['Vesc']
    cols = [!p.color]
    spec = ['ESC']
    if (doh) then begin
      store_data,'vel_h',data={x:cio_h.time, y:cio_h.vbulk}
      store_data,'Vesc',data={x:cio_h.time, y:cio_h.v_esc}
      vars = ['vel_h',vars]
      cols = [icols[2],cols]
      spec = [species[2],spec]
      first = 0
    endif
    if (doo1) then begin
      store_data,'vel_o1',data={x:cio_o1.time, y:cio_o1.vbulk}
      if (first) then begin
        store_data,'Vesc',data={x:cio_o1.time, y:cio_o1.v_esc}
        first = 0
      endif
      vars = ['vel_o1',vars]
      cols = [icols[3],cols]
      spec = [species[3],spec]
    endif
    if (doo2) then begin
      store_data,'vel_o2',data={x:cio_o2.time, y:cio_o2.vbulk}
      if (first) then begin
        store_data,'Vesc',data={x:cio_o2.time, y:cio_o2.v_esc}
        first = 0
      endif
      vars = ['vel_o2',vars]
      cols = [icols[4],cols]
      spec = [species[4],spec]
    endif
    store_data,'vel_i+',data=vars
    ylim,'vel_i+',1,500,1
    options,'vel_i+','constant',[10,100]
    options,'vel_i+','ytitle','Ion Vel!ckm/s'
    options,'vel_i+','colors',cols
    options,'vel_i+','labels',spec
    options,'vel_i+','labflag',1
    pans = [pans, 'vel_i+']

; Kinetic Energy of Bulk Flow

    vars = ['']
    cols = [-1]
    spec = ['']
    if (doh) then begin
      store_data,'engy_h',data={x:cio_h.time, y:cio_h.energy}
      vars = [vars,'engy_h']
      cols = [cols,icols[2]]
      spec = [spec,species[2]]
    endif
    if (doo1) then begin
      store_data,'engy_o1',data={x:cio_o1.time, y:cio_o1.energy}
      vars = [vars,'engy_o1']
      cols = [cols,icols[3]]
      spec = [spec,species[3]]
    endif
    if (doo2) then begin
      store_data,'engy_o2',data={x:cio_o2.time, y:cio_o2.energy}
      vars = [vars,'engy_o2']
      cols = [cols,icols[4]]
      spec = [spec,species[4]]
    endif
    store_data,'engy_i+',data=vars[1:*]
    ylim,'engy_i+',0.1,100,1
    options,'engy_i+','constant',[1,10]
    options,'engy_i+','ytitle','Ion Energy!ceV'
    options,'engy_i+','colors',cols[1:*]
    options,'engy_i+','labels',spec[1:*]
    options,'engy_i+','labflag',1
    pans = [pans, 'engy_i+']

; Angle between V and B

    vars = ['']
    cols = [-1]
    spec = ['']
    if (doh) then begin
      store_data,'VB_phi_h',data={x:cio_h.time, y:cio_h.VB_phi}
      vars = [vars,'VB_phi_h']
      cols = [cols,icols[2]]
      spec = [spec,species[2]]
    endif
    if (doo1) then begin
      store_data,'VB_phi_o1',data={x:cio_o1.time, y:cio_o1.VB_phi}
      vars = [vars,'VB_phi_o1']
      cols = [cols,icols[3]]
      spec = [spec,species[3]]
    endif
    if (doo2) then begin
      store_data,'VB_phi_o2',data={x:cio_o2.time, y:cio_o2.VB_phi}
      vars = [vars,'VB_phi_o2']
      cols = [cols,icols[4]]
      spec = [spec,species[4]]
    endif
    store_data,'VB_phi',data=vars[1:*]
    ylim,'VB_phi',0,180,0
    options,'VB_phi','colors',cols[1:*]
    options,'VB_phi','yticks',2
    options,'VB_phi','yminor',3
    options,'VB_phi','constant',[30,60,90,120,150]
    options,'VB_phi','labels',spec[1:*]
    options,'VB_phi','labflag',1
    pans = [pans, 'VB_phi']

; Angle between V and APP-i

    if (doo1 or doo2) then begin
      VI_phi = replicate(!values.f_nan,npts,2)
      if (doo1) then VI_phi[*,0] = cio_o1.VI_phi
      if (doo2) then VI_phi[*,1] = cio_o2.VI_phi
      store_data,'VI_phi',data={x:time, y:VI_phi, v:[0,1]}
      ylim,'VI_phi',0,180
      options,'VI_phi','ytitle','VI Phi!cAPP'
      options,'VI_phi','colors',icols[3:4]
      options,'VI_phi','yticks',2
      options,'VI_phi','yminor',3
      options,'VI_phi','constant',[30,60,90,120,150]
      options,'VI_phi','labels',species[3:4]
      options,'VI_phi','labflag',1
      pans = [pans, 'VI_phi']
    endif

; Angle between V and APP-k

    VK_the = replicate(!values.f_nan,npts,3)
    if (doh) then VK_the[*,0] = cio_h.VK_the
    if (doo1) then VK_the[*,1] = cio_o1.VK_the
    if (doo2) then VK_the[*,2] = cio_o2.VK_the
    store_data,'VK_the',data={x:time, y:VK_the, v:[0,1,2]}
    ylim,'VK_the',-45,45,0
    options,'VK_the','ytitle','VK The!cAPP'
    options,'VK_the','colors',icols[2:4]
    options,'VK_the','yticks',2
    options,'VK_the','yminor',3
    options,'VK_the','constant',0
    options,'VK_the','labels',species[2:4]
    options,'VK_the','labflag',1
    pans = [pans, 'VK_the']

; Shape Parameter

    cols = get_colors()
    first = 1
    if (doh) then begin
      store_data,'Shape_PAD2',data={x:cio_h.time, y:transpose(cio_h.shape^2.), v:[0,1]}
      store_data,'flux40',data={x:cio_h.time, y:cio_h.flux40}
      store_data,'ratio',data={x:cio_h.time, y:cio_h.ratio}
      store_data,'topo',data={x:cio_h.time, y:cio_h.topo}
      store_data,'reg_id',data={x:cio_h.time, y:cio_h.region}
      first = 0
    endif
    if (first and doo1) then begin
      store_data,'Shape_PAD2',data={x:cio_o1.time, y:transpose(cio_o1.shape^2.), v:[0,1]}
      store_data,'flux40',data={x:cio_o1.time, y:cio_o1.flux40}
      store_data,'ratio',data={x:cio_o1.time, y:cio_o1.ratio}
      store_data,'topo',data={x:cio_o1.time, y:cio_o1.topo}
      store_data,'reg_id',data={x:cio_o1.time, y:cio_o1.region}
      first = 0
    endif
    if (first and doo2) then begin
      store_data,'Shape_PAD2',data={x:cio_o2.time, y:transpose(cio_o2.shape^2.), v:[0,1]}
      store_data,'flux40',data={x:cio_o2.time, y:cio_o2.flux40}
      store_data,'ratio',data={x:cio_o2.time, y:cio_o2.ratio}
      store_data,'topo',data={x:cio_o2.time, y:cio_o2.topo}
      store_data,'reg_id',data={x:cio_o2.time, y:cio_o2.region}
      first = 0
    endif

    ylim,'Shape_PAD2',0,5,0
    options,'Shape_PAD2','yminor',1
    options,'Shape_PAD2','constant',1
    options,'Shape_PAD2','ytitle','Shape'
    options,'Shape_PAD2','colors',[cols.blue,cols.red]
    options,'Shape_PAD2','labels',['away','toward']
    options,'Shape_PAD2','labflag',1

    ylim,'flux40',0.1,1000,1
    options,'flux40','ytitle','Eflux/1e5!c40 eV'
    options,'flux40','constant',1
    options,'flux40','colors',cols.green

    ylim,'ratio',0,2.5,0
    options,'ratio','ytitle','Flux Ratio!caway/twd!cPA 0-30'
    options,'ratio','constant',[0.75,1]
    options,'ratio','colors',cols.green

    pans = [pans, 'Shape_PAD2', 'flux40', 'ratio']

; Topology and Plasma Region

    options,'topo','colors',cols.blue
    store_data,'topo_lab',data={x:minmax(time), y:replicate(-1,2,5), v:findgen(5)}
    options,'topo_lab','labels',['?','Closed','Open-D','Open-N','Draped']
    options,'topo_lab','labflag',1
    options,'topo_lab','colors',!p.color
    store_data,'topology',data=['topo','topo_lab']
    ylim,'topology',-0.5,4.5,0
    options,'topology','ytitle','Topology'
    options,'topology','yminor',1
    options,'topology','psym',8
    options,'topology','symsize',1
    options,'topology','constant',[1.5,3.5]

    get_data,'topo',data=topo
    y = replicate(0,npts,2)
    y[*,0] = 5 - topo.y
    y[*,1] = y[*,0]
    indx = where(y eq 5, count)
    if (count gt 0) then y[indx] = 0
    bname = 'topo_bar'
    store_data,bname,data={x:time, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,4,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

    options,'reg_id','psym',8
    options,'reg_id','symsize',1
    options,'reg_id','colors',4

    store_data,'reg_lab',data={x:minmax(time), y:replicate(-1,2,5), v:findgen(5)}
    options,'reg_lab','labels',['?','Wind','Sheath','Iono','Lobe']
    options,'reg_lab','labflag',1
    options,'reg_lab','colors',!p.color
    store_data,'reg_ids',data=['reg_id','reg_lab']
    options,'reg_ids','ytitle','Region'
    ylim,'reg_ids',-0.5,4.5,0
    options,'reg_ids','yminor',1

    get_data,'reg_id',data=reg_id
    y = replicate(0,n_elements(reg_id.x),2)
    y[*,0] = reform(reg_id.y)
    y[*,1] = y[*,0]
    bname = 'reg_bar'
    store_data,bname,data={x:reg_id.x, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,4,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

    pans = [pans, 'topology', 'reg_ids']

; Escape Flux

    vars = ['']
    cols = [-1]
    spec = ['']
    if (doo2) then begin
      flx_o2 = cio_o2.den_i * cio_o2.vbulk * 1.e5
      store_data,'mvn_sta_o2+_flux',data={x:cio_o2.time, y:flx_o2}
      vars = [vars,'mvn_sta_o2+_flux']
      cols = [cols,icols[4]]
      spec = [spec,species[4]]
    endif

    if (doo1) then begin
      flx_o1 = cio_o1.den_i * cio_o1.vbulk * 1.e5
      store_data,'mvn_sta_o+_flux',data={x:cio_o1.time, y:flx_o1}
      vars = [vars,'mvn_sta_o+_flux']
      cols = [cols,icols[3]]
      spec = [spec,species[3]]
    endif

    if (doh) then begin
      flx_h = cio_h.den_i * cio_h.vbulk * 1.e5
      store_data,'mvn_sta_p+_flux',data={x:cio_h.time, y:flx_h}
      vars = [vars,'mvn_sta_p+_flux']
      cols = [cols,icols[2]]
      spec = [spec,species[2]]
    endif

    store_data,'flux_i+',data=vars[1:*]
    ylim,'flux_i+',1e4,1e10,1
    options,'flux_i+','ytitle','Ion Flux!ccm!u-2!ns!u-1!n'
    options,'flux_i+','colors',cols[1:*]
    options,'flux_i+','labels',spec[1:*]
    options,'flux_i+','labflag',1
    pans = [pans, 'flux_i+']

; CIO Geometry

    cols = get_colors()
    first = 1
    if (doh) then begin
      store_data,'sthe',data={x:cio_h.time, y:cio_h.sthe}
      store_data,'sthe_app',data={x:cio_h.time, y:cio_h.sthe_app}
      store_data,'rthe_app',data={x:cio_h.time, y:cio_h.rthe_app}
      first = 0
    endif
    if (first and doo1) then begin
      store_data,'sthe',data={x:cio_o1.time, y:cio_o1.sthe}
      store_data,'sthe_app',data={x:cio_o1.time, y:cio_o1.sthe_app}
      store_data,'rthe_app',data={x:cio_o1.time, y:cio_o1.rthe_app}
      first = 0
    endif
    if (first and doo2) then begin
      store_data,'sthe',data={x:cio_o2.time, y:cio_o2.sthe}
      store_data,'sthe_app',data={x:cio_o2.time, y:cio_o2.sthe_app}
      store_data,'rthe_app',data={x:cio_o2.time, y:cio_o2.rthe_app}
      first = 0
    endif

    options,'sthe','colors',cols.magenta
    options,'sthe','ytitle','Sun The!cSWEA'
    options,'sthe','constant',45     ; nominal value for SWEA CIO twist

    ylim,'sthe_app',-45,45,0
    options,'sthe_app','yticks',2
    options,'sthe_app','yminor',3
    options,'sthe_app','colors',cols.magenta
    options,'sthe_app','ytitle','Sun The!cAPP'
    options,'sthe_app','constant',0  ; nominal value for STATIC CIO configuration

    ylim,'rthe_app',-45,45,0
    options,'rthe_app','yticks',2
    options,'rthe_app','yminor',3
    options,'rthe_app','colors',cols.magenta
    options,'rthe_app','ytitle','MSO RAM The!cAPP'
    options,'rthe_app','constant',0  ; nominal value for STATIC CIO configuration

    get_data,'sthe',data=sthe
    get_data,'sthe_app',data=sthe_app
    get_data,'rthe_app',data=rthe_app
    y = replicate(0,npts,2)             ; black = neither is optimized
    indx = where(abs(sthe.y - 45) lt 5, count)
    if (count gt 0) then y[indx,*] = 1  ; blue = only SWEA is optimized
    indx = where((abs(sthe_app.y) le 5) and $
                 (abs(rthe_app.y) le 10), count)
    if (count gt 0) then y[indx,*] = 2  ; yellow = only STATIC is optimized (no twist)
    indx = where((abs(sthe.y - 45) lt 5) and $
                 (abs(sthe_app.y) le 5) and $
                 (abs(rthe_app.y) le 10), count)
    if (count gt 0) then y[indx,*] = 3  ; red = both STATIC and SWEA are optimized
    bname = 'cio_bar'
    store_data,bname,data={x:sthe.x, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,3,0
    options,bname,'spec',1
    options,bname,'color_table',43  ; ensure blank-blue-yellow-red color scheme
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

; Ephemeris

    store_data,'L_s',data={x:cio_o2.time, y:cio_o2.L_s}
    store_data,'slat',data={x:cio_o2.time, y:cio_o2.slat}
    store_data,'Mdist',data={x:cio_o2.time, y:cio_o2.mdist}

  return

end
