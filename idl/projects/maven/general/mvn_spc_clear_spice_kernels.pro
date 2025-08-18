;+
;NAME:
; mvn_spc_clear_spice_kernels
;PURPOSE:
; Clears spice kernels, and unsets the 'kernel verified' flag in the
; mvn_spc_met_to_unixtime so that mvn_spc_met_to_unixtime doesn't crash
;CALLING SEQUENCE:
; mvn_spc_clear_spice_kernels
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-03-16 11:57:01 -0700 (Mon, 16 Mar 2015) $
; $LastChangedRevision: 17140 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_spc_clear_spice_kernels.pro $
;-
Pro mvn_spc_clear_spice_kernels

  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed  , kernel_verified, time_verified, sclk,tls

  cspice_kclear                 ;unload spice kernels
  undefine, kernel_verified

Return
End
