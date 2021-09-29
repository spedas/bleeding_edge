;+
;Procedure:
;  cl_load_crib
;
;Purpose:
;  Basic example of loading and plotting Cluster data (from SPDF) for multiple instruments, including:
;   1) Fluxgate magnetometer (FGM)
;   2) Electron Drift Instrument (EDI)
;   3) Electric Field and Wave experiment (EFW)
;   4) Digital Wave Processing experiment (DWP)
;   5) Cluster Ion Spectrometry experiment (CIS)
;   6) Spatio-Temporal Analysis of Field Fluctuation experiment (STAFF)
;   7) Research with Adaptive Particle Imaging Detectors (RAPID)
;   8) Plasma Electron And Current Experiment (PEACE)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-03-02 11:53:41 -0800 (Mon, 02 Mar 2020) $
;$LastChangedRevision: 28360 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/examples/cl_load_crib.pro $
;-

tr = ['2003-10-28', '2003-10-29']
probe = 4

; load the spin-resolution FGM parameters
cl_load_fgm, trange=tr, probe=probe, datatype='cp'
stop

tplot, ['B_mag__C4_CP_FGM_SPIN', 'B_vec_xyz_gse__C4_CP_FGM_SPIN']
stop

; load data from the Electron Drift Instrument (EDI); note: this example contains all NaNs
cl_load_edi, trange=['2003-10-1', '2003-11-1'], probe=probe
stop

tplot, ['V_ed_xyz_gse__C4_PP_EDI', 'E_xyz_gse__C4_PP_EDI']
stop

; load data from the Electric Field and Wave experiment (EFW)
cl_load_efw, trange=tr, probe=probe
stop

tplot, ['E_pow_f1__C4_PP_EFW', 'E_dusk__C4_PP_EFW']
stop

; load data from the Digital Wave Processing experiment (DWP)
cl_load_dwp, trange=tr, probe=probe
stop

tplot, 'Correl_Ivar__C4_PP_DWP'
stop

; load data from the Cluster Ion Spectrometry experiment (CIS)
cl_load_cis, trange=tr, probe=probe
stop

; combine the CIS parallel and perpendicular temperatures into a single variable
options, 'T_p_par__C4_PP_CIS', labels='par'
options, 'T_p_perp__C4_PP_CIS', labels='perp'
store_data, 'T_p', data='T_p_par__C4_PP_CIS T_p_perp__C4_PP_CIS'
options, 'T_p', labflag=-1
options, 'T_p', colors=[2, 4]

tplot, ['T_p', 'N_p__C4_PP_CIS', 'V_p_xyz_gse__C4_PP_CIS']
stop

; load data from the Spatio-Temporal Analysis of Field Fluctuation experiment (STAFF)
cl_load_staff, trange=tr, probe=probe
stop

tplot, ['B_par_f1__C4_PP_STA', 'B_perp_f1__C4_PP_STA']
stop

; load data from the Research with Adaptive Particle Imaging Detectors (RAPID)
cl_load_rapid, trange=tr, probe=probe
stop

tplot, ['J_e_lo__C4_PP_RAP', 'J_e_hi__C4_PP_RAP', 'J_p_lo__C4_PP_RAP', 'J_p_hi__C4_PP_RAP']
stop

; load data from the Plasma Electron And Current Experiment (PEACE)
cl_load_peace, trange=tr, probe=probe
stop

tplot, ['N_e_den__C4_PP_PEA', 'V_e_xyz_gse__C4_PP_PEA', 'T_e_par__C4_PP_PEA', 'T_e_perp__C4_PP_PEA']
stop


end