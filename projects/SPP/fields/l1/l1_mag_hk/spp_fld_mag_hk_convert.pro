;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-20 17:10:16 -0700 (Thu, 20 Apr 2017) $
;  $LastChangedRevision: 23205 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mag_hk_convert.pro $
;

function spp_fld_mag_hk_test_convert, counts

  return, 0.03125 * counts

end

function spp_fld_mag_hk_htrvmon_convert, counts

  volt_coeff = [2.17460317460317, 0.00174603174603175]

  volts = poly(counts, volt_coeff)
  
  return, volts

end

function spp_fld_mag_hk_htrcurr_convert, counts

  current_coeff = [9.806824542725,0.00842726019093892]

  current = poly(counts, current_coeff)

  return, current

end

function spp_fld_mag_hk_p12curr_convert, counts

  current_coeff = [0.846103745357006,0.101499948411061]

  current = poly(counts, current_coeff)

  return, current

end

function spp_fld_mag_hk_m12curr_convert, counts

  current_coeff = [0.00188654943288924,0.101373620129255]

  current = poly(counts, current_coeff)

  return, current

end

function spp_fld_mag_hk_p12vmon_convert, counts

  return, counts * 0.000512402368895374

end

function spp_fld_mag_hk_m12vmon_convert, counts

  return, counts * 0.00051104854534596

end

function spp_fld_mag_hk_p10vref_convert, counts

  return, counts * 0.000382342979716253

end

function spp_fld_mag_hk_p25dmon_convert, counts

  return, counts * 0.000253360149121946

end

function spp_fld_mag_hk_p33dmon_convert, counts

  return, counts * 0.000253230357938512

end

function spp_fld_mag_hk_p5vmon_convert, counts

  return, counts * 0.000253196040391981

end

function spp_fld_mag_hk_m5vmon_convert, counts

  return, counts * 0.000253077301821763

end

function spp_fld_mag_hk_snsrtmp_convert, counts

  temp_coeff = [8.146357214, 0.001459481, 6.877183e-9, -1.005099e-12,-5.851287e-19, 1.806212e-21]

  temp = poly(counts, temp_coeff)
  
  return, temp

end

function spp_fld_mag_hk_pcbtmp_convert, counts

  return, spp_fld_mag_hk_snsrtmp_convert(counts)

end

pro spp_fld_mag_hk_convert, data, times, cdf_att

  dummy = spp_fld_mag_hk_test_convert(0.)
  dummy = spp_fld_mag_hk_htrvmon_convert(0.)
  dummy = spp_fld_mag_hk_htrcurr_convert(0.)
  dummy = spp_fld_mag_hk_p12curr_convert(0.)
  dummy = spp_fld_mag_hk_m12curr_convert(0.)
  dummy = spp_fld_mag_hk_p12vmon_convert(0.)
  dummy = spp_fld_mag_hk_m12vmon_convert(0.)
  dummy = spp_fld_mag_hk_p10vref_convert(0.)
  dummy = spp_fld_mag_hk_p25dmon_convert(0.)
  dummy = spp_fld_mag_hk_p33dmon_convert(0.)
  dummy = spp_fld_mag_hk_p5vmon_convert(0.)
  dummy = spp_fld_mag_hk_m5vmon_convert(0.)
  dummy = spp_fld_mag_hk_snsrtmp_convert(0.)
  dummy = spp_fld_mag_hk_pcbtmp_convert(0.)

end