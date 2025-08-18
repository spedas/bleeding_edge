;+
;thm_crib_fgm.pro
;usage:
; .run thm_crib_fgm
;
;Notes:
;Disable print statements by calling "dprint,setdebug=-1" before running the crib
;
;Written by Hannes Schwarzl and Ken Bromund
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
; $LastChangedRevision: 17433 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_fgm.pro $
;
;-

dprint, "--- Start of crib sheet ---"
;timespan, '6-8-17', 1
timespan, '2007-3-23', 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dprint, "-"
dprint, "- 'standardized' interface, with intermediate outputs saved"
dprint, "--> enter .c"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stop

thm_load_state,probe='a', /get_support_data

thm_load_fgm,lev=1,probe=['a'],/get_support_data,type='raw', suffix='_raw'

thm_cal_fgm,probe=['a'],datatype='fg?',in_suffix='_raw', out_suffix='_ssl'

tplot_options, 'title', 'THEMIS FGM Examples'
tplot, ['tha_fgl_raw', 'tha_fgl_ssl']

;  note: thm_contrans accepts probe and datatype keywords:
thm_cotrans,probe=['a'],datatype='fg?',in_suffix='_ssl', out_suffix='_dsl', out_coord='dsl'
;  note: thm_cotrans can also work directly with tplot names:
thm_cotrans,'tha_fg?',in_suf='_dsl',out_suf='_gse', out_c='gse'

thm_cotrans,'tha_fg?',in_suf='_gse', out_suf='_gsm', out_c='gsm'

tplot, ['tha_fgl_raw', 'tha_fgl_ssl', 'tha_fgl_dsl', 'tha_fgl_gse','tha_fgl_gsm']

stop

tplot, ['tha_fg?_gsm']

stop

store_data, 'Tha_fgl_dsl_gse', data=['tha_fgl_dsl', 'tha_fgl_gse']
 options, 'tha_fgl_gse', 'colors', [1, 3, 5]
tplot, 'Tha_fgl_dsl_gse'


; clean up support data
del_data, 'th?_fg?_hed th?_state'
tplot_names
; clean up support data, and intermediate outputs, and state data
;del_data, 'th?_fg?_* th?_state*'
;tplot_names


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dprint, "-"
dprint, "- next: same thing, but  without saving intermediate outputs"
dprint, "--> enter .c"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stop

del_data, 'th* Th*'

thm_load_state,probe='a', /get_support_data

thm_load_fgm,level='L1',probe=['a'],/get_support_data,type='raw'

thm_cal_fgm,probe=['a'],datatype='fg?'

thm_cotrans,probe=['a'],datatype='fg?', out_coord='dsl'

thm_cotrans,'tha_fg?', out_c='gse'

thm_cotrans,'tha_fg?', out_c='gsm'

tplot, ['tha_fg?']

; clean up support data
del_data, 'th?_fg?_hed'
tplot_names


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dprint, "-"
dprint, "- next: load, calibrate, and transform coordinates in one call"
dprint, "--> enter .c"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stop

del_data, 'th* Th*'

timespan, '2007-3-23', 1
; only load spin data needed for cotrans
thm_load_state, probe='a', datatype='spin*', /get_support_data
; default is 'l1 calibrated dsl': request 'l1 calibrated gsm'
thm_load_fgm,level=1, probe=['a'],datatype='fg?',coord='gsm'
tplot, 'tha_fg?'

;  another thm_cotrans example: when not doing globbing, you can
;  specify output tplot variable directly:
thm_cotrans, 'tha_fgl', 'tha_fgl_gse', out_coord='gse'

;; Since /get_support_data keyword was not given, but default action is
;; to calibrate: the necessary support data is retrieved and
;; cleaned up automatically by thm_load_fgm.
;; if you want it to stick around, then give the /get_support_data keyword.
tplot_names

dprint, "cleanup state"
del_data, 'th?_state*'

tplot_names

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dprint, "-"
dprint, "- next: load data directly from L2 CDF"
dprint, "--> enter .c"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stop

; get the dsl data, and add a _l2 suffix
thm_load_fgm, probe='a', suffix='_l2', level = 'l2'
tplot_names

; load data in all coordinate systems availabe in L2 CDF
thm_load_fgm, probe='a', coord='*', level = 'l2'
tplot_names

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dprint, "-"
dprint, "- note that the original crib still works, with one change:"
dprint, "- new keyword to override new default behavior of thm_load_fgm: type='raw'"
dprint, "--> enter .c"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stop

thm_load_state,/get_support_data,probe='a'
thm_load_fgm,level=1,probe=['a'],/get_support_data,type='raw'

; file names for real calibration files are: th[a-e]_fgmcal.txt
; they can be found in the 'master' file directory of the data tree.
cal_relpathname = 'tha/l1/fgm/0000/tha_fgmcal.txt'
cal_file = spd_download(remote_file=cal_relpathname, _extra=!themis)

thm_cal_fgm,'tha_fgl','tha_fgl_hed','tha_fgl_ssl',cal_file,datatype='fgl'

tplot_options, 'title', 'THEMIS FGM Examples'
tplot, ['tha_fgl', 'tha_fgl_ssl']

; Interface to ssl2dsl has changed: all arguments now specified by
; keywords instead of positional parameters, new arguments for
; using spinmodel routines.

ssl2dsl,name_input='tha_fgl_ssl',name_output='tha_fgl_dsl',spinmodel_ptr=spinmodel_get_ptr('a')

dsl2gse,'tha_fgl_dsl','tha_state_spinras','tha_state_spindec','tha_fgl_gse'

cotrans,'tha_fgl_gse','tha_fgl_gsm',/GSE2GSM

tplot, ['tha_fgl', 'tha_fgl_ssl', 'tha_fgl_dsl', 'tha_fgl_gse','tha_fgl_gsm']

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dprint, "-"
dprint, "- The next example shows how to enable the eclipse spin model corrections"
dprint, "- when loading calibrated L1 FGM data."
dprint, "--> enter .c"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop

; Example showing use of eclipse spin model corrections for FGM data

; THB passed through a lunar shadow during this flyby.  The eclipse
; occurs between approximately 0853 and 0930 UTC.

timespan,'2010-02-13/08:00',4,/hours

; 2012-08-03: By default, the eclipse spin model corrections are not
; applied. For clarity, we'll explicitly set use_eclipse_corrections to 0
; to get a comparison plot, showing how the lack of eclipse spin model
; corrections induces an apparent rotation in the data.

thm_load_fgm,probe='b',level=1,type='calibrated',suffix='_before',use_eclipse_corrections=0

; Here we load the same data, but enable the full set of eclipse spin
; model corrections by setting use_eclipse_corrections to 2.  
;  
; use_eclipse_corrections=1 is not recommended except for SOC processing.
; It omits an important spin phase offset value that is important
; for data types that are despun on board:  particles, moments, and
; spin fits.
;
; Note that calibrated L1 data must be requested in order to use
; the eclipse spin model corrections.  The corrections are not
; yet enabled in the L1->L2 processing.

thm_load_fgm,probe='b',level=1,type='calibrated',suffix='_after',use_eclipse_corrections=2

dprint, " - This plot shows the effect of the eclipse spin model corrections"
dprint, " - on the FGL and FGH data.  The variables with suffix _before "
dprint, " - are uncorrected, while the variables with suffix _after have "
dprint, " - had the corrections enabled.  During the eclipse, between "
dprint, " - approximately 0853 and 0930 UTC, the uncorrected FGM data "
dprint, " - is clearly rotating in the spin plane, due to the spin-up "
dprint, " - that occurs during the eclipse as the probe and booms cool "
dprint, " - and contract. "

tplot,['thb_fgl_before','thb_fgl_after','thb_fgh_before','thb_fgh_after']

print, "--- End of crib sheet ---"

end


