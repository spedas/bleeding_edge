;+
; Procedure:
;  sosmag_csv_crib
;
; Purpose:
;  Demonstrate how to load and plot SOSMAG data using a CSV file.
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2023-09-07 09:09:32 -0700 (Thu, 07 Sep 2023) $
; $LastChangedRevision: 32087 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/sosmag_csv_crib.pro $
;-

pro sosmag_csv_crib

  ; Each user has to register at https://swe.ssa.esa.int/hapi/
  ; Then the user must log in using the username and password they received.

  ; After authentication, the user can download SOSMAG data as a CSV file using a browser.
  ;
  ; For example, this URL downloads one hour of calibrated data:
  ; https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
  ; and the following URL downloads real-time data:
  ; https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
  ;
  ; After the user has downloaded the data, it can be read with sosmag_csv_to_tplot.pro.
  ; For this crib, we are going to use the file sosmag_test_data.csv


  ; Initialize and start with a clean slate
  thm_init
  del_data,'*'
  
  ; Specify the CSV filename, including the full path
  path_info = routine_info('sosmag_csv_crib', /source)
  fullpath = file_dirname(path_info.path) + PATH_SEP() 
  filename = fullpath + 'sosmag_test_data.csv'
  
  ; Load data into SPEDAS
  print, 'Loading CSV file:', filename
  sosmag_load_csv, filename

  ; Plot the loaded SOSMAG variables.
  tplot_options, 'title', 'SOSMAG data, 2021-01-31'
  tplot, ['sosmag_bt_sm']

end
