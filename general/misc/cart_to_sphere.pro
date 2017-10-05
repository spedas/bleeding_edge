;+
;*****************************************************************************************
;
;  FUNCTION :   cart_to_sphere.pro
;  PURPOSE  :   Transforms from cartesian to spherical coordinates.
;
;  CALLED BY: 
;               xyz_to_polar.pro
;               add_df2dp.pro
;               add_df2d_to_ph.pro
;
;  CALLS:       NA
;
;  REQUIRES:    NA
;
;  INPUT:
;               X            :  N-Element array of cartesian X-component data points
;               Y            :  N-Element array of cartesian Y-component data points
;               Z            :  N-Element array of cartesian Z-component data points
;               R            :  Named variable to return the radial magnitudes in 
;                                 spherical coordinates
;               THETA        :  Named variable to return the poloidal angles (deg)
;               PHI          :  Named variable to return the azimuthal angles (deg)
;
;  EXAMPLES:
;
;  KEYWORDS:  
;               PH_0_360     :  IF > 0, 0 <= PHI <= 360
;                               IF = 0, -180 <= PHI <= 180
;                               IF < 0, ***if negative, best guess phi range returned***
;               PH_HIST      :  2-Element array of max and min values for PHI
;                                 [e.g. IF PH_0_360 NOT set and PH_HIST=[-220,220] THEN
;                                   if d(PHI)/dt is positive near 180, then
;                                   PHI => PHI+360 when PHI passes the 180/-180 
;                                   discontinuity until phi reaches 220.]
;               CO_LATITUDE  :  If set, THETA returned between 0.0 and 180.0 degrees
;               
;               MIN_VALUE    :  Deprecated keyword, maintained for backwards compatibility
;               MAX_VALUE    :  Deprecated keyword, maintained for backwards compatibility
;
;
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  06/21/2009   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-06-27 16:55:47 -0700 (Wed, 27 Jun 2012) $
; $LastChangedRevision: 10653 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/cart_to_sphere.pro $
; 
;*****************************************************************************************
;- 


PRO cart_to_sphere,x,y,z,r,theta,phi,PH_0_360=ph_0_360,PH_HIST=ph_hist,     $
                                     CO_LATITUDE=co_lat,MIN_VALUE=min_value,$
                                     MAX_VALUE=max_value

;-----------------------------------------------------------------------------------------
; => Define some parameters
;-----------------------------------------------------------------------------------------
rho   = x*x + y*y                     ; => Cylindrical coordinate \rho
r     = SQRT(rho + z*z)               ; => Spherical coordinate radius
phi   = 18e1/!DPI*ATAN(y,x)           ; => Spherical coordinate azimuthal angle (deg)
theta = 18e1/!DPI*ATAN(z/ SQRT(rho))  ; => " " poloidal angle (deg)
IF KEYWORD_SET(co_lat) THEN theta = 9e1 - theta

ph_mid = 0                      ; => middle value of phi
IF NOT KEYWORD_SET(ph_0_360) THEN ph_0_360 = 0
IF (ph_0_360 NE 0) THEN BEGIN
  tmp_phi = phi                 
  a = WHERE((phi GE -180) AND (phi LT 0),acount)
  IF (acount ne 0) THEN tmp_phi[a] = tmp_phi[a] + 360        ; => Make 0 <= tmp_phi <= 360
  IF ((ph_0_360 LT 0) AND (N_ELEMENTS(phi) GT 1)) THEN BEGIN ; => Auto range phi
    subt = [[-1],[1]]                                        ; => [a,b] ## subt = b - a
    mmp  = (CEIL(minmax(phi,    MIN=-360,MAX=360)##subt))[0] ; => phi range
    mmtp = (CEIL(minmax(tmp_phi,MIN=-360,MAX=360)##subt))[0] ; => tmp range
    IF (mmp eq mmtp) THEN BEGIN ; => if ranges are equal, choose one with fewer branch cuts
      a = WHERE(ABS(TS_DIFF(phi,    1)) GT 300,bcount)
      a = WHERE(ABS(TS_DIFF(tmp_phi,1)) GT 300,ccount)
      IF (bcount GT ccount) THEN ph_mid = 180
    ENDIF ELSE IF (mmp GT mmtp) THEN ph_mid = 180 
  ENDIF ELSE ph_mid = 180                                    ; => if ph_0_360 positive
  IF (ph_mid EQ 180) THEN phi = tmp_phi
  tmp_phi = 0                                                ; => deallocate memory
ENDIF 

IF KEYWORD_SET(ph_hist) THEN BEGIN
  ndim0 = (SIZE(ph_hist,/DIMENSIONS))[0]
  ntyp0 = (SIZE(ph_hist,/TYPE))[0]
  IF (ndim0 NE 2) OR (ntyp0 GE 6) THEN BEGIN
    DPRINT,'PH_HIST should be a two element array of numbers'
    DPRINT,'Ignoring request.'
  ENDIF ELSE BEGIN
    for i=1l,n_elements(phi)-1 do begin
      if ((phi[i-1] gt ph_mid)              and $
          (phi[ i ] lt ph_mid)              and $
          (phi[ i ] lt ph_hist[1]-360))     $
        then phi[i] = phi[i]+360
      if ((phi[i-1] lt ph_mid)              and $
          (phi[i] gt ph_mid)              and $
          (phi[i] gt ph_hist[0]+360))     $
        then phi[i] = phi[i]-360
    endfor
  ENDELSE
ENDIF
;-----------------------------------------------------------------------------------------
; => Define min ranges
;-----------------------------------------------------------------------------------------
IF (N_ELEMENTS(min_value) NE 0) THEN BEGIN
   bad  = WHERE(x LE min_value,count)
   minx = MIN(x,/NAN)
   IF (count NE 0) THEN BEGIN
      r[bad]     = minx[0]
      theta[bad] = minx[0]
      phi[bad]   = minx[0]
   ENDIF
ENDIF
;-----------------------------------------------------------------------------------------
; => Define max ranges
;-----------------------------------------------------------------------------------------
IF (N_ELEMENTS(max_value) NE 0) THEN BEGIN
   bad = WHERE(x GE max_value,count)
   maxx = MAX(x,/NAN)
   IF (count NE 0) THEN BEGIN
      r[bad]     = maxx[0]
      theta[bad] = maxx[0]
      phi[bad]   = maxx[0]
   ENDIF
ENDIF
;-----------------------------------------------------------------------------------------
; => If x input is float, make angles floats
;-----------------------------------------------------------------------------------------
ntyp0 = (SIZE(x[0],/TYPE))[0]
IF (ntyp0 EQ 4) THEN BEGIN 
  theta = FLOAT(theta)
  phi   = FLOAT(phi)
ENDIF

RETURN
END

