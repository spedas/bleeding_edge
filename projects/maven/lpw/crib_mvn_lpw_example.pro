
;********************************************
; This is an example file for the LPW software
;********************************************
 
;****************************************************
;THIS IS THE LATEST AND EASIEST WAY TO LOAD LPW DATA: (edit added 2017-02-22 by CMF)
;****************************************************
;This method utilizes the timespan command, so that it is compatible with the other PFP instrument load routines. 
timespan, '2015-01-01', 1.   ;set start date and number of days to get.
mvn_lpw_load_l2, ['lpnt', 'wspecact']    ;get LPW data. Enter codes for which data products to get - set the preamble in mvn_lpw_load_l2.pro for descriptions.

;An example of how to get ancillary information (such as altitude) using the LPW routines. These use the MAVEN SPICE routines underneath:
time=dindgen(86400)+time_double('2015-01-01')  ;make a time array, un UNIX time. You can also use, get_data, for example, to get "actual" time arrays.

mvn_lpw_anc_get_spice_kernels, time   ;this looks up the kernels to get, for the array time. The routine takes the earliest and latest times in the array, and looks for kernels covering this range.
mvn_lpw_anc_spacecraft, time   ;this routine calculates various ancillary data, such as altitude and position, for each timestep in the array "time". Currently, several parameters
                ;are calculated, which takes time. CMF will (at some point) add keywords so the user can decide exactly what to calculate.

 
;********************************************
; Read The CDF-files (including Level 2)  data
;********************************************
;mvn_lpw_cdf_read.pro
;The best way for users to get LPW L1a, L1b and L2 data is to use mvn_lpw_cdf_read.pro. Please see the preamble in this routine for more examples with all keywords.
;This routine assumes you have the working directory structure based on the SSL tree, ie you make use of the environment variable ROOT_DATA_DIR.

 mvn_lpw_cdf_read,'2015-01-28', vars=['wspecact','wspecpas','we12burstlf','we12burstmf','we12bursthf','wn','lpiv','lpnt','mrgexb','mrgscpot','euv','e12']

;If there is a problem loading a CDF file using this routine, but you can see the CDF file, you can load this file manually using mvn_lpw_cdf_read_file.pro.
;If the file directory is /dir/ and the filename is fname.cdf then use

 mvn_lpw_cdf_read_file, dir='/dir/', varlist='fname.cdf'

;=======
;Old comments, ignore:
;Lines 83-84 won’t work to get data from SSL. Mvn-lpw-cdf-read-file should work by specifying directory and  filenames.
;udir = getenv('ROOT_DATA_DIR')  ;at LASP this is usually /Volumes/spg/maven/data/ or /spg/maven/data
;fbase=udir+'maven'+sl+'data'+sl+'sci'+sl   ;Need some files to test this, so it may not work yet!
;=======

;Users can also get cdf files using mvn_lpw_load.pro, but it is easier to use the above. See preamble again for examples.

;********************************************
 
  

 
 
 
 
;********************************************
; Read L0 data (get the data based on the data packets)
;********************************************
;mvn_lpw_load.pro
;This will load data directly from the L0 file and bring data upto L1. THIS IS NOT scientific quality and SHOULD NOT be used for publication. Please
;use L2 CDF data for publication purposes.
;Because of the above most users will not need to use this routine.

;An additional IDL environment variable must be set when using mvn_lpw_load.pro which points to the folder that this LPW software is stored in. This is so the software
;can find additional calibration information in the 'mvn_lpw_cal_files' subfolder.
;For example:
setenv, 'mvn_lpw_software=/Users/andersson/Idl/2014_maven/SVN_controlled/LDS_MAVEN_LPW/master/'    ;new server

;Please note that there are several keywords you will need to set if you are not at LASP and using mvn_lpw_load.pro. See the preamble in the routine for examples. This
;is another reason mvn_lpw_cdf_read.pro is easier to use.



;To L0 data, the recommended default settings are below. You may also need additional keywords - see routine preamble for examples.
;trange not working on this call
mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /notatlasp 
 
 
;if there is an issue with finding the L0 file you can load a specific L0 file manually. If the full L0 file directory and filename is 'filename' then use the following  
mvn_lpw_load_file,'filename', tplot_var='all', filetype='L0', packet='nohsbm',board='FM'
 
 
;Once data is loaded:
 
 ;To look at the IV sweep, Log(abs(Current)) is recommended
 
 tplot,'*log'
 
 ;to look at the raw wave spectra
 
 tplot,['mvn_lpw_spec_lf_pas','mvn_lpw_spec_mf_pas','mvn_lpw_spec_hf_pas','mvn_lpw_spec_lf_act','mvn_lpw_spec_mf_act','mvn_lpw_spec_hf_act']
 
 ;to look at the raw V1/V2 data
 
 tplot,['*V1','*V2']
 
 ;to look at the raw e12 data
 
 tplot,['*e12']
 
 ;to look at the raw euv
 
 tplot,'*euv'
 
 
 
; ;********************************************
 
  


