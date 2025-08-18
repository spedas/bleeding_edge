;+
; NAME:
; SYNTAX:
; PURPOSE:
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY:
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2024-12-13 09:03:48 -0800 (Fri, 13 Dec 2024) $
;   $LastChangedRevision: 32990 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_gc_bjackel.pro $
;-

;---------------------------------------------------------------------------------
;(c) Brian Jackel University of Calgary
;this specific (c) refers to the subroutine gc_bjackel only
;this is just a deodetic_geocentric conversion routine used in the ASI_FOV plot
function thm_map_gc_bjackel,Position,Old2new, HELP=help,    $
         FROM_GEODETIC=from_geodetic, TO_GEODETIC=to_geodetic,      $
         FROM_GEOCENTRIC=from_geocentric, TO_GEOCENTRIC=to_geocentric,    $
         FROM_CARTESIAN=from_cartesian, TO_CARTESIAN=to_cartesian,       $
         REFERENCE_GEOID=reference_geoid
  ON_ERROR,2
  IF KEYWORD_SET(HELP) THEN BEGIN
    DOC_LIBRARY,'Geodetic_Convert'
    RETURN, [0,0,0]
  END
  IF (N_PARAMS() LT 1) THEN MESSAGE,'At least one parameter (Location) required'
  siz= SIZE(position)
  IF (siz(1) NE 3) THEN MESSAGE,'Location must be a 3 element array or 3 x N element matrix'
  nel= siz(1)
  IF KEYWORD_SET(REFERENCE_GEOID) THEN BEGIN
     geoid= STRUPCASE(reference_geoid)
     geoid= STRCOMPRESS(geoid,/REMOVE_ALL)
  ENDIF ELSE geoid='WGS84'
  CASE geoid OF
     'IAU64':BEGIN & a=6378160.0D0 & f1= 298.250D0  & END
     'IAU76':BEGIN & a=6378140.0D0 & f1= 298.2570D0 & END
     'WGS84':BEGIN & a=6378137.0D0 & f1= 298.257223563D0 & END
     ELSE:BEGIN
            dprint,'Warning- unrecognized REFERENCE_GEOID, using WGS 1984'
            a=6378137.0D0 & f1= 298.257223563D0
          END
  ENDCASE
  f= 1.0D0/f1
  e2= f*(2.0D0-f)
  eminus= (1.0D0 - f)^2
  deg2rad= !dpi/180.0D0
  rad2deg= 180.0D0/!dpi  ;
  IF KEYWORD_SET(FROM_GEODETIC) THEN BEGIN
     h= REFORM( position(0,*) )
     phi= REFORM( position(1,*) ) * deg2rad
     Nphi= a / SQRT( 1.0d0 - e2*SIN(phi)^2 )
     IF KEYWORD_SET(TO_GEOCENTRIC) THEN BEGIN
       phi_prime= ATAN( (eminus*Nphi+h)/(Nphi+h) * TAN(phi) )
       rho= (Nphi+h) * COS(phi)/COS(phi_prime)
       results= [ [rho], [phi_prime*rad2deg], [REFORM(position(2,*))] ]
     ENDIF
     IF KEYWORD_SET(TO_CARTESIAN) THEN BEGIN
        lambda= REFORM( position(2,*) ) * deg2rad
        cphi= COS(phi)  &  sphi= SIN(phi)
        x= (Nphi+h) * cphi * cos(lambda)
        y= (Nphi+h) * cphi * sin(lambda)
        z= (eminus*Nphi+h) * sphi
        results=[ [x], [y], [z] ]
        IF (n_params() EQ 2) AND (nel EQ 3) THEN BEGIN
             slam= sin(lambda)  &  clam= cos(lambda)
             east= [-slam,clam,0.0]
             down= -[cphi*clam,cphi*slam,sphi]
             north= [-clam*sphi,-slam*sphi,cphi]
             old2new= [ [down],[north],[east] ]
        END
     ENDIF
  ENDIF
  IF KEYWORD_SET(FROM_GEOCENTRIC) THEN BEGIN
     rho= REFORM(position(0,*))
     phi_prime= REFORM(position(1,*))*deg2rad
     lambda= REFORM(position(2,*))*deg2rad
     cphi= COS(phi_prime)  &   sphi= SIN(phi_prime)
     IF KEYWORD_SET(TO_GEODETIC) THEN BEGIN
         r= rho*cphi  &  z= rho*sphi
         phi= 0.0D0   &  Nphi= 0.0D0
         FOR indx=0,4 DO BEGIN
            phi= ATAN( (z + Nphi*e2*SIN(phi))/r )
            Nphi= a / SQRT(1.0D0 - e2*SIN(phi)^2)
         ENDFOR
         h= r/COS(phi) - Nphi
         results=[ [h], [phi*rad2deg], [lambda*rad2deg] ]
     ENDIF
     IF KEYWORD_SET(TO_CARTESIAN) THEN BEGIN
         x= rho * cphi * cos(lambda)
         y= rho * cphi * sin(lambda)
         z= rho * sphi
         results=[ [x] ,[y], [z] ]
         IF (n_params() EQ 2) AND (nel EQ 3) THEN BEGIN
              slam= sin(lambda)  &  clam= cos(lambda)
              east= [-slam,clam,0.0]
              down= -[cphi*clam,cphi*slam,sphi]
              north= [-clam*sphi,-slam*sphi,cphi]
              old2new= [ [down],[north],[east] ]
         ENDIF
     ENDIF
  ENDIF
  IF KEYWORD_SET(FROM_CARTESIAN) THEN BEGIN
     x= REFORM(position(0,*))
     y= REFORM(position(1,*))
     z= REFORM(position(2,*))
     IF KEYWORD_SET(TO_GEOCENTRIC) THEN BEGIN
        rho= SQRT( x^2 + y^2 + z^2 )
        phi_prime= ASIN(z/rho)
        lambda= ATAN(y,x)
        results=[ [rho], [phi_prime*rad2deg], [lambda*rad2deg] ]
     ENDIF
     IF KEYWORD_SET(TO_GEODETIC) THEN BEGIN
         lambda= ATAN(y,x)
         r= SQRT(x^2 + y^2)
         phi= 0.0D0   &  Nphi= 0.0D0
         FOR indx=0,5 DO BEGIN
            phi= ATAN( (z + Nphi*e2*SIN(phi))/r )
            Nphi= a / SQRT(1.0D0 - e2*SIN(phi)^2)
         ENDFOR
         h= r/COS(phi) - Nphi
         results=[ [h], [phi*rad2deg], [lambda*rad2deg] ]
     ENDIF
  ENDIF
  IF (N_ELEMENTS(results) EQ 0) THEN BEGIN
     MESSAGE,'Warning- no coordinate conversion carried out.'
     RETURN,position
  ENDIF ELSE RETURN, REFORM( TRANSPOSE(results) )
  END

;------------------------------------------------------------------------------