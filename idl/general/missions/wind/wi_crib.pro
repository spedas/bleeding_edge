;+
;
; General Autodownload Crib
;
; Written by: Davin Larson
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2011-02-02 14:43:12 -0800 (Wed, 02 Feb 2011) $
;$LastChangedRevision: 8087 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wi_crib.pro $
;-

; These routines will automatically download data from a remote server and
; Cache them in a local directory. The default local directory can be
; changed by setting an environment variable:  'ROOT_DATA_DIR'
; see the IDL procedure root_data_dir.pro for more info.


;if you don't set the timespan like this
;the routine will prompt you
; timespan,'2007-03-23'

; Loading WIND MFI data:
;Key parameter data:
wi_mfi_load,datatype='k0'
;h0 data (much better time resolution but usually a few weeks delayed)
wi_mfi_load,datatype='h0'



;Loading WIND 3DP data:
;Key parameter data:    (please note that the 3DP densities are too low)
wi_3dp_load,datatype='k0'
;spin resolution ion data:    (please note that the 3DP densities are too low)
wi_3dp_load,datatype='pm'
;electron pitch angle distributions
wi_3dp_load,datatype='elpd_old'


;Loading WIND SWE ion data:
;Key parameter data:  (only ions)
wi_swe_load,datatype='k0'
wi_swe_load,datatype='h0'   ; 1994-2001 only


;Loading ACE data:
ace_mfi_load,datatype='k0'    ; Low res data
ace_mfi_load,datatype='h0'    ; High res data


;GOES satellites:
goes_ep_load,probe='11',datatype='k0'    ;GOES 11 key parameter data
goes_mag_load ,datatype='k0'             ; Load GOES 11 and 12 mag data


; LANL sats
lanl_spa_load       ; Energetic particles
lanl_mpa_load       ; Plasma


; OMNI data:
omni_hro_load


; Kyoto DST 1 hour averages
kyoto_load_dst



end
