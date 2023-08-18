;+
; MMS FIELDS quicklook plots crib sheet
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-17 09:28:43 -0700 (Thu, 17 Aug 2023) $
; $LastChangedRevision: 32010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/quicklook/mms_fields_crib_qlplots.pro $
;-


; initialize and define parameters
probes = ['1', '2', '3', '4']
;trange = ['2015-09-05', '2015-09-06']
date = '2015-10-16'
timespan, date, 1, /day
iw = 0
;width = 750
;height = 1000

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = 'fields/'+time_string(date, tformat='YYYY/MM/DD/')

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

;
; START OF FIELDS PLOTS - ALL SPACECRAFT 
;  
; load mms survey Fields data
mms_load_fgm, instrument='dfg', probes=probes, level='ql', data_rate='srvy'

; DMPA - Handle Btot and Bvec 

; Btot - set title and colors and create pseudo variable
options, 'mms1*_btot', colors=[0], labels='MMS1'    ; black
options, 'mms2*_btot', colors=[6], labels='MMS2'    ; red
options, 'mms3*_btot', colors=[4], labels='MMS3'    ; green
options, 'mms4*_btot', colors=[2], labels='MMS4'    ; blue
store_data, 'mms_dfg_srvy_dmpa_btot', data = ['mms1_dfg_srvy_dmpa_btot', $
                                       'mms2_dfg_srvy_dmpa_btot', $
                                       'mms3_dfg_srvy_dmpa_btot', $
                                       'mms4_dfg_srvy_dmpa_btot']
options, 'mms_*_btot',ytitle='FGM Btot', labflag=1
options, 'mms_*_btot',ysubtitle='QL [nT]'

; Bvec - set colors, pseudo variables and titles
options, 'mms1*_bvec', colors=[0], labels='MMS1'    ; black
options, 'mms2*_bvec', colors=[6], labels='MMS2'    ; red
options, 'mms3*_bvec', colors=[4], labels='MMS3'    ; green
options, 'mms4*_bvec', colors=[2], labels='MMS4'    ; blue
; split into components x, y, z for plotting
split_vec, 'mms*_bvec'
; create pseudo variables for each component x, y, and z
store_data, 'mms_dfg_srvy_dmpa_bvec_x', data = ['mms1_dfg_srvy_dmpa_bvec_x', $
  'mms2_dfg_srvy_dmpa_bvec_x', $
  'mms3_dfg_srvy_dmpa_bvec_x', $
  'mms4_dfg_srvy_dmpa_bvec_x']
store_data, 'mms_dfg_srvy_dmpa_bvec_y', data = ['mms1_dfg_srvy_dmpa_bvec_y', $
    'mms2_dfg_srvy_dmpa_bvec_y', $
    'mms3_dfg_srvy_dmpa_bvec_y', $
    'mms4_dfg_srvy_dmpa_bvec_y']
store_data, 'mms_dfg_srvy_dmpa_bvec_z', data = ['mms1_dfg_srvy_dmpa_bvec_z', $
    'mms2_dfg_srvy_dmpa_bvec_z', $
    'mms3_dfg_srvy_dmpa_bvec_z', $
    'mms4_dfg_srvy_dmpa_bvec_z']
; set titles
options, 'mms_*_bvec_x', ytitle='FGM Bx'
options, 'mms_*_bvec_y', ytitle='FGM By'
options, 'mms_*_bvec_z', ytitle='FGM Bz'
options, 'mms_*_bvec_*', ysubtitle='DMPA [nT]', labflag=1

; GSM-DMPA - do the same for gsm_dmpa data, note gsm_dmpa data is not separated into btot and bvec
options, 'mms1*_gsm_dmpa', colors=[0], labels='MMS1'    ; black
options, 'mms2*_gsm_dmpa', colors=[6], labels='MMS2'    ; red
options, 'mms3*_gsm_dmpa', colors=[4], labels='MMS3'    ; green
options, 'mms4*_gsm_dmpa', colors=[2], labels='MMS4'    ; blue
split_vec, 'mms*_dfg_srvy_gsm_dmpa'
store_data, 'mms_dfg_srvy_gsm_dmpa_x', data = ['mms1_dfg_srvy_gsm_dmpa_0', $
  'mms2_dfg_srvy_gsm_dmpa_0', $
  'mms3_dfg_srvy_gsm_dmpa_0', $
  'mms4_dfg_srvy_gsm_dmpa_0']
store_data, 'mms_dfg_srvy_gsm_dmpa_y', data = ['mms1_dfg_srvy_gsm_dmpa_1', $
  'mms2_dfg_srvy_gsm_dmpa_1', $
  'mms3_dfg_srvy_gsm_dmpa_1', $
  'mms4_dfg_srvy_gsm_dmpa_1']
store_data, 'mms_dfg_srvy_gsm_dmpa_z', data = ['mms1_dfg_srvy_gsm_dmpa_2', $
  'mms2_dfg_srvy_gsm_dmpa_2', $
  'mms3_dfg_srvy_gsm_dmpa_2', $
  'mms4_dfg_srvy_gsm_dmpa_2']
options, 'mms_*_gsm_dmpa_x', ytitle='FGM Bx'
options, 'mms_*_gsm_dmpa_y', ytitle='FGM By'
options, 'mms_*_gsm_dmpa_z', ytitle='FGM Bz'
options, 'mms_*_gsm_dmpa_*', ysubtitle='GSM-DMPA [nT]', labflag=1

mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='epsd', level='l2'
mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='bpsd', level='l2'

; set the options for the bpsd data
ylim, 'mms?_dsp_bpsd_omni_fast_l2', 0, 0, 1
zlim, 'mms?_dsp_bpsd_omni_fast_l2', 0, 0, 1

spd_mms_load_bss, /include_labels

; set plot parameters
tplot_options, 'xmargin', [15, 15]
tplot_options, 'ymargin', [5, 5]
tplot_options, 'charsize', 1.
tplot_options, 'panel_size', 0.2

if ~postscript then window, iw;, xsize=width, ysize=height
;tplot, ['mms_bss_burst', 'mms_bss_fast', $
;        'mms_dfg_srvy_dmpa_btot', 'mms_dfg_srvy_gsm_dmpa_*', 'mms_dfg_srvy_dmpa_bvec_*',$
;        'mms?_dsp_bpsd_omni_fast_l2'], window=iw

panels = ['mms_dfg_srvy_dmpa_btot', $
  'mms_dfg_srvy_gsm_dmpa_x', $
  'mms_dfg_srvy_gsm_dmpa_y', $
  'mms_dfg_srvy_gsm_dmpa_z', $
  'mms_dfg_srvy_dmpa_bvec_x', $
  'mms_dfg_srvy_dmpa_bvec_y', $
  'mms_dfg_srvy_dmpa_bvec_z', $
  'mms1_dsp_bpsd_omni_fast_l2', $
  'mms2_dsp_bpsd_omni_fast_l2', $
  'mms3_dsp_bpsd_omni_fast_l2', $
  'mms4_dsp_bpsd_omni_fast_l2']
  
mms_tplot_quicklook, panels, window=iw, $
           fast_bar='mms_bss_fast', burst_bar='mms_bss_burst', $
           title= 'MMS Quicklook Plots for Fields Data', trange=timerange()

timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_btot', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_x', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_y', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_z', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_bvec_x', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_bvec_y', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_bvec_z', linestyle=2

if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms_fields_quicklook_plots_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif
if postscript then tprint, plot_directory + "mms1_fields_data_quicklook_plots"
iw=iw+1

;
; START OF FIELDS2 E&B PLOTS - ALL SPACECRAFT
;
; Get DCE data
mms_load_edp, data_rate='fast', probes=[1, 2, 3, 4], datatype='dce', level='ql'

options, 'mms1*_dce_xyz_dsl', colors=[0], labels='MMS1'    ; black
options, 'mms2*_dce_xyz_dsl', colors=[6], labels='MMS2'    ; red
options, 'mms3*_dce_xyz_dsl', colors=[4], labels='MMS3'    ; green
options, 'mms4*_dce_xyz_dsl', colors=[2], labels='MMS4'    ; blue
split_vec, 'mms?_edp_dce_xyz_dsl'
store_data, 'mms_edp_dce_xyz_dsl_x', data = ['mms1_edp_dce_xyz_dsl_x', $
  'mms2_edp_dce_xyz_dsl_x', $
  'mms3_edp_dce_xyz_dsl_x', $
  'mms4_edp_dce_xyz_dsl_x']
store_data, 'mms_edp_dce_xyz_dsl_y', data = ['mms1_edp_dce_xyz_dsl_y', $
  'mms2_edp_dce_xyz_dsl_y', $
  'mms3_edp_dce_xyz_dsl_y', $
  'mms4_edp_dce_xyz_dsl_y']
store_data, 'mms_edp_dce_xyz_dsl_z', data = ['mms1_edp_dce_xyz_dsl_z', $
  'mms2_edp_dce_xyz_dsl_z', $
  'mms3_edp_dce_xyz_dsl_z', $
  'mms4_edp_dce_xyz_dsl_z']
options, 'mms_*_dce_xyz_dsl_x', ytitle='EDP Ex', labflag=1
options, 'mms_*_dce_xyz_dsl_y', ytitle='EDP Ey', labflag=1
options, 'mms_*_dce_xyz_dsl_z', ytitle='EDP Ez', labflag=1

; get scpot
mms_load_edp, datatype='scpot', trange=trange, level='l2', probe=probes

options, 'mms1_edp_scpot_fast_l2', colors=[0], labels='MMS1'    ; black
options, 'mms2_edp_scpot_fast_l2', colors=[6], labels='MMS2'    ; red
options, 'mms3_edp_scpot_fast_l2', colors=[4], labels='MMS3'    ; green
options, 'mms4_edp_scpot_fast_l2', colors=[2], labels='MMS4'    ; blue
store_data, 'mms_edp_scpot_fast_l2', data = ['mms1_edp_scpot_fast_l2', $
  'mms2_edp_scpot_fast_l2', $
  'mms3_edp_scpot_fast_l2', $
  'mms4_edp_scpot_fast_l2']
options, 'mms_edp_scpot_fast_l2', ytitle='EDP!CScpot', labflag=1

if ~postscript then window, iw;, xsize=width, ysize=height
;tplot, ['mms_bss_burst', 'mms_bss_fast', $
;        'mms_*_dce_xyz_dsl_*', 'mms_edp_scpot_fast_l2', 'mms_*_btot', $
;        'mms_*_gsm_dmpa_*'], window=iw, var_label=position_vars
;panels = ['mms_*_dce_xyz_dsl_*', 'mms_edp_scpot_fast_l2', 'mms_*_btot', $
;  'mms_*_gsm_dmpa_*']
panels = ['mms_edp_dce_xyz_dsl_x', $
  'mms_edp_dce_xyz_dsl_y', $
  'mms_edp_dce_xyz_dsl_z', $
  'mms_edp_scpot_fast_l2', $
  'mms_dfg_srvy_dmpa_btot', $
  'mms_dfg_srvy_gsm_dmpa_x', $
  'mms_dfg_srvy_gsm_dmpa_y', $
  'mms_dfg_srvy_gsm_dmpa_z']
  
mms_tplot_quicklook, panels, window=iw, $
           fast_bar='mms_bss_fast', burst_bar='mms_bss_burst', $
           title='MMS E&B Quicklook Plots', trange=timerange()

timebar, 0.0, /databar, varname='mms_edp_dce_xyz_dsl_x', linestyle=2
timebar, 0.0, /databar, varname='mms_edp_dce_xyz_dsl_y', linestyle=2
timebar, 0.0, /databar, varname='mms_edp_dce_xyz_dsl_z', linestyle=2
timebar, 0.0, /databar, varname='mms_edp_scpot_fast_l2', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_btot', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_x', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_y', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_z', linestyle=2

if postscript then tprint, plot_directory + "mms1_eandb_quicklook_plots"
if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms_eandb_quicklook_plots_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif

iw=iw+1

;
; EDP QuickLook Plots 
;
ylim, 'mms?_dsp_epsd_omni', 0, 0, 1
zlim, 'mms?_dsp_epsd_omni', 0, 0, 1
tdegap, 'mms?_dsp_epsd_omni', /overwrite

;panels = ['mms_edp_scpot_fast_l2', 'mms_*_dce_xyz_dsl_?', $
;  'mms?_dsp_epsd_omni']
panels = ['mms_edp_scpot_fast_l2', $
  'mms_edp_dce_xyz_dsl_x', $
  'mms_edp_dce_xyz_dsl_y', $
  'mms_edp_dce_xyz_dsl_z', $
  'mms1_dsp_epsd_omni', $
  'mms2_dsp_epsd_omni', $
  'mms3_dsp_epsd_omni', $
  'mms4_dsp_epsd_omni']
  
if ~postscript then window, iw;, xsize=width, ysize=height
mms_tplot_quicklook, panels, window=iw, title='MMS EDP Quicklook Plots', $
        fast_bar='mms_bss_fast', burst_bar='mms_bss_burst', trange=timerange()

if postscript then tprint, plot_directory + "mms1_edp_quicklook_plots"

if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms_edp_quicklook_plots_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif
stop

end