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
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_add_site_fieldofview.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
FUNCTION thm_map_add_site_fieldofview,location,elevation,height,n_points=n_points
  Re= 6371.2
  rho0= height*(2*Re+height) / (2*Re*SIN(elevation*!dtor))
  rho=  height*(2*Re+height) / (2*Re*SIN(elevation*!dtor) + rho0)
  cartesian= thm_map_gc_bjackel(location,old2new,/from_geodetic,/to_cartesian)
  el= elevation*!dtor
  downC= old2new # [1,0,0]
  northC= old2new # [0,1,0]
  eastC= old2new # [0,0,1]
  azimuth_angle= FINDGEN(361)
  if keyword_set(n_points) then azimuth_angle=360.0*findgen(n_points)/(n_points-1)
  pos= FLTARR(3,N_ELEMENTS(azimuth_angle))
  FOR indx=0,N_ELEMENTS(azimuth_angle)-1 DO BEGIN
     az= azimuth_angle[indx]*!dtor
     aim= northC*COS(az)*COS(el) + eastC*SIN(az)*COS(el) - downC*SIN(el)
     pos[0,indx]= thm_map_gc_bjackel(cartesian+aim*rho*1.0e3,/FROM_CARTESIAN,/TO_GEODETIC)
  ENDFOR
RETURN,pos
END
;---------------------------------------------------------------------------------------------
