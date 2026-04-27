;+
;
;PURPOSE:         General crib sheet on how to run the ESCAPADE routines.
;
;CREATED BY:      Takuya Hara on 2026-03-12.
;
;                 takuya.hara_at_berkeley.edu
;                 hara_at_ssl.berkeley.edu
;                 (_at_ -> @)      
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-04-20 11:49:44 -0700 (Mon, 20 Apr 2026) $
; $LastChangedRevision: 34390 $
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
; use them, please contact Takuya Hara (SDOC Science Lead).

timespan, '2026-03-05'
ipath = './' ; Please specify where to place the L1 CDF file(s).
esc_iesa_load, prod='f4d', /blue, ipath=ipath, data=data ; 'f4d' = Fine 4D (APID 0x125) 
esc_iesa_tplot 


; Searches & Retrieves the latest L0 raw packet data file.

timespan, '2026-03-05'
get_timespan, trange
files = esc_l0_file_retrieve(trange=trange, apid='125')


;-------------------------------------------------------------------------------------------------------------------
; Useful Tips (L2 loitering & Cruise Phases)

; Converting coordinate systems from GSE to GSM.
timespan, ['2026-02-21', '2026-03-15']
esc_spice_load
cotrans, 'escb_eph_gse', 'escb_eph_gsm', /gse2gsm

