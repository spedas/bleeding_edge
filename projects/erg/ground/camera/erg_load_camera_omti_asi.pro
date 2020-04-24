;+
; PROCEDURE: erg_load_camera_omti_asi
;
; PURPOSE:
;   To load the OMTI ASI data from the STEL ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_camera_omti_asi, site='sgk'.
;           The default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['sgk', 'sta']
;           or a single string delimited by spaces, e.g., 'sgk sta'.
;           Sites: abu ath drw eur gak hlk hus isg ist ith kap ktb mgd nai nyr ptk rik rsb sgk sta syo trs yng
;   wavelength = Wavelength in Angstrom, i.e., 5577, 6300, 7200, 7774, 5893, etc.
;                The default is 5577. This can be an array of integers, e.g., [5577, 6300]
;                or strings, e.g., '5577', '5577 6300', and ['5577', '6300'].
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;
; EXAMPLE:
;   erg_load_camera_omti_asi, site='sgk', wavelength=5577, trange=['2012-01-01/00:00:00','2012-01-02/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/omti/
;
; HISTORY:
; 2013-03-28: Initial release by Y. Miyashita, Mar 28, 2013
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
; 2017-09-18: Satoshi Kurita, ISEE, Nagoya U. (kurita at isee.nagoya-u.ac.jp)
;             1. New stations (GAK, KAP, NYR, HUS) are included
;             2. Use spd_download instead of file_retrieve
;
; 2020-03-25: Atsuki Shinbori, ISEE, Nagoya U. (shinbori at isee.nagoya-u.ac.jp)
;             1. New stations (ABU, EUR, HLK, IST, and NAI) are included
;             
;   $LastChangedDate: 2020-04-23 14:59:10 -0700 (Thu, 23 Apr 2020) $
;   $LastChangedRevision: 28604 $
;-

pro erg_load_camera_omti_asi, $
        site=site, wavelength=wavelength, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

;*** site codes ***
;--- all sites (default)
site_code_all = strsplit( $
  'abu ath drw eur gak hlk hus isg ist ith kap ktb mgd nai nyr ptk rik rsb sgk sta syo trs yng', $
  ' ', /extract)

;--- check site codes
if(n_elements(site) eq 0) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if(site_code[0] eq '') then return
print, site_code

;*** wave length ***
if(n_elements(wavelength) eq 0) then wavelength=[5577]

if(size(wavelength,/type) ne 7) then wavelengthc=string(wavelength, format='(i4.4)') $
                                else wavelengthc=wavelength

wavelengthc=strjoin(wavelengthc, ' ')
wavelengthc=strsplit(strlowcase(wavelengthc), ' ', /extract)

;*** keyword set ***
if(~keyword_set(downloadonly)) then downloadonly=0
if(~keyword_set(no_server)) then no_server=0
if(~keyword_set(no_download)) then no_download=0

;*** load CDF ***
;--- Create (and initialize) a data file structure
source = file_retrieve(/struct)

;--- Set parameters for the data file class
source.local_data_dir  = root_data_dir() + 'ergsc/'
source.remote_data_dir = 'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/'

;--- Download parameters
if(keyword_set(downloadonly)) then source.downloadonly=1
if(keyword_set(no_server))    then source.no_server=1
if(keyword_set(no_download))  then source.no_download=1

for i=0, n_elements(site_code)-1 do begin
  for j=0, n_elements(wavelengthc)-1 do begin
    ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
    ;pathformat = 'ground/camera/omti/asi/SSS/YYYY/MM/DD/omti_asi_cCF_SSS_WWWW_YYYYMMDDHH_v??.cdf'

    ;--- Generate the file paths by expanding wilecards of date/time
    ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
    ;relpathnames = file_dailynames(file_format=pathformat)

    file_format  = 'ground/camera/omti/asi/'+site_code[i]+'/'+$
                  'YYYY/MM/DD/omti_asi_c??_'+site_code[i]+'_'+wavelengthc[j]+$
                  '_YYYYMMDDhh_v??.cdf'

    relpathnames=file_dailynames(file_format=file_format,trange=trange,/hour_res)

    dprint,relpathnames

    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, $
                        local_path=source.local_data_dir, _extra=source, /last_version)
    filestest=file_test(files)

    if(total(filestest) ge 1) then begin
      files=files(where(filestest eq 1))

      ;--- Load data into tplot variables
      if(downloadonly eq 0) then begin
        cdf2tplot, file=files, verbose=source.verbose, $
                   prefix='omti_asi_'+site_code[i]+'_'+wavelengthc[j]+'_', suffix='', $
                   varformat='image_* cloud'

        ;--- Rename
        if(tnames('omti_asi_'+site_code[i]+'_cloud') eq 'omti_asi_'+site_code[i]+'_cloud') then $
          del_data, 'omti_asi_'+site_code[i]+'_cloud'
        store_data, 'omti_asi_'+site_code[i]+'_'+wavelengthc[j]+'_cloud', newname='omti_asi_'+site_code[i]+'_cloud'

        ;--- time clip
        if(keyword_set(timeclip)) then begin
          get_timespan, tr & tmspan=time_string(tr)
          ;time_clip, 'omti_asi_'+site_code[i]+'_'+wavelengthc[j]+'_image_*', tmspan[0], tmspan[1], /replace
          time_clip, 'omti_asi_'+site_code[i]+'_*', tmspan[0], tmspan[1], /replace
        endif

        ;---  Reverse the order of the second subscript (row) of the image data
        ;     not to make an upside-down image with the tvscl procedure.
        get_data,   'omti_asi_'+site_code[i]+'_'+wavelengthc[j]+'_image_raw', data=imagedata
        store_data, 'omti_asi_'+site_code[i]+'_'+wavelengthc[j]+'_image_raw', $
                    data={x:imagedata.x, y:reverse(imagedata.y[*,*,*], 3)}

        ;--- Missing data -1.e+31 --> NaN
        tclip, 'omti_asi_'+site_code[i]+'_'+wavelengthc[j]+'_image_*', -1e+6, 1e+6, /overwrite
        tclip, 'omti_asi_'+site_code[i]+'_cloud', -1, 9, /overwrite
      endif

      ;--- print PI info and rules of the road
      ;if((i eq n_elements(site_code)-1) and (j eq n_elements(wavelengthc)-1)) then begin
        gatt = cdf_var_atts(files[0])

        print_str_maxlet, ' '
        print, '**********************************************************************'
        ;print, gatt.project
        print, gatt.Logical_source_description
        print, ''
        ;print, 'Information about ', gatt.Station_code
        print, 'PI: ', gatt.PI_name
        ;print, 'Affiliation: ', gatt.PI_affiliation
        ;print, 'Affiliation:'
        print_str_maxlet, gatt.PI_affiliation, 70
        print, ''
        print, 'Rules of the Road for OMTI ASI Data Use:'
        ;print, gatt.text
        for igatt=0, n_elements(gatt.text)-1 do print_str_maxlet, gatt.text[igatt], 70
        print, ''
        print, gatt.LINK_TEXT, ' '
        print, '**********************************************************************'
        print, ''
      ;endif
    endif
  endfor   ; end of for loop of j
endfor   ; end of for loop of i

;---
return
end
