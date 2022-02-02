;+
;Procedure: omni2nindex
;
;Purpose: Generate and return the N-index parameter for the TA15N field model.  Input parameters are assumed to be smoothed on 30 minute intervals
;         preceding each sample, and interpolated to a common time base.  The index is defined as
;
;         N = 0.86 * (V_p/400.0)^(4.0/3.0) * (b_t/5.0)^(2.0/3.0) * sin(theta_c/2.0)^(8.0/3.0)
;
;         where b_t is the magnitude of the tangential component of the IMF, and theta_c is the IMF clock angle (0 deg = due north, 90 deg = dawnward)
;
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
;
;Example:
;         n_index = omni2nindex(yimf=yimf, zimf=zimf, V_p=vp)
;
;Notes:
;  See Newell 2007 for details:
;  https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2006JA012015
;
;  TA15B and TA15N model description:
;  https://geo.phys.spbu.ru/~tsyganenko/TA15_Model_description.pdf
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-01-31 22:30:46 -0800 (Mon, 31 Jan 2022) $
; $LastChangedRevision: 30550 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/omni2nindex.pro $
;-


function omni2nindex,yimf=yimf,zimf=zimf, V_p=V_p

   ; clock angle of IMF, radians
   theta_c = atan2(yimf,zimf)
   
   ; tangential component of IMF  
   b_t = sqrt(yimf*yimf + zimf*zimf)
   
   ; Raise to even powers first, to avoid NaNs with fractional exponents
   bt5 = b_t/5.0D
   bt5_sqr = bt5*bt5
   
   stc2 = sin(theta_c/2.0D)
   stc2_sqr = stc2*stc2
   stc4 = stc2_sqr*stc2_sqr
   stc8 = stc4*stc4  ;  8th power of sin(theta_c/2)
   
   
   n_index = 0.86D * (V_p/400.0D)^(4.0D/3.0D) * (bt5_sqr)^(1.0/3.0D) * stc8^(1.0D/3.0D)
 
   ; Do the 30 minute running average using the IDL convol function

   ; Kernel
   k=replicate(1.0D, 7)

   ; Scale factor
   s=7.0

   ; Perform convolution using 6 preceding plus current sample
   n_index_avg = convol(n_index,k,s,center=0)

   return, n_index_avg  
end