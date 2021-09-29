;+
; PROCEDURE: ERG_LOAD_ISEE_VLF
;
; PURPOSE:
;   To load VLF spectrum data obtained by ISEE ELF/VLF network from the ISEE ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_isee_vlf, site='ath',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['ath', 'kap']
;           or a single string delimited by spaces, e.g., 'ath kap'.
;           Available sites as of July, 2017 : ath, kap, gak, ist, mam
;   downloadonly : if set, then only download the data, do not load it into variables.
;   no_server : use only files which are online locally.
;   no_download : use only files which are online locally. (Identical to no_server keyword.)
;   trange : Time range of interest  (2 element array).
;   timeclip :  if set, then data are time clipped.
;
;   cal_gain : if set, frequency-dependent gain of the antenna system is calibrated.
;              The unit of gain G(f) is V/T, and calibrated spectral power P(f)
;              at frequecy f is computed as
;
;               P(f) = S(f)/ (G(f)^2) [nT^2/Hz],
;
;              where S(f) is uncaibrated spectral power in unit of V^2/Hz.
;
; EXAMPLE:
;   erg_load_isee_vlf, site='ath', $
;         trange=['2015-03-17/00:00:00','2015-03-17/02:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/vlf/
;
; HISTORY:
;        2016-02-21 : Initial release by Yoshi Miyoshi(ERG-Science Center, ISEE, Nagoya Univ.)
;        2017-07-07 : Modified by Satoshi Kurita (ISEE, Nagoya Univ., kurita at isee.nagoya-u.ac.jp)
;
; $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
; $LastChangedRevision: 27922 $
;
;-

pro erg_load_isee_vlf, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip,cal_gain=cal_gain

;*** site codes ***
site_code_all = strsplit('ath gak hus ist kap mam nai', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

;*** keyword set ***
if(not keyword_set(downloadonly)) then downloadonly=0
if(not keyword_set(no_server)) then no_server=0
if(not keyword_set(no_download)) then no_download=0

;*** load CDF ***
;--- Create (and initialize) a data file structure
source = file_retrieve(/struct)

;--- Set parameters for the data file class
source.local_data_dir  = root_data_dir() + 'ergsc/'
source.remote_data_dir = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/'

;--- Download parameters
if keyword_set(downloadonly) then source.downloadonly=1
if keyword_set(no_server)    then source.no_server=1
if keyword_set(no_download)  then source.no_download=1

for i=0,n_elements(site_code)-1 do begin
  ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
  ;pathformat = 'ground/vlf/SSS/YYYY/isee_vlf_SSS_YYYYMMDD_v??.cdf'

  ;--- Generate the file paths by expanding wilecards of date/time
  ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"

  file_format  = 'ground/vlf/'+site_code[i]+'/YYYY/MM' $
               + '/isee_vlf_'+site_code[i]+'_YYYYMMDDhh_v??.cdf'

  relpathnames=file_dailynames(file_format=file_format,/hour_res)

  ;--- Download the designated data files from the remote data server
  ;    if the local data files are older or do not exist.

  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir,$
                      local_path=source.local_data_dir, _extra=source, /last_version)

  filestest=file_test(files)

  if(total(filestest) ge 1) then begin
    files=files(where(filestest eq 1))

    prefix='isee_vlf_'+site_code[i]+'_'

    ;--- Load data into tplot variables
    if(downloadonly eq 0) then begin
      cdf2tplot, file=files, verbose=source.verbose, $
                 prefix=prefix

    ;--- time clip
    if(keyword_set(timeclip)) then begin
        get_timespan, tr & tmspan=time_string(tr)
        time_clip, prefix+'_*', tmspan[0], tmspan[1], /replace
      endif

    endif

    zlim,prefix+['ch1','ch2'],0.0,0.0,1
    options,prefix+['ch1','ch2'],'ytitle','Frequency [Hz]'
    options,prefix+['ch1','ch2'],'ysubtitle',''
    if not keyword_set(cal_gain) then options,prefix+['ch1','ch2'],'ztitle','V^2/Hz'

    if (keyword_set(cal_gain)) then begin

          dprint, 'Calibrating the gain of VLF antenna system...'

          cdfid=cdf_open(files[0])

          cdf_varget, cdfid, 'freq_vlf',ffreq
          cdf_varget, cdfid, 'amplitude_cal_vlf_ch1',gain_ch1
          cdf_varget, cdfid, 'amplitude_cal_vlf_ch2',gain_ch2

          cdf_close, cdfid

          gain_ch1_mod=interpol(gain_ch1[1,*],gain_ch1[0,*],ffreq)*1e-9
          gain_ch2_mod=interpol(gain_ch2[1,*],gain_ch2[0,*],ffreq)*1e-9

          get_data,prefix+'ch1',data=tmp1
          get_data,prefix+'ch2',data=tmp2

          for ifq=0.,n_elements(ffreq)-1 do begin

            tmp1.y[*,ifq]=tmp1.y[*,ifq]/gain_ch1_mod[ifq]/gain_ch1_mod[ifq]
            tmp2.y[*,ifq]=tmp2.y[*,ifq]/gain_ch2_mod[ifq]/gain_ch2_mod[ifq]

          endfor

          store_data,prefix+'ch1',data=tmp1
          store_data,prefix+'ch2',data=tmp2

          options,prefix+['ch1','ch2'],'ztitle','nT^2/Hz'

    endif

    ;--- print PI info and rules of the road
    if(i eq n_elements(site_code)-1) then begin
      gatt = cdf_var_atts(files[0])

      print_str_maxlet, ' '
      print, '**********************************************************************'
      ;print, gatt.project
      print, gatt.Logical_source_description
      print, ''
      ;print, 'Information about ', gatt.Station_code
      print, 'PI: ', gatt.PI_name
      ;print, 'Affiliation: ', gatt.PI_affiliation
      print, 'Affiliation:'
      print_str_maxlet, gatt.PI_affiliation, 70
      print, ''
      print, 'Rules of the Road for ISEE VLF Data Use:'
      ;print, gatt.text
      for igatt=0, n_elements(gatt.text)-1 do print_str_maxlet, gatt.text[igatt], 70
      print, ''
      print, gatt.LINK_TEXT, ' '
      print, '**********************************************************************'
      print, ''
    endif

  endif
endfor   ; end of for loop of i

;---
return
end