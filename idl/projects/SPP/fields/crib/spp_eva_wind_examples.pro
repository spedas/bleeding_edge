;+
;
; Script for loading Wind data
;
; to be used as dummy variables for SPP EVA burst selection tool development
;
; $LastChangedBy: pulupa $
; $LastChangedDate: 2017-01-13 12:03:00 -0800 (Fri, 13 Jan 2017) $
; $LastChangedRevision: 22595 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/spp_eva_wind_examples.pro $
;
;-

pro spp_eva_wind_examples

  timespan, '1995-06-07', 12

  wi_mfi_load, datatype = 'h2' ; 11 Hz MFI data

  wi_3dp_load, 'pm' ; 3DP

  wi_swe_load, datatype = 'h1' ; SWE moments

end
