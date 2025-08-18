;+
;
; This script shows how to create a plot of FPI density with error bars
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_error_bars_crib.pro $
;-
mms_load_fpi, probe=3, trange=['2015-10-16', '2015-10-17'], datatype='des-moms'

;get the data and errors
get_data, 'mms3_des_numberdensity_err_fast', data=errors
get_data, 'mms3_des_numberdensity_fast', data=data

; store the data/errors in a new tplot variable
new_data = {x: data.x, y: data.Y, dy: errors.Y*data.Y}
store_data, 'mms3_des_numberdensity_fast_with_errs', data=new_data

; set the ylimits to reduce whitespace on the plot (so the error bars are clearly visible in this example)
ylim, 'mms3_des_numberdensity_fast_with_errs', 8, 12, 0

tplot, 'mms3_des_numberdensity_fast_with_errs'
tlimit, '2015-10-16/13:06', '2015-10-16/13:06:50'

end
