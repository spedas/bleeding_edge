;+
;COMMON BLOCK:   mvn_swe_com
;PURPOSE:
;  Stores the SWEA static memory.
;
;     swe_hsk:  slow housekeeping
;     a0:       3D survey
;     a1:       3D archive
;     a2:       PAD survey
;     a3:       PAD archive
;     a4:       ENGY survey
;     a5:       ENGY archive
;     a6:       fast housekeeping
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-15 11:25:13 -0700 (Thu, 15 May 2025) $
; $LastChangedRevision: 33310 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_com.pro $
;
;CREATED BY:	David L. Mitchell  2013-03-18
;FILE:  mvn_swe_com.pro
;-
common swe_raw, a0, a1, a2, a3, a4, a5, a6, swe_hsk, swe_3d, swe_3d_arc, $
                swe_a0_str, swe_a2_str, swe_a4_str, swe_a6_str, swe_hsk_str, $
                swe_hsk_names, swe_tabnum, swe_active_tabnum, pfp_hsk, pfp_hsk_str

common swe_dat, swe_3d_struct, swe_pad_struct, swe_engy_struct, swe_mag_struct, $
                swe_engy_l2_str, swe_pad_l2_str, swe_3d_l2_str, $
                swe_pot_struct, swe_mag1, swe_mag2, swe_sc_pot, $
                mvn_swe_engy, mvn_swe_engy_arc, mvn_swe_pad, mvn_swe_pad_arc, $
                mvn_swe_3d, mvn_swe_3d_arc, swe_specsvy_gf, swe_specarc_gf, $
                swe_padsvy_gf, swe_padarc_gf, swe_3dsvy_gf, swe_3darc_gf, $
                swe_fpad, swe_fpad_arc

common swe_cal, decom, swe_v, swe_t, swe_ne, swe_dt, swe_duty, swe_gf, swe_swp, $
                swe_de, swe_el, swe_del, swe_az, swe_daz, swe_Ka, swe_dead, $
                swe_integ_t, swe_padlut, swe_mcp_eff, swe_rgf, swe_dgf, devar, $
                mass_e, swe_min_dtc, swe_sc_mask, swe_energy, swe_denergy, $
                swe_cc_switch, swe_es_switch, swe_G, swe_Ein, swe_Ke, swe_ogf, $
                swe_ff_state, pfp_v, pfp_t, swe_paralyze

common swe_fov, Sx3d, Sy3d, Sz3d, patch_size

common swe_cfg, mvn_swe_version, t_swp, t_mtx, t_dsf, t_mcp, t_sup, t_cfg, swe_verbose

common swe_spice, swe_kernels, ker_info
