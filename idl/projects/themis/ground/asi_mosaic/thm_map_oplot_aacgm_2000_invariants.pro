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
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_oplot_aacgm_2000_invariants.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
;invariants (note restrictions on invariant lats at 5 degree intervals
;invariants calculated using Rob Barnes' PACE 2000 IDL code
;in future we should include Rob's code in the THEMIS distribution
;thm_map_add,invariant_lats=[65,70]
;thm_map_add,invariant_lats=[70]
;thm_map_add,invariant_lats=[50,60,85]    ;has contours ONLY for 50 through 85 degrees north in 5 degree steps
                                             ;takes ONLY arrays of invariant latitude values
;thm_map_add,invariant_lats=[65,70],/invariant_lons
                                             ;invariant longitudes at one hour MLT spacing starting from Churchill meridian
                                             ;only has an effect if invariant_lats is set and n_elements(invariant_lons)>1
;thm_map_add,invariant_lats=[65,70],/invariant_lons,invariant_color=250,invariant_thick=10
;---------------------------------------------------------------------------------------------
;this overplots contours of constant invariant latitude and longitude on the map
;contours are stored in the idl save file thm_map_add.sav which must be in this directory
;contours are calculated using IDL PACE routine provide by Rob Barnes using the 2000 epoch
;a later version of this program should include the Barnes program - Eric will contact him about that
;there are only limited options here designed to provide a first cut
;---------------------------------------------------------------------------------------------
pro thm_map_oplot_aacgm_2000_invariants,aacgm_lon_contour,aacgm_lat_contour,$
                                        invariant_lats=invariant_lats,$
                                        invariant_lons=invariant_lons,$
                                        invariant_color=invariant_color,$
                                        invariant_thick=invariant_thick,$
                                        invariant_linestyle=invariant_linestyle

   compile_opt idl2

   if keyword_set(invariant_lons) or keyword_set(invariant_lats) then begin
     u_lon=reform(aacgm_lon_contour[0,*,*])
     u_lat=reform(aacgm_lon_contour[1,*,*])
     v_lon=reform(aacgm_lat_contour[0,*,*])
     v_lat=reform(aacgm_lat_contour[1,*,*])
   endif
   inc=0 & if keyword_set(invariant_color) then inc=invariant_color
   if keyword_set(invariant_lats) then begin
      for i=0,n_elements(invariant_lats)-1 do begin
          j=invariant_lats[i]
          jt=j mod 5
          if jt ne 0 then dprint, 'element '+strcompress(string(i),/remove_all)+' of invariant_lats is not valid'
          if jt eq 0 then oplot,v_lon[j/5-10,*],v_lat[j/5-10,*],color=inc,thick=invariant_thick,noclip=0,linestyle=invariant_linestyle
      endfor
   endif
   if keyword_set(invariant_lons) and not keyword_set(invariant_lats) then dprint, 'you must set invariant_lats if you set invariant_lons'
   if keyword_set(invariant_lons) and keyword_set(invariant_lats) then begin
      if n_elements(invariant_lats) eq 1 then dprint, 'note - invariant_lons has no effect if n_elements(invariant_lats)=1'
      ilat0=invariant_lats[0]
      ilat1=invariant_lats[n_elements(invariant_lats)-1]
      n=20
      ilat_out=ilat0+findgen(n)/float(n-1)*(ilat1-ilat0)
      ilat_in =50+findgen(31)/float(30)*35 ;refer to where I make the invariant contour arrays
      for i=0,23 do begin
        x1=reform(u_lon[i,*])
        w1=where(x1 lt -150)
        w2=where(x1 gt  150)
        if w1[0] ne -1 and w2[0] ne -1 then x1[w1]=x1[w1]+360  ;wrap around at -180 invalidates interpolate
        y1=reform(u_lat[i,*])
        x=interpol(x1,ilat_in,ilat_out)
        y=interpol(y1,ilat_in,ilat_out)
        oplot,x,y,color=inc,thick=invariant_thick,noclip=0,linestyle=invariant_linestyle
      endfor
   endif
return
end
;---------------------------------------------------------------------------------------------
