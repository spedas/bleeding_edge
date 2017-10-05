;+
; PROCEDURE: erg_load_gmag_stel_fluxgate
;
; PURPOSE:
;   To load the STEL fluxgate geomagnetic data from the STEL ERG-SC site 
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_gmag_stel_fluxgate, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'kag']
;           or a single string delimited by spaces, e.g., 'msr kag'.
;           Sites for 1 sec data:  
;              msr rik kag ktb
;           Sites for 1 min/h data:
;              msr rik kag ktb mdm tew
;   datatype = Time resolution. '1sec' for 1 sec', '1min' for 1 min, and '1h' for 1 h.
;              The default is 'all'.  If you need two of them, set to 'all'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;
; EXAMPLE:
;   erg_load_gmag_stel_fluxgate, site='msr kag', datatype='1min', $
;       trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/magne/
;       and http://www1.osakac.ac.jp/crux/ (for mdm and tew).
;
; Written by: Y. Miyashita, Jun 19, 2013
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2017-05-19 10:27:24 -0700 (Fri, 19 May 2017) $
;   $LastChangedRevision: 23335 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/geomag/erg_load_gmag_stel_fluxgate.pro $
;-

pro erg_load_gmag_stel_fluxgate, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

;*** site codes ***
;--- all sites (default)
site_code_all = strsplit( $
   'msr rik kag ktb mdm tew', $
  ' ', /extract)

;--- check site codes
if(n_elements(site) eq 0) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if(site_code[0] eq '') then return
print, site_code

;*** time resolution ***
tres_all=strsplit('1sec 1min 1h', ' ', /extract)
if(n_elements(datatype) eq 0) then datatype='all'

datatype=strjoin(datatype, ' ')
datatype=strsplit(strlowcase(datatype), ' ', /extract)
  if(where(datatype eq '1s')  ne -1) then datatype[where(datatype eq '1s')]='1sec'
  if(where(datatype eq '1m')  ne -1) then datatype[where(datatype eq '1m')]='1min'
  if(where(datatype eq '1hr') ne -1) then datatype[where(datatype eq '1hr')]='1h'

datatype=ssl_check_valid_name(datatype, tres_all, /ignore_case, /include_all)
if(datatype[0] eq '') then return
print,datatype

case strlowcase(strjoin(datatype,' ')) of
  '1sec': begin
            tres=['1sec', '',     '']   & nfloads=0 & nfloade=0
          end
  '1min': begin
            tres=['',     '1min', '']   & nfloads=1 & nfloade=1
          end
  '1h':   begin
            tres=['',     '',     '1h'] & nfloads=1 & nfloade=1
          end
  '1sec 1min':  begin
            tres=['1sec', '1min', '']   & nfloads=0 & nfloade=1
          end
  '1sec 1h':  begin
            tres=['1sec', '',     '1h'] & nfloads=0 & nfloade=1
          end
  '1min 1h':  begin
            tres=['',     '1min', '1h'] & nfloads=1 & nfloade=1
          end
  '1sec 1min 1h':  begin
            tres=['1sec', '1min', '1h'] & nfloads=0 & nfloade=1
          end
  else:   begin
;            nfloads=0 & nfloade=1
            return
          end
endcase

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

;--- Generate the file paths by expanding wilecards of date/time 
;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange) 

for i=0, n_elements(site_code)-1 do begin
  for j=nfloads, nfloade do begin
    case j of
      0: fres='1sec'
      1: fres='1min'
    endcase

    ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
    ;pathformat = 'ground/geomag/stel/fluxgate/'+fres+'/SSS/YYYY/stel_fluxgate_'+fres+'_SSS_YYYYMMDD_v??.cdf'

    ;--- Generate the file paths by expanding wilecards of date/time 
    ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
    ;relpathnames = file_dailynames(file_format=pathformat) 

    relpathnames  = 'ground/geomag/stel/fluxgate/'+fres+'/'+site_code[i]+'/'+relpathnames1 $
                  + '/stel_fluxgate_'+fres+'_'+site_code[i]+'_'+relpathnames2+'_v??.cdf'
    ;print,relpathnames

    ;--- Download the designated data files from the remote data server
    ;    if the local data files are older or do not exist. 
    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
    filestest=file_test(files)

    if(total(filestest) ge 1) then begin
      files=files(where(filestest eq 1))

      ;--- Load data into tplot variables
      if(downloadonly eq 0) then begin
        cdf2tplot, file=files, verbose=source.verbose, $
                   prefix='stel_fluxgate_', suffix='_'+site_code[i], varformat='*hdz_'+tres[where(tres[j:j*2] ne '')+j]+'*'

        for k=j, j*2 do begin
          if(tres[k] ne '') then begin
            ;--- Rename
            if(tnames('stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz') eq 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz') then $
              del_data, 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz'
            store_data, 'stel_fluxgate_hdz_'+tres[k]+'_'+site_code[i], newname='stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz'

            ;--- time clip
            if(keyword_set(timeclip)) then begin
              get_timespan, tr & tmspan=time_string(tr)
              time_clip, 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz', tmspan[0], tmspan[1], /replace
            endif

            ;--- Missing data -1.e+31 --> NaN
            tclip, 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz', -1e+4, 1e+4, /overwrite

            ;--- Labels
            options, 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz', labels=['H','D','Z'], labflag=1, colors=[2,4,6]
;            options, 'stel_fluxgate_mag_'+site_code[i]+'_'+tres[k]+'_hdz', labels=['Ch1','Ch2','Ch3'], labflag=1, colors=[2,4,6]
          endif
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
      print, 'Rules of the Road for STEL Fluxgate Data Use:'
      ;print, gatt.text
      for igatt=0, n_elements(gatt.text)-1 do print_str_maxlet, gatt.text[igatt], 70
      print, ''
      for igatt=0, n_elements(gatt.LINK_TEXT)-1 do $
        print, gatt.LINK_TEXT[igatt], ' ', gatt.HTTP_LINK[igatt]
      print, '**********************************************************************'
      print, ''
    endif
  endfor   ; end of for loop of j
endfor   ; end of for loop of i

;---
return
end
