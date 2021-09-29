;+
; PROCEDURE: erg_load_gmag_isee_induction
;
; PURPOSE:
;   To load ISEE induction magnetometer data from the ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_gmag_stel_induction, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'sta']
;           or a single string delimited by spaces, e.g., 'msr sta'.
;           Sites: ath mgd ptk msr sta gak kap zgn
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;   frequency_dependent = get frequecy-dependent sensitivity and phase difference
;            (frequency [Hz], sensitivity (H,D,Z) [V/nT], and phase_difference (H,D,Z) [deg])
;   /time_pulse, get time pulse
;
; EXAMPLE:
;   erg_load_gmag_isee_induction, site='msr sta', $
;         trange=['2008-02-28/00:00:00','2008-02-28/02:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/magne/
;
; HISTORY:
;       2011-01-23: Originally written by Y. Miyashita
;                   ERG-Science Center, ISEE, Nagoya Univ.
;                   erg-sc-core at isee.nagoya-u.ac.jp
;
;       2017-07-07: Satoshi Kurita, ISEE, Nagoya U.
;                   1. New stations (GAK, KAP, ZGN) are included
;                   2. Use spd_download instead of file_retrieve
;
; $LastChangedDate: 2020-12-08 06:04:52 -0800 (Tue, 08 Dec 2020) $
; $LastChangedRevision: 29445 $
;
;-

pro erg_load_gmag_isee_induction, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip, $
        frequency_dependent=frequency_dependent, time_pulse=time_pulse

;*** site codes ***
;--- aliases
if(n_elements(site) ne 0) then begin
  site=strjoin(site, ' ')
  site=strsplit(strlowcase(site), ' ', /extract)
endif

;--- all sites (default)
site_code_all = strsplit( $
  'ath gak hus kap lcl mgd msr nai ptk rik sta zgn', $
  ' ', /extract)

;--- check site codes
if(n_elements(site) eq 0) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if(site_code[0] eq '') then return
dprint, site_code

;*** keyword set ***
if(~keyword_set(downloadonly)) then downloadonly=0
if(~keyword_set(no_server)) then no_server=0
if(~keyword_set(no_download)) then no_download=0

if(keyword_set(time_pulse)) then varformat='db_dt *time_pulse*' else varformat='db_dt'

;*** other variables ***
if(arg_present(frequency_dependent)) then $
  frequency_dependent=replicate({site_code:' ', nfreq:0, $
      frequency:fltarr(64), sensitivity:dblarr(64,3), phase_difference:dblarr(64,3)}, n_elements(site_code))

;*** load CDF ***
;--- Create (and initialize) a data file structure
source = file_retrieve(/struct)

;--- Set parameters for the data file class
source.local_data_dir  = root_data_dir() + 'ergsc/'
source.remote_data_dir = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/'

;--- Download parameters
if(keyword_set(downloadonly)) then source.downloadonly=1
if(keyword_set(no_server))    then source.no_server=1
if(keyword_set(no_download))  then source.no_download=1

for i=0,n_elements(site_code)-1 do begin
  ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
  ;pathformat = 'ground/geomag/stel/induction/SSS/YYYY/stel_induction_SSS_YYYYMMDDHH_v??.cdf'

  ;--- Generate the file paths by expanding wilecards of date/time
  ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
  ;relpathnames = file_dailynames(file_format=pathformat)

  file_format  = 'ground/geomag/isee/induction/'+site_code[i]+'/YYYY/MM/' $
                + 'isee_induction_'+site_code[i]+'_YYYYMMDDhh_v??.cdf'

  relpathnames=file_dailynames(file_format=file_format,trange=trange,/hour_res)

  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir,$
                      local_path=source.local_data_dir, _extra=source, /last_version)

  ;--- Download the designated data files from the remote data server
  ;    if the local data files are older or do not exist.

  filestest=file_test(files)

  if(total(filestest) ge 1) then begin
    files=files(where(filestest eq 1))

    ;--- Load data into tplot variables
    if(downloadonly eq 0) then begin
      cdf2tplot, file=files, verbose=source.verbose, $
                 prefix='isee_induction_', suffix='_'+site_code[i], varformat=varformat


    if (arg_present(frequency_dependent)) then begin

          dprint, 'Getting frequency-dependent sensitivity and phase difference'

          cdfid=cdf_open(files[0])
          cdf_control, cdfid, get_var_info=cdfcont, variable='frequency', /zvariable

          ffreq=fltarr(cdfcont.maxrec+1) & ssensi=dblarr(3,cdfcont.maxrec+1) & pphase=dblarr(3,cdfcont.maxrec+1)

          cdf_varget, cdfid, 'frequency',        ffreq,  rec_count=cdfcont.maxrec+1
          cdf_varget, cdfid, 'sensitivity',      ssensi, rec_count=cdfcont.maxrec+1
          cdf_varget, cdfid, 'phase_difference', pphase, rec_count=cdfcont.maxrec+1

          frequency_dependent[i].site_code=site_code[i]
          frequency_dependent[i].nfreq=cdfcont.maxrec+1
          frequency_dependent[i].frequency[0:cdfcont.maxrec]=ffreq[0:cdfcont.maxrec]
          frequency_dependent[i].sensitivity[0:cdfcont.maxrec,0:2]=transpose(ssensi[0:2,0:cdfcont.maxrec])
          frequency_dependent[i].phase_difference[0:cdfcont.maxrec,0:2]=transpose(pphase[0:2,0:cdfcont.maxrec])

          cdf_close, cdfid

    endif

      ;--- time clip
    if(keyword_set(timeclip)) then begin
       get_timespan, tr & tmspan=time_string(tr)
      time_clip, 'isee_induction_db_dt_'+site_code[i], tmspan[0], tmspan[1], /replace
    endif

    if not keyword_set(time_pulse) then del_data, 'isee_induction_time_pulse_'+site_code[i]

      ;--- Labels
    options, 'isee_induction_db_dt_'+site_code[i], labels=['dH/dt','dD/dt','dZ/dt'], labflag=1, colors=[2,4,6]

    ;--- print PI info and rules of the road
    ;if(i eq n_elements(site_code)-1) then begin
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
      print, 'Rules of the Road for ISEE Induction Magnetometer Data Use:'
      ;print, gatt.text
      for igatt=0, n_elements(gatt.text)-1 do print_str_maxlet, gatt.text[igatt], 70
      print, ''
      print, gatt.LINK_TEXT, ' '
      print, '**********************************************************************'
      print, ''
    ;endif
  endif
  endif
endfor   ; end of for loop of i

;---
return
end
