;rbsp_efw_position_velocity_crib

;Loads and plots RBSP (Van Allen probes) position and velocity data
;	MLT
;	Mlat
;	Lshell
;	Position (GSE)
;	Velocity (GSE)
;
;
;keywords:
;	no_spice_load -> set if you've already loaded the spice kernels
;	noplot -> set to avoid tplotting
;	notrace -> skip the ttrace2equator call. This takes a lot of computational time
;
;Need to have the SPICE ICY software package installed
;
;
;Written by Aaron Breneman, UMN, Dec 2012
;			email: awbrenem@gmail.com



pro rbsp_efw_position_velocity_crib,no_spice_load=no_spice_load,noplot=noplot,notrace=notrace


; initialize RBSP environment
  rbsp_efw_init
  !rbsp_efw.user_agent = ''

;Set timerange if it's not already set
  x = timerange()


;Load spice predicted values. Override with actual values if they exist
  if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels


;Load state data
  rbsp_load_spice_state,probe='a',coord='gse',/no_spice_load  
  rbsp_load_spice_state,probe='b',coord='gse',/no_spice_load  



;Get the pointing direction of the spin axis at 1-min cadence. Used to rotate into MGSE coordinates


  time2 = x[0]
  ntimes = (x[1] - x[0])/60.    ;one minute chunks
  time3 = time_string(time2 + 60.*indgen(ntimes))

  strput,time3,'T',10           ; convert TPLOT time string 'yyyy-mm-dd/hh:mm:ss.msec' to ISO 'yyyy-mm-ddThh:mm:ss.msec'
  cspice_str2et,time3,et2       ; convert ISO time string to SPICE ET


  cspice_pxform,'RBSPA_SCIENCE','GSE',et2,pxforma
  cspice_pxform,'RBSPB_SCIENCE','GSE',et2,pxformb

  wsc=dblarr(3,ntimes)
  wsc[2,*]=1d
  wsc_GSEa=dblarr(3,ntimes)
  wsc_GSEb=dblarr(3,ntimes)

  for qq=0l,ntimes-1 do wsc_GSEa[*,qq] = pxforma[*,*,qq] ## wsc[*,qq]
  for qq=0l,ntimes-1 do wsc_GSEb[*,qq] = pxformb[*,*,qq] ## wsc[*,qq]


  time4 = time_double(time_string(time3))



  store_data,'rbspa_spinaxis_direction_gse',data={x:time4,y:transpose(wsc_GSEa)}
  store_data,'rbspb_spinaxis_direction_gse',data={x:time4,y:transpose(wsc_GSEb)}



;Transform velocity to MGSE 

  get_data,'rbspa_state_vel_gse',data=tmpp
  wsc_GSE_tmp = [[interpol(wsc_GSEa[0,*],time4,tmpp.x)],$
                 [interpol(wsc_GSEa[1,*],time4,tmpp.x)],$
                 [interpol(wsc_GSEa[2,*],time4,tmpp.x)]]
  rbsp_gse2mgse,'rbspa_state_vel_gse',reform(wsc_GSE_tmp),newname='rbspa_state_vel_mgse'

  get_data,'rbspb_state_vel_gse',data=tmpp
  wsc_GSE_tmp = [[interpol(wsc_GSEb[0,*],time4,tmpp.x)],$
                 [interpol(wsc_GSEb[1,*],time4,tmpp.x)],$
                 [interpol(wsc_GSEb[2,*],time4,tmpp.x)]]
  rbsp_gse2mgse,'rbspb_state_vel_gse',reform(wsc_GSE_tmp),newname='rbspb_state_vel_mgse'



  
;Create position and velocity magnitude variables

  get_data,'rbspa_state_pos_gse',data=pos_gse_a
  get_data,'rbspb_state_pos_gse',data=pos_gse_b

  get_data,'rbspa_state_vel_gse',data=vela
  get_data,'rbspb_state_vel_gse',data=velb
  
  vmaga = sqrt(vela.y[*,0]^2 + vela.y[*,1]^2 + vela.y[*,2]^2)
  vmagb = sqrt(velb.y[*,0]^2 + velb.y[*,1]^2 + velb.y[*,2]^2)
  
  store_data,'rbspa_state_vmag',data={x:vela.x,y:vmaga}
  store_data,'rbspb_state_vmag',data={x:velb.x,y:vmagb}
  
  rad_a = sqrt(pos_gse_a.y[*,0]^2 + pos_gse_a.y[*,1]^2 + pos_gse_a.y[*,2]^2)/6370.
  rad_b = sqrt(pos_gse_b.y[*,0]^2 + pos_gse_b.y[*,1]^2 + pos_gse_b.y[*,2]^2)/6370.

  store_data,'rbspa_state_radius',data={x:pos_gse_a.x,y:rad_a}
  store_data,'rbspb_state_radius',data={x:pos_gse_b.x,y:rad_b}

  cotrans,'rbspa_state_pos_gse','rbspa_state_pos_gsm',/GSE2GSM	
  cotrans,'rbspb_state_pos_gse','rbspb_state_pos_gsm',/GSE2GSM	
  cotrans,'rbspa_state_vel_gse','rbspa_state_vel_gsm',/GSE2GSM	
  cotrans,'rbspb_state_vel_gse','rbspb_state_vel_gsm',/GSE2GSM	


;For calculating Mlat only
  cotrans,'rbspa_state_pos_gsm','rbspa_state_pos_sm',/GSM2SM	
  cotrans,'rbspb_state_pos_gsm','rbspb_state_pos_sm',/GSM2SM	


  options,'rbsp?_state_pos_*','panel_size',1
  options,'rbsp?_state_vel_*','panel_size',1
  options,'rbsp?_state_radius','panel_size',1


  options,'rbspa_state_vel_gse','ytitle','RBSPa!Cvelocity!CGSE'
  options,'rbspa_state_vel_mgse','ytitle','RBSPa!Cvelocity!CMGSE'
  options,'rbspa_state_vel_gsm','ytitle','RBSPa!Cvelocity!CGSM'
  options,'rbspa_state_vel_sm','ytitle','RBSPa!Cvelocity!CSM'

  options,'rbsp?_state_vel_gse','labels',['GSEx','GSEy','GSEz']
  options,'rbsp?_state_vel_mgse','labels',['mGSEx','mGSEy','mGSEz']
  options,'rbsp?_state_vel_gsm','labels',['GSMx','GSMy','GSMz']
  options,'rbsp?_state_vel_sm','labels',['SMx','SMy','SMz']


  options,'rbspb_state_vel_gse','ytitle','RBSPb!Cvelocity!CGSE'
  options,'rbspb_state_vel_mgse','ytitle','RBSPb!Cvelocity!CMGSE'
  options,'rbspb_state_vel_gsm','ytitle','RBSPb!Cvelocity!CGSM'
  options,'rbspb_state_vel_sm','ytitle','RBSPb!Cvelocity!CSM'

  options,'rbspa_state_pos_gse','ytitle','RBSPa!Cposition!CGSE'
  options,'rbspb_state_pos_gse','ytitle','RBSPb!Cposition!CGSE'
  options,'rbspa_state_pos_gsm','ytitle','RBSPa!Cposition!CGSM'
  options,'rbspb_state_pos_gsm','ytitle','RBSPb!Cposition!CGSM'
  options,'rbspa_state_pos_sm','ytitle','RBSPa!Cposition!CSM'
  options,'rbspb_state_pos_sm','ytitle','RBSPb!Cposition!CSM'

  options,'rbsp?_state_pos_gse','labels',['GSEx','GSEy','GSEz']
  options,'rbsp?_state_pos_mgse','labels',['mGSEx','mGSEy','mGSEz']
  options,'rbsp?_state_pos_gsm','labels',['GSMx','GSMy','GSMz']
  options,'rbsp?_state_pos_sm','labels',['SMx','SMy','SMz']

  options,'rbspa_state_radius','ytitle','RBSPa!CRadius!C[RE]'
  options,'rbspb_state_radius','ytitle','RBSPb!CRadius!C[RE]'



;Calculate GSE separation b/t sc
  
                                ;Interpolate to get GSE position of both sc on the same times.
  
  dif_data,'rbspa_state_pos_gse','rbspb_state_pos_gse',newname='rbsp_state_pos_diff'
  get_data,'rbsp_state_pos_diff',data=pos_diff
  store_data,'rbsp_state_pos_diff',/delete
  
  dx = pos_diff.y[*,0]/1000.
  dy = pos_diff.y[*,1]/1000.
  dz = pos_diff.y[*,2]/1000.
  
  sc_sep = sqrt(dx^2 + dy^2 + dz^2)

  store_data,'rbsp_state_sc_sep',data={x:pos_diff.x,y:sc_sep}
  options,'rbsp_state_sc_sep','labflag',0
  options,'rbsp_state_sc_sep','ytitle','SC GSE!Cabsolute!Cseparation!C[x1000 km]'

  store_data,'rbsp_state_gse_sep',data={x:pos_diff.x,y:[[dx],[dy],[dz]]}
  options,'rbsp_state_gse_sep','labels',['dx gse','dy gse','dz gse']
  options,'rbsp_state_gse_sep','ytitle','SC GSE!Cseparation!C[x1000 km]'



;Calculate magnetic latitude	

  get_data,'rbspa_state_pos_sm',data=pos_sm_a
  get_data,'rbspb_state_pos_sm',data=pos_sm_b

  
  dr2a = sqrt(pos_sm_a.y[*,0]^2 + pos_sm_a.y[*,1]^2)
  dz2a = pos_sm_a.y[*,2]
  dr2b = sqrt(pos_sm_b.y[*,0]^2 + pos_sm_b.y[*,1]^2)
  dz2b = pos_sm_b.y[*,2]

  mlat_a = atan(dz2a,dr2a)
  mlat_b = atan(dz2b,dr2b)
  

;Calculate L-shell

                                ;Method 1
  Lshell_a = rad_a/(cos(!dtor*mlat_a)^2)       ;L-shell in centered dipole
  Lshell_b = rad_b/(cos(!dtor*mlat_b)^2)       ;L-shell in centered dipole

                                ;Method 2
                                ;Position data must be in km
  
  if ~keyword_set(notrace) then begin
     ttrace2equator,'rbspa_state_pos_gsm',newname='rbspa_state_out_foot',/km
     ttrace2equator,'rbspb_state_pos_gsm',newname='rbspb_state_out_foot',/km
     
     get_data,'rbspa_state_out_foot',data=d
     Lshell_a = sqrt(d.y[*,0]^2 + d.y[*,1]^2 + d.y[*,2]^2)/6370.
     get_data,'rbspb_state_out_foot',data=d
     Lshell_b = sqrt(d.y[*,0]^2 + d.y[*,1]^2 + d.y[*,2]^2)/6370.
  endif
  
  
;Calculate invariant latitude

  ilat_a = acos(sqrt(1/Lshell_a))/!dtor
  ilat_b = acos(sqrt(1/Lshell_b))/!dtor
  


;Calculate MLT
  
  angle_tmp = atan(pos_gse_a.y[*,1],pos_gse_a.y[*,0])/!dtor
  goo = where(angle_tmp lt 0.)
  if goo[0] ne -1 then angle_tmp[goo] = 360. - abs(angle_tmp[goo])
  angle_rad_a = angle_tmp * 12/180. + 12.
  goo = where(angle_rad_a ge 24.)
  if goo[0] ne -1 then angle_rad_a[goo] = angle_rad_a[goo] - 24

  angle_tmp = atan(pos_gse_b.y[*,1],pos_gse_b.y[*,0])/!dtor
  goo = where(angle_tmp lt 0.)
  if goo[0] ne -1 then angle_tmp[goo] = 360. - abs(angle_tmp[goo])
  angle_rad_b = angle_tmp * 12/180. + 12.
  goo = where(angle_rad_b ge 24.)
  if goo[0] ne -1 then angle_rad_b[goo] = angle_rad_b[goo] - 24



;Find differences in MLT and L b/t the two sc
  store_data,'rbspa_state_mlt',data={x:pos_gse_a.x,y:angle_rad_a}
  store_data,'rbspa_state_lshell',data={x:pos_gse_a.x,y:lshell_a}
  store_data,'rbspa_state_mlat',data={x:pos_gse_a.x,y:mlat_a/!dtor}
  store_data,'rbspa_state_ilat',data={x:pos_gse_a.x,y:ilat_a}

  store_data,'rbspb_state_mlt',data={x:pos_gse_b.x,y:angle_rad_b}
  store_data,'rbspb_state_lshell',data={x:pos_gse_b.x,y:lshell_b}
  store_data,'rbspb_state_mlat',data={x:pos_gse_b.x,y:mlat_b/!dtor}	
  store_data,'rbspb_state_ilat',data={x:pos_gse_b.x,y:ilat_b}

  dif_data,'rbspa_state_mlt','rbspb_state_mlt',newname='rbsp_state_mlt_diff'
  if ~keyword_set(notrace) then dif_data,'rbspa_state_lshell','rbspb_state_lshell',newname='rbsp_state_lshell_diff'
  dif_data,'rbspa_state_mlat','rbspb_state_mlat',newname='rbsp_state_mlat_diff'


  options,'rbspa_state_mlat','ytitle','RBSPa!CMLAT!C[degrees]'
  options,'rbspb_state_mlat','ytitle','RBSPb!CMLAT!C[degrees]'
  options,'rbspa_state_mlt','ytitle','RBSPa!CMLT!C[hours]'
  options,'rbspb_state_mlt','ytitle','RBSPb!CMLT!C[hours]'
  options,'rbsp?_state_mlat','format','(f5.1)'        	

  options,'rbsp_state_mlt_diff','ytitle','MLTa-!CMLTb!C[hours]'
  options,'rbsp_state_lshell_diff','ytitle','LSHELLa-!CLSHELLb'
  options,'rbspa_state_lshell','ytitle','RBSPa!CLSHELL'
  options,'rbspb_state_lshell','ytitle','RBSPb!CLSHELL'
  options,'rbsp?_state_lshell','format','(f5.1)'

  options,'rbspa_state_ilat','ytitle','RBSPa!CILAT'
  options,'rbspb_state_ilat','ytitle','RBSPb!CILAT'
  options,'rbsp?_state_ilat','format','(f5.1)'


  options,'rbsp_state_mlat_diff','ytitle','MLATa-!CMLATb!C[degrees]'


  ylim,'rbsp_state_mlat_diff',-10,10
  ylim,'rbsp_state_mlt_diff',-5,5

  options,'rbspa_state_vmag','ytitle','RBSPa!C|V|!C[km/s]'
  options,'rbspb_state_vmag','ytitle','RBSPb!C|V|!C[km/s]'



                                ;Create combined tplot variables
  store_data,'rbsp_state_mlt_both',data=['rbspa_state_mlt','rbspb_state_mlt']
  options,'rbsp_state_mlt_both','colors',[2,6]
  options,'rbsp_state_mlt_both','ytitle','MLT!C[hours]'
  options,'rbsp_state_mlt_both','ztitle','BLUE=A,RED=B'
  options,'rbsp_state_mlt_both','labels','BLUE=A,RED=B'

  store_data,'rbsp_state_lshell_both',data=['rbspa_state_lshell','rbspb_state_lshell']
  options,'rbsp_state_lshell_both','colors',[2,6]
  options,'rbsp_state_lshell_both','ytitle','Lshell'
  options,'rbsp_state_lshell_both','ztitle','BLUE=A,RED=B'
  options,'rbsp_state_lshell_both','labels','BLUE=A,RED=B'


  store_data,'rbsp_state_mlat_both',data=['rbspa_state_mlat','rbspb_state_mlat']
  options,'rbsp_state_mlat_both','colors',[2,6]
  options,'rbsp_state_mlat_both','ytitle','Mlat!C[deg]'
  options,'rbsp_state_mlat_both','ztitle','BLUE=A,RED=B'
  options,'rbsp_state_mlat_both','labels','BLUE=A,RED=B'

  store_data,'rbsp_state_vmag_both',data=['rbspa_state_vmag','rbspb_state_vmag']
  options,'rbsp_state_vmag_both','colors',[2,6]
  options,'rbsp_state_vmag_both','ytitle','|V|!C[km/s]'
  options,'rbsp_state_vmag_both','ztitle','BLUE=A,RED=B'
  options,'rbsp_state_vmag_both','labels','BLUE=A,RED=B'

  store_data,'rbsp_state_radius_both',data=['rbspa_state_radius','rbspb_state_radius']
  options,'rbsp_state_radius_both','colors',[2,6]
  options,'rbsp_state_radius_both','ytitle','Radial!Cdistance!C[RE]'
  options,'rbsp_state_radius_both','ztitle','BLUE=A,RED=B'
  options,'rbsp_state_radius_both','labels','BLUE=A,RED=B'


  options,['rbsp_state_mlt_both','rbsp_state_mlat_both',$
           'rbsp_state_lshell_both','rbsp_state_vmag_both',$
           'rbsp_state_radius_both'],'labflag',-1




;Plot various quantities

  if ~keyword_set(noplot) then begin

     tplot_options,'title','rbsp position data'


                                ;Plot position quantities
     tplot,['rbsp?_state_pos_gse',$
            'rbsp?_state_pos_gsm',$
            'rbsp?_state_pos_sm']

     tplot,['rbsp?_state_mlat',$
            'rbsp?_state_lshell',$
            'rbsp?_state_mlt']

     
                                ;Plot velocity quantities
     tplot,['rbspa_state_vmag',$
            'rbspa_state_vel_gse',$
            'rbspa_state_vel_mgse',$
            'rbspa_state_vel_gsm',$
            'rbspa_state_vel_sm',$
            'rbspb_state_vmag',$
            'rbspb_state_vel_gse',$
            'rbspb_state_vel_mgse',$
            'rbspb_state_vel_gsm',$ 
            'rbspb_state_vel_sm']

                                ;Plot separations b/t sc
     tplot,['rbsp_state_sc_sep',$
            'rbsp_state_gse_sep',$
            'rbsp_state_mlt_diff',$
            'rbsp_state_lshell_diff',$
            'rbsp_state_mlat_diff']

  endif


end

