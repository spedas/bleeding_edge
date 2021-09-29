;+
;
;   $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;   $LastChangedRevision: 27922 $
;-
function get_mepe_az_dir_in_sga, fluxdir=fluxdir,  $
                                 debug=debug

;------------------------------------------------------------------------------
;Descriptions:
; --- This program calculates the unit vector of sight direction (in SGI
;     coordinates [satellite spin coordinates]) of the  n-th MEPe/MEPi channel.
;
; --- You can find some documents on the geometory of MEPs in the MEP server
;     directory: /raid/meps/docs. The geometory of MEPe explained in
;     MEPe_EPS_r1_black.pdf is used in this function. The document that
;     describes MEPi geometory is missing now (2017/Oct/01).
;
;Argument:
;Output:
; --- e                 :[16x3 array]
;                        unit vectors of sight direction of the MEP-e
;azimuth channels
;History:
; --- 2017/Oct/01       :[prepared]
;Author:
; --- Kazuhiro Yamamoto :[Kyoto Univ.]
;                        Email:kazuhiro@kugi.kyoto-u.ac.jp
  ;; T. Hori forked part of calc_mep_padist.pro originally written by
  ;; K. Yamamoto to create this routine. 
  
;------------------------------------------------------------------------------
;Calculation
;MEPe case
  ;parameter
  ;channel azimuthal angle
  ; --- starts from -Z(SGI) axis and increases toward -Y(SGI) axis.
  ;     Note that MEPe channel number is clockwise when you see from
  ;     +X(SGI) direction.
  azi_8 = -39.4 ;[deg] offset of channel 8 from -Z(SGI) axis
  d_azi = 22.5  ;[deg] interval of each center of aperture
  phi   = azi_8 + (indgen(16)-8) * d_azi ;azimuthal angle of n-th channel [deg]
  ;inclination of apertures (elevation)
  ; --- This value is based on visual speculation of Fig. 3 in
  ;     MEPe_EPS_r1_black.pdf.
  theta =  replicate( 2.0, 16) ;[deg]

  ;unit vector of sight direction
  ; --- Note that positive elevation of paertures in MEPe increases
                                ;     ;X(SGI) component.
  ;; e is a 2-D array [ azch, 3 ] 
  e   = [ [+1 * sin(theta*!DTOR)] $
        , [-1 * cos(theta*!DTOR) * sin(phi*!DTOR)] $
        , [-1 * cos(theta*!DTOR) * cos(phi*!DTOR)]      ]
  if keyword_set(fluxdir) then e = -1 * e ;;Flip the direction
  
return, e

end
