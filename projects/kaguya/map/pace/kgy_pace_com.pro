;+
; COMMON BLOCK:
;       kgy_pace_com
; PURPOSE:
;       stores the PACE static memory
;       *_info_str: information structures which contain energies,
;                   angles, g-factors, etc.
;       *_header_arr: header structure arrays which contain time,
;                     sensor, mode and other information
;       *_type??_arr: data structure arrays which typically contain
;                     'event', 'cnt', and 'trash' tags
; CREATED BY:
;       Yuki Harada on 2014-06-30
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2021-11-08 05:03:15 -0800 (Mon, 08 Nov 2021) $
; $LastChangedRevision: 30409 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_com.pro $
;-

common kgy_esa1, esa1_info_str,esa1_fov_str,esa1_header_arr,esa1_type00_arr,esa1_type01_arr,esa1_type02_arr
common kgy_esa2, esa2_info_str,esa2_fov_str,esa2_header_arr,esa2_type00_arr,esa2_type01_arr,esa2_type02_arr
common kgy_ima, ima_info_str,ima_fov_str,ima_header_arr,ima_type40_arr,ima_type41_arr,ima_type42_arr,ima_type43_arr, ima_tof_str
common kgy_iea, iea_info_str,iea_fov_str,iea_header_arr,iea_type80_arr,iea_type81_arr,iea_type82_arr
common kgy_pace_misc, index_next
