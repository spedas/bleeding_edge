;+
;NAME:
; mvn_lpw_anc_clear_spice_kernels
;PURPOSE:
; Clears spice kernels, and unsets the 'kernel verified' flag in the
; mvn_spc_met_to_unixtime so that mvn_spc_met_to_unixtime doesn't crash
;CALLING SEQUENCE:
; mvn_lpw_anc_clear_spice_kernels
; $LastChangedBy: cfowler2 $
; $LastChangedDate: 2016-07-26 07:47:14 -0700 (Tue, 26 Jul 2016) $
; $LastChangedRevision: 21525 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/lpw/mvn_lpw_anc_clear_spice_kernels.pro $
;-
Pro mvn_lpw_anc_clear_spice_kernels

  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed  , kernel_verified, time_verified, sclk,tls

  cspice_kclear                 ;unload spice kernels
  undefine, kernel_verified

Return
End
