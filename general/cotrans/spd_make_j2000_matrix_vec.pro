;+
; SPD_MAKE_J2000_MATRIX_VEC
;
; Vectorized version0 of spd_make_j2000_matrix_vec from spd_gei2j2000.pro
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-23 12:26:57 -0700 (Wed, 23 Sep 2015) $
; $LastChangedRevision: 18893 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/spd_make_j2000_matrix_vec.pro $
;-

;      STATEMENT FUNCTION DEFINITION FOR dxjul -- JULIAN EPHEMERIS
;      DATE AT BEGINNING OF year.
;

FUNCTION dxjul,i

    RETURN,DOUBLE((-32075+1461*(i+4800-13/12)/4  $
        +367*(-1+13/12*12)/12-3         $
        *((i+4900-13/12)/100)/4)-0.5 )

END

PRO spd_make_j2000_matrix_vec, orb_pos_time, cmatrix


  ;puts helper functions in scope
  matrix_array_lib

  dim = dimen(orb_pos_time)

  cmatrix = DBLARR(dim[0],3,3)    ;conversion matrix
  nutmat = DBLARR(dim[0],3,3)      ;Nutation matrix
  premat = DBLARR(dim[0],3,3)      ;precession matrix

  Jdj2000 = DOUBLE (2451545.0)
  R = DOUBLE (1296000.0)


  ;   Convert the given millisecond of day [orb_pos_time[1]] to second of day.
  ;   Convert the packed form into year and day-of-year

  secs = (DOUBLE(orb_pos_time[*,1]))/DOUBLE(1000.0)
  year = orb_pos_time[*,0]/1000
  day  = orb_pos_time[*,0] MOD 1000

  ;
  ;   Calculate the julian date and the time in Julian centuries from J2000
  ;
  fday = secs/DOUBLE(86400.00)
  jul_day = dxjul(year) + DOUBLE(day)+fday
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
  premat[*,0,0] = -sinzet*sinzee  + coszet*coszee*costhe
  premat[*,0,1] =  coszee*sinzet  + sinzee*costhe*coszet
  premat[*,0,2] =  sinthe*coszet
  premat[*,1,0] = -sinzee*coszet  - coszee*costhe*sinzet
  premat[*,1,1] =  coszee*coszet  - sinzee*costhe*sinzet
  premat[*,1,2] = -sinthe*sinzet
  premat[*,2,0] = -coszee*sinthe
  premat[*,2,1] = -sinzee*sinthe
  premat[*,2,2] =  costhe

  ;    CALCULATE MEAN OBLIQUITY OF DATE (epso). WHERE TIME IS MEASURED IN
  ;    JULIAN CENTURIES FROM 2000.0.

  epso=DOUBLE( (1.813E-3*T3-5.9E-4*T2 $
    -4.6815E+1*time+8.4381448E+4)*str )


  ;    CALL SPD_GET_NUT_ANGLES TO COMPUTE NUTATION IN OBLIQUITY AND LONGITUDE

  spd_get_nut_angles_vec,time,deleps,delpsi,eps

  cosep=cos(eps)
  cosepO=cos(epso)
  cospsi=cos(delpsi)
  sinep=sin(eps)
  sinepO=sin(epso)
  sinpsi=sin(delpsi)

  nutmat[*,0,0]=cospsi
  nutmat[*,1,0]=-sinpsi*cosepO
  nutmat[*,2,0]=-sinpsi*sinepO
  nutmat[*,0,1]=sinpsi*cosep
  nutmat[*,1,1]=cospsi*cosep*cosepO+sinep*sinepO
  nutmat[*,2,1]=cospsi*cosep*sinepO-sinep*cosepO
  nutmat[*,0,2]=sinpsi*sinep
  nutmat[*,1,2]=cospsi*sinep*cosepO-cosep*sinepO
  nutmat[*,2,2]=cospsi*sinep*sinepO+cosep*cosepO

  ;    CALCULATE ELEMENTS OF nutmat * premat.  THIS MATRIX IS THE
  ;    ANALYTICALLY CALCULATED TRANSFORMATION MATRIX, WHICH WILL
  ;    TRANSFORM THE MEAN EARTH EQUATOR AND EQUINOX OF J2000 INTO
  ;    THE TRUE EARTH EQUATOR AND EXQUINOX OF DATE.

  ;     cmatrix = nutmat # premat
  cmatrix = TRANSPOSE(TRANSPOSE(premat) # TRANSPOSE(nutmat))

  cmatrix = ctv_mm_mult(premat,nutmat)

end