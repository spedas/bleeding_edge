;+
; SPD_GET_NUT_ANGLES_VEC
;
; Vectorized version of spd_get_nut_angles from spd_gei2j2000.pro
;
; History: 
;   2016-02-10 - Optimized to reduce memory spike for large data sets
;                (combined a few lines and added temporary() calls)
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2016-02-10 12:59:53 -0800 (Wed, 10 Feb 2016) $
; $LastChangedRevision: 19928 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/spd_get_nut_angles_vec.pro $
;-
PRO spd_get_nut_angles_vec,time,deleps,delpsi,eps,error=error


  TOL = DOUBLE(0.5)/DOUBLE(36525.0)


  n = n_elements(time)

  deleps = dblarr(n)
  delpsi = dblarr(n)
  eps = dblarr(n)

  isinco = FLTARR(2,106)   ;Array used in nutation calculations
  icosco = FLTARR(2,106)   ;Array used in nutation calculations
  fund = DBLARR(n,5)      ;The fundamental arguments
  T = DBLARR(n,2)     ;Time
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


  
;code temporarily disabled due to bug in the original
;  IF ( ABS ( time - oldtim ) LE TOL ) THEN BEGIN
;    deleps = olddep
;    delpsi = olddps
;    eps    = oldeps
;    RETURN
;  ENDIF

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

  fund[*,0]=str*(335778.877E0+(1342.0E0*R+295263.137E0)*time  $
    -13.257E0*T2+1.1E-2*T3)
  fund[*,1]=str*(450160.280E0-(5.E0*R+482890.539E0)*time+ $
    7.455E0*T2+8.0E-3*T3)
  fund[*,2]=str*(1287099.804E0+(99.0E0*R+1292581.224E0)*time- $
    5.77E-1*T2-1.2E-2*T3)
  fund[*,3]=str*(485866.733E0+(1325.0E0*R+715922.633E0)*time+ $
    31.310E0*T2+6.4E-2*T3)
  fund[*,4]=str*(1072261.307E0+(1236.0E0*R+1105601.328E0)*time- $
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
;original--------------------------------------------------------
;  arg = TRANSPOSE(TRANSPOSE(funarg) # TRANSPOSE(fund))
;----------------------------------------------------------------

;optimized------------------------------------------------
  arg = TRANSPOSE(TRANSPOSE(funarg) # TRANSPOSE(temporary(fund)))
;----------------------------------------------------------------

  ;
  ;    (2) CALCULATE COEFFICIENTS OF sinE AND COsinE, WHICH ARE THE PRODUCTS
  ;        OF sincof * T AND coscof * T.  THESE COEFFICIENTS ARE IN UNITS
  ;        OF 0.0001 SECONDS OF ARC.
  ;
  T[*,0]=DOUBLE(1.0)
  T[*,1]=time

  ;      cofcos = coscof # T
  ;      cofsin = sincof # T
  ;      cofcos = T # coscof
  ;      cofsin = T # sincof
;original--------------------------------------------
;  cofcos = TRANSPOSE(TRANSPOSE(coscof) # TRANSPOSE(T))
;  cofsin = TRANSPOSE(TRANSPOSE(sincof) # TRANSPOSE(T))
;
;  cofcos=cofcos*DOUBLE(1.E-4)
;  cofsin=cofsin*DOUBLE(1.E-4)
;-----------------------------------------------------

  ;
  ;    (3) CALCULATE THE sinES AND COsinES OF THE argUMENTS AND MULTIPLY
  ;        BY THEIR COEFFICIENTS, THEN ADD.  COMPUTE delpsi AND deleps.
  ;
  sumpsi=DOUBLE(0.0)
  sumeps=DOUBLE(0.0)

;original-------------------------
;  sinp=sin(arg)
;  cose=cos(arg)
;
; ; FOR E=0,105 DO BEGIN
;  prodps=cofsin*sinp
;  prodep=cofcos*cose
;  
;  sumpsi=total(prodps,2)
;  sumeps=total(prodep,2)
;---------------------------------

;optimized----------------------------------------------------------------------
  sumpsi = total( 1d-4*TRANSPOSE(TRANSPOSE(sincof) # TRANSPOSE(T)) * sin(arg) ,2)
  sumeps = total( 1d-4*TRANSPOSE(TRANSPOSE(coscof) # TRANSPOSE(T)) * cos(temporary(arg)) ,2)
;-------------------------------------------------------------------------------


  deleps=sumeps*str
  delpsi=sumpsi*str

  ;
  ;    CALCULATE TRUE OBLIQUITY OF DATE (eps).
  ;
  eps=epso+deleps
;  olddep = deleps
;  olddps = delpsi
;  oldeps = eps
;  oldtim = time

END