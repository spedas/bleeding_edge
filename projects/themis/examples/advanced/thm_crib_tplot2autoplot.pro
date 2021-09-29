;+
; PROCEDURE:
;         thm_crib_tplot2autoplot
;
; PURPOSE:
;         Crib sheet showing how to send THEMIS data to Autoplot
;
; NOTES:
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-14 07:45:30 -0700 (Mon, 14 May 2018) $
; $LastChangedRevision: 25217 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_tplot2autoplot.pro $
;-

; load some data to send to Autoplot
kyoto_load_ae, trange=['2015-12-15', '2015-12-16']
thm_load_fgm, trange=['2015-12-15', '2015-12-16'], probe='d', level='l2'
thm_load_esa, trange=['2015-12-15', '2015-12-17'], probe='d', level='l2'

tplot2ap, ['kyoto_ae', 'thd_fgs_btotal', 'thd_fgs_dsl', 'thd_peif_avgtemp', 'thd_peif_en_eflux']
stop

end