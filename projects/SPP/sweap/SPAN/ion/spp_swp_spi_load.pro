; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-12-01 15:22:09 -0800 (Wed, 01 Dec 2021) $
; $LastChangedRevision: 30445 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-
pro diagonalize_tensor,tensor,eigen_val,eigen_vec
  
  dim = size(/dimen,tensor)
  np = dim[0]
  tmap = [[0,3,4],[3,1,5],[4,5,2]]
  if dim[1] ne 6 then message,'error'
  eig_val= fltarr(3)
  eig_vec= fltarr(3,3)
  for i=0L,np-1 do begin
    t6 = tensor[i,*]     
    t3x3  = t6[tmap]
    ;p = [[p(0),p(3),p(4)],[p(3),p(1),p(5)],[p(4),p(5),p(2)]]

    trired,t3x3,val,vec
    triql,val,vec,t3x3
    
    s = sort(val)
    p = t3x3
    p= p[*,s]
    val= val[s]

    if (val[2]-val[1] gt val[1]-val[0]) then begin
      eig_val[0]= val[2]
      eig_val[1]= val[0]
      eig_val[2]= val[1]
      eig_vec[*,0]= vec[*,2]
      eig_vec[*,1]= vec[*,0]
      eig_vec[*,2]= vec[*,1]
    endif else begin
      eig_val= val
      eig_vec= vec
    endelse
    
    
    stop
  endfor




end




pro spp_swp_spi_load,types=types,level=level,trange=trange,no_load=no_load,tname_prefix=tname_prefix,save=save,$
  verbose=verbose,varformat=varformat,fileprefix=fileprefix,overlay=overlay,spcname=spcname, $
  diag=diag,sc_frame=sc_frame,sc2_frame=sc2_frame,rtn_frame=rtn_frame,magname=magname

  if ~keyword_set(level) then level='L3'
  level=strupcase(level)
  if ~keyword_set(types) then types=['sf00']  ;,'sf01','sf0a']

  if types[0] eq '*' || types[0] eq 'all' then begin
    types=['hkp','fhkp','tof','rates','events']
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1','2'] do foreach type3,['0','1','2','3','a'] do types=[types,type0+type1+type2+type3]
  endif

  ;; Product File Names
  ;dir='spi/'+level+'/YYYY/MM/spi_TYP/' ;old directory structure
  dir='spi/'+level+'/spi_TYP/YYYY/MM/'
  fileformat=dir+'psp_swp_spi_TYP_'+level+'*_YYYYMMDD_v??.cdf'
  if not keyword_set(fileprefix) then fileprefix='psp/data/sci/sweap/'

  ;; Product TPLOT Parameters
  vars = orderedhash()
  vars['hkp']    = '*TEMP* *_BITS *_FLAG* RAW_EVENTS'
  vars['fhkp']   = 'ADC'
  vars['tof']    = 'TOF'
  vars['rates']  = '*_CNTS'
  vars['events'] = 'TOF DT CHANNEL

  tr=timerange(trange)
  foreach type,types do begin

    ;; Instrument string substitution
    filetype=str_sub(fileformat,'TYP',type)

    ;; Find file locations
    dprint,filetype,/phelp
    files=spp_file_retrieve(filetype,trange=tr,/daily_names,/valid_only,/last_version,prefix=fileprefix,verbose=verbose)

    if keyword_set(save) then begin
      vardata = !null
      novardata = !null
      loadcdfstr,filenames=files,vardata,novardata
      source=spp_data_product_hash('spi_'+type+'_'+level,vardata)
      ;printdat,source
    endif

    prefix='psp_swp_spi_'+type+'_'+level+'_'
    if keyword_set(tname_prefix) then prefix=tname_prefix+prefix

    if keyword_set(no_load) then continue ;Do not load the files

    ;; Load TPLOT Formats
    if keyword_set(varformat) then varformat2=varformat else if vars.haskey(type) then varformat2=vars[type] else varformat2=[]

    ;; Convert to TPLOT
    cdf2tplot,files,prefix=prefix,varformat=varformat2,verbose=verbose
    spp_swp_qf,prefix=prefix
    options,/def,prefix+'VEL'   ,colors='bgr',labels=['Vx','Vy','Vz'],labflag=-1
    options,/def,prefix+'MAGF_'+['SC','INST'],colors='bgr',labels=['Bx','By','Bz'],labflag=-1

    if keyword_set(overlay) then begin   ; && strmatch(type,'[sa]f??')
      xyz_to_polar,prefix+'VEL'
      get_data,prefix+'VEL_mag',time,vel_mag
      mass = 1836*511000. / (299792.^2)  ; mass/q of proton
      if strmatch(type,'??0[1a]') then mass= mass*2
      store_data,prefix+'NRG0',time,velocity(vel_mag,mass,/inverse)
      vname_nrg = prefix+['EFLUX_VS_ENERGY','NRG0']
      vname_th  = prefix+['EFLUX_VS_THETA','VEL_th']
      vname_phi = prefix+['EFLUX_VS_PHI','VEL_phi']

      if keyword_set(spcname) then begin   ; add SPC data
        if ~isa(spcname,/string) then spcname = 'psp_swp_spc_l3i_vp_moment_SC'
        dat = data_cut(spcname,time)       ; interpolate onto span timescale
        if keyword_set(dat) then begin
          store_data,prefix+'SPCVEL',time,dat
          rotmat = [[0.0,      0.,       1.],[  -0.93969262,  0.34202014,  0.],[ -0.34202014 , -0.93969262, 0.]]
          newname = rotate_data(prefix+'SPCVEL',rotmat,name='SPI' )   ;,repname='_SC')
          xyz_to_polar,newname,/ph_0_360
          get_data,newname+'_mag',time,vel_mag
          mass = .0104
          charge = 1
          if type eq 'sf0a' then begin
            mass =mass*4
            charge=charge * 2
          endif
          store_data,newname+'_nrg',time,velocity(vel_mag,mass/charge,/inverse)
          options,newname+'_*',colors='b'
          vname_nrg = [vname_nrg,newname+'_nrg']
          vname_th = [vname_th,newname+'_th']
          vname_phi = [vname_phi,newname+'_phi']
        endif
      endif

      store_data,prefix+'EFLUX_VS_ENERGY_OVL',data = vname_nrg,dlimit={yrange:[50.,20000.],ylog:1,zlog:1,ystyle:3}
      store_data,prefix+'EFLUX_VS_THETA_OVL',data =vname_th ,dlimit={yrange:[-60,60],ylog:0,zlog:1,ystyle:3}
      store_data,prefix+'EFLUX_VS_PHI_OVL',data = vname_phi,dlimit={yrange:[90.,190.],ylog:0,zlog:1,ystyle:3}
    endif

    if keyword_set(0) then begin
;      diag_t,'psp_swp_spi_sf00_L2B_T_TENSOR'
;      options,'T_diag',colors='bgr',yrange=[0.,150]
      get_data,'psp_swp_spi_sf00_L2B_MAGF_INST',data=mag
;      get_data,'Saxis',data=sym
;      ang = acos(abs(total(mag.y * sym.y,2))/sqrt(total(mag.y ^2,2) )  )  * 180/3.1416
;      store_data,'angle',mag.x,ang;,dlim={
       get_data,'psp_swp_spi_sf00_L2B_T_TENSOR',data=ttens
       diagonalize_tensor, ttens,rotmat,t3
       sym = rotmat
     ;  store_data,
 stop

    endif

    if keyword_set(diag) then begin
      diag_t,'psp_swp_spi_sf00_L2B_T_TENSOR'
      options,'T_diag',colors='bgr',yrange=[0.,150]
      get_data,'psp_swp_spi_sf00_L2B_MAGF_INST',data=mag
      get_data,'Saxis',data=sym
      ang = acos(abs(total(mag.y * sym.y,2))/sqrt(total(mag.y ^2,2) )  )  * 180/3.1416
      store_data,'angle',mag.x,ang;,dlim={
   ;   get_data,'psp_swp_spi_sf00_L2B_T_TENSOR',data=ttens
 
    endif

    if keyword_set(SC_frame) || keyword_set(rtn_frame) then begin
      rot_th = 20. ; rotation angle
      rotr = [[1,0,0.],[0,cosd(rot_th),sind(rot_th)],[0,-sind(rot_th),cosd(rot_th)]]
      rel = [[0,-1,0],[0,0,-1],[1,0,0]]    ; effective relabelling of axes
      RotMat_inst_sc = rel ## rotr ; transformation matrix from ion instrument coordinates TO spacecraft
      get_data,prefix+'VEL',data = spi_VEL
      spi_vel.y = rotmat_inst_sc ## spi_vel.y
      store_data,prefix+'VEL_SC',data = spi_VEL,dlimit={colors:'bgr',labels:['Vx','Vy','Vz'],labflag:-1}
      if keyword_set(sc_frame) && sc_frame eq 2 then xyz_to_polar,prefix+'VEL_SC'
    endif

    if keyword_set(SC2_frame) then begin
      quat_SC2_to_SC = [.5d,.5d,.5d,-.5d]
      quat_SC_to_SC2 = [.5d,-.5d,-.5d,.5d]
      if 0 then begin
        rot_th = 20. ; rotation angle
        rotr = [[1,0,0.],[0,cosd(rot_th),sind(rot_th)],[0,-sind(rot_th),cosd(rot_th)]]
        rel = [[0,-1,0],[0,0,-1],[1,0,0]]    ; effective relabelling of axes
        RotMat_inst_sc = rel ## rotr ; transformation matrix from ion instrument coordinates TO SC Frame
        print,spice_m2q(rotmat_inst_sc)
      endif
      quat_inst_to_sc = [ 0.57922797d  ,   0.40557979d  ,    -0.57922797d ,    0.40557979d]
      quat_inst_to_sc2 =  qmult(quat_sc_to_sc2,quat_inst_to_sc)
      get_data,prefix+'VEL',data = spi_VEL
      spi_vel.y = quaternion_rotation(  spi_vel.y ,quat_inst_to_sc2 , last_index=0)
      store_data,prefix+'VEL_SC2',data = spi_VEL,dlimit={colors:'bgr',labels:['Vx2','Vy2','Vz2'],labflag:-1}
      if sc2_frame eq 2 then xyz_to_polar,prefix+'VEL_SC2'
    endif

    if keyword_set(RTN_frame) then begin
      tplot_quaternion_rotate,prefix+'VEL_SC','SPP_SPACECRAFT_QROT_SPP_RTN',newname=prefix+'VEL_RTN'
      options,/def,prefix+'VEL_RTN',labels=['V_R','V_T','V_N'],labflag=-1,constant=0
      add_data,prefix+'VEL_RTN','SPP_VEL_RTN',newname=prefix+'VEL_RTN-SUN',/copy_dlimits
      if RTN_frame eq 2 then begin
        if ~keyword_set(magname) then magname=prefix+'MAGF_SC'
        ;magname='PSP_FLD_L2_F2_100bps_MAGi_Average_B_SC_nT'
        xyz_to_polar,prefix+'VEL_RTN-SUN'
        xyz_to_polar,magname
        get_data,magname+'_mag',dat=magf
        get_data,prefix+'DENS',dat=dens
        fudge=1. ;tuning the density
        dens2=fudge*interp(dens.y,dens.x,magf.x)
        valfven=21.812*magf.y/sqrt(dens2)
        store_data,prefix+'VEL_Alfven',magf.x,valfven,dlimits={colors:'b',labels:'V_Alfven',ystyle:3}
        vspi_valfven=prefix+'VEL_'+['RTN-SUN_mag','Alfven']
        store_data,prefix+'VEL_OVL',data=vspi_valfven,dlimits={labflag:-1,yrange:[20,2000],ylog:1,ystyle:3}
        options,/def,prefix+'VEL_RTN-SUN_mag',labels='V_spi',colors='r'
        div_data,vspi_valfven[0],vspi_valfven[1]
        options,vspi_valfven[0]+'/'+vspi_valfven[1],constant=1,yrange=[.1,10],ytitle='Alfven!CMach!CNumber',ylog=1
      endif
    endif

    if type eq 'tof' then begin
      name = prefix+'TOF'
      get_data,name,data=d
      if keyword_set(d) then begin
        tbin = replicate(1,512)
        tbin[256:*] = 2
        tbin[384:*] = 4
        ttbin = total(/preserve,/cum,tbin)
        d.y = d.y / (replicate(1, n_elements(d.x)) # tbin)
        str_element,/add,d,'v',ttbin/5.   ; approx calibration.
        store_data,name+'_cor',data=d,dlim={spec:1,panel_size:3.,zlog:1,yrange:[6,220],ylog:1,ystyle:3}
        mm = average(d.y[*,44:56],2) ;proton peak
        store_data,name+'_TOTAL',data={x:d.x, y:mm}
        d.y = d.y / (mm # replicate(1.,512) )
        store_data,name+'_NORM',data=d,dlim={spec:1,panel_size:3.,zrange:[1e-4,1]*2,zlog:1,yrange:[6,220],ylog:1,ystyle:3}
      endif
    endif

  endforeach

  ;; Set tplot Preferences
  if level eq 'L1' then begin
    options,'psp_swp_spi_fhkp_L1_ADC',zlog=1,spec=1
    options,'psp_swp_spi_tof_L1_TOF',zlog=1,spec=1
    options,'psp_swp_spi_rates_L1_*_CNTS',zlog=1,spec=1
  endif

  if keyword_set(overlay) then begin
    ;options,'psp_swp_spc_l3i_np_fit',colors='b'
    ;options,'psp_swp_spc_l3i_np_moment',colors='c'
    store_data,'psp_swp_density',data = 'psp_swp_spc_l3i_np_moment psp_swp_spc_l3i_np_fit psp_swp_spi_??0[01]_L3_DENS',dlimit={yrange:[10,1e4],ylog:1}
  endif

end