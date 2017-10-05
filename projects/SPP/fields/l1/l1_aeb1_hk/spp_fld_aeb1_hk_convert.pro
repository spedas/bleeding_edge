;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-18 16:04:07 -0700 (Tue, 18 Apr 2017) $
;  $LastChangedRevision: 23186 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb1_hk/spp_fld_aeb1_hk_convert.pro $
;

function spp_fld_aeb1_hk_voltage_readback_convert, counts

  return, 0.02604 * counts - 40.

end

function spp_fld_aeb1_hk_dac_convert, counts

  return, 0.01953 * counts - 40.

end

function spp_fld_aeb1_pa_temp_convert, counts

  pa_temp_coeff = [-2.44e+02, 4.329e-01, 1.823e-04]

  pa_temp = poly(counts, pa_temp_coeff)

  return, pa_temp

end

function spp_fld_aeb1_temp_convert, counts

  temp_coeff = [8.58e+01, -2.199e-01, 2.594e-04, -1.692e-07, 5.830e-11, -1.003e-14, 6.765e-19]

  temp = poly(counts, temp_coeff)
  
  return, temp

end

function spp_fld_aeb1_i_convert, counts

  return, 0.09644 * counts

end


pro spp_fld_aeb1_hk_convert, data, times, cdf_att

  ; Make sure these routines are compiled
  
  dummy = spp_fld_aeb1_hk_voltage_readback_convert(0.)
  dummy = spp_fld_aeb1_hk_dac_convert(0.)
  dummy = spp_fld_aeb1_pa_temp_convert(0.)
  dummy = spp_fld_aeb1_temp_convert(0.)
  dummy = spp_fld_aeb1_i_convert(0.)

end