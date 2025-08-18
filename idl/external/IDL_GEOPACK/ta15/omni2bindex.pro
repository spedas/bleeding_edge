;+
;Procedure: omni2bindex
;
;Purpose: Generate and return the B-index parameter for the TA15B field model.  Input parameters are assumed to be smoothed on 30 minute intervals 
;         preceding each sample, and interpolated to a common time base.  The index is defined as
;         
;         B = (N_p/5.0)^(1/2) * (V_p/400.0)^(5.0/2.0) * (b_t/5.0) * sin(theta_c/2.0)^6
;    
;         where b_t is the tangential component of the IMF, and theta_c is the IMF clock angle (0 deg = due north, 90 deg = dawnward)
;         
;         Input values should have a cadence of 5 minutes/sample.   Output values will be averaged from the current sample and six
;         previous samples, therefore the solar wind data should be loaded for at least 30 minutes preceding the times being modeled.
;
;Input:
;
;Keywords:
;         yimf:  (input) Array giving the IMF Y component in GSM coordinates, e.g, from OMNI_HRO_5min_Y_GSM
;
;         zimf:  (input) Array giving the IMF Z component in GSM coordinates, e.g. from OMNI_HRO_5min_Z_GSM
;
;         V_p:   (input) Solar wind (proton) speed, expressed as a scalar, in km/sec, e.g from OMNI_HRO_5min_flow_speed
;
;         N_p:   (input) Solar wind (proton) density, units cm^-3.  e.g. from OMNI_HRO_5min_proton_density
;
;
;Example:
;         b_index = omni2bindex(yimf=yimf, zimf=zimf, N_p=np, V_p=vp)   
;
;Notes:
;  See Boynton 2011 for details:
;  https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2010JA015505
;;
;  TA15B and TA15N model description:
;  https://geo.phys.spbu.ru/~tsyganenko/TA15_Model_description.pdf
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-01-31 22:30:46 -0800 (Mon, 31 Jan 2022) $
; $LastChangedRevision: 30550 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/omni2bindex.pro $
;-

function omni2bindex,yimf=yimf,zimf=zimf, N_p=N_p, V_p=V_p

   ; clock angle of IMF, radians
   theta_c = atan2(yimf,zimf)
   
   ; tangential component of IMF  
   b_t = sqrt(yimf*yimf + zimf*zimf)
   
   bt5 = b_t/5.0D
     
   stc2 = sin(theta_c/2.0D)
   stc2_sqr = stc2*stc2  ; squared
   stc3 = stc2*stc2_sqr  ; cubed
   stc6 = stc3*stc3  ;  6th power of sin(theta_c/2)
   
   
   b_index = sqrt(N_p/5.0D)*(V_p/400.0D)^(5.0D/2.0D) * bt5 * stc6
   
   ; Do the 30 minute running average using the IDL convol function
   
   ; Kernel  
   k=replicate(1.0D, 7)
   
   ; Scale factor   
   s=7.0
   
   ; Perform convolution using 6 preceding plus current sample
   b_index_avg = convol(b_index,k,s,center=0)
   
   return, b_index_avg
end