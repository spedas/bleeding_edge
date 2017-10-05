;+
;PROCEDURE: IUG_LOAD_GMAG_WDC
; iug_load_gmag_wdc, site=site, $
;                        trange=trange, $
;                        resolution = resolution, $
;                        level=level, $
;                        verbose=verbose, $
;                        addmaster=addmaster, $
;                        downloadonly=downloadonly, $
;                        no_download=no_download
;
;PURPOSE:
;  Loading geomag data in WDC format from WDC for Geomag Kyoto.
;
;KEYWORDS:
;  site  = Station ABB code or name of geomagnetic index.
;          Ex1) iug_load_gmag_wdc, site = 'kak', ...
;          Ex2) iug_load_gmag_wdc, site = ['dst', 'ae'], ...
;          If you skip this option, AE Dst SYM/ASY and KAK data are retrieved.
;  trange= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full month, a full
;          month's data is loaded.
;  reolution = Time resolution of the data: 'min' or 'hour',
;          default set to 'min' for AE index and geomag data.
;  level = The level of the data, the default is 'final' for geomag data.
;          For AE and Dst index, the default is ['final', 'provsional'].
;  /verbose : set to output some useful info.
;  /addmaster, if set, then times = [!values.d_nan, times]
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  no_download: use only files which are online locally.
;
;EXAMPLE:
;   timespan, '2007-01-22',1,/days
;   iug_load_gmag_wdc, site = 'ae', resolution = 'min'
;
;NOTES:
;  At WDC Kyoto, data service for TDAS clients is beta testing.
;  Please check the data catalog at http://wdc-data.iugonet.org/.
;
;Written by:  Daiki Yoshida,  Aug 2010
;Last Updated:  Yukinobu KOYAMA,  Oct 21, 2011
; 
;-

pro iug_load_gmag_wdc, site=site, $
                       trange=trange, $
                       resolution = resolution, $
                       level=level, $
                       verbose=verbose, $
                       addmaster=addmaster, $
                       downloadonly=downloadonly, $
                       no_download=no_download


  ; validate site settings
  vsnames = 'kak asy sym ae dst'
  vsnames_sample = strsplit(vsnames, ' ', /extract)
  vsnames_all = iug_load_gmag_wdc_vsnames()
  if(keyword_set(site)) then site_in = site else site_in = vsnames_sample
  wdc_sites = ssl_check_valid_name(site_in, vsnames_all, $
    /ignore_case, /include_all)
  if wdc_sites[0] eq '' then return
  nsites = n_elements(wdc_sites)


  for i=0, nsites-1 do begin

     if(~keyword_set(level)) then begin
        if strlowcase(wdc_sites[i]) eq 'dst' or $
           strlowcase(wdc_sites[i]) eq 'ae' then begin
           level_in = ['final','provisional']
        endif else begin
           level_in = 'final'
        endelse
     endif else level_in = level


     if(~keyword_set(resolution)) then resolution_in = 'min' $
     else resolution_in = resolution

     if strlowcase(wdc_sites[i]) eq 'sym' or $
        strlowcase(wdc_sites[i]) eq 'asy' then begin
        resolution_in = 'min'
     endif else if strlowcase(wdc_sites[i]) eq 'dst' then begin
        resolution_in = 'hour'
     endif


     for j=0, n_elements(level_in)-1 do begin
        if resolution_in eq 'hour' or $
           resolution_in eq 'hr' then begin
           iug_load_gmag_wdc_wdchr, $
              site = wdc_sites[i], $
              trange = trange, $
              level = level_in[j], $
              verbose = verbose, $
              addmaster = addmaster, $
              downloadonly = downloadonly, $
              no_download = no_download, $
              _extra = _extra
        endif else if resolution_in eq 'min' then begin
           iug_load_gmag_wdc_wdcmin, $
              site = wdc_sites[i], $
              trange = trange, $
              level = level_in[j], $
              verbose = verbose, $
              addmaster = addmaster, $
              downloadonly = downloadonly, $
              no_download = no_download, $
              _extra = _extra
        endif
     endfor

  end

end
