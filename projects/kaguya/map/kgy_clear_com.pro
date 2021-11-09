;+
; PROCEDURE:
;       kgy_clear_com
; PURPOSE:
;       undefine structures in the kgy common blocks
; CALLING SEQUENCE:
;       kgy_clear_com
; KEYWORDS:
;       onlydata: undefines data structures and keeps info and fov structures
; CREATED BY:
;       Yuki Harada on 2014-07-03
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2021-11-08 05:03:15 -0800 (Mon, 08 Nov 2021) $
; $LastChangedRevision: 30409 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/kgy_clear_com.pro $
;-

pro kgy_clear_com, onlydata=onlydata

@kgy_pace_com
  if keyword_set(onlydata) then begin
     undefine, esa1_header_arr,esa1_type00_arr,esa1_type01_arr,esa1_type02_arr
     undefine, esa2_header_arr,esa2_type00_arr,esa2_type01_arr,esa2_type02_arr
     undefine, ima_header_arr,ima_type40_arr,ima_type41_arr,ima_type42_arr,ima_type43_arr
     undefine, iea_header_arr,iea_type80_arr,iea_type81_arr,iea_type82_arr
     undefine, index_next
  endif else begin
     undefine, esa1_info_str,esa1_fov_str,esa1_header_arr,esa1_type00_arr,esa1_type01_arr,esa1_type02_arr
     undefine, esa2_info_str,esa2_fov_str,esa2_header_arr,esa2_type00_arr,esa2_type01_arr,esa2_type02_arr
     undefine, ima_info_str,ima_fov_str,ima_header_arr,ima_type40_arr,ima_type41_arr,ima_type42_arr,ima_type43_arr, ima_tof_str
     undefine, iea_info_str,iea_fov_str,iea_header_arr,iea_type80_arr,iea_type81_arr,iea_type82_arr
     undefine, index_next
  endelse

@kgy_lmag_com
  undefine, lmag_pub, lmag_all, lmag_sat, lmag_all32hz, lmag_sat32hz

end
