;+
;
;PROCEDURE:       STORE_DATA_COLBAR
;
;PURPOSE:         Wrapper of 'store_data' to create a tplot variable
;                 of color bar as a function of time. 
;
;INPUTS:          Time and bar data array. They must be same elements. 
;                 Basic usage is the same as 'store_data'. 
;                 
;
;KEYWORDS:        See, 'store_data', and 'draw_color_scale'.
;
;      DATA:      Variable that contains the data structure.
;
;    LIMITS:      Variable that contains the limit structure. 
;
;     RANGE:      Array of two giving the range in data values the
;                 scale corresponding to. 
;
;    BRANGE:      INTARR(2) giving the range in color map values the
;                 scale spans.
;
;    BOTTOM:      Sets the bottom color for byte-scaling.
;
;       TOP:      Sets the top color for byte-scaling.
;
;       LOG:      If set, make scale logarithmic.
;
;CREATED BY:      Takuya Hara on 2015-05-01.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-05-06 16:30:16 -0700 (Wed, 06 May 2015) $
; $LastChangedRevision: 17491 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/store_data_colbar.pro $
;
;-
PRO store_data_colbar, name, time, bar, values, data=data, lim=lim, verbose=verbose, $
                       range=range, brange=brange, bottom=bottom, top=top, log=log

  IF SIZE(name, /type) EQ 0 THEN name = 'time_colbar'
  IF keyword_set(log) THEN lflg = 1 ELSE lflg = 0
  IF SIZE(data, /type) NE 8 THEN BEGIN
     IF (SIZE(time, /type) EQ 0) OR (SIZE(bar, /type) EQ 0) THEN BEGIN
        dprint, 'Input data is not enough.', dlevel=2, verbose=verbose
        RETURN
     ENDIF 
  ENDIF ELSE BEGIN
     IF tag_exist(data, 'x') THEN time = data.x $
     ELSE BEGIN 
        dprint, 'No time information.', dlevel=2, verbose=verbose
        RETURN
     ENDELSE 
     IF tag_exist(data, 'y') THEN bar = data.y $
     ELSE BEGIN 
        dprint, 'No color bar information.', dlevel=2, verbose=verbose
        RETURN
     ENDELSE 
     IF tag_exist(data, 'v') THEN values = data.v 
  ENDELSE 
  IF N_ELEMENTS(time) NE N_ELEMENTS(bar) THEN BEGIN
     dprint, 'The time and bar data must be same elements', dlevel=2, verbose=verbose
     RETURN
  ENDIF 
  IF SIZE(values, /type) EQ 0 THEN values = [0., 1.]
 
  store_data, name, data={x: time, y: [ [bar], [bar] ], v: values},    $
              dlim={ytitle: '', yticks: 1, yminor: 1, ytickname: [' ', ' '], spec: 1, $
                    no_color_scale: 1}, lim=lim

  IF SIZE(range, /type) NE 0 THEN IF N_ELEMENTS(range) EQ 2 THEN $
     zlim, name, MIN(range), MAX(range), lflg, /def

  IF SIZE(brange, /type) NE 0 THEN IF N_ELEMENTS(brange) EQ 2 THEN BEGIN
     bottom = MIN(brange)
     top = MAX(brange)
  ENDIF 
  IF SIZE(bottom, /type) NE 0 THEN options, name, 'bottom', bottom, /def  
  IF SIZE(top, /type) NE 0 THEN options, name, 'top', top, /def  
  RETURN
END 
