;+
; PROCEDURE:
;         mms_tplot2autoplot_crib
;
; PURPOSE:
;         Crib sheet showing how to send MMS data to Autoplot
;
; NOTES:
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_tplot2autoplot_crib.pro $
;-

mms_load_fgm, trange=['2015-10-16', '2015-10-17'], probe=1
mms_load_feeps, trange=['2015-10-16', '2015-10-17'], probe=1
mms_load_fpi, trange=['2015-10-16', '2015-10-17'], datatype='dis-moms', probe=1

tplot2ap, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_dis_bulkv_gse_fast', 'mms1_dis_numberdensity_fast', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']
stop

end