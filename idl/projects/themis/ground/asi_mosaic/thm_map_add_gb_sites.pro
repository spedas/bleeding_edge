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
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_add_gb_sites.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
pro thm_map_add_gb_sites,t_in,tgb_sites=tgb_sites,$
                              tgb_site_color=tgb_site_color,$
                              tgb_site_name=tgb_site_name,$
                              tgb_site_abbrev=tgb_site_abbrev,$
                              tgb_site_sym_size=tgb_site_sym_size
    if keyword_set(tgb_sites) then begin
      usersym,[-1,0,1,0,-1],[0,1,0,-1,0],/fill  ;use diamond - option later
      x_offset=5
      y_offset=5 ;in device coordinates - make option later
      w=thm_gbo_site_list(tgb_sites,verbose=verbose)
      if w(0) ne -1 then begin
        cc1=0 & if keyword_set(tgb_site_color) then cc1=tgb_site_color
        tt=t_in(w)
        ss1=1 & if keyword_set(tgb_site_sym_size) then ss1=tgb_site_sym_size
        for i=0,n_elements(tt)-1 do begin
           xg=tt(i).longitude
           yg=tt(i).latitude
           u=convert_coord(xg,yg,/to_device,/data)
           xd=u(0)
           yd=u(1)
           plots,xd,yd,psym=8,color=cc1,symsize=ss1,/device
           if keyword_set(tgb_site_name) or keyword_set(tgb_site_abbrev) then begin
              b=''
              if keyword_set(tgb_site_name) then b=tt(i).name
              if keyword_set(tgb_site_abbrev) then b=tt(i).abbreviation
              xyouts,xd+x_offset,yd+y_offset,b,color=0,/device
           endif
        endfor
      endif
   endif
return
end
;--------------------------------------------------------------------------------------

