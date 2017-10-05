;+
; MMS EIS quicklook plots containing pitch angle distributions
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-02-22 09:05:59 -0800 (Wed, 22 Feb 2017) $
; $LastChangedRevision: 22846 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/quicklook/mms_load_eis_pad_crib_qlplots.pro $
;-


probe = '2'
trange = ['2016-10-16', '2016-10-17']
date = trange[0]
;timespan, date, 1
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

; load ExTOF, PHxTOF and electron data:
mms_load_eis, probes=probe, trange=trange, datatype=['phxtof', 'extof', 'electronenergy'], level='l1b'

mms_load_fgm, probes=probe, trange=trange, instrument='dfg', level='ql'
spd_mms_load_bss, trange=trange, /include_labels

; calculate the pitch angle distributions
mms_eis_pad, probe=probe, trange=trange, datatype='extof', level='l1b', energy=[68.71, 100.15], ion_type='proton', data_units='cps'
mms_eis_pad, probe=probe, trange=trange, datatype='phxtof', level='l1b', energy=[14.34, 20.44], ion_type='proton', data_units='cps'
mms_eis_pad, probe=probe, trange=trange, datatype='extof', level='l1b', energy=[111.65, 204.48], ion_type='alpha', data_units='cps'
mms_eis_pad, probe=probe, trange=trange, datatype='extof', level='l1b', energy=[169.59, 220.86], ion_type='oxygen', data_units='cps'
mms_eis_pad, probe=probe, trange=trange, datatype='electronenergy', level='l1b', energy=[54.24, 89.59], data_units='cps'

; clip the DFG data to -150nT to 150nT
tclip, 'mms'+probe+'_dfg_srvy_dmpa_bvec', -150., 150., /overwrite
options, 'mms'+probe+'_dfg_srvy_dmpa_bvec', ytitle='MMS'+probe+'!CFGM QL'
options, 'mms'+probe+'_dfg_srvy_dmpa_bvec', labflag=-1
options, 'mms'+probe+'_dfg_srvy_dmpa_bvec', labels=['Bx DMPA', 'By DMPA', 'Bz DMPA']

panels = 'mms'+probe+'_'+['dfg_srvy_dmpa_bvec', $
         'epd_eis_electronenergy_54.2400-89.5900keV_electron_cps_omni_pad_spin', $
         'epd_eis_extof_68.7100-100.150keV_proton_cps_omni_pad_spin', $
         'epd_eis_phxtof_14.3400-20.4400keV_proton_cps_omni_pad_spin', $
         'epd_eis_extof_111.650-204.480keV_alpha_cps_omni_pad_spin', $
         'epd_eis_extof_169.590-220.860keV_oxygen_cps_omni_pad_spin']

if ~postscript then window, iw, xsize=width, ysize=height
       
mms_tplot_quicklook, panels, trange=trange, title='EIS - Pitch Angle Distribution (counts/sec)', $
  burst_bar='mms_bss_burst', fast_bar='mms_bss_fast'
  
if postscript then tprint, plot_directory + prefix + "_quicklook_pad_plots"

if send_plots_to eq 'png' then begin
  mms_gen_multipngplot, 'mms'+probe + '_epd_eis_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), date, directory = plot_directory, /mkdir, $
    vars24 = panels, vars06 =  panels, vars02 = panels, vars12=panels, window=iw, $
    burst_bar = 'mms_bss_burst', $
    fast_bar = 'mms_bss_fast'
endif

stop
  
end
