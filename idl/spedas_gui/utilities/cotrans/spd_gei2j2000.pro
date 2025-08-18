;
; SPD_GEI2J2000
;
; Routines to transform from GCI coordinates to GEO coordinates,
; as well as GCI J200 to GCI True of Date.
; The following ISTP ICSS routines are appended in this file.
; 
; SPD_MAKE_J2000_MATRIX
; SPD_GCI_TO_GEO
; SPD_GET_NUT_ANGLES
; SPD_GRNWCH_SIDEREAL
;
; These routines were provided by CDAWlib and incorporated
; into spedas. The routines can be found at the SPDF web
; site and are in the IC_GCI_TRANSF.pro routine. 
; 
; In addition, the NAG routine F01CKF is emulated by a subroutine
; included in this file.  Consequently, this code should not be
; linked with the NAG libraries if available. The SPD_ and IC_ 
; routines have not been modified in any fashion other than 
; comments and or variable names.
;
; A good reference for the routines below is 'An Explanatory
; Supplement to the Astronomical Almanac,' P. Kenneth Seidelmann, ed.
; University Science Books, 1992.  ISBN 0-935702-68-7
;
; G. GERMANY   8/9/95
;
;
;------------------------------------------------------------------

@ic_gci_transf

;
; SPD_GCI_TO_GEO - return a transformation matrix
;
; PURPOSE:  Calculate the transformation matrix from GCI
;           coordinates to GEO coordinates at a given date and time.
;
; UNIT TYPE:  SUBROUTINE
;
; Example: 
;   
;   SPD_GCI_TO_GEO (orb_pos_time, transform_matrix)
;
; INPUT:
;
; orb_pos_time(2)        int      I    time OF ORB. VECTOR, year-day-MILLI OF day
;
; OUTPUT:
; transform_matrix(3,3)  double   O    TRANSFORMATION MATRIX
;
;
; DEVELOPMENT HISTORY
;
; AUTHOR  CHANGE ID RELEASE   DATE      DESCRIPTION OF CHANGE
; ------  --------- -------   ----      ---------------------
; J. LUBELCZYK      B1R1      11/21/90  INITIAL PDL
; J. Lubelczyk      B1R1      12/10/90  CODING
; J. Lubelczyk                           09/18/91  Updated to return true
;                                                  of date trans matrix
; J. LUBELCZYK ICCR #83, CCR #'S 130, 137 11/91    B3 update
; SPDF
; C. Russell                  09/21/2015 INTEGRATED INTO SPEDAS
;
; NOTES:
;

PRO spd_gci_to_geo, orb_pos_time, transform_matrix


  mean_matrix = DBLARR(3,3)
  transform_matrix = DBLARR(3,3) ;transformation matrix
  cmatrix = DBLARR(3,3)       ;the conversion matrix to rotate from
  ;mean of date to true of date

  spd_grnwch_sidereal, orb_pos_time, grnwch_sidereal_time

  ;
  ;   calculate the sin and cos of the greenwich mean sidereal time
  ;
  sin_gst = sin(grnwch_sidereal_time)
  cos_gst = cos(grnwch_sidereal_time)

  ;
  ;   Fill the mean of date transformation matrix using the sin and cos
  ;    of the greenwich mean sidereal time
  ;
  mean_matrix[0,0] = cos_gst
  mean_matrix[0,1] = -sin_gst
  mean_matrix[0,2] = 0
  mean_matrix[1,0] = sin_gst
  mean_matrix[1,1] = cos_gst
  mean_matrix[1,2] = 0
  mean_matrix[2,0] = 0
  mean_matrix[2,1] = 0
  mean_matrix[2,2] = 1

  spd_make_j2000_matrix,orb_pos_time, cmatrix

  transform_matrix = TRANSPOSE( $
    TRANSPOSE(mean_matrix) # TRANSPOSE(cmatrix) )

END


; SPD_MAKE_J2000_MATRIX - Returns the conversion matrix that is necessary to rotate
;       from mean of date to true of date
;
; PURPOSE:  THIS SUBROUTINE CALCULATES, THROUGH APPROPRIATE ANALYTIC
;           EXPRESSIONS, VALUES FOR THE PRECESSION AND NUTATION
;           ANGLES AND THE MATRIX REQUIRED TO ROTATE FROM MEAN OF
;           JULIAN 2000 TO TRUE OF DATE.
; NAME                 TYPE   USE  DESCRIPTION
; ----                ----   ---  -----------
; orb_pos_time(2)     I*4    I    time OF ORB. VECTOR, year-day-MILLI OF day
; CMATRIX(3,3)        R*8    O    Matrix to rotate from J2000 to true of date
;
; EXTERNAL REFERENCES:
; F01CKF - NAG routine that multiplies two matrices
; From SPDF IC_GET_NUT_ANGLES          Routine to compute the nutation angles
;

PRO spd_make_j2000_matrix, orb_pos_time, cmatrix

  cmatrix = DBLARR(3,3)    ;conversion matrix
  nutmat = DBLARR(3,3)      ;Nutation matrix
  premat = DBLARR(3,3)      ;precession matrix

  Jdj2000 = DOUBLE (2451545.0)
  R = DOUBLE (1296000.0)


  ;   Convert the given millisecond of day [orb_pos_time[1]] to second of day.
  ;   Convert the packed form into year and day-of-year

  secs = (DOUBLE(orb_pos_time[1]))/DOUBLE(1000.0)
  year = orb_pos_time[0]/1000
  day  = orb_pos_time[0] MOD 1000

  ;
  ;   Calculate the julian date and the time in Julian centuries from J2000
  ;
  fday = secs/DOUBLE(86400.00)
  jul_day = julday(1,1,year,0,0,0) + DOUBLE(day)+fday
  time = (jul_day - Jdj2000)/DOUBLE(36525.0)

  T2 = time*time
  T3 = time*T2

  ;    CALCULATE CONVERSION FACTORS: DEGREES TO RADANS (dtr), SECONDS TO
  ;    RADIANS (str)
  ;
  PI= DOUBLE(4.0 * ATAN(1.0))
  dtr=PI/DOUBLE(180.0)
  str=dtr/DOUBLE(3600.0)


  ;    CALCULATE PRECESSION ANGLES

  zeta   = DOUBLE(                      $
    0.11180860865024398D-01*time $
    + 0.14635555405334670D-05*T2 $
    + 0.87256766326094274D-07*T3 )
  theta  = DOUBLE(                      $
    0.97171734551696701D-02*time $
    - 0.20684575704538352D-05*T2 $
    - 0.20281210721855218D-06*T3 )
  zee    = DOUBLE(                      $
    0.11180860865024398D-01*time $
    + 0.53071584043698687D-05*T2 $
    + 0.88250634372368822D-07*T3 )

  sinzet = sin(zeta)
  coszet = cos(zeta)
  sinzee = sin(zee)
  coszee = cos(zee)
  sinthe = sin(theta)
  costhe = cos(theta)
  ;
  ;    COMPUTE THE TRANSFORMATION MATRIX BETWEEN MEAN EQUATOR AND
  ;    EQUINOX OF 1950 AND MEAN EQUATOR AND EQUINOX OF DATE. THIS
  ;    MATRIX IS CALLED premat.
  ;
  premat[0,0] = -sinzet*sinzee  + coszet*coszee*costhe
  premat[0,1] =  coszee*sinzet  + sinzee*costhe*coszet
  premat[0,2] =  sinthe*coszet
  premat[1,0] = -sinzee*coszet  - coszee*costhe*sinzet
  premat[1,1] =  coszee*coszet  - sinzee*costhe*sinzet
  premat[1,2] = -sinthe*sinzet
  premat[2,0] = -coszee*sinthe
  premat[2,1] = -sinzee*sinthe
  premat[2,2] =  costhe

  ;    CALCULATE MEAN OBLIQUITY OF DATE (epso). WHERE TIME IS MEASURED IN
  ;    JULIAN CENTURIES FROM 2000.0.

  epso=DOUBLE( (1.813E-3*T3-5.9E-4*T2 $
    -4.6815E+1*time+8.4381448E+4)*str )


  ;    CALL SPD_GET_NUT_ANGLES TO COMPUTE NUTATION IN OBLIQUITY AND LONGITUDE

  spd_get_nut_angles,time,deleps,delpsi,eps

  cosep=cos(eps)
  cosepO=cos(epso)
  cospsi=cos(delpsi)
  sinep=sin(eps)
  sinepO=sin(epso)
  sinpsi=sin(delpsi)

  nutmat[0,0]=cospsi
  nutmat[1,0]=-sinpsi*cosepO
  nutmat[2,0]=-sinpsi*sinepO
  nutmat[0,1]=sinpsi*cosep
  nutmat[1,1]=cospsi*cosep*cosepO+sinep*sinepO
  nutmat[2,1]=cospsi*cosep*sinepO-sinep*cosepO
  nutmat[0,2]=sinpsi*sinep
  nutmat[1,2]=cospsi*sinep*cosepO-cosep*sinepO
  nutmat[2,2]=cospsi*sinep*sinepO+cosep*cosepO

  ;    CALCULATE ELEMENTS OF nutmat * premat.  THIS MATRIX IS THE
  ;    ANALYTICALLY CALCULATED TRANSFORMATION MATRIX, WHICH WILL
  ;    TRANSFORM THE MEAN EARTH EQUATOR AND EQUINOX OF J2000 INTO
  ;    THE TRUE EARTH EQUATOR AND EXQUINOX OF DATE.

  ;     cmatrix = nutmat # premat
  cmatrix = TRANSPOSE(TRANSPOSE(premat) # TRANSPOSE(nutmat))

END




; SPD_GET_NUT_ANGLES - Returns angles that are necessary to adjust the
;          Greenwich Hour angle to true of date
;
; PURPOSE : THIS SUBROUTINE CALCULATES, THROUGH APPROPRIATE ANALYTIC
;           EXPRESSIONS, VALUES FOR THE NUTATION
;           ANGLES TO ROTATE FROM MEAN OF
;           JULIAN 2000 TO TRUE OF DATE.
;
; NAME        TYPE    USE DESCRIPTION
; ----       ----    ---       -----------
; time       R*8     I         time IN JULIAN CENTURIES OF 36525.0
;                              MEAN SOLAR dayS FROM J2000. (NOTE: THIS
;                              CAN BE POSITIVE OR NEGATIVE.)
; deleps     R*8     O          DELTA epsILON, Nutation in obliquity
; delpsi     R*8     O         DELTA PSI, Nutation in longitude
; eps        R*8     O         epsILON



PRO spd_get_nut_angles,time,deleps,delpsi,eps


  TOL = DOUBLE(0.5)/DOUBLE(36525.0)


  isinco = FLTARR(2,106)   ;Array used in nutation calculations
  icosco = FLTARR(2,106)   ;Array used in nutation calculations
  fund = DBLARR(1,5)      ;The fundamental arguments
  T = DBLARR(1,2)     ;Time
  ifunar = intarr(5,106)   ;array used in nutation calculations
  oldtim = DOUBLE(0.0)



  ;
  ;    INITIALIZE VALUES OF IFUNAR, isinco, AND icosco ARRAYS FOR USE IN
  ;    NUTATION CALCULATIONS.
  ;
  ;    THE 1980 IAU THEORY OF NUTATION,CONTAINED IN JPL
  ;    DE200 PLANETARY EPHEMERIS.


  ifunar[0,0:79] = [0,0,2,-2,2, 0,2,-2,2,0, 2,2,2,0,2, 0,0,2,0,0, $
    2,0,2,0,0, -2,-2,0,0,2, 2,0,2,2,0, 2,0,0,0,2, $
    2,2,0,2,2,  2,2,0,0,2,  0,2,2,2,0, 2,0,2,2,0, $
    0,2,0,-2,0, 0,2,2,2,0,  2,2,2,2,0, 0,0,2,0,0]
  ifunar[0,80:105] = [2,2,0,2,2,  2,4,0,2,2,  0,4,2,2,2, 0,-2,2,0,-2, $
    2,0,-2,0,2, 0]

  ifunar[1,0:79] = [1,2,1,0,2, 0,1,1,2,0,  2,2,1,0,0, 0,1,2,1,1, $
    1,1,1,0,0, 1,0,2,1,0,  2,0,1,2,0, 2,0,1,1,2, $
    1,2,0,2,2, 0,1,1,1,1,  0,2,2,2,0, 2,1,1,1,1, $
    0,1,0,0,0, 0,0,2,2,1,  2,2,2,1,1, 2,0,2,2,0]
  ifunar[1,80:105] = [2,2,0,2,1, 2,2,0,1,2,  1,2,2,0,1, 1,1,2,0,0, $
    1,1,0,0,2, 0]

  ifunar[2,0:79] = [0,0,0,0,0, -1,-2,0,0,1,  1,-1,0,0,0, 2,1,2,-1,0, $
    -1,0,1,0,1,  0,1,1,0,1,   0,0,0,0,0,  0,0,0,0,0, $
    0,0,0,0,0,  0,0,0,0,0,   1,1,-1,0,0, 0,0,0,0,0, $
    -1,0,1,0,0,  1,0,-1,-1,0, 0,-1,1,0,0, 0,0,0,0,0]
  ifunar[2,80:105] = [0,0,0,1,0,  0,0,-1,0,0,  0,0,0,0,1, -1,0,0,1,0, $
    -1,1,0,0,0,  1]

  ifunar[3,0:79] = [0,0,-2,2,-2, 1,0,2,0,0,    0,0,0,2,0,   0,0,0,0,-2, $
    0,2,0,1,2,   0,0,0,-1,0,   0,1,0,1,1,  -1,0,1,-1,-1, $
    1,0,2,1,2,   0,-1,-1,1,-1, 1,0,0,1,1,   2,0,0,1,0, $
    1,2,0,1,0,   1,1,1,-1,-2,  3,0,1,-1,2,  1,3,0,-1,1]
  ifunar[3,80:105] = [-2,-1,2,1,1, -2,-1,1,2,2,   1,0,3,1,0,  -1,0,0,0,1, $
    0,1,1,2,0,   0]

  ifunar[4,0:79] = [0,0,0,0,0,    -1,-2,0,-2,0, -2,-2,-2,-2,-2, 0,0,-2,0,2, $
    -2,-2,-2,-1,-2, 2,2,0,1,-2,   0,0,0,0,-2,    0,2,0,0,2, $
    0,2,0,-2,0,    0,0,2,-2,2,  -2,0,0,2,2,    -2,2,2,-2,-2, $
    0,0,-2,0,1,    0,0,0,2,0,    0,2,0,-2,0,    0,0,1,0,-4]
  ifunar[4,80:105] = [2,4,-4,-2,2,   4,0,-2,-2,2,  2,-2,-2,-2,0,  2,0,-1,2,-2, $
    0,-2,2,2,4,    1]


  isinco[0,0:79] = [-171996.,2062.,46.,11.,-3.,   -3.,-2.,1.,-13187.,1426., $
    -517.,217.,129.,48.,-22.,     17.,-15.,-16.,-12.,-6., $
    -5.,4.,4.,-4.,1.,              1.,-1.,1.,1.,-1., $
    -2274.,712.,-386.,-301.,-158., 123.,63.,63.,-58.,-59., $
    -51.,-38.,29.,29.,-31.,        26.,21.,16.,-13.,-10., $
    -7.,7.,-7.,-8.,6.,             6.,-6.,-7.,6.,-5., $
    5.,-5.,-4.,4.,-4.,           -3.,3.,-3.,-3.,-2., $
    -3.,-3.,2.,-2.,2.,            -2.,2.,2.,1.,-1.]
  isinco[0,80:105] = [1.,-2.,-1.,1.,-1.,           -1.,1.,1.,1.,-1., $
    -1.,1.,1.,-1.,1.,              1.,-1.,-1.,-1.,-1., $
    -1.,-1.,-1.,1.,-1.,            1.]

  isinco[1,0:38] = [-174.2,.2,0.,0.,0.,            0.,0.,0.,-1.6,-3.4, $
    1.2,-.5,.1,0.,0.,            -.1,0.,.1,0.,0., $
    0.,0.,0.,0.,0.,               0.,0.,0.,0.,0., $
    -.2,.1,-.4,0.,0.,               0.,0.,.1,-.1]

  icosco[0,0:79] = [92025.,-895.,-24.,0.,1.,   0.,1.,0.,5736.,54., $
    224.,-95.,-70.,1.,0.,      0.,9.,7.,6.,3., $
    3.,-2.,-2.,0.,0.,          0.,0.,0.,0.,0., $
    977.,-7.,200.,129.,-1.,   -53.,-2.,-33.,32.,26., $
    27.,16.,-1.,-12.,13.,     -1.,-10.,-8.,7.,5., $
    0.,-3.,3.,3.,0.,          -3.,3.,3.,-3.,3., $
    0.,3.,0.,0.,0.,            0.,0.,1.,1.,1., $
    1.,1.,-1.,1.,-1.,          1.,0.,-1.,-1.,0.]
  icosco[0,80:105] = [-1.,1.,0.,-1.,1.,           1.,0.,0.,-1.,0., $
    0.,0.,0.,0.,0.,            0.,0.,0.,0.,0., $
    0.,0.,0.,0.,0.,            0.]

  icosco[1,0:33] = [8.9,.5,0.,0.,0.,           0.,0.,0.,-3.1,-.1, $
    -.6,.3,0.,0.,0.,           0.,0.,0.,0.,0., $
    0.,0.,0.,0.,0.,           0.,0.,0.,0.,0.,  $
    -.5,0.,0.,-.1]

  R = DOUBLE(1296000.0)

  IF ( ABS ( time - oldtim ) LE TOL ) THEN BEGIN
    deleps = olddep
    delpsi = olddps
    eps    = oldeps
    RETURN
  ENDIF

  T2 = time*time
  T3 = time*T2

  ;    CONVERT IFUNAR, isinco, AND icosco ARRAYS TO REAL*8 ARRAYS FUNarg,
  ;    sincof, AND coscof, RESPECTIVELY.
  ;
  funarg = DOUBLE(ifunar)
  sincof = DOUBLE(isinco)
  coscof = DOUBLE(icosco)


  ;    CALCULATE CONVERSION FACTORS: DEGREES TO RADANS (dtr), SECONDS TO
  ;    RADIANS (str)

  PI= DOUBLE(4.0 * ATAN(1.0))
  dtr=PI/DOUBLE(180.0)
  str=dtr/DOUBLE(3600.0)

  ;    BEGIN COMPUTATION OF NUTATION IN OBLIQUITY AND LONGITUDE

  ;    CALCULATE FUNDAMENTAL argUMENTS FOR USE IN NUTATION CALCULATIONS
  ;    time IS REFERENCED TO J2000.0.
  ;    fund(1,1)= F
  ;    fund(2,1)= OMEGA
  ;    fund(3,1)= L PRIME
  ;    fund(4,1)= L
  ;    fund(5,1)= D

  fund[0,0]=str*(335778.877E0+(1342.0E0*R+295263.137E0)*time  $
    -13.257E0*T2+1.1E-2*T3)
  fund[0,1]=str*(450160.280E0-(5.E0*R+482890.539E0)*time+ $
    7.455E0*T2+8.0E-3*T3)
  fund[0,2]=str*(1287099.804E0+(99.0E0*R+1292581.224E0)*time- $
    5.77E-1*T2-1.2E-2*T3)
  fund[0,3]=str*(485866.733E0+(1325.0E0*R+715922.633E0)*time+ $
    31.310E0*T2+6.4E-2*T3)
  fund[0,4]=str*(1072261.307E0+(1236.0E0*R+1105601.328E0)*time- $
    6.891E0*T2+1.9E-2*T3)


  ;    CALCULATE MEAN OBLIQUITY OF DATE (epso). WHERE time IS MEASURED IN
  ;    JULIAN CENTURIES FROM 2000.0.

  epso=(1.813E-3*T3-5.9E-4*T2-4.6815E+1*time+8.4381448E+4)*str


  ;
  ;    CALCULATE NUTATION IN LONGITUDE (delpsi) AND NUTATION IN OBLIQUITY
  ;    (deleps).  THIS IS A THREE STEP PROCESS:
  ;    (1) CALCULATE argUMENTS OF sinE (FOR delpsi) AND COsinE (FOR deleps)
  ;        THESE ARE OF THE FORM
  ;
  ;        arg = SUMMATION ( A(I) * fund(I,1) ), I = 1,5
  ;
  ;        WHERE THE A(I)'S ARE ELEMENTS OF FUNarg.
  ;
  ;      arg = funarg # fund
  ;      arg = fund # funarg
  arg = TRANSPOSE(TRANSPOSE(funarg) # TRANSPOSE(fund))

  ;
  ;    (2) CALCULATE COEFFICIENTS OF sinE AND COsinE, WHICH ARE THE PRODUCTS
  ;        OF sincof * T AND coscof * T.  THESE COEFFICIENTS ARE IN UNITS
  ;        OF 0.0001 SECONDS OF ARC.
  ;
  T[0,0]=DOUBLE(1.0)
  T[0,1]=time

  ;      cofcos = coscof # T
  ;      cofsin = sincof # T
  ;      cofcos = T # coscof
  ;      cofsin = T # sincof
  cofcos = TRANSPOSE(TRANSPOSE(coscof) # TRANSPOSE(T))
  cofsin = TRANSPOSE(TRANSPOSE(sincof) # TRANSPOSE(T))

  cofcos=cofcos*DOUBLE(1.E-4)
  cofsin=cofsin*DOUBLE(1.E-4)

  ;
  ;    (3) CALCULATE THE sinES AND COsinES OF THE argUMENTS AND MULTIPLY
  ;        BY THEIR COEFFICIENTS, THEN ADD.  COMPUTE delpsi AND deleps.
  ;
  sumpsi=DOUBLE(0.0)
  sumeps=DOUBLE(0.0)

  sinp=sin(arg)
  cose=cos(arg)

  FOR E=0,105 DO BEGIN
    prodps=cofsin[0,E]*sinp[0,E]
    prodep=cofcos[0,E]*cose[0,E]
    sumpsi=sumpsi+prodps
    sumeps=sumeps+prodep
  ENDFOR

  deleps=sumeps*str
  delpsi=sumpsi*str

  ;
  ;    CALCULATE TRUE OBLIQUITY OF DATE (eps).
  ;
  eps=epso+deleps
  olddep = deleps
  olddps = delpsi
  oldeps = eps
  oldtim = time

END



; SPD_GRNWCH_SIDEREAL - return the greenwich true sidereal time in radians
;
; PURPOSE:  Calculate the true of date greenwich sidereal time in radians.
;
; NAME                    TYPE   USE  DESCRIPTION
; ----                   ----   ---  -----------
; orb_pos_time(2)        I*4    I    time OF ORB. VECTOR, year-day-MILLI OF day
; gst             R*8    O    GREENWICH MEAN SIDEREAL time

; EXTERNAL REFERENCES:
; SPDF IC_GET_NUT_ANGLES - Returns angles necessary to adjust the Greenwich
;                          hour angle to true of date
; NOTES:
; 1)  THE ORIGINAL ALGORITHM USED WAS COPIED FROM A SHORT PROGRAM BY
;     G. D. MEAD, INCLUDED IN 'GEOPHYSICAL COORDINATE
;                      TRANSFORMATIONS' BY CHRISTOPHER T. RUSSELL
; 2)  THIS VERSION INCORPORATES SEVERAL CHANGES TO CALCULATE THE GREENWICH
;     MEAN SIDEREAL time CORRECTLY ON THE J2000 COORDINATE SYSTEM.  THE
;     PREVIOUS VERSION WAS ONLY CORRECT IN THE B1950 COORDINATE SYSTEM.
; 3)  NOW RETURNS THE TRUE OF DATE GREENWICH SIDEREAL time ON THE J2000 SYS

PRO spd_grnwch_sidereal, orb_pos_time, gst

  half  = DOUBLE(0.50)
  C0    = DOUBLE(1.7533685592332653)     ;Polynomial Coef.
  C1    = DOUBLE(628.33197068884084)     ;Polynomial Coef.
  C2    = DOUBLE(0.67707139449033354E-05)  ;Polynomial Coef.
  C3    = DOUBLE(6.3003880989848915)     ;Polynomial Coef.
  C4    = DOUBLE(-0.45087672343186841E-09) ;Polynomial Coef.
  TWOPI = DOUBLE(6.283185307179586)      ;Two PI


  year = orb_pos_time[0]/1000
  day  = orb_pos_time[0] MOD 1000

  ;
  ;   Convert the given millisecond of day [orb_pos_time[1]] to second of day.
  ;
  secs = (DOUBLE(orb_pos_time[1]))/DOUBLE(1000.0)

  ;
  ;    Begin calculating the greenwich mean sidereal time **
  ;
  fday = secs/86400.00
  dj = DOUBLE(365*(year-1900)+(year-1901)/4+day-half)


  ;
  ;       THE NEXT STATEMENT CAUSES THE REFERENCE EPOCH TO BE SHIFTED
  ;    TO THE J2000 REFERENCE EPOCH.
  ;

  T = (dj-DOUBLE(36525.0))/DOUBLE(36525.0)
  gst = DOUBLE(C0 + T*(C1 + T*(C2 + C4*T)) + C3*fday)
  gst = DOUBLE(gst MOD TWOPI)
  IF (gst LT DOUBLE(0.0)) THEN gst = gst + TWOPI

  ;
  ;   Convert gst to true of date by adjusting for nutation
  ;
  spd_get_nut_angles, T, deleps, delpsi, eps
  gst = gst + delpsi*cos(eps+deleps)

END

;     XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

pro spd_gei2j2000
  ; does nothing.
  ; call cotrans_lib at the beginning of any routine
  ; that needs to use any cotrans_lib routines, to ensure
  ; that they are compiled.
end
