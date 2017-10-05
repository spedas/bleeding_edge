;+
;Program:  SPICE_CRIB 
;Purpose: This crib sheet is currently for testing/demonstration purposes only ;
;Usage:
;    .run spice_crib
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

dprint,print_trace=4

dprint,'This crib sheet shows how to use some wrapper routines to the CSPICE DLM library routines.
dprint  
dprint,'The added benefits are:
dprint,'  Time conversion from UT (unix time) to/from ET (Ephemeris time)'
dprint,'  Consolidation of KERNEL names to a central procedure/function'
dprint,'  Auto downloading of SPICE KERNELS (data files)'
dprint,'  Vectorization of inputs.  functions and procedures can operate on arrays as well as scalers'
dprint,'  Trapping of data gaps to prevent crashes when requesting data outside the kernel ranges'
dprint,'  Generic informational routines to provide kernel info'
dprint
dprint,'These routines are in development and are quite likely to change (without notice) in the next few months. February 2014
dprint
dprint,'The SPICE_ routines are:
libs,'spice_*'
libs,'time_ephemeris'



if  ~spice_test()  then begin
   message,'You must install the SPICE ICY DLM before proceeding.'
endif

dprint,'Load the supposed "STANDARD" kernals:'
sk = spice_standard_kernels()
printdat , sk


dprint,'Load the kernels -
spice_kernel_load,sk
dprint,'Type ".cont" to continue'
stop 


dprint,'; Display all loaded kernels:
print, spice_test('*')
dprint
dprint,'Type ".cont" to continue'
stop 

dprint,'Get information on all loaded kernels'
info = spice_kernel_info()
print_struct,info
dprint,'Type ".cont" to continue'
stop 


dprint,'; Get planet positions:'
body = 'Earth'
observer = 'Sun'
ut = '2013-1-1'
frame='ECLIPJ2000'
earth_position =  spice_body_pos(body,observer,utc=ut,frame=frame) 
printdat,ut,body,observer,frame,earth_position
dprint,'Type ".cont" to continue'
stop 

dprint
dprint,'Get 2 years of planet positions (1 day resolution)'
ut = time_double(ut) +dindgen(2*365) * 24d*3600d
earth_position =  spice_body_pos(body,observer,utc=ut,frame=frame) 
printdat,ut,body,observer,frame,earth_position
dprint,'Type ".cont" to continue'
stop 

dprint
dprint,'Get mars ephemeris data:  ONLY new Kernels are loaded. Previous kernels are ignored.
sk = spice_standard_kernels(/load,/mars)
mars_position =  spice_body_pos(body,observer,utc=ut,frame=frame) 
printdat,ut,body,observer,frame,mars_position
dprint,'Type ".cont" to continue'
stop 


dprint
dprint,'Get information on all loaded kernels'
kernel_info = spice_kernel_info(verbose=2)
dprint,'Type ".cont" to continue'
stop 

dprint
dprint
dprint,'Display information on all loaded kernels'
print_struct,kernel_info
dprint,'Type ".cont" to continue'
stop 

dprint
dprint,'Get FRAME transformation matrix
from_frame = 'IAU_EARTH'
to_frame = 'EClIPJ2000'
mrot = spice_body_att(from_frame,to_frame,ut)
printdat,from_frame,to_frame,ut,mrot
dprint,'Type ".cont" to continue'
stop 

dprint
dprint,'Get FRAME transformation unit Quaternion
from_frame = 'EClIPJ2000'
to_frame = 'IAU_EARTH'
qrot = spice_body_att(from_frame,to_frame,ut,/quaternion)
printdat,from_frame,to_frame,ut,qrot
dprint,'Type ".cont" to continue'
stop 


if 1 then begin
frame='ECLIPJ2000'
scale = 149.6e6
timespan,'13-1-1',365*2
dprint,'Create some TPLOT variables with position data and then plot it.'
spice_position_to_tplot,'Earth','SUN',frame=frame,res=3600d*24,scale=scale,name=n2
spice_position_to_tplot,'MARS','SUN',frame=frame,res=3600d*24,scale=scale,name=n3
options,n3,linestyle=2
store_data,'POS',data=[n2,n3]
tplot,'POS',tr=[0d,0]
dprint,'Type ".cont" to continue'
stop 
endif







end


