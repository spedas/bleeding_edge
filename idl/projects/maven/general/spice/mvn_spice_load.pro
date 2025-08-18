;+
;NAME: MVN_SPICE_LOAD
; Procedure: mvn_spice_load
;PURPOSE:
; LOADS SPICE kernels and creates a few tplot variables
; Demonstrates usage of MAVEN SPICE ROUTINES
;
;CALLING SEQUENCE:
;   mvn_spice_load  [,kernels=kernels] [,trange=trange]
;
;  Author:  Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2023-12-29 18:52:02 -0800 (Fri, 29 Dec 2023) $
; $LastChangedRevision: 32325 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_load.pro $
;-

pro mvn_spice_load,trange=trange,kernels=kernels,download_only=download_only,verbose=verbose,names=names,no_attitude=no_attitude,$
  quaternion=quaternion,orbit_data=orbit_data,no_download=no_download,load=load,clear=clear,resolution=res

  orbdata = mvn_orbit_num(verbose=verbose)
  store_data,'mvn_orb_num',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
  store_data,'mvn_peri_alt',orbdata.peri_time,orbdata.sc_alt
  if keyword_set(orbit_data) then    store_data,'mvn_ORB_',data=orbdata,tagnames='SOL_* SC_*',time_tag='PERI_TIME'
  ;   tplot,var_label='orbnum'
  tplot_options,'timebar','mvn_orb_num'
  tplot_options,'var_label','mvn_orb_num'

  dprint,dlevel=2,'Current Orbit Number is: ',mvn_orbit_num(time=systime(1))

  if spice_test(verbose=2) eq 0 then begin
    dprint,'Unable to continue.  Sorry!'
    return
  endif

  if n_elements(load) eq 0 then load=1
  if n_elements(clear) eq 0 then clear=1
  if keyword_set(no_attitude) then names=['STD','SCK','FRM','IK','SPK'] else all=1 ;don't give me the attitude!
  kernels = mvn_spice_kernels(names,all=all,clear=clear,load=load,trange=trange,verbose=2,no_download=no_download)
  if keyword_set(download_only) then return

  if ~keyword_set(res) then res=300d
  spice_position_to_tplot,'MAVEN','Mars',frame='MSO',res=res,scale=1000.,name=n1  ,trange=trange
  xyz_to_polar,n1

  times = dgen(range=timerange(trange),res=res)
  pos = spice_body_pos('MAVEN','MARS',frame='IAU_MARS',utc=times,check_objects=['MAVEN','MARS','IAU_MARS'])
  cspice_bodvrd, 'MARS', 'RADII', 3, radii
  re = total(radii[0:1])/2.
  rp = radii[2]
  f= (re-rp)/re
  dprint,dlevel=3,/phelp,radii,re,f

  cspice_recgeo, pos, re, f, pdlon, pdlat, pdalt

  store_data,'mvn_lat',times,pdlat*180./!dpi,dlimit={ytitle:'Maven!cLattitude',yrange:[-90,90],ystyle:1}
  store_data,'mvn_lon',times,pdlon*180./!dpi,dlimit={ytitle:'Maven!cLongitude',yrange:[-180,180],ystyle:1}
  store_data,'mvn_alt',times,pdalt,dlimit={ylog:1,ytitle:'Altitude'}
  tplot_options,'var_label','mvn_orb_num mvn_alt'

  frame = 'MAVEN_SPACECRAFT'
  ;frame = 'MAVEN_SCALT'
  if keyword_set(Quaternion) then spice_qrot_to_tplot,frame,'MSO',get_omega=3,res=res,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .5 *!pi/180.  ; .5 degree error
  ;spice_qrot_to_tplot,frame,'MAVEN_APP',get_omega=3,res=30d,names=tn,check_obj=['MAVEN_SPACECRAFT','MAVEN_APP_OG'] ,error=  .5 *!pi/180  ; .5 degree error

end


