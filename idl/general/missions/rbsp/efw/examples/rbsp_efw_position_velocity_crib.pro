;+
;NAME: rbsp_efw_position_velocity_crib.pro
;PURPOSE: Loads and plots RBSP (Van Allen probes) position and velocity related data
;CALLING SEQUENCE:
; timespan,'2014-01-01'
; rbsp_efw_position_velocity_crib
;INPUT:
;KEYWORDS:
; probe = set to specify to load only "a" or "b" other than both.
; no_spice_load -> set if you've already loaded the spice kernels
;	noplot -> set to avoid tplotting
;	notrace -> skip the ttrace2equator call. This takes a lot of computational time
; nospinaxis_calcs -> skip the part that loads the spinaxis pointing direction.
;   This can be problematic on certain dates. Only set if you don't need the
;   spinaxis direction or the sc velocity in mGSE coord
; _extra --> possible useful extra keywords include:
;       no_spice_load
;       no_rbsp_efw_init
;OUTPUT: various tplot variables
;HISTORY:
; Written by Aaron Breneman, UMN, Dec 2012
;	email: awbrenem@gmail.com
;REQUIRED: Need to have the SPICE ICY software package installed
;
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2020-09-11 13:32:39 -0700 (Fri, 11 Sep 2020) $
;$LastChangedRevision: 29136 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_position_velocity_crib.pro $
;-


pro rbsp_efw_position_velocity_crib,$
  probe=probe,$
  noplot=noplot,$
  notrace=notrace,$
  nospinaxis_calcs=nospinaxis_calcs,$
  _extra=extra


  if KEYWORD_SET(probe) then begin
    if probe eq 'a' then no_b = 1
    if probe eq 'b' then no_a = 1
  endif


  ;initialize RBSP environment
  rbsp_efw_init,_extra=extra


  ;Set timerange if it's not already set
  x = timerange()

  ;last day of probe B 2019-07-17. Be sure not to try to load data beyond this date.
  if x[0] gt time_double('2019-07-18/00:00') then no_b = 1


  ;Load spice predicted values. Override with actual values if they exist
  ;if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels,_extra=extra
;  rbsp_load_spice_kernels,_extra=extra


  ;Load state data
  if ~KEYWORD_SET(no_a) then rbsp_load_spice_state,probe='a',coord='gse',_extra=extra
  if ~KEYWORD_SET(no_b) then rbsp_load_spice_state,probe='b',coord='gse',_extra=extra




  ;Get the pointing direction of the spin axis at 1-min cadence.
  ;Used to rotate into MGSE coordinates
  time2 = x[0]
  ntimes = (x[1] - x[0])/60.    ;one minute chunks
  time3 = time_string(time2 + 60.*indgen(ntimes))
  strput,time3,'T',10           ; convert TPLOT time string 'yyyy-mm-dd/hh:mm:ss.msec' to ISO 'yyyy-mm-ddThh:mm:ss.msec'
  cspice_str2et,time3,et2       ; convert ISO time string to SPICE ET
  time4 = time_double(time_string(time3))


  if ~KEYWORD_SET(nospinaxis_calcs) then begin
    if ~KEYWORD_SET(no_a) then cspice_pxform,'RBSPA_SCIENCE','GSE',et2,pxforma
    if ~KEYWORD_SET(no_b) then cspice_pxform,'RBSPB_SCIENCE','GSE',et2,pxformb

    wsc=dblarr(3,ntimes)
    wsc[2,*]=1d
    wsc_GSEa=dblarr(3,ntimes)
    wsc_GSEb=dblarr(3,ntimes)

    if ~KEYWORD_SET(no_a) then for qq=0l,ntimes-1 do wsc_GSEa[*,qq] = pxforma[*,*,qq] ## wsc[*,qq]
    if ~KEYWORD_SET(no_b) then for qq=0l,ntimes-1 do wsc_GSEb[*,qq] = pxformb[*,*,qq] ## wsc[*,qq]

    if ~KEYWORD_SET(no_a) then store_data,'rbspa_spinaxis_direction_gse',data={x:time4,y:transpose(wsc_GSEa)}
    if ~KEYWORD_SET(no_b) then store_data,'rbspb_spinaxis_direction_gse',data={x:time4,y:transpose(wsc_GSEb)}


    ;Transform velocity to MGSE
    if ~KEYWORD_SET(no_a) then begin
      get_data,'rbspa_state_vel_gse',data=tmpp
      wsc_GSE_tmp = [[interpol(wsc_GSEa[0,*],time4,tmpp.x)],$
                     [interpol(wsc_GSEa[1,*],time4,tmpp.x)],$
                     [interpol(wsc_GSEa[2,*],time4,tmpp.x)]]
      rbsp_gse2mgse,'rbspa_state_vel_gse',reform(wsc_GSE_tmp),$
        newname='rbspa_state_vel_mgse'
    endif

    if ~KEYWORD_SET(no_b) then begin
      get_data,'rbspb_state_vel_gse',data=tmpp
      wsc_GSE_tmp = [[interpol(wsc_GSEb[0,*],time4,tmpp.x)],$
                     [interpol(wsc_GSEb[1,*],time4,tmpp.x)],$
                     [interpol(wsc_GSEb[2,*],time4,tmpp.x)]]
      rbsp_gse2mgse,'rbspb_state_vel_gse',reform(wsc_GSE_tmp),$
        newname='rbspb_state_vel_mgse'
    endif
  endif

  ;Create position and velocity magnitude variables
  get_data,'rbspa_state_pos_gse',data=pos_gse_a
  get_data,'rbspb_state_pos_gse',data=pos_gse_b
  get_data,'rbspa_state_vel_gse',data=vela
  get_data,'rbspb_state_vel_gse',data=velb

  if ~KEYWORD_SET(no_a) then begin
    vmaga = sqrt(vela.y[*,0]^2 + vela.y[*,1]^2 + vela.y[*,2]^2)
    store_data,'rbspa_state_vmag',data={x:vela.x,y:vmaga}
    rad_a = sqrt(pos_gse_a.y[*,0]^2 + pos_gse_a.y[*,1]^2 + pos_gse_a.y[*,2]^2)/6370.
    store_data,'rbspa_state_radius',data={x:pos_gse_a.x,y:rad_a}
    cotrans,'rbspa_state_pos_gse','rbspa_state_pos_gsm',/GSE2GSM

  	get_data,'rbspa_state_pos_gsm',data=d
    vx = deriv(d.x,d.y[*,0]) & vy = deriv(d.x,d.y[*,1]) & vz = deriv(d.x,d.y[*,2])
    store_data,'rbspa_state_vel_gsm',d.x,[[vx],[vy],[vz]],[1,2,3],dlimits=dl

;    cotrans,'rbspa_state_vel_gse','rbspa_state_vel_gsm',/GSE2GSM
    ;For calculating Mlat only
    cotrans,'rbspa_state_pos_gsm','rbspa_state_pos_sm',/GSM2SM
  endif

  if ~KEYWORD_SET(no_b) then begin
    vmagb = sqrt(velb.y[*,0]^2 + velb.y[*,1]^2 + velb.y[*,2]^2)
    store_data,'rbspb_state_vmag',data={x:velb.x,y:vmagb}
    rad_b = sqrt(pos_gse_b.y[*,0]^2 + pos_gse_b.y[*,1]^2 + pos_gse_b.y[*,2]^2)/6370.
    store_data,'rbspb_state_radius',data={x:pos_gse_b.x,y:rad_b}
    cotrans,'rbspb_state_pos_gse','rbspb_state_pos_gsm',/GSE2GSM

    get_data,'rbspb_state_pos_gsm',data=d
    vx = deriv(d.x,d.y[*,0]) & vy = deriv(d.x,d.y[*,1]) & vz = deriv(d.x,d.y[*,2])
    store_data,'rbspb_state_vel_gsm',d.x,[[vx],[vy],[vz]],[1,2,3],dlimits=dl

;    cotrans,'rbspb_state_vel_gse','rbspb_state_vel_gsm',/GSE2GSM
    ;For calculating Mlat only
    cotrans,'rbspb_state_pos_gsm','rbspb_state_pos_sm',/GSM2SM
  endif


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

  if ~keyword_set(no_a) and ~keyword_set(no_b) then begin
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
  endif

  ;Calculate magnetic latitude
  if ~keyword_set(no_a) then begin
    get_data,'rbspa_state_pos_sm',data=pos_sm_a
    dr2a = sqrt(pos_sm_a.y[*,0]^2 + pos_sm_a.y[*,1]^2)
    dz2a = pos_sm_a.y[*,2]
    mlat_a = atan(dz2a,dr2a)


  endif
  if ~keyword_set(no_b) then begin
    get_data,'rbspb_state_pos_sm',data=pos_sm_b
    dr2b = sqrt(pos_sm_b.y[*,0]^2 + pos_sm_b.y[*,1]^2)
    dz2b = pos_sm_b.y[*,2]
    mlat_b = atan(dz2b,dr2b)
  endif

  ;Calculate L-shell

  ;Method 1
  if ~keyword_set(no_a) then Lshell_a = rad_a/(cos(!dtor*mlat_a)^2)       ;L-shell in centered dipole
  if ~keyword_set(no_b) then Lshell_b = rad_b/(cos(!dtor*mlat_b)^2)       ;L-shell in centered dipole

  ;Method 2
  ;Position data must be in km. Output in GSM (see crib_ttrace.pro)
  if ~keyword_set(notrace) then begin
     if ~keyword_set(no_a) then begin
       ttrace2equator,'rbspa_state_pos_gsm',newname='rbspa_state_out_foot_gsm',/km
       get_data,'rbspa_state_out_foot_gsm',data=d
       Lshell_a = sqrt(d.y[*,0]^2 + d.y[*,1]^2 + d.y[*,2]^2)/6370.
     endif

     if ~keyword_set(no_b) then begin
       ttrace2equator,'rbspb_state_pos_gsm',newname='rbspb_state_out_foot_gsm',/km
       get_data,'rbspb_state_out_foot_gsm',data=d
       Lshell_b = sqrt(d.y[*,0]^2 + d.y[*,1]^2 + d.y[*,2]^2)/6370.
     endif
  endif


  ;Calculate invariant latitude
  if ~keyword_set(no_a) then begin
    ilat_a = acos(sqrt(1/Lshell_a))/!dtor
    ;Calculate MLT
    angle_tmp = atan(pos_gse_a.y[*,1],pos_gse_a.y[*,0])/!dtor
    goo = where(angle_tmp lt 0.)
    if goo[0] ne -1 then angle_tmp[goo] = 360. - abs(angle_tmp[goo])
    angle_rad_a = angle_tmp * 12/180. + 12.
    goo = where(angle_rad_a ge 24.)
    if goo[0] ne -1 then angle_rad_a[goo] = angle_rad_a[goo] - 24
    store_data,'rbspa_state_mlt',data={x:pos_gse_a.x,y:angle_rad_a}
    store_data,'rbspa_state_lshell',data={x:pos_gse_a.x,y:lshell_a}
    store_data,'rbspa_state_mlat',data={x:pos_gse_a.x,y:mlat_a/!dtor}
    store_data,'rbspa_state_ilat',data={x:pos_gse_a.x,y:ilat_a}
  endif

  if ~keyword_set(no_b) then begin
    ilat_b = acos(sqrt(1/Lshell_b))/!dtor
    angle_tmp = atan(pos_gse_b.y[*,1],pos_gse_b.y[*,0])/!dtor
    goo = where(angle_tmp lt 0.)
    if goo[0] ne -1 then angle_tmp[goo] = 360. - abs(angle_tmp[goo])
    angle_rad_b = angle_tmp * 12/180. + 12.
    goo = where(angle_rad_b ge 24.)
    if goo[0] ne -1 then angle_rad_b[goo] = angle_rad_b[goo] - 24
    store_data,'rbspb_state_mlt',data={x:pos_gse_b.x,y:angle_rad_b}
    store_data,'rbspb_state_lshell',data={x:pos_gse_b.x,y:lshell_b}
    store_data,'rbspb_state_mlat',data={x:pos_gse_b.x,y:mlat_b/!dtor}
    store_data,'rbspb_state_ilat',data={x:pos_gse_b.x,y:ilat_b}
  endif

  ;Find differences in MLT and L b/t the two sc
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




;  ;Plot various quantities
;  if ~keyword_set(noplot) then begin
;
;    tplot_options,'title','rbsp position data'
;
;    ;Plot position quantities
;    tplot,['rbsp?_state_pos_gse',$
;          'rbsp?_state_pos_gsm',$
;          'rbsp?_state_pos_sm']
;
;    tplot,['rbsp?_state_mlat',$
;          'rbsp?_state_lshell',$
;          'rbsp?_state_mlt']
;
;
;    ;Plot velocity quantities
;    tplot,['rbspa_state_vmag',$
;          'rbspa_state_vel_gse',$
;          'rbspa_state_vel_mgse',$
;          'rbspa_state_vel_gsm',$
;          'rbspa_state_vel_sm',$
;          'rbspb_state_vmag',$
;          'rbspb_state_vel_gse',$
;          'rbspb_state_vel_mgse',$
;          'rbspb_state_vel_gsm',$
;          'rbspb_state_vel_sm']
;
;    ;Plot separations b/t sc
;    tplot,['rbsp_state_sc_sep',$
;          'rbsp_state_gse_sep',$
;          'rbsp_state_mlt_diff',$
;          'rbsp_state_lshell_diff',$
;          'rbsp_state_mlat_diff']
;
;  endif

end
