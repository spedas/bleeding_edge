;+
;
;PURPOSE:         General crib sheet on how to run the ESCAPADE routines.
;
;NOTE:            If you have any questions, concerns, or feedback regarding the ESCAPADE data analysis software,
;                 please feel free to contact Takuya Hara (ESCAPADE Science Data Lead).
;
;CREATED BY:      Takuya Hara on 2026-03-12.
;
;                 takuya.hara_at_berkeley.edu
;                 hara_at_ssl.berkeley.edu
;                 (_at_ -> @)      
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-08-21 15:56:26 -0700 (Fri, 21 Aug 2026) $
; $LastChangedRevision: 34800 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/general/esc_gen_crib.pro $
;
;-


;-------------------------------------------------------------------------------------------------------------------
; Loading procedures


; Note:
; YYYY-MM-DD:
; 2026-03-12: Please keep in mind using /commissioning keyword! 
; 2026-04-20: NO LONGER need to use /commissioning keyword, 
;             because the latest routines can automatically determine
;             where to retrieve the science data.
;

; Determines the mission phases.

times = ['2024-10', '2025-11-14', '2026-02-26']
phases = esc_mission_phase(times)
print, phases


; Loading the s/c position in the GSE frame. The output unit should be
; R_E (Earth Radii).

timespan, ['2025-11-14', '2026-03-12']
esc_eph_load, /commissioning, frame='GSE', /re


; Alternatively, we can calculate the s/c position using the
; SPICE/kernels.

timespan, ['2025-11-14', '2026-03-12']
esc_spice_load, info=info


; Loading the EMAG L1 CDF data.

timespan, '2026-03-05'
esc_emag_load, frame=['GSE', 'RTN']


; Loading the ELP L1 CDF data.

timespan, '2026-02-25'
esc_elp_load, /blue 


; Loading the EESA-e L1 CDF data.
; The data is stored in common blocks.
; The routine prefix should be 'esc_eesa_'. 

timespan, '2026-03-05'
esc_eesa_load, prod='f3d', /blue, data=data ; 'f3d' = Full 3D (APID 0x140)
esc_eesa_tplot, /mean


; Loading the EESA-i L1 CDF data.
; The data is stored in common blocks.
; The routine prefix should be 'esc_iesa_'.
; As of 2026-03-12, any EESA-i CDF files are not available.
; If you are a member of the official science team and would like to
; use them, please contact Takuya Hara (Science Data Lead).

timespan, '2026-03-05'
ipath = './'                    ; Please specify from which to load the provisional L1 CDF file(s).

; 'f4d' = Fine 4D     (APID 0x125)
; 'fm'  = Fine Masses (APID 0x147)
; 'sw'  = Solar Wind  (APID 0x139)
esc_iesa_load, prod=['f4d', 'fm', 'sw'], /blue, ipath=ipath, data=data
esc_iesa_tplot 


; Searches & Retrieves the latest L0 raw packet data file.

timespan, '2026-03-05'
get_timespan, trange
files = esc_l0_file_retrieve(trange=trange, apid='125')


;-------------------------------------------------------------------------------------------------------------------
; Quicklook Plot Routines (updated 2026-08-19)
;
; NOTE: Tohban should always use the latest version (i.e., bleeding-edge version) of the IDL/SPEDAS software, 
;       because the quicklook routines and relevant subroutines may be updated frequently.
;
; As of 2026-08-19, only provisional EESA-i CDF files are available.
; Therefore, specify the path from which to load the EESA-i CDF files using the IPATH keyword. 

ipath = './' 
esc_ql_tplot, trange=['2026-06-28', '2026-07-05'], ipath=ipath, /reset, /l1, /clock, /keep

; If Tohban wants to visualize the overview quicklook plot for the past two weeks, execute the following:

oneday = 86400.d0
esc_ql_tplot, '2026-08-19', long=14, tshift=-1.d0 * 14.d0 * oneday, /reset, /l1, /clock, /keep

; As of 2026-08-19, the EESA-e PAD and ELP EUV proxy data are not yet available.
; If Tohban wants to omit these panels, execute the following:

esc_ql_tplot, '2026-08-19', long=14, tshift=-1.d0 * 14.d0 * oneday, /reset, /l1, /clock, /keep, pad=0, euv=0

; If Tohban encounters any errors, please reach out to Takuya Hara (ESCAPADE Science Data Lead) via email or Slack.
;
; Email:
; takuya.hara_at_berkeley.edu
; hara_at_ssl.berkeley.edu (_at_ -> @)
;

;-------------------------------------------------------------------------------------------------------------------
; ESCAPADE-dedicated Tplot Wrapper: esc_tplot (updated 2026-08-21)
;
line_colors, 5
timespan, '2026-08-21'
esc_emag_load, frame='GSE'

; Setup 0: Set the visualization routine to 'esc_tplot' using the "tplot_routine" keyword.
options, ['esc_emag_tot', 'esc*_emag_gse'], tplot_routine='esc_tplot'

; Example 1: Customize the y-axis title color.
options, 'escb_emag_gse', ytitle_color=2 ; = Blue   (for ESCAPADE/BLUE)
options, 'escg_emag_gse', ytitle_color=5 ; = Orange (for ESCAPADE/GOLD)

; Example 2: Add a timebar (i.e., draw vertical line(s) at the user-specified timestamp(s)) to the specified tplot variable.
t = '2026-08-21/12'
options, 'esc_emag_tot', timebar={time: t, color: 1, linestyle: 2}


;-------------------------------------------------------------------------------------------------------------------
; Useful Tips (L2 loitering & Cruise Phases)

; Converting coordinate systems from GSE to GSM.
timespan, ['2026-02-21', '2026-03-15']
esc_spice_load
cotrans, 'escb_eph_gse', 'escb_eph_gsm', /gse2gsm

