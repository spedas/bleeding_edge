;+
; flatten_spectra crib sheet
;
; This crib sheet shows how to create spectra plots (flux vs. energy) at certain times using flatten_spectra
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-07-22 11:40:10 -0700 (Wed, 22 Jul 2020) $
; $LastChangedRevision: 28919 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_flatten_spectra_crib.pro $
;-

mms_load_fpi, probe=1, data_rate='brst', datatype=['des-moms'], trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip

; plot one or more spectra variables
tplot, ['mms1_des_energyspectr_omni_brst', $
        'mms1_des_energyspectr_par_brst', $
        'mms1_des_energyspectr_anti_brst', $
        'mms1_des_energyspectr_perp_brst']

; select the time on the time varying energy spectra figure 
flatten_spectra, /xlog, /ylog
stop

; specify the time via keyword instead of the mouse
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07'
stop

; use the samples keyword to average over a number of samples
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07', samples=10
stop

; use the trange keyword to average over a time range
flatten_spectra, /xlog, /ylog, trange=['2015-10-16/13:06:50', '2015-10-16/13:07']
stop

; change the variable names in the legend
options, 'mms1_des_energyspectr_omni_brst', 'legend_name', 'MMS1 DES OMNI'
options, 'mms1_des_energyspectr_par_brst', 'legend_name', 'MMS1 DES PARALLEL'
options, 'mms1_des_energyspectr_anti_brst', 'legend_name', 'MMS1 DES ANTI-PARALLEL'
options, 'mms1_des_energyspectr_perp_brst', 'legend_name', 'MMS1 DES PERP'
flatten_spectra, /xlog, /ylog, /replot
stop

; save the figure as a PNG file
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07', filename='spectra', /png
stop

; save the figure as a postscript file
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07', filename='spectra', /postscript
stop

; Convert the x-axis to keV before plotting
; note: FEEPS data are already in keV, FPI data are in eV; the to_kev keyword uses 
; the units in the ysubtitle to determine which to convert; the y-axis units are still different.
mms_load_feeps, data_rate='brst', trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip, probe=1

tplot, ['mms1_des_energyspectr_omni_brst', $
        'mms1_epd_feeps_brst_l2_electron_intensity_omni']

flatten_spectra, /to_kev, /xlog, /ylog, time='2015-10-16/13:07'
stop

; Convert the y-axis to flux [1/(cm^2 s sr keV)] before plotting
mms_load_fpi, probe=1, data_rate='brst', datatype=['dis-moms'], trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip
mms_load_eis, datatype=['extof', 'phxtof'], data_rate='brst', trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip, probe=1
mms_load_hpca, data_rate='brst', trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip, probe=1, datatype='ion', /major
mms_hpca_calc_anodes, fov=[0, 360]
mms_hpca_spin_sum, probe=1, /avg

tplot, ['mms1_dis_energyspectr_omni_brst', $
  'mms1_hpca_hplus_flux_elev_0-360_spin', $
  'mms1_epd_eis_brst_phxtof_proton_flux_omni', $
  'mms1_epd_eis_brst_extof_proton_flux_omni']

flatten_spectra, /to_flux, /to_kev, /xlog, /ylog, time='2015-10-16/13:07', filename='spectra', /png
stop

; to create line plots for multiple times instead of multiple plots, use flatten_spectra_multi, e.g.,
tplot, 'mms1_dis_energyspectr_omni_brst'

flatten_spectra_multi, 3, /to_flux, /to_kev, /xlog, /ylog
stop

; the colors, line thickness and linestyle can be set individually for each plot, e.g.,
flatten_spectra_multi, 3, /to_flux, /to_kev, /xlog, /ylog, colors=[0, 4, 6], thick=[1, 3, 6], linestyle=[1, 2, 3]
stop

; save the output to a postscript file:
flatten_spectra_multi, 3, filename='spectra_multi', /postscript, /to_flux, /to_kev, /xlog, /ylog
stop

end