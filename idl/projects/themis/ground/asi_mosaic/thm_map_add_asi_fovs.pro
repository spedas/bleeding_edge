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
;   $LastChangedDate: 2026-10-14 09:54:40 -0700 (Wed, 14 Oct 2026) $
;   $LastChangedRevision: 34975 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_add_asi_fovs.pro $
;-
; user modification: broadened integer-type test (is_int) so asi_fovs=1
; works under compile_opt idl2

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
      ; any integer type counts as numeric input (a literal 1 is LONG under
      ; compile_opt idl2, which the old jt eq 2 test silently rejected --
      ; asi_fovs=1 drew nothing in thm_crib_map ex_4/ex_5)
      is_int = (jt ge 1 and jt le 3) or (jt ge 12 and jt le 15)
      if is_int and jd eq 0 then w=where(t_in.themis_asi eq 1)
      if is_int and jd eq 1 then w=kk
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
