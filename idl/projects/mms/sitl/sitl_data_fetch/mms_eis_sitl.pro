;+
; mms_eis_sitl.pro
;
; PURPOSE: Loads and generates EIS data for use by SITL in EVA
;
; KEYWORDS:
;         trange: time range of interest (string, ex. ['yyyy-mm-dd','yyyy-mm-dd'])
;         probe: string indicating value for mms SC #
;         bin_size: size of the pitch angle bins (numeric)
;         data_rate: instrument data rates ['brst', 'srvy' (default), 'fast', 'slow']
;         data_units: desired units for data. for eis units are ['flux', 'cps', 'counts'] (default = flux)
;         ion_type: array containing types of particles to include.
;               for PHxTOF data, valid options are 'proton', 'oxygen'
;               for ExTOF data, valid options are 'proton', 'oxygen', and/or 'alpha'
;         i_ph: set to 1 to include phxtof protons (default = 0)
;         i_plot: set to 1 to plot to screen (default = 0)
;         i_print: set to 1 to print to PS file (default = 0)
;         i_scopes: set to 1 to omit sun-blocked telescopes in PADs (default = 0)
;
; OUTPUT:
;
; CREATED BY: I. Cohen, 2016-01-12
;
;-
probe = '2'
trange = ['2015-12-06', '2015-12-07']
timespan, '2015-12-06', 1
iw = 0
width = 850
height = 1000
prefix = 'mms'+probe+'_epd_eis'
data_units = 'cps'

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

; variable patterns to load
if (data_units eq 'cps') then begin
  varformat = ['mms'+probe+'_epd_eis_*_spin', $
    'mms'+probe+'_epd_eis_*_pitch_angle_t*', $
    'mms'+probe+'_epd_eis_*_*_cps_t*']
endif else begin
  varformat = ['mms'+probe+'_epd_eis_*_spin', $
    'mms'+probe+'_epd_eis_*_pitch_angle_t*', $
    'mms'+probe+'_epd_eis_*_*_flux_t*']
      
endelse

; load ExTOF and electron data:
mms_load_eis, probes=probe, trange=trange, datatype='extof', level='l1b', data_units = data_units, varformat=varformat
mms_load_eis, probes=probe, trange=trange, datatype='phxtof', level='l1b', data_units = data_units, varformat=varformat
mms_load_eis, probes=probe, trange=trange, datatype='electronenergy', level='l1b', data_units = data_units, varformat=varformat

; load DFG data
mms_load_dfg, probes=probe, trange=trange, level='ql'
tclip, 'mms'+probe+'_dfg_srvy_gse_bvec', -100., 100., /overwrite

; setup for plotting the proton flux for all channels
ylim, prefix+'_electronenergy_electron_'+data_units+'_omni_spin', 40, 750, 1
zlim, prefix+'_electronenergy_electron_'+data_units+'_omni_spin', 0, 0, 1
ylim, prefix+'_extof_proton_'+data_units+'_omni_spin', 50, 500, 1
zlim, prefix+'_extof_proton_'+data_units+'_omni_spin', 0, 0, 1
ylim, prefix+'_phxtof_proton_'+data_units+'_omni_spin', 15, 45, 1
zlim, prefix+'_phxtof_proton_'+data_units+'_omni_spin', 0, 0, 1
ylim, prefix+'_extof_oxygen_'+data_units+'_omni_spin', 150, 1000, 1
zlim, prefix+'_extof_oxygen_'+data_units+'_omni_spin', 0, 0, 1
ylim, prefix+'_extof_alpha_'+data_units+'_omni_spin', 80, 800, 1
zlim, prefix+'_extof_alpha_'+data_units+'_omni_spin', 0, 0, 1

; calculate pitch angle distributions
mms_eis_pad, probe = probe, trange = trange, species = 'ion', energy = [46.,68.], bin_size = bin_size, data_units = data_units, datatype = 'extof', ion_type = ['proton']
  options, prefix+'_extof_46.0000-68.0000keV_proton_'+data_units+'_pad_spin', ytitle = 'mms'+probe+'!Ceis!Cproton',ysubtitle='46-68 keV!CPAD [deg]'
  ;if (data_units eq 'flux') then zlim, proton_ex_pad,1., 100000.,1. else zlim, proton_ex_pad, 0.01, 350., 1
mms_eis_pad, probe = probe, trange = trange, species = 'ion', energy = [60.3,110.5], bin_size = bin_size, data_units = data_units, datatype = 'extof', ion_type = ['alpha']
  options, prefix+'_extof_60.3000-110.500keV_alpha_'+data_units+'_pad_spin', ytitle = 'mms'+probe+'!Ceis!Chelium',ysubtitle='60-111 keV!CPAD [deg]', ztitle=data_units
mms_eis_pad, probe = probe, trange = trange, species = 'ion', energy = [129.,169.], bin_size = bin_size, data_units = data_units, datatype = 'extof', ion_type = ['oxygen']
  options, prefix+'_extof_129.000-169.000keV_oxygen_'+data_units+'_pad_spin', ytitle = 'mms'+probe+'!Ceis!Coxygen',ysubtitle='129-169 keV!CPAD [deg]'
  ;zlim, oxygen_pad, .01, 10., 1  
mms_eis_pad, probe = probe, trange = trange, species = 'ion', energy = [20.5,30.], bin_size = bin_size, data_units = data_units, datatype = 'phxtof', ion_type = ['proton']
  options, prefix+'_phxtof_20.5000-30.0000keV_proton_'+data_units+'_pad_spin', ytitle = 'mms'+probe+'!Ceis!Cproton',ysubtitle='20-30 keV!CPAD [deg]'
  ;zlim, proton_ph_pad, 0.005, 20., 1
mms_eis_pad, probe = probe, trange = trange, species = 'electron', energy = [29.,53.], bin_size = bin_size, data_units = data_units, datatype = 'electronenergy'
  options, prefix+'_electronenergy_29.0000-53.0000keV_electron_'+data_units+'_pad_spin', ytitle = 'mms'+probe+'!Ceis!Celectron',ysubtitle='30-53 keV!CPAD [deg]'
  ;if (data_units eq 'flux') then zlim, electron_pad,1, 35000.,1. else zlim, electron_pad, 0.01, 100.,1. ;64., 1
  
; force the min/max of the Y axes to the limits
options, '*_flux_omni*', ystyle=1

tplot_options, 'ymargin', [5, 5]
tplot_options, 'xmargin', [15, 15]

panels = ['mms'+probe+'_dfg_srvy_gse_bvec', $
  prefix+'_electronenergy_electron_'+data_units+'_omni_spin', $
  prefix+'_electronenergy_29.0000-53.0000keV_electron_'+data_units+'_pad_spin', $
  prefix+'_extof_proton_'+data_units+'_omni_spin', $
  prefix+'_extof_46.0000-68.0000keV_proton_'+data_units+'_pad_spin', $
  prefix+'_phxtof_proton_'+data_units+'_omni_spin', $
  prefix+'_phxtof_20.5000-30.0000keV_proton_'+data_units+'_pad_spin', $
  prefix+'_extof_alpha_'+data_units+'_omni_spin', $
  prefix+'_extof_60.3000-110.500keV_alpha_'+data_units+'_pad_spin', $
  prefix+'_extof_oxygen_'+data_units+'_omni_spin', $
  prefix+'_extof_129.000-169.000keV_oxygen_'+data_units+'_pad_spin']

tplot, panels, var_label=position_vars, window=iw

end