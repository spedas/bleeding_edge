;+
;NAME: MVN_SPICE_CRIB
; Program: mvn_spice_crib
;PURPOSE:
; Demonstrates usage of MAVEN SPICE ROUTINES
;  
;CALLING SEQUENCE:
;  .run mvn_spice_crib
;  
;  Author:  Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-01-21 17:01:02 -0800 (Tue, 21 Jan 2014) $
; $LastChangedRevision: 13960 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/idl_socware/trunk/projects/maven/general/mvn_file_source.pro $
;-


dprint,'Please run the demonstration program:  SPICE_CRIB first.
dprint


testall=1


if keyword_set(0 && testall) then begin              ;  time conversion routines
utc = ['2013-11-1','2015-10-1']
if not keyword_set(sc) then SC = -202
dprint,sc

ut = time_double(utc)
met2 = mvn_spc_unixtime_to_met(utc,correct_clockdrift=0) ; No drift corrections here
met1 = mvn_spc_unixtime_to_met(utc,correct_clockdrift=1) ;  drift corrections here
metdrift = met2-met1
printdat,met2,met1,metdrift
ut2  = mvn_spc_met_to_unixtime(met2,correct_clockdrift=0)  ;  no correction
ut1  = mvn_spc_met_to_unixtime(met1,correct_clockdrift=1)  ;  with drift correction
utdrift1 = ut-ut1
utdrift2 = ut-ut2
printdat,utdrift1,utdrift2
et = time_ephemeris(utc)
cspice_sce2c, sc, et, sclkdp1
cspice_sce2t, sc, et[0], sclkdp2         ; scaler only
cspice_sce2s, sc, et[0], sclkch          ; string (not useful)
sclkdp_s16 = sclkdp1 / 2d^16

dprint
printdat,utc,ut,met,et,sclkch,sclkdp1,sclkdp2,sclkdp_s16
drift = met1 - sclkdp_s16
printdat,drift
dprint,'Type ".cont" to continue'
stop
endif



if keyword_set(testall) then begin
mk = mvn_spice_kernels(/all,/load,verbose=1)
frame='ECLIPJ2000'
scale = 149.6e6   ; 1AU in km
timespan,'13-1-1',365*2
dprint,'Create some TPLOT variables with position data and then plot it.'
spice_position_to_tplot,'MAVEN','SUN',frame=frame,res=3600d*24,scale=scale,name=n1
spice_position_to_tplot,'Earth','SUN',frame=frame,res=3600d*24,scale=scale,name=n2
spice_position_to_tplot,'MARS','SUN',frame=frame,res=3600d*24,scale=scale,name=n3
store_data,'POS',data=[n1,n2,n3]
options,n2,linestyle=2
options,n3,linestyle=1
tplot,'POS',tr=[0d,0]
dprint,'Type ".cont" to continue'

stop

scale=1000 ; km
spice_position_to_tplot,'MAVEN','MARS',frame='MSO',res=3600d,scale=scale,name=n1



endif

if getenv('USER') eq 'davin' then def_frame = 'MAVEN_SSO'
if not keyword_set(def_frame) then def_frame = 'MAVEN_MSO'

;  Tplot routines

;test routines


; Load kernels
if keyword_set(testall) then begin


timespan,['13-11-1','15-1-1']
tr =[ '2014-1-6/16:29','2014-1-7/16:40']
tr =[ '2013-11-22','2013-12-31'] 
tr=[ '2014-1-6','2014-1-12']

tr = ['2013-11-20',time_string(systime(1))]
tr = ['2014 1 5','2014-1-12']
timespan,tr
mk = mvn_spice_kernels(/all,/load,trange=timerange())
tr=0

spice_qrot_to_tplot,'MAVEN_SPACECRAFT',def_frame,get_omega=3,res=3600d,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .5 *!pi/180  ; .5 degree error
;  split_vec,tn[0]
xyz_to_polar,tn[2],tplotnames=tnr   
ylim,tnr[0],1,1,1
tplot, '*QROT*'
; spice_qrot_to_tplot,'MAVEN_SPACECRAFT','MAVEN_MSO',get_omega=3,res=3600d,trange=tr,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  1 *!pi/180  ; 1 degree error
; spice_qrot_to_tplot,'MAVEN_SPACECRAFT','MAVEN_NOM',get_omega=3,res=3600d,trange=tr,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  1 *!pi/180  ; 1 degree error
dprint,'Type ".cont" to continue'
stop
endif


if keyword_set(testall) then begin

dprint,'Example of how to rotate vector data into another frame.'

;timespan,'14-1-6',3
;pathname = '/maven/data/sci/pfp/l0/' + ['mvn_pfp_svy_l0_20140106_v2.dat','mvn_pfp_svy_l0_20140107_v2.dat','mvn_pfp_svy_l0_20140108_v2.dat']
;pathname = '/maven/data/sci/pfp/l0/mvn_pfp_svy_l0_20140107_v2.dat'
;mvn_pfp_l0_file_read ,pathname=pathname,mag=1;,sep=1

timespan,'14-1-6',2
;The following code segment will obtain some raw (absolutely unprocessed) MAG data. No proper scaling or offsets have been applied
; DO NOT USE FOR SCIENCE PURPOSES!!!!
; THIS IS FOR EXAMPLE PURPOSES ONLY!
mvn_sep_load,mag=1,sep=0   ;  load some vector data (MAG)

tplot,['*BRAW',tn]
options,'mvn_mag1_svy_BRAW',spice_frame='MAVEN_MAG_PY',spice_master_frame='MAVEN_SPACECRAFT'
options,'mvn_mag2_svy_BRAW',spice_frame='MAVEN_MAG_MY',spice_master_frame='MAVEN_SPACECRAFT'

dprint,'This routine is REALLY slow!  So use a reduced time range.'
tr = ['2014-01-07/13:47:00', '2014-01-07/15:15:00']
spice_vector_rotate_tplot,'mvn_mag?_svy_BRAW',def_frame,verbose=3,trange=tr

tplot,['*BRAW',tn,'*BRAW_*'], trange=tr
dprint,'  Note:  The MAG data is not to be used for scientific purposes.  '
dprint,'    No MAG offsets have been applied. Therefore there is a constant difference. But wiggles match.'
dprint,'   Type .cont to continue'

stop

;
;get_data,'mvn_mag2_svy_BRAW',time_mag2,mag2
;qrot =  spice_body_att('MAVEN_MAG_MY','MAVEN_SO',time,/quaternion,check_object='MAVEN_SPACECRAFT') 
;mag2_so = transpose(quaternion_rotation(transpose(mag2),qrot,/last_ind))
;store_data,'mvn_mag2_svy_BRAW_SO',time_mag2,mag2_so
;
;dprint
;get_data,'mvn_mag1_svy_BRAW',time_mag1,mag1
;dprint
;qrot =  spice_body_att('MAVEN_MAG_PY','MAVEN_SO',time_mag1,/quaternion,check_object='MAVEN_SPACECRAFT',verbose=3) 
;dprint
;mag1_so = transpose(quaternion_rotation(transpose(mag1),qrot,/last_ind))
;store_data,'mvn_mag1_svy_BRAW_SO',time_mag1,mag1_so
;dprint

endif 




testall=0
if getenv('USER') eq 'davin_' then testall=1



if keyword_set(testall) then begin
spice_qrot_to_tplot,'MAVEN_SEP1',def_frame,get_omega=0,trange=tr,res=res,names=rot_sep1,check_obj='MAVEN_SPACECRAFT'
spice_qrot_to_tplot,'MAVEN_SEP2',def_frame,get_omega=0,trange=tr,res=res,names=rot_sep2,check_obj='MAVEN_SPACECRAFT'
tplot,'*QROT*',trange=[0d,0d]
endif

if keyword_set(testall) then begin
;get_data,'mvn_sep1_svy_ATT',ut,state  ; get times of sep1 data
ut=0
tr = ['2014-01-06/16:53:00', '2014-01-06/23:40:30']
spice_position_to_tplot,/normalize,'SUN','MAVEN',frame='MAVEN_SEP1' ,check_obj='maven_spacecraft'  ;,trange=tr
spice_position_to_tplot,/normalize,'SUN','MAVEN',frame='MAVEN_SEP2' ,check_obj='maven_spacecraft'  ;,trange=tr
endif



if keyword_set(testall) then begin
tr =[ '2014-1-6/16:29','2014-1-7/16:40']
spice_qrot_to_tplot,'MAVEN_SPACECRAFT',frame='MAVEN_SO',get_omega=3,trange=tr,res=30.,names=tn
tplot,tn,trange=[0.,0.d]
endif

if  keyword_set(testall) then begin
tr =[ '2014-1-6/16:29','2014-1-7/16:40']
spice_qrot_to_tplot,'MAVEN_MSO',frame='MAVEN_MME_2000',get_omega=3,trange=tr,res=30.,names=tn
tplot,tn,trange=[0d,0d]
endif



if 0 && keyword_set(testall) then begin
tr =[ '2013-1-360','2014-1-5']
tr =[ '2013-1-361','2013-1-362']
spice_qrot_to_tplot,'RBSPA_SPACECRAFT',get_omega=3,res=1,trange=tr,names=names
tplot,names
endif





end





;cspice_sxform
;cspice_ckgp ; only works with certain files 
;cspice_pxform,from,to,et,res    ; 3 element position? (online documentation is misleading
;cspice_sxform,from,to,et,res    ; Returns 6 element state vector rotation matrix
;cspice_ckgp,inst,sclkdp,tol,ref,cmat,clkout,found    ; only works with certain files ?
;printdat,cmat,clkout,found
;return,cmat
