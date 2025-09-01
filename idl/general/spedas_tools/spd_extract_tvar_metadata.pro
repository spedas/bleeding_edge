;+
; FUNCTION:
;         spd_extract_tvar_metadata
;
; PURPOSE:
;         Returns metadata extracted from a tplot variable; mostly for tplot2ap and tplot2cdf
; NOTES:
;         prefers the following order:
;         - limits structure (set by the user during the session)
;         - dlimnits structure (set by the load routine)
;         - dlimits.cdf structure (stored in the CDF file)
;
; $LastChangedBy: dcarpenter $
; $LastChangedDate: 2025-08-25 18:06:30 -0700 (Mon, 25 Aug 2025) $
; $LastChangedRevision: 33578 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_extract_tvar_metadata.pro $
;-

function spd_extract_tvar_metadata, tvar
  compile_opt idl2
  tvar = tnames(tvar)
  if tvar eq '' then begin
    dprint, dlevel = 0, 'tplot variable not found!'
    return, -1
  endif
   
  out = create_struct('units', '', 'labels', '', 'catdesc', '', 'ztitle', '', 'ytitle', strjoin(strsplit(tvar, '_', /extract), '!C'), 'spec', 0b, 'ylog', 0b, 'zlog', 0b, 'yrange', [0, 0], 'zrange', [0, 0])
  str_element, out, 'COORDINATE_SYSTEM', '', /add
  
  get_data, tvar, dlimits = dl, limits = l
  if is_struct(dl) then begin
    ; check that the CDF structure exists
    str_element, dl, 'cdf', success = s
    
    ; first try the CDF info
    if s && is_struct(dl.cdf.vatt) then begin
      str_element, dl.cdf.vatt[0], 'catdesc', success = s
      if s then out.catdesc = dl.cdf.vatt[0].catdesc
  
      str_element, dl.cdf.vatt[0], 'units', success = s
      if s then out.units = dl.cdf.vatt[0].units
      
      if array_contains(STRUPCASE(TAG_NAMES(dl.cdf.vatt[0])), 'COORDINATE_SYSTEM') then str_element,out,'COORDINATE_SYSTEM',dl.cdf.vatt[0].COORDINATE_SYSTEM ,/add
      if array_contains(STRUPCASE(TAG_NAMES(dl.cdf.vatt[0])), 'COORD_SYS') then str_element,out,'COORDINATE_SYSTEM',dl.cdf.vatt[0].COORD_SYS ,/add
    endif

    ; now override of the load routine set the metadata
    str_element, dl, 'units', success = exists
    if exists then out.units = dl.units
    
    if array_contains(STRUPCASE(TAG_NAMES(dl)), 'COORDINATE_SYSTEM') then str_element,out,'COORDINATE_SYSTEM',dl.COORDINATE_SYSTEM ,/add
    if array_contains(STRUPCASE(TAG_NAMES(dl)), 'COORD_SYS') then str_element,out,'COORDINATE_SYSTEM',dl.COORD_SYS ,/add
    
    str_element, dl, 'data_att', success = data_att_exists
    if data_att_exists then begin
      str_element, dl.data_att, 'units', success = exists
      if exists then out.units = dl.data_att.units
      
      if array_contains(STRUPCASE(TAG_NAMES(dl.data_att)), 'COORDINATE_SYSTEM') then str_element,out,'COORDINATE_SYSTEM',dl.data_att.COORDINATE_SYSTEM ,/add
      if array_contains(STRUPCASE(TAG_NAMES(dl.data_att)), 'COORD_SYS') then str_element,out,'COORDINATE_SYSTEM',dl.data_att.COORD_SYS ,/add
    endif

    str_element, dl, 'ztitle', success = ztitle_exists
    if ztitle_exists then out.ztitle = dl.ztitle

    str_element, dl, 'ytitle', success = ytitle_exists
    if ytitle_exists then out.ytitle = dl.ytitle

    str_element, dl, 'labels', success = labels_exists
    if labels_exists then str_element, out, 'labels', dl.labels, /add

    str_element, dl, 'spec', success = exists
    if exists && byte(dl.spec) ne 0b then out.spec = 1b

    str_element, dl, 'ylog', success = exists
    if exists && byte(dl.ylog) ne 0b then out.ylog = 1b

    str_element, dl, 'zlog', success = exists
    if exists && byte(dl.zlog) ne 0b then out.zlog = 1b

    str_element, dl, 'yrange', success = exists
    if exists then out.yrange = dl.yrange

    str_element, dl, 'zrange', success = exists
    if exists then out.zrange = dl.zrange
  endif
  if is_struct(l) then begin
    ; try to extract data from the limits last, as 'limits' are set by the user
    str_element, l, 'units', success = exists
    if exists then out.units = l.units

    str_element, l, 'data_att', success = data_att_exists
    if data_att_exists then begin
      str_element, l.data_att, 'units', success = exists
      if exists then out.units = l.data_att.units
      
      if array_contains(STRUPCASE(TAG_NAMES(l.data_att)), 'COORDINATE_SYSTEM') then str_element,out,'COORDINATE_SYSTEM',l.data_att.COORDINATE_SYSTEM ,/add
      if array_contains(STRUPCASE(TAG_NAMES(l.data_att)), 'COORD_SYS') then str_element,out,'COORDINATE_SYSTEM',l.data_att.COORD_SYS ,/add
    endif

    str_element, l, 'ztitle', success = ztitle_exists
    if ztitle_exists then out.ztitle = l.ztitle

    str_element, l, 'ytitle', success = ytitle_exists
    if ytitle_exists then out.ytitle = l.ytitle

    str_element, l, 'labels', success = labels_exists
    if labels_exists then str_element, out, 'labels', l.labels, /add

    str_element, l, 'spec', success = exists
    if exists && byte(l.spec) ne 0b then out.spec = 1b

    str_element, l, 'ylog', success = exists
    if exists && byte(l.ylog) ne 0b then out.ylog = 1b

    str_element, l, 'zlog', success = exists
    if exists && byte(l.zlog) ne 0b then out.zlog = 1b

    str_element, l, 'yrange', success = exists
    if exists then out.yrange = l.yrange

    str_element, l, 'zrange', success = exists
    if exists then out.zrange = l.zrange
  endif

  return, out
end
