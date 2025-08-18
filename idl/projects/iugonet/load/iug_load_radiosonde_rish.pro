;+
;
;NAME:
;iug_load_radiosonde_rish
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for all the observation data taken by 
;  the radiosonde at several observation points and loads data into
;  tplot format.
;
;SYNTAX:
;  iug_load_radiosonde_rish [ ,DATATYPE = string ]
;                           [ ,SITE = string ]
;                           [ ,TRANGE = [min,max] ]
;                           [ ,<and data keywords below> ]
;
;KEYWOARDS:
;  DATATYPE = The type of data to be loaded. In this load program,
;             DATATYPEs are 'DAWEX' and 'misc'.
;  SITE = The observation site. In this load program,
;             defualt is 'sgk'.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
; A. Shinbori, 19/12/2012.
;
;MODIFICATIONS:
; A. Shinbori, 04/06/2013.
; A. Shinbori, 24/01/2014.
; A. Shinbori, 19/05/2016.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-
  
pro iug_load_radiosonde_rish, datatype = datatype, $
  site = site, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2
 
;***************
;Datatype check:
;***************

;--- all datatypes (default)
datatype_all = strsplit('dawex misc',' ', /extract)

;--- check datatypes
if(not keyword_set(datatype)) then datatype='all'
datatypes = ssl_check_valid_name(datatype, datatype_all, /ignore_case, /include_all)

print, datatypes

;***********
;site check:
;***********
;--- all site codes (default)
site_all = strsplit('bdg drw gpn ktb ktr pon sgk srp uji',' ', /extract)
dawex_site = strsplit('drw gpn ktr',' ', /extract)
misc_site = strsplit('bdg ktb pon sgk srp uji',' ', /extract)

;--- check site code
if (not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_all, /ignore_case, /include_all)

;---Search the index of dawex and misc site codes:
for i = 0, n_elements(dawex_site)-1 do begin
   site_idx = where(site_code eq dawex_site[i])
   append_array, dawex_site_idx, site_idx
endfor
for i = 0, n_elements(misc_site)-1 do begin
   site_idx = where(site_code eq misc_site[i])
   append_array, misc_site_idx, site_idx
endfor

print, site_code

  ;======================================
  ;======Load data of radiosonde=========
  ;======================================
  for i=0, n_elements(datatypes)-1 do begin
     ;load of DAWEX radiosonde data
      if strupcase(datatypes[i]) eq 'DAWEX' then begin
         for j=0, n_elements(dawex_site_idx)-1 do begin
            if dawex_site_idx[j] ne -1 then iug_load_radiosonde_dawex_nc, site=site_code[dawex_site_idx[j]], $
                                                                                downloadonly=downloadonly, trange=trange, verbose=verbose
         endfor
      endif 
     ;load of Shigaraki radiosonde data
      if (datatypes[i] eq 'misc') then begin
         for j=0, n_elements(misc_site_idx)-1 do begin
            if misc_site_idx[j] ne -1 then begin
               case site_code[misc_site_idx[j]] of
                  'bdg':iug_load_radiosonde_bdg_nc, downloadonly=downloadonly, trange=trange, verbose=verbose 
                  'ktb':iug_load_radiosonde_ktb_nc, downloadonly=downloadonly, trange=trange, verbose=verbose 
                  'pon':iug_load_radiosonde_pon_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
                  'sgk':iug_load_radiosonde_sgk_csv, downloadonly=downloadonly, trange=trange, verbose=verbose
                  'srp':iug_load_radiosonde_srp_nc, downloadonly=downloadonly, trange=trange, verbose=verbose 
                  'uji':iug_load_radiosonde_uji_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
               else:begin
                  print,'found no match sites for datatype misc'
               end
               endcase
            endif
         endfor
      endif 
   endfor  
end
