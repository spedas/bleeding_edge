;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2017-04-18 14:28:02 -0700 (Tue, 18 Apr 2017) $
;  $LastChangedRevision: 23182 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dcb_analog_hk/spp_fld_dcb_analog_hk_convert.pro $

function spp_fld_dcb_hk_temp_convert, counts

  dcb_hk_temp_coeff = [1.68D+02, -4.31D-01, 6.62D-04, -5.42D-07, 2.12D-10, -3.18D-14]

  dcb_hk_temp = poly(counts, dcb_hk_temp_coeff)

  return, dcb_hk_temp

end

function spp_fld_lnps_scm_temp_convert, counts

  lnps_scm_temp_coeff = [155.640, -0.071870, -1.34E-04, 2.47E-07, -1.65E-10, 4.96E-14, -5.64E-18]

  lnps_scm_temp = poly(counts, lnps_scm_temp_coeff)

  return, lnps_scm_temp

end

function spp_fld_dcb_znr_v_convert, counts

  znr_v_conv_factor = 0.002930 * counts
  
  return, counts * znr_v_conv_factor

end

function spp_fld_lnps1_p100v_convert, counts

  lnps1_p100v_conv_factor = 0.045420

  return, counts * lnps1_p100v_conv_factor

end

function spp_fld_lnps1_n100v_convert, counts

  lnps1_n100v_conv_factor = -0.044390

  return, counts * lnps1_n100v_conv_factor

end

function spp_fld_lnps1_n12v_convert, counts

  lnps1_n12v_conv_factor = -0.004443

  return, counts * lnps1_n12v_conv_factor

end

function spp_fld_lnps1_p12v_convert, counts

  lnps1_p12v_conv_factor = 0.004717
  
  return, counts * lnps1_p12v_conv_factor

end

function spp_fld_lnps1_n6v_convert, counts

  lnps1_n6v_conv_factor = -0.002147

  return, counts * lnps1_n6v_conv_factor

end


function spp_fld_lnps1_p6v_convert, counts

  lnps1_p6v_conv_factor = 0.003120

  return, counts * lnps1_p6v_conv_factor

end


function spp_fld_dcb_15vd_convert, counts

  spp_fld_dcb_15vd_conv_factor = 0.000977

  return, counts * spp_fld_dcb_15vd_conv_factor

end

function spp_fld_dcb_25v_convert, counts

  spp_fld_dcb_25v_conv_factor = 0.000977

  return, counts * spp_fld_dcb_25v_conv_factor

end


function spp_fld_lnps1_18v_convert, counts

  lnps1_18v_conv_factor = 0.000977
  
  return, counts * lnps1_18v_conv_factor

end

function spp_fld_dcb_hk_gnd_convert, counts

  dcb_hk_gnd_conv_factor = 0.000977

  return, counts * dcb_hk_gnd_conv_factor

end

function spp_fld_lnps1_33v_convert, counts

  lnps1_33v_conv_factor = 0.001440

  return, counts * lnps1_33v_conv_factor

end

function spp_fld_lnps1_4v_5v_convert, counts

  lnps1_4v_5v_conv_factor = 0.001953

  return, counts * lnps1_4v_5v_conv_factor

end

function spp_fld_dcb_flashv_convert, counts

  flashv_factor = 0.001953

  return, counts * flashv_factor

end


pro spp_fld_dcb_analog_hk_convert, data, times, cdf_att 

  ; Make sure these routines are compiled

  dummy = spp_fld_dcb_hk_temp_convert(0.)
  dummy = spp_fld_dcb_znr_v_convert(0.)
  dummy = spp_fld_lnps_scm_temp_convert(0.)
  dummy = spp_fld_lnps1_p100v_convert(0.)
  dummy = spp_fld_lnps1_n100v_convert(0.)
  dummy = spp_fld_lnps1_n12v_convert(0.)
  dummy = spp_fld_lnps1_p12v_convert(0.)
  dummy = spp_fld_lnps1_n6v_convert(0.)
  dummy = spp_fld_lnps1_p6v_convert(0.)
  dummy = spp_fld_lnps1_18v_convert(0.)
  dummy = spp_fld_lnps1_33v_convert(0.)
  dummy = spp_fld_lnps1_4v_5v_convert(0.)
  dummy = spp_fld_dcb_15vd_convert(0.)
  dummy = spp_fld_dcb_25v_convert(0.)
  dummy = spp_fld_dcb_hk_gnd_convert(0.)
  dummy = spp_fld_dcb_flashv_convert(0.)

end