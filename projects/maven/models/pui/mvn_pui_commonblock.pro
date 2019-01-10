;20170126 Ali
;Pickup ion code common blocks
;pui:  model-data structure
;pui0: instrument and model constants
;pui1: energy bins
;pui2: temporary variables
;pui3: 2D mapping of pickup ion d2m ratios
;pui4 to pui 9: reserved for future use
common mvn_pui_com,pui,pui0,pui1,pui2,pui3,pui4,pui5,pui6,pui7,pui8,pui9

;SWIA common block
common mvn_swia_data,info_str,swihsk,swics,swica,swifs,swifa,swim,swis

;SEP common block (pointers)
@mvn_sep_handler_commonblock.pro

;SWEA common block
@mvn_swe_com 
                
;STATIC common block
common mvn_c0,mvn_c0_ind,mvn_c0_dat
common mvn_c6,mvn_c6_ind,mvn_c6_dat
common mvn_d0,mvn_d0_ind,mvn_d0_dat
common mvn_d1,mvn_d1_ind,mvn_d1_dat

