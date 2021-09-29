;+
; PROCEDURE:
;         mms_load_fsm_crib
;
; PURPOSE:
;         Crib sheet showing how to load and plot L3 FSM (FGM+SCM) data
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-05-27 17:26:03 -0700 (Wed, 27 May 2020) $
; $LastChangedRevision: 28744 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fsm_crib.pro $
;-

; Load 60 seconds of FSM data for probe 4
timespan, '2017-07-11/22:33:30', 60, /seconds

mms_load_fsm, probe=4, /time_clip

tplot, ['mms4_fsm_b_gse_brst_l3', 'mms4_fsm_b_mag_brst_l3']

stop
end