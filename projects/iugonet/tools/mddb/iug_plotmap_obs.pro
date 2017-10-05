;+
; :PROCEDURE: 
;    iug_plotmap_obs
;
; :PURPOSE:
;    Plots observatories on the world map.
;
; :KEYWORDS:
;    glatlim:     geographic latitude range
;    glonlim:     geographic longitude range
;    query:       free word to search
;    charsize:    font size of observatory name
;    charcolor:   color of observatory name
;    psym:        plot symbol for observatories
;    symsize:     symbol size
;    symcolor:    symbol color
;    noname:      If set, no observatory name will be written on the map.
;    position:    Set the location of the plot frame in the plot window
;    isotropic:   Set to produce a map that has the same scale in X and Y.
;
;    obs: information of observatories returned from metadata database.
;    
; :EXAMPLES:
;    iug_plotmap_obs, glatlim=[55, 75], glonlim=[0, 40], $
;                     query='wdc'
;
; :Author:
;       Y.-M. Tanaka (E-mail: ytanaka@nipr.ac.jp)
;-

PRO iug_plotmap_obs, $
      glatlim=glatlim, glonlim=glonlim, query=query, rpp=rpp, $
      charsize=charsize, charcolor=charcolor, $
      psym=psym, symsize=symsize, symcolor=symcolor, $
      noname=noname, position=position, $
      isotropic=isotropic, obs=obs

;glatlim=[20, 50]
;glonlim=[120, 150]
;query='MAGDAS'

if ~keyword_set(glatlim) then glatlim=[-90, 90]
if ~keyword_set(glonlim) then glonlim=[-180, 180]

slat=glatlim[0] 
nlat=glatlim[1]
wlon=glonlim[0]
elon=glonlim[1]

glatc=mean(glatlim)
glonc=mean(glonlim)

lats = indgen(19)*10-90
lons = indgen(25)*15-180
latnames=' '
lonnames=' '

;----- Search observatory -----;
iug_get_obsinfo, nlat=nlat, slat=slat, elon=elon, wlon=wlon, $
                 query=query, rpp=rpp, obs=obs

;----- Draw map -----;
map_set, glatc, glonc, limit=[slat, wlon, nlat, elon], $
         isotropic=isotropic, /orthographic, /continent, /horizon
map_grid,lats=lats, lons=lons, latnames=latnames, lonnames=lonnames

;----- Draw observatory -----;
overlay_map_obs, obs, position=position, $
    charsize=charsize, charcolor=charcolor, $
    psym=psym, symsize=symsize, symcolor=symcolor, $
    noname=noname

end

