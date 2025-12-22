;+
; PROCEDURE:
; 	 tms_himass_get_angles
;
; DESCRIPTION:
;
;	Procedure to return the theta and phi arrays for TEAMS HiMass data
;
; CALLING SEQUENCE:
;
; 	tms_himass_get_angles, theta, dtheta, phi, dphi
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
;	@(#)tms_himass_get_angles.pro	1.1 08/16/95
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Aug '95
;-


PRO tms_himass_get_angles, theta, dtheta, phi, dphi

   thetamin=								   $
     [ -22.5   ,-22.5   ,22.5    ,-90     ,-22.5   ,-22.5   ,22.5          $
       ,-90     ,-22.5   ,-22.5   ,22.5    ,-90     ,-22.5   ,-22.5        $
       ,22.5    ,-90     ]

   thetamax = 								   $
     [ 22.5    ,22.5    ,90      ,-22.5   ,22.5    ,22.5    ,90            $
       ,-22.5   ,22.5    ,22.5    ,90      ,-22.5   ,22.5    ,22.5         $
       ,90      ,-22.5   ]

   phimin = 								   $
     [ 0       ,45      ,0       ,0       ,180     ,225     ,180           $
       ,180     ,90      ,135     ,90      ,90      ,270     ,315          $
       ,270     ,270     ]

   phimax =								   $
     [ 45      ,90      ,90      ,90      ,225     ,270     ,270           $
       ,270     ,135     ,180     ,180     ,180     ,315     ,360          $
       ,360     ,360     ]

   theta = FLOAT (REPLICATE (1., 48) # (thetamin+thetamax)/2.)
   dtheta = FLOAT (thetamax - thetamin)
   phi = FLOAT (REPLICATE (1., 48) # (phimin+phimax)/2.)
   dphi = FLOAT (phimax - phimin)

END
