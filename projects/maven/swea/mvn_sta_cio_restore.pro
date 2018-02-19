;+
;PROCEDURE:   mvn_sta_cio_restore
;PURPOSE:
;  Restores STATIC cold ion outflow results.
;  See mvn_sta_coldion.pro for details.
;
;USAGE:
;  mvn_sta_cio_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range.
;
;KEYWORDS:
;       LOADONLY:      Download but do not restore any cio data.
;
;       RESULT_H:      CIO result structure for H+.
;
;       RESULT_O1:     CIO result structure for O+.
;
;       RESULT_O2:     CIO result structure for O2+.
;
;       DOPLOT:        Make tplot variables.
;
;       PANS:          Tplot panel names created when DOPLOT is set.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-02-18 12:38:39 -0800 (Sun, 18 Feb 2018) $
; $LastChangedRevision: 24744 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_restore.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_restore.pro
;-
pro mvn_sta_cio_restore, trange, loadonly=loadonly, result_h=result_h, $
                         result_o1=result_o1, result_o2=result_o2, doplot=doplot, $
                         pans=pans

  rootdir = 'maven/data/sci/sta/l3/cio/YYYY/MM/'
  fname = 'mvn_sta_cio_YYYYMMDD_v02.sav'

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(trange,/type) eq 0) then begin
    print,"You must specify a time or orbit range."
    return
  endif
  tmin = min(time_double(trange), max=tmax)
  file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names)
  nfiles = n_elements(file)

  finfo = file_info(file)
  indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
  if (nfiles eq 0) then return
  file = file[indx]

  if keyword_set(loadonly) then begin
    print,''
    print,'Files found:'
    for i=0,(nfiles-1) do print,file[i],format='("  ",a)'
    print,''
    return
  endif

; Restore the save file(s)

  first = 1
  docat = 0
  
  for i=0,(nfiles-1) do begin
    print,"Processing file: ",file_basename(file[i])
    
    if (first) then begin
      restore, filename=file[i]
      if (size(cio_h,/type) eq 8) then begin
        result_h  = temporary(cio_h)
        result_o1 = temporary(cio_o1)
        result_o2 = temporary(cio_o2)
        first = 0
      endif else print,"No data were restored."
    endif else begin
      restore, filename=file[i]
      if (size(cio_h,/type) eq 8) then begin
        result_h  = [temporary(result_h),  temporary(cio_h)]
        result_o1 = [temporary(result_o1), temporary(cio_o1)]
        result_o2 = [temporary(result_o2), temporary(cio_o2)]
      endif else print,"No data were restored."
    endelse
  endfor

  npts = n_elements(result_h.time)

; Trim to the requested time range

  indx = where((result_h.time ge tmin) and (result_h.time le tmax), mpts)

  if (mpts eq 0L) then begin
    print,"No data within specified time range!"
    result_h = 0
    result_o1 = 0
    result_o2 = 0
    return
  endif

  if (mpts lt npts) then begin
    result_h  = temporary(result_h[indx])
    result_o1 = temporary(result_o1[indx])
    result_o2 = temporary(result_o2[indx])
    npts = mpts
  endif

; Make tplot variables

  if keyword_set(doplot) then begin

    icols = [2,4,6]  ; colors for H+, O+, O2+
    species = ['H+','O+','O2+']

; Density

    store_data,'den_h',data={x:result_h.time, y:result_h.den_i}
    store_data,'den_o1',data={x:result_o1.time, y:result_o1.den_i}
    store_data,'den_o2',data={x:result_o2.time, y:result_o2.den_i}
    store_data,'den_e',data={x:result_h.time, y:result_h.den_e}

    den_h = result_h.den_i
    indx = where(~finite(den_h), count)
    if (count gt 0L) then den_h[indx] = 0.
    den_o = result_o1.den_i
    indx = where(~finite(den_o), count)
    if (count gt 0L) then den_o[indx] = 0.
    den_o2 = result_o2.den_i
    indx = where(~finite(den_o2), count)
    if (count gt 0L) then den_o2[indx] = 0.
    den_t = den_h + den_o + den_o2
    store_data,'den_t',data={x:result_h.time, y:den_t}

    store_data,'den_i+',data=['den_t','den_e','den_h','den_o1','den_o2']
    ylim,'den_i+',0.1,100,1
    options,'den_i+','constant',[1,10]
    options,'den_i+','ytitle','Ion Density!c1/cc'
    options,'den_i+','colors',[!p.color,1,icols]
    options,'den_i+','labels',['i+','e-',species]
    options,'den_i+','labflag',1
    pans = ['den_i+']

; Temperature

    store_data,'temp_h',data={x:result_h.time, y:result_h.temp}
    store_data,'temp_o1',data={x:result_o1.time, y:result_o1.temp}
    store_data,'temp_o2',data={x:result_o2.time, y:result_o2.temp}
    store_data,'temp_i+',data=['temp_h','temp_o1','temp_o2']
    ylim,'temp_i+',0.1,100,1
    options,'temp_i+','constant',[1,10]
    options,'temp_i+','ytitle','Ion Temp!ceV'
    options,'temp_i+','colors',icols
    options,'temp_i+','labels',species
    options,'temp_i+','labflag',1
    pans = [pans, 'temp_i+']

; Vector Velocity

    store_data,'velocity_h',data={x:result_h.time, y:transpose(result_h.vel), v:[0,1,2]}
    options,'velocity_h','ytitle','H Vel!ckm/s'
    options,'velocity_h','colors',[2,4,6]
    options,'velocity_h','labels',['Vx','Vy','Vz']
    options,'velocity_h','labflag',1
    store_data,'velocity_o1',data={x:result_o1.time, y:transpose(result_o1.vel), v:[0,1,2]}
    options,'velocity_o1','ytitle','O Vel!ckm/s'
    options,'velocity_o1','colors',[2,4,6]
    options,'velocity_o1','labels',['Vx','Vy','Vz']
    options,'velocity_o1','labflag',1
    store_data,'velocity_o2',data={x:result_o2.time, y:transpose(result_o2.vel), v:[0,1,2]}
    options,'velocity_o2','ytitle','O2 Vel!ckm/s'
    options,'velocity_o2','colors',[2,4,6]
    options,'velocity_o2','labels',['Vx','Vy','Vz']
    options,'velocity_o2','labflag',1

; Bulk Velocity

    store_data,'vel_h',data={x:result_h.time, y:result_h.vbulk}
    store_data,'vel_o1',data={x:result_o1.time, y:result_o1.vbulk}
    store_data,'vel_o2',data={x:result_o2.time, y:result_o2.vbulk}
    store_data,'Vesc',data={x:result_h.time, y:result_h.v_esc}
    options,'Vesc','linestyle',2
    store_data,'vel_i+',data=['vel_h','vel_o1','vel_o2','Vesc']
    ylim,'vel_i+',1,500,1
    options,'vel_i+','constant',[10,100]
    options,'vel_i+','ytitle','Ion Vel!ckm/s'
    options,'vel_i+','colors',[icols,!p.color]
    options,'vel_i+','labels',[species,'ESC']
    options,'vel_i+','labflag',1
    pans = [pans, 'vel_i+']

; Polarity of the O2+ bulk flow (+X or -X)

    V_phi = atan(result_o2.vel[2],result_o2.vel[1])*!radeg
    indx = where(V_phi lt 0., count)
    if (count gt 0L) then V_phi[indx] += 360.
    V_the = asin(result_o2.vel[0]/result_o2.vbulk)*!radeg

    store_data,'V_o2_phi',data={x:result_o2.time, y:V_phi}
    ylim,'V_o2_phi',0,360,0
    options,'V_o2_phi','ytitle','V_O2 (MSO)!cYZ Clock'
    options,'V_o2_phi','yticks',4
    options,'V_o2_phi','yminor',3
    options,'V_o2_phi','constant',[90,180,270]
    options,'V_o2_phi','psym',3
    options,'V_o2_phi','colors',[4]

    store_data,'V_o2_the',data={x:result_o2.time, y:V_the}
    ylim,'V_o2_the',-90,90,0
    options,'V_o2_the','ytitle','V_O2 (MSO)!cX Polar'
    options,'V_o2_the','yticks',2
    options,'V_o2_the','yminor',3
    options,'V_o2_the','constant',[0]
    options,'V_o2_the','psym',3
    options,'V_o2_the','colors',[4]

    pans = [pans, 'V_o2_phi', 'V_o2_the']

    Vx = result_o2.vel[0] # [1.,1.]
    indx = where(Vx ge 0., npos, complement=jndx, ncomplement=nneg)
    if (npos gt 0L) then Vx[indx,*] = -1.
    if (nneg gt 0L) then Vx[jndx,*] =  1.

    bname = 'Vx_o2'
    store_data,bname,data={x:result_o2.time, y:Vx, v:[-1,1]}
    ylim,bname,0,1,0
    zlim,bname,-1.5,1,0  ; optimized for color table 43
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

; Kinetic Energy of Bulk Flow

    store_data,'engy_h',data={x:result_h.time, y:result_h.energy}
    store_data,'engy_o1',data={x:result_o1.time, y:result_o1.energy}
    store_data,'engy_o2',data={x:result_o2.time, y:result_o2.energy}
    store_data,'engy_i+',data=['engy_h','engy_o1','engy_o2']
    ylim,'engy_i+',0.1,100,1
    options,'engy_i+','constant',[1,10]
    options,'engy_i+','ytitle','Ion Energy!ceV'
    options,'engy_i+','colors',icols
    options,'engy_i+','labels',species
    options,'engy_i+','labflag',1
    pans = [pans, 'engy_i+']

; Angle between V and B

    store_data,'VB_phi_h',data={x:result_h.time, y:result_h.VB_phi}
    store_data,'VB_phi_o1',data={x:result_o1.time, y:result_o1.VB_phi}
    store_data,'VB_phi_o2',data={x:result_o2.time, y:result_o2.VB_phi}
    store_data,'VB_phi',data=['VB_phi_h','VB_phi_o1','VB_phi_o2']
    ylim,'VB_phi',0,180,0
    options,'VB_phi','colors',icols
    options,'VB_phi','yticks',2
    options,'VB_phi','yminor',3
    options,'VB_phi','constant',[30,60,90,120,150]
    options,'VB_phi','labels',species
    options,'VB_phi','labflag',1
    pans = [pans, 'VB_phi']

; Shape Parameter

    store_data,'Shape_PAD2',data={x:result_h.time, y:transpose(result_h.shape^2.), v:[0,1]}
    ylim,'Shape_PAD2',0,5,0
    options,'Shape_PAD2','yminor',1
    options,'Shape_PAD2','constant',1
    options,'Shape_PAD2','ytitle','Shape'
    options,'Shape_PAD2','colors',[2,6]
    options,'Shape_PAD2','labels',['away','toward']
    options,'Shape_PAD2','labflag',1
    pans = [pans, 'Shape_PAD2']

    str_element, result_h, 'flux40', success=ok
    if (ok) then begin
      store_data,'flux40',data={x:result_h.time, y:result_h.flux40}
      ylim,'flux40',0.1,1000,1
      options,'flux40','ytitle','Eflux/1e5!c40 eV'
      options,'flux40','constant',1
      options,'flux40','colors',4

      store_data,'ratio',data={x:result_h.time, y:result_h.ratio}
      ylim,'ratio',0,2.5,0
      options,'ratio','ytitle','Flux Ratio!caway/twd!cPA 0-30'
      options,'ratio','constant',[0.75,1]
      options,'ratio','colors',4

      pans = [pans, 'flux40', 'ratio']
    endif

; Escape Flux

    flx_o2 = result_o2.den_i * result_o2.vbulk * 1.e5
    store_data,'mvn_sta_o2+_flux',data={x:result_o2.time, y:flx_o2}

    flx_o1 = result_o1.den_i * result_o1.vbulk * 1.e5
    store_data,'mvn_sta_o+_flux',data={x:result_o1.time, y:flx_o1}

    flx_h = result_h.den_i * result_h.vbulk * 1.e5
    store_data,'mvn_sta_p+_flux',data={x:result_h.time, y:flx_h}

    store_data,'flux_i+',data=['mvn_sta_p+_flux','mvn_sta_o+_flux','mvn_sta_o2+_flux']
    ylim,'flux_i+',1e4,1e10,1
    options,'flux_i+','ytitle','Ion Flux!ccm!u-2!ns!u-1!n'
    options,'flux_i+','colors',icols
    options,'flux_i+','labels',species
    options,'flux_i+','labflag',1
    pans = [pans, 'flux_i+']

; Spacecraft potential (when not otherwise available)

    store_data,'cio_scp',data={x:result_h.time, y:result_h.sc_pot}
    options,'cio_scp','ytitle','S/C Pot!cV'
    options,'cio_scp','constant',[0.]
    pans = [pans, 'cio_scp']

; Ephemeris and geometry

    slon = result_h.slon
    indx = where(slon lt 0., count)
    if (count gt 0L) then slon[indx] += 360.
    store_data,'Sun_GEO_Lon',data={x:result_h.time, y:slon}
    ylim,'Sun_GEO_Lon',0,360,0
    options,'Sun_GEO_Lon','yticks',4
    options,'Sun_GEO_Lon','yminor',3
    options,'Sun_GEO_Lon','psym',3
    options,'Sun_GEO_Lon','colors',5
    options,'Sun_GEO_Lon','ytitle','Sun Lon!cIAU_MARS'

    x = reform(result_h.geo[0])
    y = reform(result_h.geo[1])
    lon = atan(y,x)*!radeg
    indx = where(lon lt 0., count)
    if (count gt 0L) then lon[indx] += 360.
    store_data,'Mvn_GEO_Lon',data={x:result_h.time, y:lon}
    ylim,'Mvn_GEO_Lon',0,360,0
    options,'Mvn_GEO_Lon','yticks',4
    options,'Mvn_GEO_Lon','yminor',3
    options,'Mvn_GEO_Lon','psym',3
    options,'Mvn_GEO_Lon','colors',4
    options,'Mvn_GEO_Lon','ytitle','Mvn Lon!cIAU_MARS'

    store_data,'Lon_GEO',data=['Sun_GEO_Lon','Mvn_GEO_Lon']
    ylim,'Lon_GEO',0,360,0
    options,'Lon_GEO','colors',[5,4]
    options,'Lon_GEO','ytitle','Lon!cIAU_MARS'
    options,'Lon_GEO','labels',['Sun','Mvn']
    options,'Lon_GEO','labflag',1

    pans = ['Lon_GEO', pans]

    store_data,'Sun_PL_The',data={x:result_h.time, y:result_h.sthe}
    options,'Sun_PL_The','colors',4
    options,'Sun_PL_The','ynozero',1
    options,'Sun_PL_The','ytitle','Sun The!cS/C'
    pans = ['Sun_PL_The', pans]

  endif else pans = ''

  return

end
