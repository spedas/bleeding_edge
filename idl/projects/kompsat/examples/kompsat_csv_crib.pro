;+
; Procedure:
;  kompsat_csv_crib
;
; Purpose:
;  Demonstrate how to load and plot KOMPSAT data using a CSV file.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-03-14 13:38:31 -0700 (Fri, 14 Mar 2025) $
; $LastChangedRevision: 33177 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/examples/kompsat_csv_crib.pro $
;-

pro kompsat_csv_crib

  ; Each user has to register at https://swe.ssa.esa.int/hapi/
  ; Then the user must log in using the username and password they received.

  ; After authentication, the user can download SOSMAG data as a CSV file using a browser.
  ;
  ; For example, this URL downloads one hour of calibrated data:
  ; https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_recalib&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
  ; and the following URL downloads real-time data:
  ; https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_1m&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
  ;
  ; After the user has downloaded the data, it can be read with kompsat_load_csv.pro.
  ; For this crib, we are going to use the file sosmag_test_data.csv


  ; Initialize and start with a clean slate
  thm_init
  del_data,'*'

  ; Specify the CSV filename, including the full path
  path_info = routine_info('kompsat_csv_crib', /source)
  fullpath = file_dirname(path_info.path) + PATH_SEP()
  filename = fullpath + 'sosmag_test_data.csv'

  ; Load data into SPEDAS
  print, 'Loading CSV file:', filename
  kompsat_load_csv, filename

  ; Print the names of the loaded tplot variables
  tplot_names

  ; Plot the SOSMAG b field in GSE coordinates.
  tplot_options, 'title', 'SOSMAG data, 2021-01-31'
  tplot, ['kompsat_b_gse']

end
