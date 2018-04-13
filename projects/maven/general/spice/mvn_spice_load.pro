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
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-01-21 17:01:02 -0800 (Tue, 21 Jan 2014) $
; $LastChangedRevision: 13960 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/idl_socware/trunk/projects/maven/general/mvn_file_source.pro $
;-

pro mvn_spice_load,trange=trange,kernels=kernels,download_only=download_only,verbose=verbose,Quaternion=quaternion,Orbit_data=orbit_data,no_download=no_download

   ; Create

   orbdata = mvn_orbit_num(verbose=verbose)                 
   store_data,'orb_num',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
   if keyword_set(orbit_data) then    store_data,'mvn_ORB_',data=orbdata,tagnames='SOL_* SC_*',time_tag='PERI_TIME'
;   tplot,var_label='orbnum'
   tplot_options,'timebar','orb_num'
   tplot_options,'var_label','orb_num'
   
   dprint,dlevel=2,'Current Orbit Number is: ',mvn_orbit_num(time=systime(1))
   
   if spice_test(verbose=2) eq 0 then begin
    dprint,'Unable to continue.  Sorry!'
    return    
   endif


   kernels = mvn_spice_kernels(/all,/clear,/load,trange=trange,verbose=2,no_download=no_download)
   if keyword_set(download_only) then return
   
   
   spice_position_to_tplot,'MAVEN','Mars',frame='MSO',res=300d,scale=1000.,name=n1  ,trange=trange
   xyz_to_polar,n1
   
   times = dgen(range=timerange(trange),res=60.)   ; 60 second time resolution
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
   tplot_options,'var_label','orb_num mvn_alt'


   
   
   frame = 'MAVEN_SPACECRAFT'
;   frame = 'MAVEN_SCALT'
if keyword_set(Quaternion) then   spice_qrot_to_tplot,frame,'MSO',get_omega=3,res=60d,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .5 *!pi/180.  ; .5 degree error
 ;  spice_qrot_to_tplot,frame,'MAVEN_APP',get_omega=3,res=30d,names=tn,check_obj=['MAVEN_SPACECRAFT','MAVEN_APP_OG'] ,error=  .5 *!pi/180  ; .5 degree error
   
end


