;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2022-02-01 16:35:26 -0800 (Tue, 01 Feb 2022) $
; $LastChangedRevision: 30553 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/psp_fld_venus_examples.pro $
;
;-

pro psp_fld_venus_examples

  ; First, show the directory where you have SPEDAS installed.  If this yields
  ; an error or no result, then you need a recent 'bleeding edge' version
  ; of SPEDAS, see:
  ; http://spedas.org/wiki/index.php?title=Main_Page#Downloads_and_Installation

  libs, 'psp_fld_load'

  ; Confirm that you have installed a recent version of the CDF patch.
  ; Versions including and above 3.6.3.1 should work.  If you don't have a
  ; recent version, install one from:
  ; https://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html

  help, 'CDF', /dlm

  ; You can download files manually and load them, but it's easier to use
  ; the SPEDAS file_retrieve routine.

  ; Set a timespan for a Venus gravity assist.

  ; timespan, '2018-10-03' ; VGA 1
  ; timespan, '2019-12-26' ; VGA 2
  timespan, '2020-07-11'   ; VGA 3
  ; timespan, '2021-02-20' ; VGA 4

  ; Downloads and load MAG data in VSO coordinates

  psp_fld_load, type = 'mag_VSO'

  ; Load RFS LFR data (also available: 'rfs_hfr')

  psp_fld_load, type = 'rfs_lfr'

  ; Load DFB single ended waveform data
  ; (also available: 'dfb_wf_dvdc' and 'dfb_wf_scm')

  psp_fld_load, type = 'dfb_wf_vdc'

  ; Load DFB AC spectral data
  ; (also available: 'dfb_ac_xspec', 'dfb_dc_spec', 'dfb_dc_xspec', with
  ; cross spectral data available for limited times)

  psp_fld_load, type = 'dfb_ac_spec'

  ; Show available items to plot

  tplot_names

  ; Make a plot of some selected items

  tplot, ['psp_fld_l2_mag_VSO', $
    'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2', $
    'psp_fld_l2_dfb_wf_V1dc', $
    'psp_fld_l2_dfb_ac_spec_dV12hg', $
    'psp_fld_l2_quality_flags']

  stop

  ; See the file 'crib_tplot.pro' in the SPEDAS distribution for examples
  ; on how to interact with TPLOT, including 'tlimit' and 'get_data'. 

end