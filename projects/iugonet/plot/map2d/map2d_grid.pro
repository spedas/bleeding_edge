;+
; PROCEDURE map2d_grid
;
; :DESCRIPTION:
;    Draw the latitude-longitude mesh with given intervals in Lat and Lon. 
;
; :KEYWORDS:
;    dlat:  interval in Latitude [deg]. If not set, 10 deg is used as default. 
;    dlon:   interval in Longitude [deg]. If not set, 15 deg (1 hour in local time) is used as default. 
;    color: number of color table to be used for drawing lat-LT mesh
;    linethick: thickness of lines/curves used for the mesh
;    
; :EXAMPLES:
;    map2d_set, /nogrid         ;map2d_set automatically calls map2d_grid unless nogrid keyword is set. 
;    map2d_grid, dlat=10., dlon=15. 
;
; :AUTHOR:
;    Tomo Hori (E-mail: horit at stelab.nagoya-u.ac.jp)
;
; :HISTORY:
;    2014/08/12: Created
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-05-12 16:56:35 -0700 (Thu, 12 May 2016) $
; $LastChangedRevision: 21069 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/plot/map2d/map2d_grid.pro $
;-
PRO map2d_grid, dlat=dlat, dlon=dlon, color=color, linethick=linethick
    
  ;Initialize the map2d plot environment
  map2d_init
  
  if ~keyword_set(dlat) then dlat = 10. 
  if ~keyword_set(dlon) then dlon = 15.  ; 15 deg = 1 hour in local time
  
  map_grid, latdel=dlat, londel=dlon, color=color, glinethick=linethick  
  
  RETURN
END
