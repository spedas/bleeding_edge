;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2020-09-14 11:28:02 -0700 (Mon, 14 Sep 2020) $
; $LastChangedRevision: 29153 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/spp_fld_examples.pro $
;
;-

pro spp_fld_examples

  ; First, show the directory where you have SPEDAS installed.  If this yields
  ; an error or no result, then you need a recent 'bleeding edge' version
  ; of SPEDAS, see:
  ; http://spedas.org/wiki/index.php?title=Main_Page#Downloads_and_Installation

  libs, 'spp_fld_load_l1'

  ; Confirm that you have installed a recent version of the CDF patch.
  ; Versions including and above 3.6.3.1 should work.  If you don't have a
  ; recent version, install one from:
  ; https://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html
  
  help, 'CDF', /dlm
  
  ;
  ; You can download files manually and load them, but it's easier to use
  ; the SPEDAS file_retrieve routine.  To do that, you'll need to set up
  ; and your user name and password.
  ;
  ; Pre-release, password-protected data is restricted to members of the 
  ; FIELDS team. In SPEDAS, this data is accessed via a routine,
  ; 'spp_fld_load', which has nearly identical syntax to the public
  ; 'psp_fld_load' routine. 
  ; 
  ; (In fact, 'psp_fld_load' is actually a wrapper routine for 'spp_fld_load'.
  ; The only real difference is that 'psp_fld_load' points by default 
  ; to the public data folder rather than the password-protected one.)
  ;
  ; Password access is controlled in SPEDAS by setting environment variables. 
  ; The relevant variables are PSP_STAGING_ID, for your username, and 
  ; PSP_STAGING_PW, for your password. Several methods can be used to set
  ; these variables:
  ;
  ; In a shell startup file (bash or zsh shell), include the lines:
  ;
  ;   export PSP_STAGING_ID=your_username
  ;   export PSP_STAGING_PW=your_password
  ;
  ; In a shell startup file (csh), include the lines:
  ; 
  ;   setenv PSP_STAGING_ID your_username
  ;   setenv PSP_STAGING_PW your_password
  ;
  ; As an IDL command (in an IDL startup file, entered manually at the IDL
  ; prompt, or included in a script as in the code below:
  ;
  ; setenv, 'PSP_STAGING_ID=your_username'
  ; setenv, 'PSP_STAGING_PW=your_password'
  ;
  
  if getenv('PSP_STAGING_PW') EQ '' then $
    setenv, 'PSP_STAGING_PW=your_password'

  if getenv('PSP_STAGING_ID') EQ '' then $
    setenv, 'PSP_STAGING_ID=your_username'

  ; Set a timespan for a day in perihelion.  
  ; Loading multiple days should work but can be slow for large data sets.

  timespan, '2020-06-02'
  
  ; Download MAG and RFS files.

  spp_fld_load, type = 'mag_RTN_4_Sa_per_Cyc'

  spp_fld_load, type = 'rfs_hfr'
  spp_fld_load, type = 'rfs_lfr'

  tplot, ['psp_fld_l2_mag_RTN_4_Sa_per_Cyc', $
    'psp_fld_l2_rfs_hfr_auto_averages_ch0_V1V2', $
    'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2', $
    'psp_fld_l2_quality_flags']

  stop

end