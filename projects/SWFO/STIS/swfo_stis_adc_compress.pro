; $LastChangedBy: davin-mac $
; $LastChangedDate: 2022-04-20 23:26:32 -0700 (Wed, 20 Apr 2022) $
; $LastChangedRevision: 30776 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_adc_compress.pro $

function swfo_stis_adc_compress,data
  return, swfo_stis_log_decomp(data,17,/compress)
end
