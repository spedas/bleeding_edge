;+
; NAME:      thm_gbo_site_list
; SYNTAX:
; PURPOSE:
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY:   original from Donovan
;            2007-03-16, hfrey update to local THEMIS dir
;
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2026-10-14 09:54:40 -0700 (Wed, 14 Oct 2026) $
;   $LastChangedRevision: 34975 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_gbo_site_list.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan - 2007
;interpret input site list (tgb_sites above, or seventh input variable), which can be in 4 forms
; sites_list_in                  outcome
;   1                       gako mcgr kian fykn inuv whit ekat fsim pgeo rank fsmi atha gill tpas pina snkq kapu kuuj chbg gbay
; 'atha'                    atha
; 'ATHA'                    atha
; ['gako','atha','rank']    gako atha rank
; ['GAKO','ATHA','RANK']    gako atha rank
; [3,11,12,13,14]           kian fsmi atha gill tpas

function thm_gbo_site_list,site_list_in,verbose=verbose
      site_list=site_list_in
	; thm_map_add.sav ships with the SPEDAS distribution (asi_mosaic
	; directory); previously restored from the downloaded Berkeley copy
      rt_info = routine_info('thm_gbo_site_list', /source, /functions)
      restore, file_dirname(rt_info.path) + path_sep() + 'thm_map_add.sav'
      jt=size(site_list,/type)
      jd=size(site_list,/n_dimensions)
      je=size(site_list,/n_elements)
      w=[-1]
      ; any integer type counts as numeric input (a literal 1 is LONG under
      ; compile_opt idl2, which the old jt eq 2 test silently rejected)
      is_int = (jt ge 1 and jt le 3) or (jt ge 12 and jt le 15)
      if is_int and jd eq 0 then w=where(THG_MAP_GB_SITES.themis_asi eq 1)
      if is_int and jd eq 1 then w=site_list
      if jt eq 7                              then begin
        if jd eq 0 then site_list=[site_list]
        nt=0
        for i=0,n_elements(site_list)-1 do begin
           b=strlowcase(site_list(i))
           wt=where(strlowcase(THG_MAP_GB_SITES.abbreviation) eq b)
           if wt(0) ne -1 then begin
              if nt eq 0 then w(nt)=wt(0)
              if nt eq 1 then w=[w,wt(0)]
              nt=1
           endif
        endfor
      endif
      if keyword_set(verbose) then if w(0) eq -1 then dprint, 'C101(thm_gbo_site_list): site_list not valid'
return,w
end
;--------------------------------------------------------------------------------------
