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
;   $LastChangedDate: 2024-12-13 08:57:41 -0800 (Fri, 13 Dec 2024) $
;   $LastChangedRevision: 32989 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_oplot_geographic_grid.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
;subroutine to be called by thm_map_add
pro thm_map_oplot_geographic_grid,geographic_lons=geographic_lons,$
                                 geographic_lats=geographic_lats,$
                                 geographic_color=geographic_color,$
                                 geographic_thick=geographic_thick,$
                                 geographic_linestyle=geographic_linestyle
                                 
  compile_opt idl2
  
  ing=0
  if keyword_set(geographic_color) then ing=geographic_color
  if keyword_set(geographic_lats) and keyword_set(geographic_lons) then begin
         lat0=geographic_lats[0]
         lat1=geographic_lats[n_elements(geographic_lats)-1]
         lon0=geographic_lons[0]
         lon1=geographic_lons[n_elements(geographic_lons)-1]
         n=150
         for i=0,n_elements(geographic_lats)-1 do begin
             u=lon0+findgen(n)/float(n-1)*(lon1-lon0)
             oplot,u,replicate(geographic_lats[i],n),$
                   color=ing,$
                   thick=geographic_thick,$
                   linestyle=geographic_linestyle,$
                   noclip=0
         endfor
         n=30
         for i=0,n_elements(geographic_lons)-1 do begin
             u=lat0+findgen(n)/float(n-1)*(lat1-lat0)
             oplot,replicate(geographic_lons[i],n),u,$
                   color=ing,$
                   thick=geographic_thick,$
                   linestyle=geographic_linestyle,$
                   noclip=0
         endfor
  endif
  if keyword_set(geographic_lats) and not keyword_set(geographic_lons) then begin
         n=150 & u=360.0*findgen(n)/float(n-1)
         for i=0,n_elements(geographic_lats)-1 do $
             oplot,u,replicate(geographic_lats[i],n),$
               color=ing,thick=geographic_thick,linestyle=geographic_linestyle,noclip=0
  endif
  if keyword_set(geographic_lons) and not keyword_set(geographic_lats) then begin
         n=91 & u=-90+indgen(n)*2
         for i=0,n_elements(geographic_lons)-1 do $
             oplot,replicate(geographic_lons[i],n),u,$
               color=ing,thick=geographic_thick,linestyle=geographic_linestyle,noclip=0
  endif
return
end
;----------------------------------------------------------------------------------------------------