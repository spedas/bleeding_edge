;+
;
;NAME:
;iug_load_gps_ro_rish
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the GPS radio occultation FSI data in the netCDF format
;  provided by UCAR and loads data into tplot format.
;
;SYNTAX:
; iug_load_gps_ro_rish, site=site, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;   SITE  = Observatory code name.  For example, iug_load_gps_ro_rish, site = 'champ'.
;           The default is 'all', i.e., load all available stations.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
; A. Shinbori, 14/05/2016.
;
;MODIFICATIONS:
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_gps_ro_rish, site=site, $
   downloadonly=downloadonly, $
   trange=trange, $
   verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2


;****************
;Site code check:
;****************
;--- all sites (default)
site_code_all = strsplit('champ cosmic',' ', /extract)

;--- check site codes
if (not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

print, site_code

;---Load the meteor radar data:
for i=0, n_elements(site_code)-1 do begin
   case site_code[i] of
      'champ': iug_load_gps_champ_fsi_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
      'cosmic': iug_load_gps_cosmic_fsi_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
   endcase
endfor
end
