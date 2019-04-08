;+
; PROCEDURE overlay_map_coast
;
; :Description:
;		Draw the world map on the plot window set up by map_set. 
;
;
;	:Keywords:
;    fill:      Set to fill the continents
;    col:       Set the color index to draw the coast lines with 
;                 (Usually the time should be set by sd_time)
;    static:    Set to plot on the MLAT-MLON grid, not the MLAT-MLT. 
;               This keyword does nothing when keyword geo_plot is set. 
;    time:      Set the time (in UNIX time) to calculate the AACGM coords 
;               of the map for. Do nothing with keyword geo_plot on.  
;    geo_plot:  Set to draw in geographical coordinates
;    position:  Set to draw the map at the designated position in the plot window
;    height:    Set a height in [km] for which the AACGM conversion is made. 
;               Default: 0.01 km. DO NOT set zero or negative otherwise it crashes. 
;
; :EXAMPLES:
;   overlay_map_coast     (to draw the world map in AACGM)
;
; :Author:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/11/10: Created
; 	2011/06/15: renamed to overlay_map_coast
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
PRO overlay_map_coast,fill=fill,col=col, $
      static=static,time=time, geo_plot=geo_plot, coord=coord, $
      position=position, south=south, height=height 

  stack = SCOPE_TRACEBACK(/structure)
  filename = stack[SCOPE_LEVEL()-1].filename
  dir = FILE_DIRNAME(filename)
  OPENR,map_unit,dir+'/sd_world_data',/GET_LUN
  
  IF KEYWORD_SET(south) THEN hemisphere=-1 ELSE hemisphere=1
  
  IF NOT KEYWORD_SET(col) THEN col=0
  
  IF NOT KEYWORD_SET(height) then height = 0.01 ; [km]
  
  ;Initialize the SD environment
  sd_init
  
  IF ~KEYWORD_SET(time) THEN BEGIN
    t0 = !map2d.time
    get_timespan, tr
    IF t0 GE tr[0] AND t0 LE tr[1] THEN time = t0 ELSE BEGIN
      time = (tr[0]+tr[1])/2.  ; Take the center of the designated time range
    ENDELSE
  ENDIF
  
  if size(coord, /type) ne 0 then begin
    map2d_coord, coord 
  endif
  if keyword_set(geo_plot) then !map2d.coord = 0
  
  ts = time_struct(time)
  year=ts.year
  year_secs= LONG( (ts.doy-1)*86400L + ts.sod )
  
  no_blocks=17
  block_len=INTARR(17)
  READF,map_unit,no_blocks,block_len
  
  coast=FLTARR(2,10000) & pts=0
  FOR read_block=0,no_blocks-1 DO BEGIN
    read_coast=FLTARR(2,block_len(read_block))
    READF,map_unit,read_coast
    coast(*,pts:pts+block_len(read_block)-1)=read_coast(*,*)
    pts=pts+block_len(read_block)
  ENDFOR
  CLOSE,map_unit
  FREE_LUN,map_unit
  
  ;Set !p.position and preserve the original setting 
  pre_pos = !p.position
  if keyword_set(position) then begin
    !p.position = position
  endif else position = !p.position
  
  plot_coast=FLTARR(2,5000) & plot_pts=0
  FOR i=0,pts-1 DO BEGIN
    IF (coast(0,i) NE 0 OR coast(1,i) NE 0) THEN BEGIN
    
      ;IF coast(0,i)*hemisphere GT 0 THEN BEGIN
      
        if ~keyword_set(geo_plot) and !map2d.coord eq 1 then begin  ;For plotting in AACGM
          aacgmconvcoord,coast[0,i],coast[1,i],height,mlat,mlon,err,/TO_AACGM
          mag_pos = [mlat, mlon]
          ;mag_pos=cnvcoord(coast(0,i),coast(1,i),1)
          
          ;;;;;;For plotting with MAP_SET (stay in polar coordinates)
          
          IF NOT KEYWORD_SET(static) THEN BEGIN
            ;x0= mlt(year,year_secs,mag_pos[1])*180/12 ;longitude [deg]
            x0 = aacgmmlt(year,year_secs,mag_pos[1])*180./12. ; [deg]
            x0= (x0 + 360. ) MOD 360.
            y0= mag_pos[0] ;latitude [deg]
            ;x0= ABS(hemisphere*90-mag_pos(0))* $
            ;  SIN(mlt(year,year_secs,mag_pos(1))*!pi/12)
            ;y0=-ABS(hemisphere*90-mag_pos(0))* $
            ;  COS(mlt(year,year_secs,mag_pos(1))*!pi/12)
          ENDIF ELSE BEGIN
            x0= mag_pos[1] ;longitude [deg]
            x0= (x0 + 360. ) MOD 360.
            y0= mag_pos[0] ;latitude [deg]
          ;x0= ABS(hemisphere*90-mag_pos(0))* $
          ;                                    SIN(mag_pos(1)*!pi/180)
          ;                            y0=-ABS(hemisphere*90-mag_pos(0))* $
          ;                                   COS(mag_pos(1)*!pi/180)
          ENDELSE
        endif else begin   ;For plotting in GEO
          y0 = coast[0,i]
          x0 = coast[1,i]
        endelse
        
        plot_coast(*,plot_pts)=[x0,y0]
        plot_pts=plot_pts+1
        
        
      ;ENDIF
    ENDIF ELSE BEGIN
      IF plot_pts GT 0 THEN BEGIN
        IF KEYWORD_SET(fill) THEN BEGIN
          POLYFILL,plot_coast(0,0:plot_pts-1),plot_coast(1,0:plot_pts-1),NOCLIP=0,COL=col
        ENDIF ELSE BEGIN
          OPLOT,plot_coast(0,[INDGEN(plot_pts),0]),plot_coast(1,[INDGEN(plot_pts),0]),COL=col
        ENDELSE
      ENDIF
      plot_pts=0
    ENDELSE
  ENDFOR
  
  ;Restore the original position
  !p.position = pre_pos
  
  
END

;-----------------------------------------------------------------------
