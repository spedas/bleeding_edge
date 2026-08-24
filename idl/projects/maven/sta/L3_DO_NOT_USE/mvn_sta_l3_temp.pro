pro mvn_sta_l3_temp, trange=trange, success=temperature_success, savedir=tmpdir, stitch_only=stitch_only, vsTR=vSTR, $
spiceloaded=spiceloaded, parent_files=parent_files

;; generates STATIC temperatures to populate mvn_sta_temp_struct
;; trange : [t1, t2] part of the same day

;spiceloaded: set to a string array containing the names of SPICE kernels used for this run. This array will be stored in the preliminary
;             tplot density file, under the limit structure.
;
;parent_files: set to a string array containing the names of the STATIC L2 files used for this run. This array will be stored in the
;              preliminary tplot density file, under the limit structure.

if keyword_set(vSTR) then vv=vSTR else vv='03'
if size(spiceloaded, /type) eq 0 then spiceloaded = ''
if size(parent_files, /type) eq 0 then parent_files = ''

proname='mvn_sta_l3_temp'

startingtime=systime(/seconds) 

if size(tmpdir,/type) ne 0 then basedir=tmpdir else basedir ='/disks/data/maven/data/sci/sta/l3/temperature/'


common mvn_sta_temp, o2_temp
common mvn_c6, mvn_c6_ind, mvn_c6_dat
common mvn_c8, mvn_c8_ind, mvn_c8_dat
common mvn_d0, mvn_d0_ind, mvn_d0_dat
common mvn_d1, mvn_d1_ind, mvn_d1_dat
common mvn_sta_temp_error, sta_c6_errtime, sta_c6error, sta_c8_errtime, sta_c8error
common mvn_sta_vd_cmn, do_vd, sta_c6_vd, sta_c6_vd_errtime, sta_c6_vd_error, sta_c8_vd, sta_c8_vd_errtime, sta_c8_vd_error


loadct2, 43
colors = get_colors()
!p.background=255
!p.color=0

if keyword_set(trange) then begin
  tr = trange
endif else begin
  tr = minmax(mvn_c6_dat.time)
endelse

;dat=mvn_sta_get_c6(total(tr)/2.)
;if total(dat.bkg) eq 0 then begin
if total(mvn_c6_dat.bkg) eq 0 then begin
  print, proname, ": STATIC bkg has not been loaded. Make sure level iv data are available."
  success=0
  return
endif


  date=time_string(tr[0],prec=-3)
  ;yearmonth = time_string(date,prec=-4)
  ymdtmp = strsplit(date,'-',/extract)
  year=ymdtmp[0]
  month=ymdtmp[1]
  day=ymdtmp[2]
  
  checkdir1 = basedir+year+'/'+month
  checkdir2 = '/disks/data/maven/data/sci/sta/l3/temperature/full/'+year+'/'+month
  dir1 = file_search(checkdir1, count=ndir1)
  dir2 = file_search(checkdir2, count=ndir2)
  if ndir1 eq 0 then mvn_sta_makedir, basedir, year, month,group=1
  if ndir2 eq 0 then mvn_sta_makedir, '/disks/data/maven/data/sci/sta/l3/temperature/full/', year, month, group=1
  savedir = basedir+year+'/'+month+'/'
  ;savedir2 = '/mydisks/home/maven/gwen.hanley/idf/';'+year+'/'+month+'/
   savedir2 = '/disks/data/maven/data/sci/sta/l3/temperature/full/'+year+'/'+month+'/'
  
  fname='mvn_sta_l3_temp_'+year+month+day+'_v'+vv
  fname2='mvn_sta_l3_temp_'+year+month+day+'_full_v'+vv
  fname3='mvn_sta_l3_temp_'+year+month+day+'_gwen_v'+vv
  
        maven_orbit_tplot
        ylim, 'alt2', 150,500
        mvn_attitude_bar
        mvn_mag_load, 'L2_1sec', spice_frame='MSO'
        mvn_sta_c6_tplot
   
 get_data, 'mvn_sta_d1_E',tmp,tmp2
 if size(tmp2, /type) ne 4 then nod1 = 1 else nod1 = 0
  
  ;;;;;;;;; start doing the calculations unless the stitch_only keyword is set

	kk = mvn_sta_get_kk3(tr[0])
	
	if ~keyword_set(stitch_only) then begin

    ;; (1) ENERGY-BASED TEMPERATURE -- O2+ ONLY
    mvn_sta_ti_en
    
    ;; (2) ANGLE-BASED TEMPERATURE -- assumes everything is O2+
    ;;; this creates 'mvn_sta_c8_tp','mvn_sta_c8_o2+_tp_ana', 'mvn_sta_c8_o2+_tp_ana_only', $
    ;;;  'mvn_sta_c8_o2+_untempd', 'mvn_sta_c8_o2+_tempd', 'tperp_w_corr'
    mvn_sta_ti_an
  
    ;; (3) MOMENT CALCULATIONS FOR O2+ 
    
      mincnt = 50.
      bins = make_array(64)
      bins[29:30] = 1
      
      if nod1 then begin
        print, 'calculating temperature moment from d0 data'
        get_4dt, 't_4dg', 'mvn_sta_get_d0', name='mvn_sta_temp_moment_o2+_all', mass=[24.,40.], m_int=32., mincnt=mincnt
      endif else begin
        print, 'calculating temperature moment from d1 data'
        get_4dt, 't_4dg', 'mvn_sta_get_d1', name='mvn_sta_temp_moment_o2+_all', mass=[24.,40.], m_int=32., mincnt=mincnt
      endelse    ; nod1
      print, 'calculations done'

    endif else begin ;keyword_set(stitch_only)
      ;;; if you have the stitch_only keyword set, then you need to load the _full_ file
      fullfile = savedir+fname2+'.tplot'
      ftest = file_test(fullfile) 
      if ftest then tplot_restore,f=fullfile else message,'The data does not exist; turn off /stitch_only' 
    endelse
    
    
      print, 'stitching profiles together'

      mvn_sta_temp_stitch,/tails
                
      ;;; whenever you have all the data, update the structures by looping through the times

      get_data, 'mvn_sta_c6_o2+_temp', tpart, tpar
      get_data, 'mvn_sta_c6_o2+_temp_ac', tparc, cpar
      get_data, 'mvn_sta_c6_o2+_temp_statunc', tpare, epar
      get_data, 'mvn_sta_c8_temp', tperpt, tperp
      get_data, 'mvn_sta_c8_o2+_temp_ac', tperpc, cperp
      get_data, 'mvn_sta_c8_temp_statunc', tperpe, eperp
      get_data, 'mvn_sta_temp_moment_o2+_all', tmomat, tmoma

      makegap,4.,tmomat,tmoma

      ;;; put in error handling for if one of the times is undefined

      ;    alltimes = [tperpt, tpart, tmomat, tmom10t, tmom20t]
      alltimes = [tperpt, tpart, tmomat]
      tstruct = alltimes[uniq(alltimes, sort(alltimes))] ;;1 monotonic copy of each unique time in alltimes

      tstruct = tstruct[where(tstruct gt 0)]
      
      result=mvn_sta_temp_struct(n_elements(tstruct))

;  temp_str = {time     : dNaN        , $   ; time
;    temp     : NaN         , $   ; best estimate of core temperature
;    dtemp    : NaN         , $   ; uncertainty of core temperature
;    kintemp  : NaN4        , $   ; kinetic temperature
;    prod     : NaN         , $   ; which temperature product is used; 0=c6;1=c8;2,3,4=d1/d0
;    c6t      : NaN         , $   ; corrected c6 (energy) beamwidth temperature (eV)
;    c6c      : NaN         , $   ; correction to c6 beamwidth temperature (eV)
;    c6e      : NaN         , $   ; statistical error in c6 beamwidth temperature (eV)
;    c8t      : NaN         , $   ; corrected c8 (angular) beamwidth temperature (eV)
;    c8c      : NaN         , $   ; correction to c8 beamwidth temperature (eV)
;    c8e      : NaN,        , $   ; statistical error in c8 beamwidth temperature (eV)
;;    dt10     : NaN4        , $   ; d1/d0 temperature moment restricted from 0 to 10 eV (eV)
;;    dt20     : NaN4        , $   ; d1/d0 temperature moment restricted from 0 to 20 eV (eV)
;    dt       : NaN4        , $   ; d1/d0 temperature moment including all energies (eV)
;;    dt30r    : NaN4        , $   ; d1/d0 temperature moment restricted from 0 to 30 eV and to the ram direction (eV)
;    dtc       : NaN         , $   ; correction to d0/d1 temperature (eV)
;    dte       : NaN         , $   ; statistical error in d0/d1 temperature (eV)
;;    modech   : NaN         , $   ; 1 if near mode/attenuator state change
;    locnts   : NaN         , $   ; 1 it O2+ counts are low
;    bigcorr  : NaN         , $   ; 1 if correction to provided temperature is >80%
;    badscpot : NaN         , $   ; 1 if lpw data missing or scpot is too large
;    vbulk    : NaN         , $   ; 1st moment of df used in tbc calculation
;    vbulke   : NaN         , $   ; statistical error in the above
;    df_engy  : NaN32       , $   ; c6 energy table for the df
;   df       : NaN32       , $   ; c6 df integrated over masses [24,40]
;    core_A   : NaN         , $   ; amplitude of the Maxwellian fit to the core (c6 df units)
;   core_T   : NaN         , $   ; temperature of the Maxwellian fit to the core (eV)
;   core_v   : NaN         , $   ; bulk velocity of the Maxwellian fit to the core (km/s)
;  eflux_ratio: NaN       , $   ; ratio of the eflux in the tail to the eflux in the core
;    ec_o2    : NaN         , $   ; characteristic energy of O2+ distribution (eV) 
;    ec_o     : NaN         , $   ; characteristic energy of O+ distribution (eV) 
;    att      : NaN         , $   ; STATIC attenuator state
;    mode     : NaN         , $   ; STATIC mode
;;    fovf     : NaN         , $   ; field-of-view flag from Fowler code checking STATIC FOV
;    tail     : NaN         , $   ; 1 if a significant portion of eflux is in a suprathermal tail
;    tpath    : NaN         , $   ; path taken through temp stitching code
;    magf     : NaN3        , $   ; magnetic field in MSO frame (nT)
;    sc_pot   : NaN         , $   ; spacecraft potential (V)
;    mass     : NaN         , $   ; assumed ion mass (amu)
;    mrange   : [NaN,NaN]   , $   ; mass range for N, V, and T moments (amu)
;    erange   : [NaN,NaN]   , $   ; energy range for V and T moments (eV)
;    frame    : ''          , $   ; reference frame for all vectors (except as noted)
;    shape    : [NaN,NaN]   , $   ; e- shape parameter [away, toward]
;    ratio    : NaN         , $   ; e- flux ratio (away/toward)
;    flux40   : NaN         , $   ; e- energy flux at 40 eV
;    topo     : 0           , $   ; magnetic topology index (Xu-Weber method)
;    region   : 0           , $   ; plasma region index (Halekas method)
;    imf_clk  : NaN         , $   ; clock angle of upstream IMF (0 = east, pi = west)
;    sw_press : NaN         , $   ; dynamic pressure of upstream solar wind (nPa)
;    mso      : NaN3        , $   ; MSO coordinates of spacecraft
;    mse      : NaN3        , $   ; MSE coordinates of spacecraft
;    geo      : NaN3        , $   ; GEO coordinates of spacecraft
;    alt      : NaN         , $   ; spacecraft altitude (ellipsoid)
;    slon     : NaN         , $   ; GEO longitude of sub-solar point
;    slat     : NaN         , $   ; GEO latitude of sub-solar point
;    Mdist    : NaN         , $   ; Mars-Sun distance (A.U.)
;    L_s      : NaN         , $   ; Mars season (L_s)
;    sza      : NaN         , $   ; solar zenith angle
;    lst      : NaN         , $   ; local solar time
;    sthe     : NaN         , $   ; elevation of Sun in s/c frame (SWEA twist)
;    sthe_app : NaN         , $   ; elevation of Sun in APP frame (STA CIO config)
;    rthe_app : NaN         , $   ; elevation of MSO RAM in APP frame (STA CIO config)
;    inbound  : NaN         , $   ; 1 if inbound portion of orbit, 0 if outbound 
;    valid    : 0              }

    get_data, 'mvn_sta_o2+_temp', tstitch,tempstitch
    get_data, 'mvn_sta_o2+_temp_unc',dtstitch, dtempstitch
    get_data, 'mvn_sta_temp_product',tmp,tempprod
    get_data, 'mvn_sta_o2+_kintemp',tkintemp,kintemp
    ; get the flags

    
    get_data, 'mvn_sta_c6_o2+_ec',ect,ec
    get_data, 'mvn_sta_c6_att', attt, att
    get_data, 'mvn_sta_c6_mode', modet, mode
    get_data, 'mvn_sta_temp_path',tmp,tpath
    get_data, 'mvn_sta_c6_scpot', scpott, scpot
    get_data, 'cntflag', cntft, cntf
    get_data, 'modeflag', modeft, modef
    get_data, 'corrflag', corrft, corrf
    get_data, 'scpotflag', scpotft, scpotf
    get_data, 'tailflag', tailt, tailflag
    get_data, 'eflux_ratio_tail_to_core', efluxtime, eflux_ratio
    get_data, 'core_A', coretime, core_A
    get_data, 'core_T', coretime, core_T
    get_data, 'core_v', coretime, core_v
     get_data, 'lpw_scpot', coretime, lpw_scpot, c6_df_engy
    get_data, 'c6_df', coretime, c6_df, c6_df_engy 
   
 
    store_data, 'mvn_sta_c6_scpotneg', data={x:scpott,y:-1*scpot} 
    store_data, 'mvn_sta_c6_E_m32e', data=['mvn_sta_c6_E_m32', 'mvn_sta_c6_o2+_ec']
    store_data, 'mvn_sta_c6_E_m32_scpot',data=['mvn_sta_c6_E_m32','mvn_sta_c6_scpotneg']
    store_data,'mvn_sta_c6_mode_att',data={x: modet, y: [ [mode] , [att] ]}
    ylim, 'mvn_sta_c6_E_m32e', 0.1,100.,1
    ylim, 'mvn_sta_c6_E_m32_scpot',0.1,100.,1
    
    result.time = tstruct
    
    tind = nn2(tstitch,tstruct)
    result.temp = tempstitch[tind]
    result.dtemp = dtempstitch[tind]
    result.prod = tempprod[tind]
    result.tpath = tpath[tind]

    for j=0,n_elements(tstruct)-1 do begin
      
      tind = where(tstruct[j] eq tstitch)

      if tind ne -1 then begin
        ;if finite(tempstitch[tind]) then stop
      
        result[j].temp = tempstitch[tind]
        result[j].prod = tempprod[tind]
        result[j].tpath = tpath[tind]
      endif
      
      
        tind = where(tstruct[j] eq tpart) 
        if tind ne -1 then result[j].c6t = tpar[tind] & result[j].vbulk = sta_c6_vd[tind] & result[j].vbulke = sta_c6_vd_error[tind+1]
        tind = where(tstruct[j] eq tparc)
        if tind ne -1 then result[j].c6c = cpar[tind]
        tind = where(tstruct[j] eq tpare)
        if tind ne -1 then result[j].c6e = epar[tind]
        
        tind = where(tstruct[j] eq coretime)
        if tind ne -1 then result[j].core_A = core_A[tind] & result[j].core_T = core_T[tind] & $
         result[j].core_v = core_v[tind] & result[j,*].df = transpose(c6_df[tind,*]) & $
         result[j,*].df_engy = transpose(c6_df_engy[tind,*]) & result[j,*].lpw_scpot = transpose(lpw_scpot[tind,*])

        tind = where(tstruct[j] eq efluxtime)
        if tind ne -1 then result[j].eflux_ratio = eflux_ratio[tind]
     
      
        tind = where(tstruct[j] eq tperpt)
        if tind ne -1 then result[j].c8t = tperp[tind]
        if tind ne -1 then result[j].c8e = eperp[tind]
        tind = where(tstruct[j] eq tperpc)
        if tind ne -1 then result[j].c8c = cperp[tind]
        ;tind = where(tstruct[j] eq tperpe)       
      
      
      
        tind = where(tstruct[j] eq tmomat)
        if n_elements(tind) eq 1 then begin
		if tind ne -1 then result[j].dt = tmoma[tind,*]
	endif
	tind = where(tstruct[j] eq tkintemp)
        if n_elements(tind) eq 1 then begin
		if tind ne -1 then result[j].kintemp = kintemp[tind,*]
	endif
        ;; d corrections

      
      tind = where(tstruct[j] eq ect)
      if tind ne -1 then result[j].ec_o2 = ec[tind]
      tind = where(tstruct[j] eq modet)
      if tind ne -1 then result[j].mode = mode[tind] 
      tind = where(tstruct[j] eq attt)
      if tind ne -1 then result[j].att = att[tind]
      tind = where(tstruct[j] eq scpott)
      if tind ne -1 then result[j].sc_pot = scpot[tind]
      tind = where(tstruct[j] eq scpotft)
      if tind ne -1 then result[j].badscpot = scpotf[tind]
      tind = where(tstruct[j] eq cntft)
      if tind ne -1 then result[j].locnts = cntf[tind]
;      tind = where(tstruct[j] eq modeft)
;      if tind ne -1 then result[j].modech = modef[tind]
      tind = where(tstruct[j] eq corrft)
      if tind ne -1 then result[j].bigcorr = corrf[tind]
      tind = where(tstruct[j] eq tailt)
      if tind ne -1 then result[j].tail = tailflag[tind]

     endfor ;; loop through day 
 
      result.mass = 32.
      result.mrange = [28.,40.]
      tmp=where(result.prod eq 0 or result.prod eq 1)
      result[tmp].erange = [0.,30.]
      tmp=where(result.prod eq 2)
      result[tmp].erange = [0.,10.]
      tmp=where(result.prod eq 2)
      result[tmp].erange = [0.,20.]
      tmp=where(result.prod eq 4)
      result[tmp].erange = [0.,1000000.]
      
      ;;; now all the STATIC temp fields of the result structure are populated so update the ephs
      ;;; info if that option is set
      
      ;    magf     : NaN3        , $   ; magnetic field in MSO frame (nT)
      ;      frame    : ''          , $   ; reference frame for all vectors (except as noted)
      ;      shape    : [NaN,NaN]   , $   ; e- shape parameter [away, toward]
      ;      ratio    : NaN         , $   ; e- flux ratio (away/toward)
      ;      flux40   : NaN         , $   ; e- energy flux at 40 eV
      ;      topo     : 0           , $   ; magnetic topology index (Xu-Weber method)
      ;      region   : 0           , $   ; plasma region index (Halekas method)
      ;      imf_clk  : NaN         , $   ; clock angle of upstream IMF (0 = east, pi = west)
      ;      sw_press : NaN         , $   ; dynamic pressure of upstream solar wind (nPa)
      ;      mso      : NaN3        , $   ; MSO coordinates of spacecraft
      ;      mse      : NaN3        , $   ; MSE coordinates of spacecraft
      ;      geo      : NaN3        , $   ; GEO coordinates of spacecraft
;		vsc_mso  : NaN3	   , $   ; MSO velocity of spacecraft
      ;      alt      : NaN         , $   ; spacecraft altitude (ellipsoid)
      ;      slon     : NaN         , $   ; GEO longitude of sub-solar point
      ;      slat     : NaN         , $   ; GEO latitude of sub-solar point
      ;      Mdist    : NaN         , $   ; Mars-Sun distance (A.U.)
      ;      L_s      : NaN         , $   ; Mars season (L_s)
      ;      sza      : NaN         , $   ; solar zenith angle
      ;      lst      : NaN         , $   ; local solar time
      ;      sthe     : NaN         , $   ; elevation of Sun in s/c frame (SWEA twist)
      ;      sthe_app : NaN         , $   ; elevation of Sun in APP frame (STA CIO config)
      ;      rthe_app : NaN         , $   ; elevation of MSO RAM in APP frame (STA CIO config)
      ;      valid    : 0              }

      ;;; calculate some parameters for O+ too 
      get_4dt,'ec_4d','mvn_sta_get_c6',mass=[12.,20.],name='mvn_sta_c6_o+_ec',m_int=16.,mincnt=50.,gap_time=5.
      get_data,'mvn_sta_c6_o+_ec',eco_time, eco
      tind = nn2(eco_time, tstruct)
      result.ec_o = eco[tind]
      
      ;; get the magnetic field at the right timestamps
      
      get_data, 'mvn_B_1sec_MAVEN_MSO', magtime, mag
      maginterp = interp(mag, magtime, tstruct)

      result.magf = transpose(maginterp)
      result.frame='MSO'
      
      ;; get the FOV flag at the right timestamps
;      get_data, 'mvn_sta_FOV_flag_mr(0.0,100.0)_er(0.0,1000000.0)', fovt,fov
;      tind = value_locate(fovt,tstruct)      
;      ; not really an interpolation, since the value is an integer
;      fovinterp = fov[tind]
;      fovinterp[where(tind eq -1)] = !values.F_NAN
;      result.fovf = fovinterp 
      
      ;; much of what follows is stolen from mvn_sta_coldion -- thanks Dave! 
      
       ;Spacecraft potential (fill in missing values)

      ;indx = where(~finite(result.sc_pot), count)
      ;if (count gt 0L) then result[indx].sc_pot = mvn_get_scpot(tstruct[indx])
            
     ; Shape parameter (Xu method)
    
      mvn_swe_shape_restore, /tplot, parng=parng, result=shape
      
      
      if (size(shape,/type) eq 8) then begin
;        shp = smooth_in_time(transpose(shape.shape[0:1,parng]), shape.t, dt)
        shp = transpose(shape.shape[0:1,parng])
        result.shape[0] = interpol(shp[*,0], shape.t, result.time)
        result.shape[1] = interpol(shp[*,1], shape.t, result.time)
       
;        f40 = smooth_in_time(shape.f40, shape.t, dt)
        result.flux40 = interpol(shape.f40, shape.t, result.time)/1.e5
    
;        frat40 = smooth_in_time(shape.fratio_a2t[0,parng], shape.t, dt)
        frat40 = shape.fratio_a2t[0,parng]
        result.ratio = 1./interpol(frat40, shape.t, result.time)
      endif else print,'Could not get shape parameter.'
    
    ; Topology Index (Xu-Weber method)
    ;   All types of closed loops (DD, DN, NN, TRP) are combined into one.
    ;   0 = unknown, 1 = closed, 2 = open to day, 3 = open to night, 4 = draped
    
      mvn_swe_topo, result=topo, /filter_reg, /storeTplot
      if (size(topo,/type) eq 8) then begin
        ttime = topo.time
        topo = round(topo.topo)
        indx = where((topo ge 1) and (topo le 4), count)  ; closed loops
        if (count gt 0) then topo[indx] = 1
        indx = where(topo eq 5, count)       ; open to day
        if (count gt 0) then topo[indx] = 2
        indx = where(topo eq 6, count)       ; open to night
        if (count gt 0) then topo[indx] = 3
        indx = where(topo eq 7, count)       ; draped
        if (count gt 0) then topo[indx] = 4
    
;        dtt = ttime - shift(ttime,1)
;        dtt = median(dtt[1:*])
;        nfilter = round(dt/dtt)
;        if ~(nfilter mod 2) then nfilter++
;        topo = round(median(topo, nfilter))  ; dt-width median filter
;    
        indx = nn2(ttime, tstruct)
        result.topo = topo[indx]
      endif else print,'Could not get topology information.'
    
    ; Plasma Region (Halekas method)
    ;   Both ionosphere indices are combined into one.
    ;   0 = unknown, 1 = solar wind, 2 = sheath, 3 = ionosphere, 4 = tail lobe
    
      get_data,'reg_id',data=reg_id
      if (size(reg_id,/type) eq 8) then begin
;        dtt = reg_id.x - shift(reg_id.x,1)
;        dtt = median(dtt[1:*])
;        nfilter = round(dt/dtt)
;        if ~(nfilter mod 2) then nfilter++
;        region = round(median(reg_id.y, nfilter))  ; dt-width median filter
;        
        region = reg_id.y
        indx = nn2(reg_id.x, tstruct)
        result.region = region[indx]
      endif else print,'Could not get plasma region information.'
    
    ; Upstream drivers (direct and proxy)
    
     ; path = root_data_dir() + 'maven/data/sci/swe/l3/'
     tplot_restore, file='/disks/data/maven/data/sci/swe/l3/drivers_merge_l2.tplot'  ; direct (Halekas)
      ngud = 0L
      get_data, 'bsw', data=imf, index=i
      if (i gt 0) then begin
        dtmax = 5D*3600D  ; within 5 hours of sw measurement
        By = interp(imf.y[*,1], imf.x, tstruct, int=dtmax)
        Bz = interp(imf.y[*,2], imf.x, tstruct, int=dtmax)
    
        gap = where(~finite(By) or ~finite(Bz), ngap)
        if (ngap gt 0) then begin
          restore, '/disks/data/maven/data/sci/swe/l3/mag_sheath.sav' 
          if (size(mag_sheath,/type) eq 8) then begin
            By[gap] = interp(mag_sheath.mag[*,1], mag_sheath.time, tstruct[gap], int=dtmax)
            Bz[gap] = interp(mag_sheath.mag[*,2], mag_sheath.time, tstruct[gap], int=dtmax)
          endif else print,'Could not get solar wind proxy database.'
        endif
    
        Bclk = atan(Bz,By)  ; radians (0 = east, pi = west)
        result.imf_clk = Bclk
    
        igud = where(finite(Bclk), ngud)
        if (ngud gt 0L) then begin
          cosclk = cos(Bclk)
          sinclk = sin(Bclk)
        endif
    
        get_data, 'npsw', data=npsw, index=i
        Np = interp(npsw.y, npsw.x, tstruct, int=dtmax)  ; cm-3
        get_data, 'vpsw', data=vpsw, index=i
        Vp = interp(vpsw.y, vpsw.x, tstruct, int=dtmax)  ; km/s
    
        Psw = (1.67e-6) * (Np*Vp*Vp)  ; nPa
        result.sw_press = Psw  
      endif else print,'Could not get upstream drivers database.'
      
      ;; geo information
      
      get_mvn_eph, tstruct, eph, /silent
      result.mso = transpose([ [eph.x_ss], [eph.y_ss], [eph.z_ss] ])
      result.geo = transpose([ [eph.x_pc], [eph.y_pc], [eph.z_pc] ])
      result.alt = eph.alt
      result.sza = eph.sza*!radeg
      result.lst = eph.lst 
      
      vsc_mso = transpose([ [eph.vx_ss], [eph.vy_ss], [eph.vz_ss] ])
      vsc_sta = spice_vector_rotate(vsc_mso, tstruct, 'MSO','MAVEN_STATIC',check_objects='MAVEN_SPACECRAFT')
      result.vsc_sta = vsc_sta
      
      inds_tplot=nn2(tstruct,tstitch)
      
      store_data,'mvn_sta_anc_mvn_pos_mso',data={x:tstruct[inds_tplot], y: transpose(result[inds_tplot].mso)}
      store_data,'mvn_sta_anc_mvn_pos_geo',data={x:tstruct[inds_tplot], y: transpose(result[inds_tplot].geo)}
      store_data,'mvn_sta_anc_mvn_alt_iau',data={x:tstruct[inds_tplot], y: result[inds_tplot].alt}
      store_data,'mvn_sta_anc_mvn_sza',data={x:tstruct[inds_tplot], y: result[inds_tplot].sza}
      store_data,'mvn_sta_anc_mvn_lst',data={x:tstruct[inds_tplot], y: result[inds_tplot].lst} 
      
      if (ngud gt 0L) then begin
        result[igud].mse[0] = result[igud].mso[0]
        result.mse[1] = cosclk*result.mso[1] + sinclk*result.mso[2]
        result.mse[2] = cosclk*result.mso[2] - sinclk*result.mso[1]
      endif
      
      ; Direction of Sun in IAU_MARS frame (orientation of crustal fields)

      s_mso = [1D, 0D, 0D] # replicate(1D, n_elements(tstruct))
      s_geo = spice_vector_rotate(s_mso, tstruct, 'MAVEN_MSO', 'IAU_MARS')
      s_lon = reform(atan(s_geo[1,*], s_geo[0,*])*!radeg)
      s_lat = reform(asin(s_geo[2,*])*!radeg)

      result.slon = s_lon
      result.slat = s_lat

      ; Mars season (Ls)

      L_s = mvn_ls(tstruct)
      result.L_s = L_s

      ; Mars-Sun distance

      au = 1.495978707d8  ; Astronomical Unit (km)
      odat = mvn_orbit_num()
      Mdist = interp(odat.sol_dist, odat.peri_time, tstruct)/au

      result.Mdist = Mdist

      ; Elevation angle of the Sun in the spacecraft frame
      ;   0 deg = x-y plane ; +90 deg = +z
      ;   cold-ion configuration is +45 deg for twist, +90 deg for no-twist

      get_data,'Sun_SWEA_The',data=sthe_swe,index=i
      if (i eq 0) then begin
        mvn_sundir, frame='swe', /polar
        get_data,'Sun_SWEA_The',data=sthe_swe,index=i
      endif
      if (i gt 0) then begin
        indx = where(finite(sthe_swe.y), count)
        if (count gt 0) then begin
          result.sthe = spline(sthe_swe.x[indx], sthe_swe.y[indx], tstruct)
        endif else print,'MVN_STA_L3_TEMP: Failed to get Sun (PL) direction!'
      endif else print,'MVN_STA_L3_TEMP: Failed to get Sun (PL) direction!'

      ; Elevation angle of the Sun in the APP frame
      ;   0 deg = i-j plane ; +90 deg = +k
      ;   cold-ion configuration is ~0 deg

      mvn_sundir, frame='app', /polar
      get_data,'Sun_APP_The',data=sthe_app,index=i
      if (i gt 0) then begin
        indx = where(finite(sthe_app.y), count)
        if (count gt 0) then begin
          result.sthe_app = spline(sthe_app.x[indx], sthe_app.y[indx], tstruct)
        endif else print,'MVN_STA_L3_TEMP: Failed to get Sun (APP) direction!'
      endif else print,'MVN_STA_L3_TEMP: Failed to get Sun (APP) direction!'

      ; Elevation angle of MSO RAM in the APP frame
      ;   0 deg = i-j plane ; +90 deg = +k
      ;   cold-ion configuration is ~0 deg

      mvn_ramdir, /mso, frame='app', /polar
      get_data,'V_sc_APP_The',data=rthe_app,index=i
      if (i gt 0) then begin
        indx = where(finite(rthe_app.y), count)
        if (count gt 3) then begin
          result.rthe_app = spline(rthe_app.x[indx], rthe_app.y[indx], tstruct)
        endif else print,'MVN_STA_L3_TEMP: Failed to get MSO RAM direction!'
      endif else print,'MVN_STA_L3_TEMP: Failed to get MSO RAM direction!'
      
      ; inbound/outbound
      inout = shift(result.alt,1) - result.alt
      
      inbnd = where(inout gt 0.)
      outbnd = where(inout lt 0.)
      tmp = where(inout eq 0.)
      result[inbnd].inbound=1
      result[outbnd].inbound=0
      result[tmp].inbound=result[(tmp-1)>0].inbound
      
      inout = result[1].alt - result[0].alt
      if inout gt 0 then result[0].inbound = 0 else result[0].inbound = 1
      ; that's it! 
      
      
      ; if it got through the tempstitch routine then it's valid 
      result[where(finite(result.tpath))].valid = 1
      
      ;Add spiceloaded and parent_files to mvn_sta_o2+_temp: (goes to limits structure)
      options, 'mvn_sta_o2+_temp', 'spiceloaded', spiceloaded
      options, 'mvn_sta_o2+_temp', 'parent_files', parent_files
     
     
;;; save the structure 

  save, result, file=savedir+fname3+'.sav'
  
;  tplot_save,['mvn_sta_o2+_temp', $
;    'mvn_sta_o2+_temp_flag', 'mvn_sta_o2+_temp_unc', $
;    'mvn_sta_anc_mvn_pos_geo', 'mvn_sta_anc_mvn_pos_mso', 'mvn_sta_anc_mvn_alt_iau', 'mvn_sta_anc_mvn_sza', 'mvn_sta_anc_mvn_lst'],file=savedir+fname
;  
  tplot_save,['mvn_sta_c6_o2+_tparu','mvn_sta_c6_o2+_temp_statunc','mvn_sta_c6_o2+_temp_ac', 'mvn_sta_c6_o2+_temp', $ ;; c6 beamwidth 
    'mvn_sta_c6_o2+_ec','mvn_sta_c6_o2+_de_swp', 'mvn_sta_c6_ti_kk3', 'mvn_sta_c6_o2+_de_fwhm_scat','ana_de_fwhm_c6','mvn_sta_c6_o2+_temp_ana_response', $ ;; c6 correction terms
    'mvn_sta_c6_o2+_temp_nolpw', 'mvn_lpw_pot_c6', $ ;; c6 lpw corrections
    'mvn_sta_c8_tperpu','mvn_sta_c8_temp_statunc', 'mvn_sta_c8_o2+_temp_ac', 'mvn_sta_c8_temp', $ ;; c8 beamwidth
    'mvn_sta_c8_tp_kk3','mvn_sta_c8_o2+_de_fwhm_scat','ana_dth_fwhm','ana_dth_fwhm_corr', 'mvn_sta_c8_o2+_tp_ana_response', $ ;; c8 correction terms
      'mvn_sta_temp_moment_o2+_all', $ ;; moment from d0/d1
    'mvn_sta_o2+_temp_preclean', 'mvn_sta_o2+_temp', 'mvn_sta_o2+_kintemp', $ ;; stitched temperatures
    'mvn_sta_temp_product', 'mvn_sta_temp_path', $ ;; housekeeping
    'tailflag', 'eflux_ratio_tail_to_core',$ ;; tail flag
    'cntflag', 'corrflag', 'scpotflag', 'mvn_sta_o2+_temp_flag', 'mvn_sta_o2+_temp_unc',$
    'core_A','core_T','core_v','mvn_sta_c6_o+_ec', 'mvn_sta_ramdir_angle', $;; other flags
    'mvn_sta_anc_mvn_pos_geo', 'mvn_sta_anc_mvn_pos_mso', 'mvn_sta_anc_mvn_alt_iau', 'mvn_sta_anc_mvn_sza', 'mvn_sta_anc_mvn_lst', $
    'mvn_sta_c6_mode','mvn_sta_c6_att','mvn_sta_c6_mode_att'],file=savedir+fname2 
 ; tplot_save,file=savedir+fname2
  totaltime = systime(/seconds)-startingtime
  print, totaltime
 
  end
