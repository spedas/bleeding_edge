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
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_add_asi_fovs.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
pro thm_map_add_asi_fovs,t_in,asi_fovs=asi_fovs,$
                              asi_emission_height=asi_emission_height,$
                              asi_fov_elevation=asi_fov_elevation,$
                              asi_fov_color=asi_fov_color,$
                              asi_fov_thick=asi_fov_thick
   if keyword_set(asi_fovs) then begin
      if keyword_set(asi_emission_height) then height=asi_emission_height else height=110     ;km
      if keyword_set(asi_fov_elevation) then elevation=asi_fov_elevation else elevation=10    ;degrees
      kk=asi_fovs
      jt=size(kk,/type)
      jd=size(kk,/n_dimensions)
      je=size(kk,/n_elements)
      w=[-1]
      if jt eq 2 and jd eq 0 then w=where(t_in.themis_asi eq 1)
      if jt eq 2 and jd eq 1 then w=kk
      if jt eq 7 and jd eq 0 then kk=[kk]
      if jt eq 7 then begin
        nt=0
        for i=0,n_elements(kk)-1 do begin
           b=strlowcase(kk[i])
           wt=where(strlowcase(t_in.abbreviation) eq b)
           if wt[0] ne -1 then begin
              if nt eq 0 then w[nt]=wt[0]
              if nt eq 1 then w=[w,wt[0]]
              nt=1
           endif
        endfor
      endif
      if w[0] ne -1 then begin
        afc=0 & if keyword_set(asi_fov_color) then afc=asi_fov_color
        tt=t_in[w]
        for i=0,n_elements(tt)-1 do begin
           pos=thm_map_add_site_fieldofview([0.0,tt[i].latitude,tt[i].longitude],elevation,height)
           oplot,pos[2,*],pos[1,*],color=afc,thick=asi_fov_thick,linestyle=0
        endfor
      endif
   endif
return
end
;---------------------------------------------------------------------------------------------------------------
