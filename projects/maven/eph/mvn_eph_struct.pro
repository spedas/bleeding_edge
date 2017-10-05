;+ 
;
;FUNCTION:        MVN_EPH_STRUCT
;   
;PURPOSE:         Creates a MAVEN ephemeris structure template.
;                 The structure elements are as follows:
;
;     time    :   spacecraft event time (seconds since 1970-01-01/00:00:00)
;     ;;orbit   : orbit numbers (TBD)
;     x_ss    :   s/c location in ss coordinates (x)
;     y_ss    :   s/c location in ss coordinates (y)
;     z_ss    :   s/c location in ss coordinates (z)
;     vx_ss   :   s/c velocity in ss coordinates (x)
;     vy_ss   :   s/c velocity in ss coordinates (y)
;     vz_ss   :   s/c velocity in ss coordinates (z)
;     x_pc    :   s/c location in pc coordinates (x)
;     y_pc    :   s/c location in pc coordinates (y)
;     z_pc    :   s/c location in pc coordinates (z)
;     Elon    :   east longitude of s/c [radians]
;     lat     :   latitude of s/c [radians]
;     alt     :   s/c altitude above Mars surface [km]
;     sza     :   solar zenith angle of s/c [radians]
;     lst     :   local solar time of s/c (0 = midnight, 12 = noon) [hour] 
;     ;;sun     : sunlight flag (0 = s/c in Mars' optical shadow
;                                1 = s/c illuminated by sun) (TBD)
;
;     The coordinate systems are:
;
;     SS = Mars-centered, sun-state coordinates: (MSO)
;                 X -> Sun
;                 Y -> opposite to Mars' orbital motion
;                 Z -> X x Y
;
;     PC = Mars-centered, body-fixed coordinates: (IAU_MARS)
;                 X -> 0 deg longitude, 0 deg latitude
;                 Z -> +90 deg latitude (Mars' north pole)
;                 Y -> Z x X (= +90 deg east longitude)
;
;USAGE:           mvn_eph = mvn_eph_struct(npts)
;   
;INPUTS:
;
;     NPTS:       Number of ephemeris points.
;
;KEYWORDS:
;
;     INIT:       Initialize the structure with the specified float scalar.
;                 Default = !values.f_nan
;
;CREATED BY:	  Takuya Hara on 2014-10-06.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-03-24 16:28:09 -0700 (Tue, 24 Mar 2015) $
; $LastChangedRevision: 17176 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/mvn_eph_struct.pro $
;
;-
FUNCTION mvn_eph_struct, npts, init=init
  IF keyword_set(init) THEN init = FLOAT(init) ELSE init = !values.f_nan
  mvn_eph = {  time  : 0D   , $
               ;; orbit : 0    , $
               x_ss  : init , $
               y_ss  : init , $
               z_ss  : init , $
               vx_ss : init , $
               vy_ss : init , $
               vz_ss : init , $
               x_pc  : init , $
               y_pc  : init , $
               z_pc  : init , $
               Elon  : init , $
               lat   : init , $
               alt   : init , $
               sza   : init , $
               lst   : init } ;;, $
               ;; sun   : 0B      }
  IF (npts GT 1) THEN mvn_eph = REPLICATE(mvn_eph, npts)
  RETURN, mvn_eph
END 
