;+
; Procedure:
;         kompsat_load_csv
;
; Purpose:
;         Load KOMPSAT data from a local CSV file into tplot variables.
;         Data files can contain either magnetometer data (SOSMAG intrument) or particle data (particle detector).
;
; Keywords:
;         filename : the csv filename, including the full path
;         dataset: string, 'recalib' (default, can be omitted), '1m', 'p', 'e'
;         tformat (optional): string, time format, for example 'DD.MM.YYYY hh:mm:ss'
;                             default time format is 'YYYY-MM-DDThh:mm:ss.fffZ'
;         desc (optional): string, description of the data
;         prefix (optional): string, prefix for tplot variables
;         suffix (optional): string, suffix for tplot variables
;
; Notes:
;   First, the user must register at the ESA web site, then download a csv file to his computer,
;   and then load the csv file data into SPEDAS using "kompsat_load_csv, filename".
;
;   To register, the user can go to the following web site and click on "capabilities".
;     https://swe.ssa.esa.int/hapi/
;   A new page will appear which includes the link for registration.
;
;   To download data as csv files, the user can use a web browser with the ESA HAPI web server.
;
;   For example, the following URL downloads SOSMAG calibrated data (data product d3s_gk2a_sosmag_recalib):
;   https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_recalib&time.min=2024-05-11T01:00:00.000Z&time.max=2024-05-11T02:00:00.000Z&format=csv
;
;   The following downloads SOSMAG real-time data (data product d3s_gk2a_sosmag_1m):
;   https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_1m&time.min=2024-05-11T01:00:00.000Z&time.max=2024-05-11T02:00:00.000Z&format=csv
;
;   The following downloads proton flux data (data product kma_gk2a_ksem_pd_p_l1):
;   https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_p_l1&time.min=2024-05-11T01:00:00.000Z&time.max=2024-05-11T02:00:00.000Z&format=csv
;
;   The following downloads electron flux data (data product kma_gk2a_ksem_pd_e_l1):
;   https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_e_l1&time.min=2024-05-11T01:00:00.000Z&time.max=2024-05-11T02:00:00.000Z&format=csv
;
;
;   To find information on the variables for each data set, use the above links with 'info' instead of 'data' and 'json' instead of 'csv'. For example:
;   https://swe.ssa.esa.int/hapi/info?id=spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_recalib&time.min=2024-05-11T01:00:00.000Z&time.max=2024-05-11T02:00:00.000Z&format=json
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-03-14 13:38:31 -0700 (Fri, 14 Mar 2025) $
; $LastChangedRevision: 33177 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/kompsat_load_csv.pro $
;-

pro kompsat_load_csv, filename, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars

  if ~keyword_set(filename) then begin
    dprint, 'No file specified.'
    return
  endif

  if undefined(dataset) then dataset='recalib'
  result = WHERE(STRCMP(dataset, ['recalib', '1m', 'p', 'e'], /FOLD_CASE) EQ 1, count)
  if count ne 1 then begin
    dprint, 'Dataset should one of: recalib, 1m, p, e'
    return
  endif

  if FILE_TEST(filename, /read) then begin
    s = read_csv(filename, count=count)
    if count le 0 then begin
      dprint, 'File does not contail data: ' + filename
      return
    endif
    num_columns = n_tags(s)
    if num_columns ne 14 and num_columns ne 34 then begin
      dprint, 'File is expected to have either 14 columns (magnetometer) or 34 columns (particles). This file had: ' + string(num_columns)
      return
    endif
  endif else begin
    dprint, 'File cannot be read: ' + filename
    return
  endelse

  ; Transform to array
  n_rows = n_elements((s.(0)))
  n_cols = n_tags(s)

  ; Create the 2D string array
  array_2d = strarr(n_cols, n_rows)

  ; Fill the array with data from the structure
  FOR i = 0, n_cols - 1 DO BEGIN
    array_2d[i, *] = string(s.(i))
  ENDFOR
  array_2d = transpose(array_2d)

  kompsat_to_tplot, array_2d, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars

end

