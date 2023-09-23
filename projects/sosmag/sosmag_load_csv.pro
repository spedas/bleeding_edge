;+
; Procedure:
;         sosmag_load_csv
;
; Purpose:
;         Load SOSMAG data from a local CSV file into tplot variables
;
; Keywords:
;         filename : the csv filename, including the full path
;         tformat (optional): string, time format, for example 'DD.MM.YYYY hh:mm:ss'
;                             default time format is 'YYYY-MM-DDThh:mm:ss.fffZ'
;         desc (optional): string, description of the data
;         prefix (optional): string, prefix for tplot variables
;         suffix (optional): string, suffix for tplot variables
;
; Notes:
;   First, the user must register at the ESA web site, then download a csv file to his computer,
;   and then he can load the csv file data into SPEDAS using "sosmag_load_csv, filename".
;
;   To register, the user can go to the following web site and click on "capabilities".
;     https://swe.ssa.esa.int/hapi/
;   A new page will appear which includes links for registration.
;
;   To download data as csv files, the user can use a web browser with the ESA HAPI web server.
;   For example, the following URL downloads calibrated data (data product esa_gk2a_sosmag_recalib) for 2021/01/31 1am to 2am UTC:
;   https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
;
;   And the following downloads real-time data (data product esa_gk2a_sosmag_1m):
;   https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
;
;   See also:
;     sosmag_csv_to_tplot.pro
; 
; $LastChangedBy: nikos $
; $LastChangedDate: 2023-09-07 09:09:32 -0700 (Thu, 07 Sep 2023) $
; $LastChangedRevision: 32087 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/sosmag_load_csv.pro $
;-

pro sosmag_load_csv, filename, tformat=tformat, desc=desc, prefix=prefix, suffix=suffix

  if ~keyword_set(filename) then begin
    dprint, 'No file specified.'
    return

  endif
  if FILE_TEST(filename, /read) then begin
    s = read_csv(filename, count=count)
    if count le 0 then begin
      dprint, 'File does not contail data: ' + filename
      return
    endif
  endif else begin
    dprint, 'File cannot be read: ' + filename
    return
  endelse

  sosmag_csv_to_tplot, s, tformat=tformat, desc=desc, prefix=prefix, suffix=suffix
end
