;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; neutral_sheet - This routine calculates the NS position along the zaxis 
;                 at a specific x and y location, Z of the NS in gsm coordinates. 
;                 The value is positive if the NS is above Z=0 gsm plane, negative if below
;                 All input,output in re.
;                 Models include 'sm','themis', 'aen', 'den', 'fairfield',  
;                 'den-fairfield', 'lopez'. Default is 'themis'. 
;
; *** WARNING *** These models have been initially verified but require 
;                 more testing. Use with caution!!!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; Inputs:
;
;   time - array of time stamps for position data. Time is double precision
;          number of seconds since Jan 01, 1970.
;   gsm_pos - position data, units are in RE, default coordinate system is gsm
;             pos=[x,y,z] (ex: x=pos[*,0], y=pos[*,1], z=pos[*,2]) an Nx3 array
;
; Input Keywords [optional]:
;   
;   model - name of the neutral sheet model used to generate distance data
;           Models include 'sm','themis', 'aen', 'den', 'fairfield', 'den-fairfield',
;           'lopez'. Default is 'themis'.
;   kp - kp value used by the lopez model. Default value is 0.
;   mlt - magnetic latitude in degrees used by the lopez model. Default is 0.0
;   in_coord - set this keyword equal to the input coordinate system of the data
;              if it's not in gsm coordiantes. Valid coordinate systems are: 
;              [gei, gsm, sm, gse, geo]
;   sc2NS - if set, the routine returns distance to the neutral sheet from the spacecraft 
;           position 
;   
; Output Keywords:
;    
;   distance2NS - Z of the NS in gsm coordinates. The value is positive if the NS is above Z=0 gsm plane, 
;                 negative if below 
;                 If /sc2NS is set the value is positive if the NS is northward of the SC location, 
;                 and negative if below 
;
; Example:
;   neutral_sheet, time, gsm_pos, model='themis', distance2NS=distance2NS
;   neutral_sheet, time, gsm_pos, model='lopez', kp=kp, mlt=mlt
;   neutral_sheet, time, gsm_ops, model='sm', /sc2NS
;   
;  Modification History:
;    Initial Release - clrussell, 03-26-12
;
;  Notes:
;  1. The THM model returns the closest results at larger distances and 
;     the LM model - for smaller distances.
;  2. While the model scripts work, there is no such thing as the best 
;     or most accurate model. 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;NAME:
; sm_ns_model
;
;PURPOSE:
; This routine calculates the NS position along the zaxis at a specific x and y location. 
;
;CALLING SEQUENCE:
; zNS=sm_ns_model(time, position)
; or
; dz2NS=sm_ns_model(time, position, /sc2ns)
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS) 
;        Value is positive if NS is above z=0 gsm plane, negative if below
;    
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet 
;            Value is positive if the NS is northward of the SC location, and negative if below
;    
;    
;NOTES:
;    For the nominal mission, THEMIS used this model for the inner probes
;
;HISTORY:
;
;-----------------------------------------------------------------------------

FUNCTION sm_ns_model, time, gsm_pos, sc2NS=sc2NS

; convert gsm to sm coordinates
cotrans,gsm_pos,sm_pos,time,/GSM2SM
zns = gsm_pos[*,2] - sm_pos[*,2]

IF undefined(sc2NS) THEN BEGIN
  RETURN, zns
ENDIF ELSE BEGIN
  sc2NS = gsm_pos[*,2] - zns
  RETURN, sc2NS
ENDELSE

END


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;NAME:
; themis_NS_model
;
;PURPOSE:
; This routine calculates the position along the zaxis at a specific
; x and y location. The themis model is used for this calculation.
; The themis model uses z-sm (converted from z-gsm) for the inner probes
; and the Hammond model for the outer probes.
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS)
;        Value is positive if NS is above z=0 gsm plane, negative if below
;
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet
;            Value is positive if the NS is northward of the SC location, and negative if below
;
;NOTES;
; Reference:
; The themis model uses z-sm (converted from z-gsm) for the inner probes
; and the Hammond model (default) for the outer probes. The algorithm can be found
; in ssllib neutralsheet.pro.
; 
;HISTORY:
;
;-----------------------------------------------------------------------------

FUNCTION themis_ns_model, time, gsm_pos, sc2NS=sc2NS

; initialize constants and variables
re = 6378.
h0 = 8.6 ;10.5        ; hinge point of the neutral sheet
rad = !pi/180.
dz2NS = make_array(n_elements(time), /double)
tilt = make_array(n_elements(time), /double)

; constants used in hammond model
H1=8.6
Y0=20.2
D=12.2

; calculate the radial distance
rdist = sqrt(gsm_pos[*,0]^2 + gsm_pos[*,1]^2 + gsm_pos[*,2]^2)

; Use the sm coordinates for radial distances <= h0  (8.6)
sm_ind = where(rdist LE h0, ncnt)
IF ncnt GT 0 THEN BEGIN
   cotrans,gsm_pos[sm_ind,*],sm_pos,time[sm_ind],/GSM2SM
   dz2ns[sm_ind] = -sm_pos[*,2]    
ENDIF

; Use the Hammond model for radial distances > h0  (8.6)
lr_ind = where(rdist GT h0, ncnt)
IF ncnt GT 0 THEN BEGIN
   ; initialize variables
   x = gsm_pos[lr_ind,0]
   y = gsm_pos[lr_ind,1]
   z = gsm_pos[lr_ind,2]
   tilt = make_array(n_elements(x), /double)
   ; check input time format and convert to doy, hr, min
   FOR i=0,n_elements(x)-1 DO BEGIN
       IF size(time, /type) EQ 5 or size(time, /type) EQ 7 THEN BEGIN
          time_struc = time_struct(time[lr_ind[i]])
          yr = time_struc.year
          doy = time_struc.doy
          hr = time_struc.hour
          mm = time_struc.min
          sc = time_struc.sec
       ENDIF ELSE BEGIN
          print, 'Invalid time format. Format: YYYY-MM-DD/hh:mm:ss or seconds since 1970'
          RETURN, -1
       ENDELSE    
       ; calculate the tilt in degrees
       geopack_recalc, yr, doy, hr, mm, sc, tilt=tt
       tilt[i]=tt*rad   ;convert to radians
   ENDFOR
   ; hammond model 
   iless=where(abs(y) LT Y0, jless)
   IF (jless GT 0) THEN dz2ns[lr_ind[iless]]=((H1+D)*sqrt(1-y(iless)^2/Y0^2)-D)*sin(tilt(iless))
   imore=where(abs(y) GE Y0, jmore)
   IF (jmore GT 0) THEN dz2ns[lr_ind[imore]]=-D*sin(tilt(imore))

ENDIF

IF undefined(sc2NS) THEN BEGIN
  RETURN, gsm_pos[*,2] - (-dz2ns)
ENDIF ELSE BEGIN
  RETURN, -dz2ns
ENDELSE

END


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
;NAME:  
; aen_ns_model
;
;PURPOSE:  This program is to find the AEN(Analytical Equatorial Neutral) sheet in the 
;          magnetopause in different time and position
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS)
;        Value is positive if NS is above z=0 gsm plane, negative if below
;
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet
;            Value is positive if the NS is northward of the SC location, and negative if below
; 
;NOTES:
;
; References:
;(1) AEN(Analytical Equatorial Neutral):
;    Zhu, M. and R.-L. Xu, 1994, A continuous neutral sheet model and a normal
;    curved coordinate system in the magnetotail,  Chinese J. Space Science,  14,
;    (4)269, (in Chinese).
;    Wang, Z.-D. and R.-L. Xu, Neutral Sheet Observed on ISEE Satellite, 
;    Geophysical Research Letter, 21, (19)2087, 1994.
;(2) Magnetopause model:
;    Sibeck, D. G., R. E. Lopez, and E. C. Roelof, Solar wind control of the
;    magnetopause shape, location, and motion, J. Grophys. Res., 96, 5489, 1991
;
;HISTORY:
;
;-----------------------------------------------------------------------------

FUNCTION aen_ns_model, time, gsm_pos, z2ns=z2ns, sc2NS=sc2NS

; initialize constants
rad = !pi/180.
h0 = 12.6/!pi

dz2ns = make_array(n_elements(time), /double)

FOR i=0,n_elements(time)-1 DO BEGIN
    
    ; convert time into year, doy, ....
    IF size(time, /type) EQ 5 or size(time, /type) EQ 7 THEN BEGIN
       time_struc = time_struct(time[i])
       yr = time_struc.year
       doy = time_struc.doy
       hr = time_struc.hour
       mm = time_struc.min
       sc = time_struc.sec
    ENDIF ELSE BEGIN
       print, 'Invalid time format. Format: YYYY-MM-DD/hh:mm:ss or seconds since 1970'
       RETURN, -1
    ENDELSE

    ; calculate the tilt angle
    geopack_recalc, yr, doy, hr, mm, sc, tilt=tt
    
    ; calcuate the position of the neutral sheet
    dz2NS[i] = -h0 * sin(tt*rad) * atan(gsm_pos[i,0]/5) * (2*cos(gsm_pos[i,1]/6))

ENDFOR 

IF undefined(sc2NS) THEN BEGIN
  RETURN, dz2ns
ENDIF ELSE BEGIN
  RETURN, gsm_pos[*,2]-dz2ns
ENDELSE

END


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;NAME:  
; den_ns_model
;
;PURPOSE:
; This program finds the DEN(Displaced Equatorial Neutral) sheet inside 
;  the magnetopause in different tine and positions. The routine calculates 
;  the position along the zaxis at a specific location. 
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS) 
;        Value is positive if NS is above z=0 gsm plane, negative if below
;    
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet 
;            Value is positive if the NS is northward of the SC location, and negative if below
;    
;NOTES: 
;References:
;(1) DEN(Displaced Equatorial Neutral):
;    Xu, R.-L., A Displaced Equatorial Neutral Sheet Surface Observed on ISEE-2
;    Satellite,  J. Atmospheric and Terrestrial Phys., 58, 1085, 1991
;(2) Magnetopause model:
;    Sibeck, D. G., R. E. Lopez, and R. C. Roelof, Solar wind control of the
;    magnetopause shape, location, and motion, J. Grophys. Res., 96, 5489, 1991
;Original Authors of the FORTRAN source code:
;Ronglan XU and Lei LI, Center for Space Sci. and Applied Res.,
;Chinese Academy of Sciences, PO Box 8701, Beijing 100080, China
;E-mail: XURL@SUN.IHEP.AC.CN, XURL@SUN20.CSSAR.AC.CN
;
;This source code was ported from the original FORTRAN source code into IDL
;The original source code only calculated to 10.05 RE. In this IDL version
;that restriction was increased to 25. 
; 
;HISTORY:
;
;-----------------------------------------------------------------------------

; helper function
PRO SMPF, xgsm, rmp, im

   im = 0
   rmp2 = -0.14*xgsm^2 - 18.2*xgsm+217.4
   IF rmp2 LT 0 THEN BEGIN
      im = 9999.99    
   ENDIF ELSE BEGIN
      rmp = sqrt(rmp2)
      IF xgsm LE -65 THEN rmp = 28.5
   ENDELSE

END

; helper function
PRO SFA4, aa, bb, cc, dd, x

   ndx = 0
   xmin = 0
   xmax = 50
   ndxmax = 3
   dx = 1
   x = xmin
   yy = x^4 + aa*x^3 + bb*x^2 + cc*x + dd

   WHILE ndx LE ndxmax DO BEGIN
      x = x+dx
      IF x GE xmax THEN BEGIN
         ndx = 0
         RETURN
      ENDIF
      y = x^4 + aa*x^3 + bb*x^2 + cc*x + dd
      ry = y/yy
      IF ry LT 0. THEN BEGIN
         x = x-dx
         dx = dx/10.
         ndx = ndx+1
      ENDIF ELSE BEGIN
          yy = y
      ENDELSE           
   ENDWHILE

END

; helper function
PRO SD1, til, H,  H1,  xgsm, d

      ct = cos(til)
      xx = xgsm
      xh = -H*ct
      IF xgsm GE xh THEN xx = xh

      ; calculate the radius of the cross section
      IF xx LE -5. THEN rm = 9*(10-3*xx)/(10-xx)+3
      IF xx GT -5. THEN rm = sqrt(18^2-(xx+5)^2)
      rm2 = RM^2

      ; in cross_section areas above and below the neutral
      ; sheet
      aa = 4*H-(32*rm2*H^2)/(!pi^2*H1^2*(H-xx/ct))
      bb = 2*H^2*(3.-8.*rm2/(!pi^2*H1^2))
      cc = 4*(H^3)
      dd = H^4
      sfa4, aa, bb, cc, dd, x

      d = x
      IF xgsm GE xh THEN BEGIN
         fk = -x/sqrt(-xh)
         d = -fk*sqrt(-xgsm)
      ENDIF

END

FUNCTION den_ns_model, time, gsm_pos, sc2NS=sc2NS

; calcuate the position of the neutral sheet along z axis
H = 25.5      
H1 = 25.05
rad = !pi/180.

dz2ns = make_array(n_elements(time), /float)

FOR i = 0, n_elements(time)-1 DO BEGIN

   done = 0
   xgsm = gsm_pos[i,0]
   ygsm = gsm_pos[i,1]

   IF size(time, /type) EQ 5 or size(time, /type) EQ 7 THEN BEGIN
      time_struc = time_struct(time[i])
      yr = time_struc.year
      doy = time_struc.doy
      hr = time_struc.hour
      mm = time_struc.min
      sc = time_struc.sec
   ENDIF ELSE BEGIN
      print, 'Invalid time format. Format: YYYY-MM-DD/hh:mm:ss or seconds since 1970'
      RETURN, -1
   ENDELSE

   ; get tilt angle of magnetic pole
   geopack_recalc, yr, doy, hr, mm, sc, tilt=tt
   tilt = tt * rad
   
   IF xgsm GT -100. THEN BEGIN
      sd1, tilt, H, H1, xgsm, d
      ym21 = ((H1*(H+d))^2) * (1-(xgsm/(H*cos(tilt)))^2)
      ym22 = (H+d)^2 - (d-xgsm/cos(tilt))^2
      ym2 = ym21/ym22
      IF ym2 LT 0 THEN BEGIN
         ie[i] = 2
         CONTINUE
      ENDIF
      ym = sqrt(ym2)
      xd2 = ((H*cos(tilt))^2) * (1-(ygsm/H1)^2)
      IF abs(ygsm) GT H1 THEN xd2 = 0
      ; find the equatorial region
      xd = sqrt(xd2)
      rd = sqrt(xd^2+ygsm^2)
      rsm = sqrt(xgsm^2+ygsm^2)
      IF xgsm GT 0 OR rsm le rd THEN BEGIN
         dz2ns[i] = -xgsm*sin(tilt)/cos(tilt)
         done = 1
      ENDIF 
      IF abs(ygsm) GT ym && done NE 1 THEN BEGIN
         dz2ns[i] = -d*sin(tilt)
         done = 1 
      ENDIF
      IF done NE 1 THEN BEGIN
         dz2ns[i] = ((H+d)*sqrt(1-(ygsm^2)/ym2)-d)*sin(tilt)
      ENDIF

   ENDIF    ; end of xgsm LE 0.
   

ENDFOR

IF undefined(sc2NS) THEN BEGIN
  RETURN, dz2ns
ENDIF ELSE BEGIN
  sc2NS = gsm_pos[*,2] - dz2ns
  RETURN, sc2NS
ENDELSE

END


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;NAME:
; fairfield_NS_model
;
;PURPOSE:
; This routine calculates the position along the zaxis at a specific
; x and y location. The Fairfield model is used to this calculation.
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS) 
;        Value is positive if NS is above z=0 gsm plane, negative if below
;    
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet 
;            Value is positive if the NS is northward of the SC location, and negative if below
;    
;NOTES:
;Reference:
; A statistical determination of the shape and position of the 
; geomagnetic neutral sheet,  Journal of Geophysical Research,
; Vol. 85, No A2, pages 775-780, February 1, 1980
; Author - D. Fairfield
;
;HISTORY:
;
;-----------------------------------------------------------------------------

FUNCTION fairfield_ns_model, time, gsm_pos, sc2NS=sc2NS

; constants (in re)
h0 = 10.5
y0 = 22.5
d = 14.

rad = !pi/180.
dz2NS = make_array(n_elements(time), /double)
tilt = make_array(n_elements(time), /double)

FOR i=0,n_elements(time)-1 DO BEGIN

    ; check input time format and convert to doy, hr, min
    IF size(time, /type) EQ 5 OR size(time, /type) EQ 7 THEN BEGIN
       time_struc = time_struct(time[i])
       yr = time_struc.year
       doy = time_struc.doy
       hr = time_struc.hour
       mm = time_struc.min
       sc = time_struc.sec
    ENDIF ELSE BEGIN
       print, 'Invalid time format. Format: YYYY-MM-DD/hh:mm:ss or seconds since 1970'
       RETURN, -1
    ENDELSE

    ; calculate tilt angle of geomagnetic axis
    geopack_recalc, yr, doy, hr, mm, sc, tilt=tt
    tilt[i] = tt*rad

ENDFOR

; calcuate the position of the neutral sheet along z axis
y_ge_y0 = where(abs(gsm_pos[*,1]) ge y0, ge_count)
y_lt_y0 = where(abs(gsm_pos[*,1]) lt y0, lt_count)
if (ge_count gt 0) then begin
    dz2ns[y_ge_y0] = -d*sin(tilt[y_ge_y0])
endif
if (lt_count gt 0) then begin
    dz2ns[y_lt_y0] = ((h0 + d) * sqrt(1 - gsm_pos[y_lt_y0,1]^2/y0^2) - d)*sin(tilt[y_lt_y0])
endif

IF undefined(sc2NS) THEN BEGIN
  RETURN, dz2ns
ENDIF ELSE BEGIN
  sc2NS = gsm_pos[*,2] - dz2ns
  RETURN, sc2NS
ENDELSE

END


;+ 
;NAME:  
; den_fairfield_ns_model
;
;PURPOSE:
; This routine calculates the position along the zaxis at a specific
; x and y location. 
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS) 
;        Value is positive if NS is above z=0 gsm plane, negative if below
;    
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet 
;            Value is positive if the NS is northward of the SC location, and negative if below
;    
; 
;HISTORY:
;
;-----------------------------------------------------------------------------

FUNCTION den_fairfield_ns_model, time, gsm_pos, sc2NS=sc2NS

; initialize constants
rad = !pi/180.
dz2ns = make_array(n_elements(time), /double)

; Use the den model for radial distances <12.re
rdist = sqrt(gsm_pos[*,0]^2 + gsm_pos[*,1]^2 + gsm_pos[*,2]^2)
sm_ind = where(rdist LE 10., ncnt)
IF ncnt GT 0 THEN dz2ns[sm_ind] = (den_ns_model(time[sm_ind], gsm_pos[sm_ind,*])) 

; use the fairfield model for radial distances >12.re
lr_ind = where(rdist GT 10., ncnt)
IF ncnt GT 0 THEN dz2ns[lr_ind] = (fairfield_ns_model(time[lr_ind], gsm_pos[lr_ind,*])) 

IF undefined(sc2NS) THEN BEGIN
  RETURN, dz2ns
ENDIF ELSE BEGIN
  sc2NS = gsm_pos[*,2] - dz2ns
  RETURN, sc2NS
ENDELSE

END


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;NAME:  
; lopez_NS_model
;
;PURPOSE:
; This routine calculates the position along the zaxis at a specific
; x and y location. The Lopez model is used for this calculation. 
;
;INPUT:
; time - string or double format
;        double(s)  seconds since 1970
;        string(s)  format:  YYYY-MM-DD/hh:mm:ss
; gsm_pos - position vector in GSM coordinates in re (pos[*,3])
; kp - kp index value
; mlt - magnetic local time in degrees (0=midnight)
;
;OUTPUT: returns Z displacement of the neutral sheet above or below the XY plane in Re (zgsm of the NS)
;        Value is positive if NS is above z=0 gsm plane, negative if below
;
;KEYWORDS
;    sc2NS - if set returns Z displacement from the spacecraft to the neutral sheet
;            Value is positive if the NS is northward of the SC location, and negative if below
;
;NOTES:
;Reference:
; The position of the magnetotail neutral sheet in the near-Earth Region,
; Geophysical Research Letters, Vol. 17, No 10, pages 1617-1620, 1990
; Author - Ramon E. Lopez
;
; The lopez model is best used for distances <8.8 RE
;
;HISTORY:
;
;-----------------------------------------------------------------------------

FUNCTION lopez_ns_model, time, gsm_pos, kp=kp, mlt=mlt, sc2NS=sc2NS

; constants
re = 6378.
rad = !pi/180.
IF ~keyword_set(kp) THEN kp = 0
IF ~keyword_set(mlt) THEN mlt = 0.0
tilt = make_array(n_elements(time), /double)
tt = make_array(n_elements(time), /double)

FOR i=0,n_elements(time)-1 DO BEGIN
    ; check input time format and convert to doy, hr, min
    IF size(time, /type) EQ 5 or size(time, /type) EQ 7 THEN BEGIN
       time_struc = time_struct(time[i])
       yr = time_struc.year
       doy = time_struc.doy
       hr = time_struc.hour
       mm = time_struc.min
       sc = time_struc.sec
    ENDIF ELSE BEGIN
       print, 'Invalid time format. Format: YYYY-MM-DD/hh:mm:ss or seconds since 1970'
       RETURN, -1 
    ENDELSE

    ; calculate tilt angle of geomagnetic axis
    geopack_recalc, yr, doy, hr, mm, sc, tilt=t
    tt[i]=t
    tilt[i] = tt[i]

ENDFOR

; calcuate the position of the neutral sheet along z axis
rdist = sqrt(gsm_pos[*,0]^2 + gsm_pos[*,1]^2 + gsm_pos[*,2]^2)
mlat = -(0.14*Kp + 0.69) * ((cos(rad*mlt))^.3333333) * (0.065*(rdist^0.8) - 0.16) * tilt
mlat = mlat + tilt

; convert magnetic latitude to position
rthph2xyz, rdist, mlat, mlt, x, y, z
dz2NS = z

IF undefined(sc2NS) THEN BEGIN
  RETURN, dz2ns
ENDIF ELSE BEGIN
  sc2NS = gsm_pos[*,2] - dz2ns
  RETURN, sc2NS
ENDELSE

END

; Helper function for the lopez model
; converts spherical to cartesian coordinates
; NOTE: th,ph in degrees, and th is latitude (not colatitude) (i.e. [-90->90])
PRO rthph2xyz,r,th,ph,x,y,z

FLAG=6.8792E+28
FLAG98=0.98*FLAG
PI=3.1415926535898

thrad=th*PI/180.
phrad=ph*PI/180.
sth=sin(thrad)
cth=cos(thrad)
sph=sin(phrad)
cph=cos(phrad)
x=r*cth*cph
y=r*cth*sph
z=r*sth

iflags=where((r GT FLAG98) OR (th GT FLAG98) OR (ph GT FLAG98), iany)
IF (iany GT 0) THEN BEGIN
  x(iflags)=FLAG
  y(iflags)=FLAG
  z(iflags)=FLAG
ENDIF

RETURN

END

PRO neutral_sheet, time, pos, kp = kp, model = model, mlt = mlt, in_coord = incoord, $
                   distance2NS = distance2NS, sc2NS = sc2NS

  ; validate and initialize parameters if not set
  IF ~keyword_set(model) THEN model = 'themis' ELSE model = strlowcase(model)
  models = ['sm', 'themis', 'aen', 'den', 'fairfield', 'den_fairfield', 'lopez']
  res = where(model EQ models, ncnt)
  IF ncnt LE 0 THEN BEGIN 
     print, 'An invalid neutral sheet model name was used. Valid entries include: '
     print, models 
     RETURN
  ENDIF
  
  ; check input coordinate system, convert to gsm if needed
  IF ~keyword_set(in_coord) THEN in_coord = 'gsm' ELSE in_coord = strlowcase(in_coord)
  CASE in_coord OF
     'gsm': gsm_pos = pos
     'sm':  cotrans,pos,gsm_pos,time,/SM2GSM
     'gei': BEGIN
         cotrans,pos,gse_pos,time,/GEI2GSE
         cotrans,gse_pos,gsm_pos,time,/GSE2GSM
     END
     'gse': cotrans,pos,gsm_pos,time,/GSE2GSM
     'geo': BEGIN
         cotrans,pos,gei_pos,time,/GEO2GEI
         cotrans,gei_pos,gse_pos,time,/GEI2GSE     
         cotrans,gse_pos,gsm_pos,time,/GSE2GSM
     END
     ELSE: BEGIN
        print, 'Invalid coordinate system.' 
        print, 'Valid coordinate systems are: [gei, gsm, sm, gse, geo]'
        RETURN
     ENDELSE
  ENDCASE  

  ; call the appropriate neutral sheet model  
  CASE model OF
    'sm': distance2NS = sm_ns_model(time, gsm_pos, sc2NS=sc2NS)
    'themis': distance2NS = themis_ns_model(time, gsm_pos, sc2NS=sc2NS)
    'aen': distance2NS = aen_ns_model(time, gsm_pos, sc2NS=sc2NS)
    'den': distance2NS = den_ns_model(time, gsm_pos, sc2NS=sc2NS)
    'fairfield': distance2NS = fairfield_ns_model(time, gsm_pos, sc2NS=sc2NS)
    'den_fairfield': distance2NS = den_fairfield_ns_model(time, gsm_pos, sc2NS=sc2NS)
    'lopez': distance2NS = lopez_ns_model(time, gsm_pos, kp=kp, mlt=mlt, sc2NS=sc2NS)
    ELSE: BEGIN
        print, 'Invalid neutral sheet model.' 
        print, 'Valid models are: [sm, themis, aen, den, fairfield, den_fairfield, lopez]'
        RETURN
    ENDELSE
  ENDCASE

END
