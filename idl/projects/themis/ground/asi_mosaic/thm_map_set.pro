;+
; NAME:
; SYNTAX:
; PURPOSE:
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY:
;   2015-05-22 - af - don't reset window if /noerase set, updating (some) documentation
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2024-12-13 08:57:41 -0800 (Fri, 13 Dec 2024) $
;   $LastChangedRevision: 32989 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_set.pro $
;-

;(c) 2007 - Eric Donovan & Brian Jackel - University of Calgary
;quick idl map_set to prepare for overplotting of mosaic
;right now just has orthographic projection but will incorporate satellite view soon
;changes color table to table 39 with the modification of a grey level scale
;   between colors 0 (black) and 12 (very light grey or almost white) - white is color 255
;examples (see also thm_map_examples)
;the default center of the map is roughly Rankin Inlet
;thm_map_set,central_lon=180
;thm_map_set,central_lon=250
;thm_map_set,central_lon=320
;thm_map_set,central_lat=40
;thm_map_set,central_lat=60
;thm_map_set,central_lat=80
;thm_map_set,xsize=600,ysize=100
;thm_map_set,xsize=600,ysize=400
;thm_map_set,xsize=600,ysize=800
;thm_map_set,position=[0.1,0.3,0.9,0.7]

pro thm_map_set,scale=scale,$                         ;scale for map set
                   central_lat=central_lat,$          ;geographic latitude of center of plot
                   central_lon=central_lon,$          ;geographic longitude of center of plot
                   color_continent=color_continent,$  ;shade of continent fill
                   color_background=color_background,$;shade of background (2015-05-22: this keyword doesn't work)
                   position=position,$                ;position of plot on window (normal coordinates)
                   xsize=xsize,$                      ;xsize of window (ignored if /noerase set)
                   ysize=ysize,$                      ;ysize of window (ignored if /noerase set)
                   noerase=noerase,$                  ;do not erase current window
                   zbuffer=zbuffer,$		      ; do it in z-buffer
                   projection=projection,$	      ; which projection to use
                   window=window,$		      ; select window number
                   rotation=rotation,$
                   no_color=no_color

   ;set up color scale (eric's poor man's gray sdcale)
;   loadct,39
;   tvlct,r,g,b,/get
;   r(0:12)=round(indgen(13)/13.0*250)
;   g(0:12)=r(0:12)
;   b(0:12)=r(0:12)
;   background_color=8       & if keyword_set(color_background) then background_color=color_background
;   continent_color=4        & if keyword_set(color_continent)  then continent_color=color_continent

	; Harald addition
   if not keyword_set(no_color) then begin
     loadct,0,/silent
     tvlct,r,g,b,/get
     g[255]=0 & b[255]=0
     tvlct,r,g,b
     endif

   background_color=154     & if keyword_set(color_background) then background_color=color_background
   continent_color=75       & if keyword_set(color_continent)  then continent_color=color_continent

   ;map set defaults
   scale1=42e6
   if keyword_set(scale) then scale1=scale

   ;plotting defaults
   pa1=[0,0,1,1]            & if keyword_set(position) then pa1=position
   lat1=63                  & if keyword_set(central_lat) then lat1=central_lat
   lon1=265                 & if keyword_set(central_lon) then lon1=central_lon

   if keyword_set(xsize) or keyword_set(ysize) then begin
      xs=xsize
      ys=ysize
      endif else begin
      xs=600
      ys=300
      endelse

   if keyword_set(window) then win_num=window else win_num=0
   if keyword_set(zbuffer) then begin
      set_plot,'z'
      device,set_resolution=[xs,ys]
   endif else begin
      ;old plot always erased if window is reset
      if ~keyword_set(noerase) then begin
         window,win_num,xsize=xs,ysize=ys
      endif
   endelse
      
   if keyword_set(projection) then name=projection else name='mercator'
   if keyword_set(rotation) then rot=rotation else rot=0.

;   map_set,/mercator,lat1,lon1,scale=scale1,/continents,position=pa1,noerase=noerase
;   polyfill,pa1([0,0,2,2,0]),pa1([1,3,3,1,1]),color=background_color,/normal
;   map_continents,/fill_continents,color=continent_color
   map_set,name=name,lat1,lon1,rot,scale=scale1,position=pa1,noerase=noerase
   if not keyword_set(noerase) then erase,background_color
   map_continents,/fill_continents,color=continent_color

return
end


