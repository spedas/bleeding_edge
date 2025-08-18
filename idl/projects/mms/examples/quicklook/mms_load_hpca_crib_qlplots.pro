;+
; MMS HPCA quick look plots crib sheet
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-17 09:28:43 -0700 (Thu, 17 Aug 2023) $
; $LastChangedRevision: 32010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/quicklook/mms_load_hpca_crib_qlplots.pro $
;-

; initialize and define parameters
probes = ['1', '2', '3', '4']
species = ['H+', 'He+', 'He++', 'O+']
tplotvar_species = ['hplus', 'heplus', 'heplusplus', 'oplus']

; set parameters  
pid = probes[0]      ; set probe to mms1
sid = species[0]     ; set species to H+
tsid = tplotvar_species[0]    

;timespan, '2015-08-15', 1
date = '2016-4-20'
timespan, date, 1
;trange = ['2015-11-02', '2015-11-03']
tplotvar = 'mms'+pid + '_hpca_' + tsid + '_RF_corrected'

iw = 2
;width = 800
;height = 900

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows
send_plots_to = 'win'
plot_directory = 'hpca/'+time_string(date, tformat='YYYY/MM/DD/')

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

; load mms survey HPCA data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='srvy', suffix='_srvy'

; load QL FGM data, currently only for ephemeris data 
mms_load_fgm, instrument='dfg', trange=trange, probes=pid, level='ql'

; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid, suffix='_srvy'
mms_hpca_calc_anodes, anode=[13, 14], probe=pid, suffix='_srvy'
mms_hpca_calc_anodes, anode=[0, 15], probe=pid, suffix='_srvy'

; do the same for burst data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='brst', suffix='_brst'

; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid, suffix='_brst'
mms_hpca_calc_anodes, anode=[13, 14], probe=pid, suffix='_brst'
mms_hpca_calc_anodes, anode=[0, 15], probe=pid, suffix='_brst'

; create pseudo variables for the combined burst and survey data
store_data, tplotvar+'_brst_srvy_0_15', data=[tplotvar+'_brst_anodes_0_15', tplotvar+'_srvy_anodes_0_15'], dlimits=dl, limits=l
store_data, tplotvar+'_brst_srvy_5_6', data=[tplotvar+'_brst_anodes_5_6', tplotvar+'_srvy_anodes_5_6'], dlimits=dl, limits=l
store_data, tplotvar+'_brst_srvy_13_14', data=[tplotvar+'_brst_anodes_13_14', tplotvar+'_srvy_anodes_13_14'], dlimits=dl, limits=l

;options, tplotvar+'_brst_srvy_0_15', 'labels'

; get ephemeris data for x-axis annotation
;mms_load_state, probes=pid, trange = trange, /ephemeris
;eph_j2000 = 'mms'+pid+'_defeph_pos'
;eph_gei = 'mms'+pid+'_defeph_pos_gei'
;eph_gse = 'mms'+pid+'_defeph_pos_gse'
eph_gsm = 'mms'+pid+'_ql_pos_gse'

; convert from J2000 to gsm coordinates
;cotrans, eph_j2000, eph_gei, /j20002gei
;cotrans, eph_gei, eph_gse, /gei2gse
;cotrans, eph_gse, eph_gsm, /gse2gsm

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_0',ytitle='X (Re, GSE)'
options, eph_gsm+'_re_1',ytitle='Y (Re, GSE)'
options, eph_gsm+'_re_2',ytitle='Z (Re, GSE)'
options, eph_gsm+'_re_3',ytitle='R (Re)'
position_vars = [eph_gsm+'_re_3', eph_gsm+'_re_0', eph_gsm+'_re_1', eph_gsm+'_re_2']

; create a tplot variable with flags for burst and survey data
;mode_var=mms_hpca_mode(tplotvar+'_brst', tplotvar+'_srvy')
; use bss routine to create tplot variables for fast, burst, status, and/or FOM
spd_mms_load_bss, trange=trange, /include_labels, datatype=['fast', 'burst']

; set up some plotting parameters
tplot_options, 'xmargin', [15, 15]
tplot_options, 'ymargin', [5, 5]
;tplot_options, 'title', 'Quicklook Plots for HPCA '+sid+' Data'
;panels=['mms_bss_burst', 'mms_bss_fast','mms_bss_status', $
;  'mms1_hpca_hplus_RF_corrected_brst_srvy_anodes_0_15', $
;  'mms1_hpca_hplus_RF_corrected_brst_srvy_anodes_5_6', $
;  'mms1_hpca_hplus_RF_corrected_brst_srvy_anodes_13_14']

; don't interpolate through the gaps for burst mode data
tdegap, 'mms1_hpca_hplus_RF_corrected_brst_anodes_*', /overwrite

panels=['mms1_hpca_hplus_RF_corrected_brst_anodes_0_15', $
   'mms1_hpca_hplus_RF_corrected_brst_anodes_5_6', $
   'mms1_hpca_hplus_RF_corrected_brst_anodes_13_14', $
   'mms1_hpca_hplus_RF_corrected_srvy_anodes_0_15', $
   'mms1_hpca_hplus_RF_corrected_srvy_anodes_5_6', $
   'mms1_hpca_hplus_RF_corrected_srvy_anodes_13_14']
   
if ~postscript then window, iw;, xsize=width, ysize=height
title= 'Quicklook Plots for HPCA '+sid+' Data'
mms_tplot_quicklook, panels, title=title, window=iw, var_label=position_vars, $
  fast_bar='mms_bss_fast', burst_bar='mms_bss_burst'

if postscript then tprint, plot_directory + "mms1_hpca_hplus_RF_corrected"

if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms_hpca_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif

stop

end