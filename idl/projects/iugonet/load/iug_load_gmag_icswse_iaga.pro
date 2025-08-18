;+
;PROCEDURE: IUG_LOAD_GMAG_ICSWSE_IAGA,
;  iug_load_gmag_icswse_iaga, site = site, resolution = resolution, $
;                      trange = trange, verbose = verbose, $
;                      downloadonly = downloadonly, no_download = no_download, $
;                      no_server = no_server
;PURPOSE:
;  This procedure allows you to download and plot 1-second and 1-minute magnetometer data
;  produced by International Center for Space Weather Science and Education, Kyushu University, Japan,
;  written in IAGA 2002 data exchange format.
;
;KEYWORDS:
;  site  = Observatory name.  For example, iugo_load_gmag_icswse_iaga, site = 'aae'.
;          The default is 'all', i.e., load all available stations.
;  resolution = Time resolution. '1sec' for 1 second data, and '1min' for 1 minute data.
;             The default is 'all'.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /verbose, if set, then output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  /no_server, use only files which are online locally.
;  /no_download, use only files which are online locally. (Identical to no_server keyword.)
;
;EXAMPLE:
;  iug_load_gmag_icswse_iaga, site = 'aae', trange = ['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
;CODE:
;  Shuji Abe
;
;CHANGELOG:
;  08-April-2015, abeshu, initial release
;  07-February-2018, abeshu, update for official release
;  17-February-2018, abeshu, modified header reading
;
;ACKNOWLEDGMENT:
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/load/iug_load_gmag_icswse_iaga.pro $
;-

;**************************
;***** Procedure name *****
;**************************
pro iug_load_gmag_icswse_iaga, site = site, resolution = resolution, $
                        trange = trange, verbose = verbose, $
                        downloadonly = downloadonly, no_download = no_download, $
                        no_server = no_server


;*************************
;****** Initialize *******
;*************************
; download parameters
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_server) then no_server=0
if ~keyword_set(no_download) then no_download=0
if ~keyword_set(verbose) then verbose=0

; list of sites
vsnames = 'aab  asb  can  ckt  drb  gsi  ica  krt  lgz  mgd  onw  sbh  tir  zgn ' + $
         'abj  asw  cdo  cmd  dvs  her  ilr  ktn  lkw  mlb  prp  scn  twv ' + $
         'abu  bcl  ceb  dav  eus  hln  jrs  kuj  lsk  mnd  ptk  sma  wad ' + $
         'ama  bik  cgr  daw  ewa  hob  jyp  lag  lwa  mut  ptn  tgg  yak ' + $
         'anc  bkl  chd  des  fym  hvd  kpg  laq  mcq  nab  roc  tik  yap'
vsnames_all = strsplit(vsnames, ' ', /extract)

; time resolution
resolutionnames = '1sec 1min'
resolution_all = strsplit(resolutionnames, ' ', /extract)


;*************************
;***** Keyword check *****
;*************************
; validate resolution
if keyword_set(resolution) then resolution = resolution else resolution = 'all'
resolution = ssl_check_valid_name(resolution, resolution_all, /ignore_case, /include_all)
if resolution[0] eq '' then return

; validate sites
if keyword_set(site) then site_in = site else site_in = 'all'
kyumag_sites = ssl_check_valid_name(site_in, vsnames_all, /ignore_case, /include_all)
if kyumag_sites[0] eq '' then return

; number of valid resolutions and sites
nresolution = n_elements(resolution)
nsites = n_elements(kyumag_sites)

; define remote and local path information
source = file_retrieve(/struct)
source.verbose = verbose
source.local_data_dir = root_data_dir() + 'iugonet/icswse/magnetometer/iaga/'
source.remote_data_dir = 'http://data.icswse.kyushu-u.ac.jp/gmag/data/'

if keyword_set(downloadonly) then source.downloadonly=1
if keyword_set(no_server)    then source.no_server=1
if keyword_set(no_download)  then source.no_download=1

; acknowlegment string array
acknowledgstring = [ 'Scientists who want to engage in collaboration with ICSWSE', +$
'should contact the project leader of MAGDAS/CPMN', +$
'observations, Dr. Akimasa Yoshikawa, Kyushu Univ., who will', +$
'organize such collaborations.', +$
'There is a possibility that the PI of MAGDAS will arrange offers', +$
'so that there is less overlapping of themes between MAGDAS research groups', +$
'Before you use MAGDAS/CPMN data for your papers,', +$
'you must agree to the following points;', +$
' ', +$
' 1. Before you submit your paper, you must contact the PI', +$
'    (Dr. Akimasa Yoshikawa: yoshi@geo.kyushu-u.ac.jp) and', +$
'    discuss authorship.', +$
' 2. When you submit your paper after doing the above item 1, you must mention', +$
'    the source of the data in the acknowledgment section of your paper.', +$
' 3. In general, you must use the following references:', +$
'     1. Yumoto, K., and the 210MM Magnetic Observation Group, The STEP', +$
'        210 magnetic meridian network project, J. Geomag. Geoelectr.,', +$
'        48, 1297-1310., 1996.', +$
'     2. Yumoto, K. and the CPMN Group, Characteristics of Pi 2 magnetic', +$
'        pulsations observed at the CPMN stations: A review of the STEP', +$
'        results, Earth Planets Space, 53, 981-992, 2001.', +$
'     3. Yumoto K. and the MAGDAS Group, MAGDAS project and its application', +$
'        for space weather, Solar Influence on the Heliosphere and Earth''s', +$
'        Environment: Recent Progress and Prospects, Edited by N. Gopalswamy', +$
'        and A. Bhattacharyya, ISBN-81-87099-40-2, pp. 309-405, 2006.', +$
'     4. Yumoto K. and the MAGDAS Group, Space weather activities at SERC', +$
'        for IHY: MAGDAS, Bull. Astr. Soc. India, 35, pp. 511-522, 2007.', +$
' 4. In all circumstances, if anything is published you must send', +$
'    a hardcopy to the following address:', +$
' ', +$
'        Dr. Akimasa Yoshikawa', +$
'        PI of MAGDAS/CPMN Project', +$
'        International Center for Space Weather Science and Education,', +$
'        Kyushu University CE10', +$
'        744, Motooka, Nishi-ku, Fukuoka 819-0395, JAPAN', +$
'        TEL/FAX:+81-92-802-6240, e-mail: yoshi@geo.kyushu-u.ac.jp']


;*************************************************************************
;***** Download files, read data, and create tplot vars at each site *****
;*************************************************************************
;=================================
;=== Loop on downloading files ===
;=================================
; make remote path, local path, and download files
for n=0, nresolution-1 do begin
for i=0, nsites-1 do begin
  ; define file names
  pathformat= strupcase(strmid(kyumag_sites[i],0,3)) + '/' +  $
              strupcase(strmid(resolution[n],1,1)) + strlowcase(strmid(resolution[n],2,2)) + $
              '/YYYY/' + strupcase(strmid(kyumag_sites[i],0,3)) + 'YYYYMMDDp' + $
              strlowcase(strmid(resolution[n],1,3)) + '.' +  strlowcase(strmid(resolution[n],1,3))
  relpathnames = file_dailynames(file_format=pathformat, trange=trange)

  ; download data
  ;local_files = file_retrieve(relpathnames, _extra=source)
  local_files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, $
    local_path=source.local_data_dir, no_download=no_download)

  ; if downloadonly set, go to the top of this loop
  if keyword_set(downloadonly) then continue

  ;===================================
  ;=== Loop on reading KYUMAG data ===
  ;===================================
  for j=0,n_elements(local_files)-1 do begin
    file = local_files[j]

    if file_test(/regular,file) then begin
      dprint,'Loading KYUMAG data file: ', file
      fexist = 1
    endif else begin
      dprint,'KYUMAG data file ',file,' not found. Skipping'
      continue
    endelse

    ; create base time
    year = (strmid(relpathnames[j], 16,4))
    month = (strmid(relpathnames[j], 20,2))
    day = (strmid(relpathnames[j], 22,2))
    basetime = time_double(year+'-'+month+'-'+day)

    ; read header
    openr, lun, file, /get_lun
    str = ''
    header = {}
    for k=0,11 do begin
      readf, lun, str
      header = create_struct(header, strtrim(strmid(str,1,23)), strtrim(strmid(str,24,45)))
    endfor      
    
    optional = []
    start = 12
    while (strmid(str,0,4) ne 'DATE') do begin
      readf, lun, str
      optional = [optional, strtrim(strmid(str,0,69), 1)]
      start = start + 1
    endwhile
    header = create_struct(header, 'OPTIONAL', optional)

    free_lun, lun

    ; read data
    sdata = read_ascii(file, data_start=start)
    rdata = double(transpose(reform(sdata.field1[3:6,*])))
    
    ; append data and time index
    append_array, databuf, rdata
    if resolution[n] eq '1sec' then begin
      append_array, timebuf, basetime + dindgen(86400)*1d
    endif else begin
      append_array, timebuf, basetime + dindgen(1440)*60d
    endelse
    
  endfor

  ;=======================================
  ;=== Loop on creating tplot variable ===
  ;=======================================
  if size(databuf,/type) eq 5 then begin
    ; tplot variable name
    tplot_name = 'kyumag_mag_' + strlowcase(strmid(kyumag_sites[i],0,3)) + '_' + strlowcase(resolution[n]) + '_hdzf'
  
    ; for bad data
    wbad = where(databuf eq  99999.99, nbad)
    if nbad gt 0 then databuf[wbad] = !values.d_nan

    ; default limit structure
    header = create_struct(header,'acknowledgment', acknowledgstring, 'PI_NAME', 'A. Yoshikawa')
    dlimit = create_struct('data_att', create_struct(header))

    ; store data to tplot variable
    databuf=databuf(*,0:3)
    store_data, tplot_name, data={x:timebuf, y:databuf}, dlimit=dlimit

    ; add options
    options, tplot_name, labels=['H','D','Z', 'F'] , colors=[2,4,6,0],$
                         ytitle = 'KYUMAG ' + strupcase(strmid(kyumag_sites[i],0,3)) + ' ' + strupcase(resolution[n]), $
                         ysubtitle = '[nT]'
                         ;title = 'KYUMAG magnetometer'
  endif

  ; clear data and time buffer
  databuf = 0
  timebuf = 0

; go to next site
endfor
endfor

;******************************************
;***** Display additional information *****
;******************************************
print, ''
print, 'Rules of the Road for MAGDAS/CPMN Data Use:'
print, ''
for i = 0, n_elements(acknowledgstring)-1 do  print, acknowledgstring[i]
print, ''
print, 'For more information, see'
print, 'http://data.icswse.kyushu-u.ac.jp/'
print, ''

end
