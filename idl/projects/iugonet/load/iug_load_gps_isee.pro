;+
;
;NAME:
;iug_load_gps_isee
;
;PURPOSE:
;  Queries the ISEE servers for the GPS TEC (Total Electron Content) data
;  provided from ISEE and and loads data into tplot format.
;
;SYNTAX:
; iug_load_gps_isee, site=site, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  DATATYPE = The type of data to be loaded. In this load program,
;             DATATYPEs are 'atec'. In future, 'dtec' and 'roti' will be added.
;
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE : [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
;  A. Shinbori, 06/10/2021.
;
;MODIFICATIONS:
;  
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:  $
; $LastChangedDate: $
; $LastChangedRevision:  $
; $URL $
;-

pro iug_load_gps_isee, datatype = datatype, $
  trange = trange, $
  verbose = verbose, $
  downloadonly=downloadonly

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;****************
;Datatype check:
;****************

;--- all datatypes (default)
datatype_all = strsplit('atec',' ', /extract)

;--- check datatypes
if (not keyword_set(datatype)) then datatype='all'
datatypes = ssl_check_valid_name(datatype, datatype_all, /ignore_case, /include_all)

print, datatypes

  ;===============================
  ;======Load data of TEC=========
  ;===============================
  for i=0L, n_elements(datatypes)-1 do begin

    if (datatypes[i] eq 'atec') then begin
      ;---load of aws data at the Shigaraki sites
      iug_load_gps_atec, trange = trange, downloadonly=downloadonly, verbose = verbose
    end
    
  endfor
end


