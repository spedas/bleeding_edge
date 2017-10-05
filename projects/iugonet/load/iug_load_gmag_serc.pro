;+
;PROCEDURE: IUG_LOAD_GMAG_SERC,
;  iug_load_gmag_serc, site = site, datatype = datatype, $
;                      trange = trange, verbose = verbose, $
;                      downloadonly = downloadonly
;PURPOSE:
;  This procedure allows you to download and plot MAGDAS 1-minute
;  averaged magnetometer data on TDAS.
;  It is currently applicable only to MAGDAS 1-minute averaged
;  data observed during recent WHI campaign (from March 20 to April 16, 2008).
;  You can see more details about this data:
;  http://magdas.serc.kyushu-u.ac.jp/whi/index.php
;  Future data release is a work in progress.
;
;KEYWORDS:
;  site  = Observatory name.  For example, serc_load_gmag_sample, site = 'kuj'.
;          The default is 'all', i.e., load all available stations.
;  datatype = The type of data to be loaded.  In this sample
;             procedure, there is only one option, the default value of 'mag'.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /verbose, if set, then output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;EXAMPLE:
;  iug_load_gmag_serc, site = 'kuj', trange = ['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
;CODE:
;  Shuji Abe
;
;CHANGELOG:
;  07-April-2010, abeshu, test release.
;  08-April-2010, abeshu, minor update.
;  14-November-2010, abeshu, update.
;  08-March-2011, abeshu, update.
;  01-May-2011, abeshu, modify title and ylabel on tdas plot.
;  09-May-2011, abeshu, modify the rules of the road.
;  12-Jan-2012, abeshu, add default colors.
;  21-Jan-2012, abeshu, change default color of total magnetic field.
;
;ACKNOWLEDGMENT:
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-05-19 11:44:55 -0700 (Fri, 19 May 2017) $
; $LastChangedRevision: 23337 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/load/iug_load_gmag_serc.pro $
;-

;**************************
;***** Procedure name *****
;**************************
pro iug_load_gmag_serc, site = site, datatype = datatype, $
                        trange = trange, verbose = verbose, $
                        downloadonly = downloadonly


;*************************
;***** Keyword check *****
;*************************
; verbose
if ~keyword_set(verbose) then verbose=0

; data type
if ~keyword_set(datatype) then datatype='mag'

; validate datatype
vns=['mag']
if size(datatype,/type) eq 7 then begin
  datatype=ssl_check_valid_name(datatype,vns, $
                                /ignore_case, /include_all)
  if datatype[0] eq '' then return
endif else begin
  message,'DATATYPE must be of string type.',/info
  return
endelse

; site
; list of sites
vsnames = 'anc asb cmd cst dav daw dvs eus her hob ilr kuj lkw mcq ' + $
          'mgd mlb mnd mut onw prp ptk roc sma tir twv wad yap'
vsnames_all = strsplit(vsnames, ' ', /extract)

; validate sites
if(keyword_set(site)) then site_in = site else site_in = 'all'
magdas_sites = ssl_check_valid_name(site_in, vsnames_all, $
                                    /ignore_case, /include_all)
if magdas_sites[0] eq '' then return

; number of valid sites
nsites = n_elements(magdas_sites)

; acknowlegment string (use for creating tplot vars)
acknowledgstring = 'Scientists who want to engage in collaboration with SERC ' + $
                   'should contact the project leader of MAGDAS/CPMN ' + $
                   'observations, Prof. Dr. K. Yumoto, Kyushu Univ., who will ' + $
                   'organize such collaborations.' + $
                   'For detail, please see the Rules of the Road for MAGDAS/CPMN Data Use.'


;*************************************************************************
;***** Download files, read data, and create tplot vars at each site *****
;*************************************************************************
;=================================
;=== Loop on downloading files ===
;=================================
; make remote path, local path, and download files
for i=0, nsites-1 do begin
  ; define file names
  pathformat= strupcase(strmid(magdas_sites[i],0,3)) + '/Min/YYYY/' + $
              strupcase(strmid(magdas_sites[i],0,3)) + '_MIN_YYYYMMDD0000.mgd'
  relpathnames = file_dailynames(file_format=pathformat, trange=trange)

  ; define remote and local path information
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir = root_data_dir() + 'iugonet/serc/'
  source.remote_data_dir = 'http://magdas.serc.kyushu-u.ac.jp/whi/data/'

  ; download data
  local_files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
  
  ; if downloadonly set, go to the top of this loop
  if keyword_set(downloadonly) then continue

  ;===================================
  ;=== Loop on reading MAGDAS data ===
  ;===================================
  for j=0,n_elements(local_files)-1 do begin
    file = local_files[j]

    if file_test(/regular,file) then begin
      dprint,'Loading MAGDAS data file: ', file
      fexist = 1
    endif else begin
      dprint,'MAGDAS data file ',file,' not found. Skipping'
      continue
    endelse

    ; create base time
    year = (strmid(relpathnames[j],21,4))
    month = (strmid(relpathnames[j],25,2))
    day = (strmid(relpathnames[j],27,2))
    basetime = time_double(year+'-'+month+'-'+day)

    ; open file
    openr, lun, file, /get_lun

    ; seek delimiter
    buf = bytarr(1, 1)
    while (buf ne 26) do begin
      readu, lun, buf
    end
    readu, lun, buf

    ; read data
    rdata = fltarr(7, 1440)
    readu, lun, rdata
    rdata = transpose(rdata)

    ; close file
    free_lun, lun

    ; append data and time index
    append_array, databuf, rdata
    append_array, timebuf, basetime + dindgen(1440)*60d
  endfor
  
  ;=======================================
  ;=== Loop on creating tplot variable ===
  ;=======================================
  if size(databuf,/type) eq 4 then begin
    ; tplot variable name
    tplot_name = 'magdas_mag_' + strlowcase(strmid(magdas_sites[i],0,3))
  
    ; for bad data
    wbad = where(finite(databuf) gt 99999, nbad)
    if nbad gt 0 then databuf[wbad] = !values.f_nan

    ; default limit structure
    dlimit=create_struct('data_att',create_struct('acknowledgment', acknowledgstring, $
                                                  'PI_NAME', 'K. Yumoto'))

    ; store data to tplot variable
    databuf=databuf(*,0:3)
    store_data, tplot_name, data={x:timebuf, y:databuf}, dlimit=dlimit

    ; add options
    options, tplot_name, labels=['H','D','Z','F'] , colors=[2,4,6,0],$
                         ytitle = 'MAGDAS ' + strupcase(strmid(magdas_sites[i],0,3)), $
                         ysubtitle = '[nT]'
                         ;title = 'SERC MAGDAS magnetometer'
  endif

  ; clear data and time buffer
  databuf = 0
  timebuf = 0

; go to next site
endfor


;******************************************
;***** Display additional information *****
;******************************************
print, ''
print, 'Rules of the Road for MAGDAS/CPMN Data Use:'
print, ''
print, 'The Data Citation Rules of the MAGDAS Project are based on "ULTIMA'
print, 'Memorandum of Understanding for Use of Geomagnetic Data"(in progress).'
print, 'ULTIMA (http://www.serc.kyushu-u.ac.jp/ultima/ultima.html)'
print, 'was established on 17 November 2006.
print, 'It is an international consortium of ground-based magnetometer arrays.'
print, ''
print, 'Scientists who want to engage in collaboration with SERC '
print, 'should contact the project leader of MAGDAS/CPMN '
print, 'observations, Prof. Dr. K. Yumoto, Kyushu Univ., who will '
print, 'organize such collaborations.'
print, ''
print, 'There is a possibility that the PI of MAGDAS will arrange offers'
print, 'so that there is less overlapping of themes between MAGDAS research groups'
print, ''
print, 'Before you use MAGDAS/CPMN data for your papers,'
print, 'you must agree to the following points;'
print, ''
print, '  1. Before you submit your paper, you must contact the PI'
print, '     (Prof. K. Yumoto: yumoto@serc.kyushu-u.ac.jp) and'
print, '     discuss authorship.'
print, '  2. When you submit your paper after doing the above item 1, you must mention'
print, '     the source of the data in the acknowledgment section of your paper.'
print, '  3. In general, you must use the following references:'
print, '    1. Yumoto, K., and the 210MM Magnetic Observation Group, The STEP'
print, '       210 magnetic meridian network project, J. Geomag. Geoelectr.,'
print, '       48, 1297-1310., 1996.'
print, '    2. Yumoto, K. and the CPMN Group, Characteristics of Pi 2 magnetic'
print, '       pulsations observed at the CPMN stations: A review of the STEP'
print, '       results, Earth Planets Space, 53, 981-992, 2001.'
print, '    3. Yumoto K. and the MAGDAS Group, MAGDAS project and its application'
print, "       for space weather, Solar Influence on the Heliosphere and Earth's"
print, '       Environment: Recent Progress and Prospects, Edited by N. Gopalswamy'
print, '       and A. Bhattacharyya, ISBN-81-87099-40-2, pp. 309-405, 2006.'
print, '    4. Yumoto K. and the MAGDAS Group, Space weather activities at SERC' 
print, '       for IHY: MAGDAS, Bull. Astr. Soc. India, 35, pp. 511-522, 2007.'
print, '  4. In all circumstances, if anything is published you must send'
print, '     a hardcopy to the following address:'
print, ''
print, '    Prof. Dr. Kiyohumi Yumoto'
print, '    PI of MAGDAS/CPMN Project'
print, '    Director of Space Environment Research Center,'
print, '    Kyushu University 53'
print, '    6-10-1 Hakozaki, Higashi-ku Fukuoka 812-8581, JAPAN'
print, '    TEL/FAX:+81-92-642-4403, e-mail: yumoto@serc.kyushu-u.ac.jp'
print, ''
print, 'Note:'
print, 'This procedure is currently applicable only to MAGDAS 1-minute averaged'
print, 'magnetometer data observed during recent WHI campaign'
print, '(from March 20 to April 16, 2008).'
print, 'You can see more details about this data:'
print, 'http://magdas.serc.kyushu-u.ac.jp/whi/index.php'
print, 'Future data release is a work in progress.'

end
