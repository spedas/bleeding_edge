;+
; MMS EPD-EIS quick look plots crib sheet
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-17 09:28:43 -0700 (Thu, 17 Aug 2023) $
; $LastChangedRevision: 32010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/quicklook/mms_load_feeps-eis_crib_qlplots.pro $
;-

probe = '1'
date = '2015-10-16'
timespan, date
iw = 0
;width = 850
;height = 1200
eis_prefix = 'mms'+probe+'_epd_eis'
feeps_prefix = 'mms'+probe+'_epd_feeps'

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows
send_plots_to = 'win'
plot_directory = 'feeps-eis/'+time_string(date, tformat='YYYY/MM/DD/')

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

; load FEEPS data
mms_load_feeps, probes=probe, level='l1b', datatype='electron', data_rate='srvy'

tdeflag, tnames('*_intensity_*'), 'repeat', /overwrite
tdeflag, tnames('*_count_rate_*'), 'repeat', /overwrite
tdeflag, tnames('*_counts_*'), 'repeat', /overwrite

; load EIS extof, phxtof, and electron data:
mms_load_eis, probes=probe, datatype='extof', level='l1b', data_rate='srvy'
mms_load_eis, probes=probe, datatype='phxtof', level='l1b', data_rate='srvy'
mms_load_eis, probes=probe, datatype='electronenergy', level='l1b', data_rate='srvy'

; setup for plotting the proton flux for all channels
;ylim, feeps_prefix+'_electronenergy_electron_flux_omni_spin', 30, 1000, 1
;zlim, feeps_prefix+'_electronenergy_electron_flux_omni_spin', 0, 0, 1
ylim, feeps_prefix+'_electron_intensity_omni_spin', 71, 600, 1 ; don't include the bottom channel
ylim, eis_prefix+'_electronenergy_electron_flux_omni_spin', 30, 1000, 1
zlim, eis_prefix+'_electronenergy_electron_flux_omni_spin', 0, 0, 1
ylim, eis_prefix+'_extof_proton_flux_omni_spin', 50, 500, 1
zlim, eis_prefix+'_extof_proton_flux_omni_spin', 0, 0, 1
ylim, eis_prefix+'_extof_oxygen_flux_omni_spin', 150, 1000, 1
zlim, eis_prefix+'_extof_oxygen_flux_omni_spin', 0, 0, 1
ylim, eis_prefix+'_extof_alpha_flux_omni_spin', 80, 800, 1
zlim, eis_prefix+'_extof_alpha_flux_omni_spin', 0, 0, 1
ylim, eis_prefix+'_phxtof_proton_flux_omni_spin', 10, 50, 1
zlim, eis_prefix+'_phxtof_proton_flux_omni_spin', 0, 0, 1
;ylim, eis_prefix+'_phxtof_oxygen_flux_omni_spin', 10, 50, 1
;zlim, eis_prefix+'_phxtof_oxygen_flux_omni_spin', 0, 0, 1

; force the min/max of the Y axes to the limits
options, '*_flux_omni*', ystyle=1

; get ephemeris data for x-axis annotation
mms_load_state, probes=probe, /ephemeris

eph_gsm = 'mms'+probe+'_mec_r_gse'

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; calculate R to spacecraft
calc, '"mms'+probe+'_defeph_R_gsm" = sqrt("'+eph_gsm+'_re_x'+'"^2+"'+eph_gsm+'_re_y'+'"^2+"'+eph_gsm+'_re_z'+'"^2)'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_x',ytitle='X (Re, GSE)'
options, eph_gsm+'_re_y',ytitle='Y (Re, GSE)'
options, eph_gsm+'_re_z',ytitle='Z (Re, GSE)'
options, 'mms'+probe+'_defeph_R_gsm',ytitle='R (Re)'
position_vars = ['mms'+probe+'_defeph_R_gsm', eph_gsm+'_re_z', eph_gsm+'_re_y', eph_gsm+'_re_x']

;tplot_options, 'ymargin', [5, 5]
tplot_options, 'xmargin', [15, 15]

spd_mms_load_bss, datatype=['fast','burst'], /include_labels

panels = [feeps_prefix+'_srvy_l1b_electron_intensity_omni_spin', $
  eis_prefix+'_electronenergy_electron_flux_omni_spin', $
  ; fast ion survey
  eis_prefix+'_extof_proton_flux_omni_spin', $
  eis_prefix+'_extof_alpha_flux_omni_spin', $
  eis_prefix+'_extof_oxygen_flux_omni_spin', $
  eis_prefix+'_phxtof_proton_flux_omni_spin']

if ~postscript then window, iw;, xsize=width, ysize=height
mms_tplot_quicklook, panels, var_label=position_vars, window=iw, title='EPD FEEPS-EIS - Quicklook', $
  burst_bar = 'mms_bss_burst', fast_bar = 'mms_bss_fast'

if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms'+probe + '_feeps-eis_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif

if postscript then tprint, plot_directory + prefix + "_quicklook_plots"

end