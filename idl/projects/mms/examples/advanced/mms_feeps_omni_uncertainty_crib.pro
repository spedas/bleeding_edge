;
;
; This crib demonstrates use of l1b and L2 data to compute and plot percentage uncertainty for FEEPS omnidirectional electron data.
; 
;
;
; Load l1b data needed to compute relative errors in omnidirectional electron data.  (Team-only at present)
; 

mms_load_feeps, trange=['2020-08-03/01:05:00', '2020-08-03/01:08:00'], probes = '2', level = 'l1b', data_rate = 'brst', datatype = 'electron', data_units = 'counts';,quality_flag=3.;3.

; Load FEEPS L2 electron data, with the get_err switch specified

mms_load_feeps, trange=['2020-08-03/01:05:00', '2020-08-03/01:08:00'], probes = '2', level = 'l2', data_rate = 'brst', datatype = 'electron', data_units = 'intensity',get_err=1;,quality_flag=3.;3.

; Plot the FEEPS omnidirectional electron intensity, and the percent uncertainty

tplot,['mms2_epd_feeps_brst_l2_electron_intensity_omni', 'mms2_epd_feeps_brst_l2_electron_intensity_omni_percent_uncertainty']

end