;+
;Name:
;  thm_crib_superpo_interpol_histo
;
;Purpose:
;  Demonstrates the application of the routines
;  superpo_interpol and superpo_histo
;
;Notes:
;  The examples in this crib sheet call 'superpo_interpol'. Simply
;  replace the calls with 'superpo_histo' to try the other routine.
;  Both routines accept the same input parameters.
;
;History:
;  Written by Andreas Keiling
;  2015-05-14 (af) load only THEMIS GBO sites instead of all (there are a lot now)
;   
;
;$LastChangedBy:   $
;$LastChangedDate:   $
;$LastChangedRevision:  $
;$URL $
;-

;=========================================================
; Example 1
;=========================================================

del_data,'*'
thm_init
timespan,'2007-03-23/00:00:00'      ; one whole day by default

thm_load_gmag,site='ccnv'
thm_load_gmag,site='drby'
thm_load_gmag,site='fsim'
thm_load_gmag,site='fsmi'
thm_load_gmag,site='fykn'

split_vec,'thg_mag_ccnv'
split_vec,'thg_mag_drby'
split_vec,'thg_mag_fsim'
split_vec,'thg_mag_fsmi'
split_vec,'thg_mag_fykn'

superpo_interpol,'thg_mag_ccnv_x thg_mag_drby_x thg_mag_fsim_x thg_mag_fsmi_x thg_mag_fykn_x', $
        min='thg_pseudoAL', $
        max='thg_pseudoAU', $
        dif='thg_pseudoAE', $
		avg='thg_avg', $
        med='thg_median', $
        res=30.0

;superpo_histo,'thg_mag_ccnv_x thg_mag_drby_x thg_mag_fsim_x thg_mag_fsmi_x thg_mag_fykn_x', $
;        min='thg_pseudoAL', $
;        max='thg_pseudoAU', $
;        dif='thg_pseudoAE', $
;	 	 avg='thg_avg', $
;        med='thg_median', $
;        res=30.0

options,'*_x thg_pseudoAU thg_pseudoAL thg_pseudoAE thg_avg thg_median', /ynozero
tplot,'*_x thg_pseudoAU thg_pseudoAL thg_pseudoAE thg_avg thg_median'

stop


;=========================================================
; Example 2
;=========================================================

del_data,'*'
thm_init
timespan,'2006-12-23/00:00:00'   ; one whole day by default

thm_load_gmag, /thm_sites, /subtract_median    ; load all stations and subtract median from each station
split_vec,'thg_mag_????'

superpo_interpol,'thg_mag_????_x',min='thg_pseudoAL', res=600.0  ; use all available stations
;superpo_histo,'thg_mag_????_x',min='thg_pseudoAL', res=600.0  ; use all available stations

tplot,'*pseudo*'

stop


;=========================================================
; Example 3
;=========================================================

del_data,'*'
thm_init
timespan,'2006-12-23/00:00:00',18,/hour

thm_load_gmag, /thm_sites, /subtract_median    ; load all stations and subtract median from each station
split_vec,'thg_mag_????'

superpo_interpol,'thg_mag_????_x', res=1.0   ; does default values for all keywords except res
;superpo_histo,'thg_mag_????_x', res=1.0   ; does default values for all keywords except res

tplot,'*arr*'

stop


;=========================================================
; Example 4
;=========================================================

del_data,'*'
thm_init
timespan,'2006-12-23/00:00:00',18,/hour

thm_load_gmag, /thm_sites    ; load all stations
split_vec,'thg_mag_????'

superpo_interpol,'thg_mag_????_x'    ; does default values for all keywords
;superpo_histo,'thg_mag_????_x'    ; does default values for all keywords

options,'thg_mag_????_x *arr*', /ynozero
tplot,'thg_mag_????_x *arr*'



end
