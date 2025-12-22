;+
; PROCEDURE:
; 	 tms_surv_get_angles
;
; DESCRIPTION:
;
;	Procedure to return the theta and phi arrays for TEAMS survey data
;
; CALLING SEQUENCE:
;
; 	tms_surv_get_angles, theta, dtheta, phi, dphi
;
; ARGUMENTS:
;
;	theta:	the returned array of theta angles vs bins
;	dtheta:	the returned array of delta theta angles vs bins
;	phi:	the returned array of phi angles vs bins
;	dphi:	the returned array of delta phi angles vs bins
;
; REVISION HISTORY:
;
;	@(#)tms_surv_get_angles.pro	1.1 08/16/95
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Aug '95
;-


PRO tms_surv_get_angles, theta, dtheta, phi, dphi

   thetamin=								   $
     [ 0.        , -22.5   , 22.5    , 0.      , -22.5   , -45.    , 0.	   $
       , -22.5   , 67.5    , 45.     , 22.5    , 0.      , -22.5   , -45.  $
       , -67.5   , -90.    , 0.      , -22.5   , 22.5    , 0.      , -22.5 $
       , -45.    , 0.      , -22.5   , 67.5    , 45.     , 22.5    , 0.	   $
       , -22.5   , -45.    , -67.5   , -90.    , 0.      , -22.5   , 22.5  $
       , 0.      , -22.5   , -45.    , 0.      , -22.5   , 67.5    , 45.   $
       , 22.5    , 0.      , -22.5   , -45.    , -67.5   , -90.    , 0.	   $
       , -22.5   , 22.5    , 0.      , -22.5   , -45.    , 0.      , -22.5 $
       , 67.5    , 45.     , 22.5    , 0.      , -22.5   , -45.    , -67.5 $
       , -90.]

   thetamax = 								   $
     [ 22.5      ,0.      ,45.     ,22.5    ,0.      ,-22.5   ,22.5        $
       , 0.      ,90.     ,67.5    ,45.     ,22.5    ,0.      ,-22.5       $
       , -45.    ,-67.5   ,22.5    ,0.      ,45.     ,22.5    ,0.          $
       , -22.5   ,22.5    ,0.      ,90.     ,67.5    ,45.     ,22.5        $
       , 0.      ,-22.5   ,-45.    ,-67.5   ,22.5    ,0.      ,45.         $
       , 22.5    ,0.      ,-22.5   ,22.5    ,0.      ,90.     ,67.5        $
       , 45.     ,22.5    ,0.      ,-22.5   ,-45.    ,-67.5   ,22.5        $
       , 0.      ,45.     ,22.5    ,0.      ,-22.5   ,22.5    ,0.          $
       , 90.     ,67.5    ,45.     ,22.5    ,0.      ,-22.5   ,-45.        $
       ,-67.5   ]

   phimin = 								   $
     [ 0.        , 0.      , 0.      , 22.5    , 22.5    , 0.      , 45.   $
       , 45.     , 0.      , 0.      , 45.     , 67.5    , 67.5    , 45.   $
       , 0.      , 0.      , 180.    , 180.    , 180.    , 202.5   , 202.5 $
       , 180.    , 225.    , 225.    , 180.    , 180.    , 225.    , 247.5 $
       , 247.5   , 225.    , 180.    , 180.    , 90.     , 90.     , 90.   $
       , 112.5   , 112.5   , 90.     , 135.    , 135.    , 90.     , 90.   $
       , 135.    , 157.5   , 157.5   , 135.    , 90.     , 90.     , 270.  $
       , 270.    , 270.    , 292.5   , 292.5   , 270.    , 315.    , 315.  $
       , 270.    , 270.    , 315.    , 337.5   , 337.5   , 315.    , 270.  $
       ,270.    ]

   phimax =								   $
     [ 22.5      , 22.5    , 45.     , 45.     , 45.     , 45.     , 67.5  $
       , 67.5    , 90.     , 90.     , 90.     , 90.     , 90.     , 90.   $
       , 90.     , 90.     , 202.5   , 202.5   , 225.    , 225.    , 225.  $
       , 225.    , 247.5   , 247.5   , 270.    , 270.    , 270.    , 270.  $
       , 270.    , 270.    , 270.    , 270.    , 112.5   , 112.5   , 135.  $
       , 135.    , 135.    , 135.    , 157.5   , 157.5   , 180.    , 180.  $
       , 180.    , 180.    , 180.    , 180.    , 180.    , 180.    , 292.5 $
       , 292.5   , 315.    , 315.    , 315.    , 315.    , 337.5   , 337.5 $
       , 360.    , 360.    , 360.    , 360.    , 360.    , 360.    , 360.  $
       , 360.    ]

   theta = FLOAT (REPLICATE (1., 48) # (thetamin+thetamax)/2.)
   dtheta = FLOAT (thetamax - thetamin)
   phi = FLOAT (REPLICATE (1., 48) # (phimin+phimax)/2.)
   dphi = FLOAT (phimax - phimin)

END
