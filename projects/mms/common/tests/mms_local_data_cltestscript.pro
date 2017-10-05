;+
;File:
;  mms_local_data_cltestscript
;
;Purpose:
;  A test script to verify the software's ability to find local 
;  files in case the server is not accessible.
;
;Notes:
;  -initial tests copied from mms crib sheets
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:24:15 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19590 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_local_data_cltestscript.pro $
;-


;==================================================
;  Instructions:
;  
;  Run and verify no errors were thrown in console output.
;  
;  Check that remote and local plots are identical.
;    - Each test is run twice: first normally to ensure 
;      that data is loaded, then with no_server set.
;
;==================================================

spd_init_tests

mms_init

window, xs=1100, ys=950

p = 'mms-local-data-test '
tests = ['remote','local']

for i=0, n_elements(tests)-1 do begin

  
  if tests[i] eq 'local' then begin
    !mms.no_server = 1
  endif    

  ;use same test # for both iterations
  t_num = 0
  
  ;-----------------------------------------------------------------------
  
  t_name = 'dsp epsd - '+tests[i]
  
  catch, err
  if err eq 0 then begin
    
    del_data, '*'
    
    mms_load_data, instrument='dsp', trange=['2015-06-22', '2015-06-23'], $
      probes=[1, 2, 3, 4], datatype='epsd', level='l2', data_rate='fast'

    options, 'mms?_dsp_epsd_*', spec=1, zlog=1, ylog=1
    options, 'mms?_dsp_epsd_omni', zrange=[1e-14, 1e-4], yrange=[30, 1e5]

    tplot, 'mms?_dsp_epsd_omni'
    
    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name
    
  endif
  catch, /cancel
  
  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'dsp bpsd - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_data, instrument='dsp', trange=['2015-06-22', '2015-06-23'], $
        probes=[1, 2, 3, 4], datatype='bpsd', level='l2', data_rate='fast'
    
    options, 'mms?_dsp_bpsd_*', spec=1, zlog=1, ylog=1
    options, 'mms?_dsp_bpsd_omni', zrange=[1e-14, 10], yrange=[10, 1e4]
    
    tplot, 'mms?_dsp_bpsd_omni'

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'eis e energy - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_eis, probes='1', trange=['2015-06-22', '2015-06-23'], datatype='electronenergy'

    tplot, ['mms1_epd_eis_electronenergy_electron_omni', $
            'mms1_epd_eis_electron_pad']

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'eis part energy - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_eis, probes='1', trange=['2015-07-08', '2015-07-09'], datatype='partenergy'
    
    options, 'mms1_epd_eis_partenergy_nonparticle_cps_t?', spec=1, ylog=1, zlog=1

    tplot, 'mms1_epd_eis_partenergy_nonparticle_cps_t?'

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'feeps - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_feeps, probes='1', trange=['2015-07-22', '2015-07-23'], datatype='electron'

    top_cpa = ['mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_3', $
      'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_4', $
      'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_5', $
      'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_11', $
      'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_12']

    bottom_cpa = ['mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_3', $
      'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_4', $
      'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_5', $
      'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_11', $
      'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_12']

    options, top_cpa, spec=1, zlog=1, yrange=[1, 10]
    options, bottom_cpa, spec=1, zlog=1, yrange=[1, 10]

    tplot, top_cpa, title='Top sensors'

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'dfg - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_fgm, probes=[1, 2], trange=['2015-06-22', '2015-06-24'], instrument='dfg', level='ql'

    tplot, ['mms1_dfg_srvy_dmpa', 'mms2_dfg_srvy_dmpa']

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'afg - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_fgm, probes=['1', '2'], trange=['2015-06-22', '2015-06-24'], instrument='afg', level='ql'

    tplot, ['mms1_afg_srvy_dmpa', 'mms2_afg_srvy_dmpa']

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'hpca mom - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_hpca, probes='1', trange=['2015-07-22', '2015-07-23'], datatype='moments'

    tplot, ['mms1_hpca_hplus_number_density', $
      'mms1_hpca_oplus_number_density', $
      'mms1_hpca_heplus_number_density']

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'hcpa ion - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_hpca, probes='1', trange=['2015-06-22', '2015-06-23'], datatype='ion', varformat='*_RF_corrected'

    rf_corrected = ['mms1_hpca_hplus_RF_corrected', $
      'mms1_hpca_oplus_RF_corrected', $
      'mms1_hpca_heplus_RF_corrected']

    options, rf_corrected, 'spec', 1
    options, rf_corrected, 'no_interp', 1
    ylim, rf_corrected, 1, 40.,1
    zlim, rf_corrected, .1, 10000.,1

    tplot, rf_corrected

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

  ;-----------------------------------------------------------------------

  t_name = 'scm - '+tests[i]

  catch, err
  if err eq 0 then begin

    del_data, '*'

    mms_load_scm, trange=['2015-06-15', '2015-06-15/4:00'], probes='1', level='l2'

    options, 'mms1_scm_sc128_gse', colors=[2, 4, 6]
    options, 'mms1_scm_sc128_gse', labels=['X', 'Y', 'Z']
    options, 'mms1_scm_sc128_gse', labflag=-1

    tplot, 'mms1_scm_sc128_gse'

    makepng, p + ' '+strtrim(t_num,2)+' ' + t_name

  endif
  catch, /cancel

  spd_handle_error, err, t_name, t_num++

endfor

mms_init, /reset

spd_end_tests


end