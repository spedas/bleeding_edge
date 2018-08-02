;+
;
;NAME:
;iug_load_mf_rish
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the observation data (uwind, vwind, wwind)
;  in the NetCDF format taken by the MF radar at Pameungpeuk and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_mf_rish, site=site, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;   SITE  = Observatory code name.  For example, iug_load_mf_rish, site = 'pam'.
;          The default is 'all', i.e., load all available stations.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
; A. Shinbori, 09/19/2010.
;
;MODIFICATIONS:
; A. Shinbori, 03/24/2011.
; A. Shinbori, 02/04/2013.
; A. Shinbori, 08/01/2014.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-


pro iug_load_mf_rish, site=site, $
   downloadonly=downloadonly, $
   trange=trange, $
   verbose=verbose

;**************
;keyword check:
;**************
if (not keyword_set(verbose)) then verbose=2

;***********
;site codes:
;***********
;--- all sites (default)
site_code_all = strsplit('pam pon',' ', /extract)

;--- check site codes:
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if n_elements(site_code) eq 1 then begin
   if site_code eq '' then begin
      print, 'This station code is not valid. Please input the allowed keywords, all, pam, and pon.'
      return
   endif
endif
print, site_code

;--- Load MF radar data:
for i=0, n_elements(site_code)-1 do begin
   case site_code[i] of
      'pam':iug_load_mf_rish_pam_nc, downloadonly=downloadonly, $
                                     trange=trange, verbose=verbose
      'pon':iug_load_mf_rish_pon_nc, downloadonly=downloadonly, $
                                     trange=trange, verbose=verbose
   endcase
endfor

end
