;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2019-08-01 13:39:30 -0700 (Thu, 01 Aug 2019) $
;  $LastChangedRevision: 27530 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_get_bp_bins_04_ac.pro $
;

function SPP_Get_BP_bins_04_AC

  top_sample_rate = 150d3

  freq_hi = top_sample_rate / 2d / (2LL^(indgen(7))); * 0.8d ;; 80% to account for filter roll-off
  freq_lo = top_sample_rate / 4d / (2LL^(indgen(7))); * 0.8d

  freq_avg = (freq_hi + freq_lo) / 2d

  return_struct = {freq_lo:freq_lo, $
    freq_hi:freq_hi, $
    freq_avg:freq_avg}


  return, return_struct


  ;;THE
END
