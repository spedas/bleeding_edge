;+
; PROCEDURE:
;         mms_spd_pgs_solar_wind
;
; PURPOSE:
;         this script creates multiple figures for solar wind intervals
;         for comparing Mitsuo's binning with bulk velocity subtraction
;         with PGS with bulk velocity subtraction
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-04 11:03:41 -0700 (Fri, 04 May 2018) $
; $LastChangedRevision: 25166 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/validation/mms_spd_pgs_solar_wind.pro $
;-

sw_intervals = [['2017-10-27/20:30', '2017-10-27/20:32'], $
                ['2017-11-18/07:50', '2017-11-18/07:52'], $
                ['2016-12-07/14:40', '2016-12-07/15:15'], $
                ['2016-12-06/11:36', '2016-12-06/11:43'], $
                ['2017-10-10/02:30', '2017-10-10/02:40'], $
                ['2017-12-01/17:00', '2017-12-01/17:05'], $
                ['2017-12-04/10:10', '2017-12-04/10:15']]

probe='4'
output=['pa', 'energy']
species = 'i'
SUBTRACT_BULK = 1
fsuffix = SUBTRACT_BULK eq 1 ? '_bulk' : ''
output_folder = 'bulk_vel_subtraction/'
;energy_range = [900, 1100] ; solar wind ions
energy_range = [0, 25536]
ranges = intarr(1,2)
ranges[0,*] = energy_range
energy_range_str = strcompress(/rem, string(ranges[0,0])+'-'+string(ranges[0,1]))+'_eV'

for sw_i=0, n_elements(sw_intervals[0, *])-1 do begin
  ; mitsuo's calcs
  trange = time_double(sw_intervals[*, sw_i])
  support_trange = trange + [-60,60]
  
  mms_load_fpi,  probe=probe, trange=trange, data_rate='brst', level='l2', datatype='d'+species+'s-'+['dist','moms'], /time_clip
  mms_load_state,probe=probe, trange=support_trange
  mms_load_fgm,  probe=probe, trange=support_trange, data_rate='srvy', level='l2', /time_clip

  ; Generates pitch-angle-distribution data using Mitsuo's binning
  moka_mms_part_products, 'mms'+probe+'_d'+species+'s_dist_brst', mag_name='mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec', out=['pad', 'energy'], vel_name='mms'+probe+'_d'+species+'s_bulkv_dbcs_brst', subtract_bulk=SUBTRACT_BULK
  moka_mms_part_products_pt, 'mms'+probe+'_d'+species+'s_dist_brst_moka_pad', ranges=ranges
  
  ;; PGS below
  mms_part_getspec, trange=sw_intervals[*, sw_i], output=output, species=species, subtract_bulk=SUBTRACT_BULK, energy=energy_range, suffix='_'+energy_range_str+'_'+species, data_rate='brst', probe=probe
  
  ; save the PAD image
  wi, 1
  tplot, window=1, ['mms'+probe+'_moka_pad_'+energy_range_str, 'mms'+probe+'_d'+species+'s_dist_brst_pa_'+energy_range_str+'_'+species]
  makepng, window=1, output_folder+'mms'+probe+'_'+time_string(sw_intervals[0, sw_i], tformat='YYYYMMDD')+'_'+energy_range_str+'_'+species+'_pad_'+fsuffix
  flatten_spectra, time=trange[0]+(trange[1]-trange[0])/2.0, /ylog, /png, filename=output_folder+'mms'+probe+'_'+time_string(trange[0]+(trange[1]-trange[0])/2.0, tformat='YYYYMMDDhhmmss')+'_'+energy_range_str+'_'+species+'_line'+fsuffix
  
  ; save the energy spectra 
  wi, 2
  tplot, window=2, ['', '']
  makepng, window=2, output_folder+'mms'+probe+'_'+time_string(sw_intervals[0, sw_i], tformat='YYYYMMDD')+'_'+energy_range_str+'_'+species+'_spec_'+fsuffix
  del_data, '*'
endfor

stop
end