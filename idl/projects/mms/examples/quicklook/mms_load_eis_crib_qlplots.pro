;+
; MMS EIS quick look plots crib sheet
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-17 09:28:43 -0700 (Thu, 17 Aug 2023) $
; $LastChangedRevision: 32010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/quicklook/mms_load_eis_crib_qlplots.pro $
;-

probe = '1'
;trange = ['2015-08-15', '2015-08-16']
;timespan, '2015-08-15', 1
date = '2015-10-16'
timespan, date, 1
iw = 0
width = 850
height = 1000
prefix = 'mms'+probe+'_epd_eis'

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = 'epd_eis/'+time_string(date, tformat='YYYY/MM/DD/')

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

; load ExTOF and electron data:
mms_load_eis, probes=probe, trange=trange, datatype=['extof', 'phxtof'], level='l1b'
mms_load_eis, probes=probe, trange=trange, datatype='electronenergy', level='l1b'

; load DFG data
mms_load_fgm, instrument='dfg', probes=probe, trange=trange, level='ql'

; setup for plotting the proton flux for all channels
ylim, prefix+'_electronenergy_electron_flux_omni_spin', 30, 1000, 1
zlim, prefix+'_electronenergy_electron_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_proton_flux_omni_spin', 50, 500, 1
zlim, prefix+'_extof_proton_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_oxygen_flux_omni_spin', 150, 1000, 1
zlim, prefix+'_extof_oxygen_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_alpha_flux_omni_spin', 80, 800, 1
zlim, prefix+'_extof_alpha_flux_omni_spin', 0, 0, 1

; force the min/max of the Y axes to the limits
options, '*_flux_omni*', ystyle=1

; get ephemeris data for x-axis annotation
;mms_load_state, probes=probe, trange=trange, /ephemeris
;eph_j2000 = 'mms'+probe+'_defeph_pos'
;eph_gei = 'mms'+probe+'defeph_pos_gei'
;eph_gse = 'mms'+probe+'_defeph_pos_gse'
eph_gsm = 'mms'+probe+'_ql_pos_gse'

; calculate MLT
tgsm2mlt, eph_gsm, 'mms'+probe+'_ql_pos_mlt'

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; calculate R to spacecraft
;calc, '"mms'+probe+'_defeph_R_gsm" = sqrt("'+eph_gsm+'_re_x'+'"^2+"'+eph_gsm+'_re_y'+'"^2+"'+eph_gsm+'_re_z'+'"^2)'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_0',ytitle='X (Re, GSE)'
options, eph_gsm+'_re_1',ytitle='Y (Re, GSE)'
options, eph_gsm+'_re_2',ytitle='Z (Re, GSE)'
options, eph_gsm+'_re_3',ytitle='R (Re)'
options, 'mms'+probe+'_ql_pos_mlt', ytitle='MLT'
position_vars = ['mms'+probe+'_ql_pos_mlt', eph_gsm+'_re_3', eph_gsm+'_re_2', eph_gsm+'_re_1', eph_gsm+'_re_0']

tplot_options, 'ymargin', [5, 5]
tplot_options, 'xmargin', [15, 15]

; clip the DFG data to -150nT to 150nT
tclip, 'mms'+probe+'_dfg_srvy_dmpa', -150., 150., /overwrite
options, 'mms'+probe+'_dfg_srvy_dmpa', ytitle='MMS'+probe+'!CFGM!CQL'
options, 'mms'+probe+'_dfg_srvy_dmpa', labflag=-1
options, 'mms'+probe+'_dfg_srvy_dmpa', labels=['Bx DMPA', 'By DMPA', 'Bz DMPA', 'Btot']

spd_mms_load_bss, trange=trange, /include_labels 

panels = ['mms'+probe+'_dfg_srvy_dmpa', $
 ; prefix+'_electronenergy_electron_flux_omni_spin', $
  prefix+'_extof_proton_flux_omni_spin', $
  prefix+'_phxtof_proton_flux_omni_spin', $
  prefix+'_extof_alpha_flux_omni_spin', $
  prefix+'_extof_oxygen_flux_omni_spin']
 
if ~postscript then window, iw, xsize=width, ysize=height
;tplot, panels, var_label=position_vars, window=iw
mms_tplot_quicklook, panels, trange=trange, var_label=position_vars, title='EIS - Quicklook', $
  burst_bar='mms_bss_burst', fast_bar='mms_bss_fast', window=iw
timebar, 0.0, /databar, varname='mms'+probe+'_dfg_srvy_dmpa', linestyle=2

if postscript then tprint, plot_directory + prefix + "_quicklook_plots"

if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms'+probe + '_epd_eis_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif

end