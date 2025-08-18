;+
; PROCEDURE: erg_load_gmag_isee_fluxgate
;
; PURPOSE:
;   To load the STEL fluxgate geomagnetic data from the ISEE ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_gmag_isee_fluxgate, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'kag']
;           or a single string delimited by spaces, e.g., 'msr kag'.
;           Sites for 1 sec data:
;              msr rik kag ktb
;           Sites for 1 min/h data:
;              msr rik kag ktb mdm tew
;   datatype = Time resolution. '64hz' for 64 Hz', '1sec' for 1 sec', '1min' for 1 min, and '1h' for 1 h.
;              The default is 'all'.  If you need two of them, set to 'all'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;
; EXAMPLE:
;   erg_load_gmag_isee_fluxgate, site='msr kag', datatype='1min', $
;       trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/magne/
;       and http://www1.osakac.ac.jp/crux/ (for mdm and tew).
;
; HISTORY:
;       2013-07-19: Originally written by Y. Miyashita
;                   ERG-Science Center, ISEE, Nagoya Univ.
;                   erg-sc-core at isee.nagoya-u.ac.jp
;
;       2017-07-07: Satoshi Kurita, ISEE, Nagoya U.
;                   1. Use spd_download instead of file_retrieve
;                   2. renamed STEL to ISEE
;                   
;       2020-08-13: Atsuki Shinbori, ISEE, Nagoya U.
;                   1. Add the lcl station to the list of a site_code_all variable.
;                   2. Add '64hz' to the datatype for donwloading the lcl 64hz CDF data.
;                   
;       2021-10-12: Atsuki Shinbori, ISEE, Nagoya U.
;                   1. Modify rename of tplot variables.
;
;   $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
;   $LastChangedRevision: 31399 $
;-

pro erg_load_gmag_isee_fluxgate, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

;*** site codes ***
;--- all sites (default)
site_code_all = strsplit( $
   'msr rik kag ktb lcl mdm tew', $
  ' ', /extract)

;--- check site codes
if(n_elements(site) eq 0) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if(site_code[0] eq '') then return
print, site_code

;*** time resolution ***
tres_all=strsplit('64hz 1sec 1min 1h', ' ', /extract)
if(n_elements(datatype) eq 0) then datatype='all'

datatype=strjoin(datatype, ' ')
datatype=strsplit(strlowcase(datatype), ' ', /extract)
  if(where(datatype eq '64')  ne -1) then datatype[where(datatype eq '64')]='64hz'
  if(where(datatype eq '1s')  ne -1) then datatype[where(datatype eq '1s')]='1sec'
  if(where(datatype eq '1m')  ne -1) then datatype[where(datatype eq '1m')]='1min'
  if(where(datatype eq '1hr') ne -1) then datatype[where(datatype eq '1hr')]='1h'

datatype=ssl_check_valid_name(datatype, tres_all, /ignore_case, /include_all)
if(datatype[0] eq '') then return
print,datatype


;*** keyword set ***
if(~keyword_set(downloadonly)) then downloadonly=0
if(~keyword_set(no_server)) then no_server=0
if(~keyword_set(no_download)) then no_download=0

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

for i=0, n_elements(site_code)-1 do begin
  
  for m = 0, n_elements(datatype)-1 do begin
       datatype_index = where(tres_all eq datatype[m])
       append_array, datatype_index_app, datatype_index
  endfor

  for j=0, n_elements(datatype_index_app)-1 do begin
  
    fm = datatype_index_app[j]
    
    case fm of
      0:fres = '64hz'
      1:fres = '1sec'
      2:fres = '1min'
      3:fres = '1h'
    endcase 

    ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
    ;pathformat = 'ground/geomag/stel/fluxgate/'+fres+'/SSS/YYYY/stel_fluxgate_'+fres+'_SSS_YYYYMMDD_v??.cdf'

    ;--- Generate the file paths by expanding wilecards of date/time
    ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
    ;relpathnames = file_dailynames(file_format=pathformat)
    
    if (fres eq '64hz') then begin

      file_format = 'ground/geomag/isee/fluxgate/'+fres+'/'+site_code[i]+'/YYYY/MM' $
        + '/isee_fluxgate_'+fres+'_'+site_code[i]+'_YYYYMMDDhh_v??.cdf'      
      relpathnames=file_dailynames(file_format=file_format,trange=trange,/hour_res)
      
    endif 
    
    if fres eq '1h' then fres = '1min'
    if fres eq '1sec' or fres eq '1min' then begin
          file_format = 'ground/geomag/isee/fluxgate/'+fres+'/'+site_code[i]+'/YYYY' $
                        + '/isee_fluxgate_'+fres+'_'+site_code[i]+'_YYYYMMDD_v??.cdf'
          relpathnames=file_dailynames(file_format=file_format,trange=trange)

    endif    

    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir,$
      local_path=source.local_data_dir, _extra=source, /last_version)

    filestest=file_test(files)

    if(total(filestest) ge 1) then begin
      files=files(where(filestest eq 1))

      ;--- Load data into tplot variables
      if(downloadonly eq 0) then begin
        
        for k=0, n_elements(datatype_index_app)-1 do begin
           tres = datatype[k]
           cdf2tplot, file=files, verbose=source.verbose, $
                   prefix='isee_fluxgate_', suffix='_'+site_code[i], varformat='*hdz_'+tres+'*'
            ;--- Rename
            if(tnames('isee_fluxgate_hdz_'+tres+'_'+site_code[i]) eq 'isee_fluxgate_hdz_'+tres+'_'+site_code[i]) then $
               store_data, 'isee_fluxgate_hdz_'+tres+'_'+site_code[i], newname='isee_fluxgate_mag_'+site_code[i]+'_'+tres+'_hdz'
               del_data, 'isee_fluxgate_hdz_'+tres+'_'+site_code[i]

            ;--- time clip
            if(keyword_set(timeclip)) then begin
              get_timespan, tr & tmspan=time_string(tr)
              time_clip, 'isee_fluxgate_mag_'+site_code[i]+'_'+tres+'_hdz', tmspan[0], tmspan[1], /replace
            endif

            ;--- Missing data -1.e+31 --> NaN
            tclip, 'isee_fluxgate_mag_'+site_code[i]+'_'+tres+'_hdz', -1e+4, 1e+4, /overwrite

            ;--- Labels
            options, 'isee_fluxgate_mag_'+site_code[i]+'_'+tres+'_hdz', labels=['H','D','Z'], labflag=1, colors=[2,4,6]
            ;options, 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz', labels=['Ch1','Ch2','Ch3'], labflag=1, colors=[2,4,6]

            ;--- Delete no content tplot variables:
            get_data,'isee_fluxgate_mag_'+site_code[i]+'_'+tres+'_hdz', data =d
            res = size(d)
            if res[0] eq 0 then del_data, 'isee_fluxgate_mag_'+site_code[i]+'_'+tres+'_hdz'


        endfor
      endif

      ;--- print PI info and rules of the road
      gatt = cdf_var_atts(files[0])

      print_str_maxlet, ' '
      print, '**********************************************************************'
      ;print, gatt.project
      print, gatt.Logical_source_description
      print, ''
      print, 'Information about ', gatt.Station_code
      ;print, 'PI and Host PI(s): ', gatt.PI_name
      print, 'PI and Host PI(s):'
      print_str_maxlet, gatt.PI_name, 70
      print, ''
      ;print, 'Affiliations: ', gatt.PI_affiliation
      print, 'Affiliations:'
      ;print_str_maxlet, gatt.PI_affiliation, 70
      piaff=strsplit(gatt.PI_affiliation, '\([1-9]\)', /regex, /extract)


      for igatt=0, n_elements(piaff)-1 do begin
        if(n_elements(piaff) ge 2) then pinum='('+string(igatt+1,format='(i0)')+')' else pinum=''
        piaff[igatt]=pinum+piaff[igatt]
        print_str_maxlet, piaff[igatt], 70
      endfor

      print, ''
      print, 'Rules of the Road for ISEE Fluxgate Data Use:'
      ;print, gatt.text
      for igatt=0, n_elements(gatt.text)-1 do print_str_maxlet, gatt.text[igatt], 70
      print, ''
      for igatt=0, n_elements(gatt.LINK_TEXT)-1 do $
        print, gatt.LINK_TEXT[igatt], ' ', gatt.HTTP_LINK[igatt]
      print, '**********************************************************************'
      print, ''
    endif
  endfor   ; end of for loop of j
  
  ;----Clear buffer:
  datatype_index_app = 0
  
endfor   ; end of for loop of i

;---
return
end
