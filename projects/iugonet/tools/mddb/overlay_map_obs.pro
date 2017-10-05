;+
; :PROCEDURE: overlay_map_obs
;
; :DESCRIPTION:
;    Plot observatories on the world map.
;
; :PARAMS:
;    obs:  structure for observatories obtained by iug_get_obsinfo.
;
; :KEYWORDS:
;    obs: structure for observatories obtained by iug_get_obsinfo.
;    position:  Set the location of the plot frame in the plot window
;    charsize:    font size of observatory name
;    charcolor:   color of observatory name
;    psym:        plot symbol for observatories
;    symsize:     symbol size
;    symcolor:    symbol color
;    noname:      If set, no observatory name will be written on the map.
;
; :AUTHOR:
; 	Y.-M. Tanaka (E-mail: ytanaka@nipr.ac.jp)
;-

;----------------------------------------------------------
PRO overlay_map_obs, obs, position=position, $
       charsize=charsize, charcolor=charcolor, $
       psym=psym, symsize=symsize, symcolor=symcolor, $
       noname=noname

;Check argument and keyword
npar=N_PARAMS()
IF npar LT 1 THEN RETURN

if size(obs, /type) ne 8 then return

;Size of characters
if ~keyword_set(charsize) then charsize=1.0
if ~keyword_set(charcolor) then charcolor=0
if ~keyword_set(psym) then psym=5
if ~keyword_set(symsize) then symsize=1.0
if ~keyword_set(symcolor) then symcolor=0

nstn=n_elements(obs.name)
  
;Loop for processing a multi-tplot vars
FOR istn=0L, nstn-1 DO BEGIN
    
    ;Set the plot position
    pre_position = !p.position
    IF KEYWORD_SET(position) THEN BEGIN
        !p.position = position
    ENDIF ELSE position = !p.position
            
    ;Draw the data
    stname = obs.name[istn]
    lat = obs.glat[istn]
    lon = obs.glon[istn]
      
    oplot, [lon, lon], [lat, lat], psym=psym, symsize=symsize, $
           color=symcolor
    if ~keyword_set(noname) then begin
        xyouts, lon, lat, strupcase(stname), charsize=charsize, $
            color=charcolor
    endif

ENDFOR ;End of the loop for multi-tplot var

;Normal end
RETURN
  
END

