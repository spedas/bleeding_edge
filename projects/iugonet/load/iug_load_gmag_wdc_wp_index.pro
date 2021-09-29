;+
;PROCEDURE: iug_load_gmag_wdc_wp_index
;  iug_load_gmag_wdc_wp_index,trange = trange, $
;                      downloadonly = downloadonly, no_download = no_download, $
;                      no_server = no_server
;PURPOSE:
;  This procedure get Wp index and the number of available station.
;
;KEYWORDS:
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  /no_server, use only files which are online locally.
;  /no_download, use only files which are online locally. (Identical to no_server keyword.)
;
;EXAMPLE:
;  iug_load_gmag_wdc_wp_index, trange = ['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
;CODE:
;  Shun Imajo
;
;CHANGELOG:
;  21-March-2017, Imajo. first version.
;
;ACKNOWLEDGMENT:
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/load/iug_load_gmag_wdc_wp_index.pro $
;-

;**************************
;***** Procedure name *****
;**************************
pro iug_load_gmag_wdc_wp_index,trange = trange, $
    downloadonly = downloadonly, no_download = no_download, $
    no_server = no_server

    ; for acknowledgment
    acknowledg_str = $
        'For detailed explanation of the Wp index, please refer to Nose et al.' + $
        '[2012, Space Weather, 10, S08002, doi:10.1029/2012SW000785]. When the ' + $
        'Wp index is used in publication, it is highly recommended to cite the ' + $
        'above paper and data DOI (doi:10.17593/13437-46800).' + $
        'The rules for the data use and exchange are defined by the Guide on ' + $
        'the World Data Center System (ICSU Panel on World Data Centers, 1996). ' + $
        'Note that information on the appropriate institution(s) is also supplied ' + $
        'with the WDC data sets. If the data are used in publications and ' + $
        'presentations, the data suppliers and the WDC for Geomagnetism, Kyoto ' + $
        'must properly be acknowledged. Commercial use and re-distribution of ' + $
        'WDC data are, in general, not allowed. Please ask for the information of ' + $
        'each observatory to the WDC. The distribution of the data has been ' + $
        'partly supported by the IUGONET (Inter-university Upper atmosphere ' + $
        'Global Observation NETwork) project (http://www.iugonet.org/) funded ' + $
        'by the Ministry of Education, Culture, Sports, Science and Technology ' + $
        '(MEXT), Japan.'

    tplot_dlimit = create_struct('data_att', $
        create_struct('acknowledgment', acknowledg_str))

    ;*************************
    ;****** Initialize *******
    ;*************************
    ; download parameters
    if ~keyword_set(downloadonly) then downloadonly=0
    if ~keyword_set(no_server) then no_server=0
    if ~keyword_set(no_download) then no_download=0

    ; define remote and local path information
    source = file_retrieve(/struct)
    source.local_data_dir = root_data_dir() + 'geom_indices/kyoto/Wp/'
    source.remote_data_dir = 'http://s-cubed.info/data/'

    if keyword_set(downloadonly) then source.downloadonly=1
    if keyword_set(no_server)    then source.no_server=1
    if keyword_set(no_download)  then source.no_download=1


    ;*************************************************************************
    ;***** Download files, read data, and create tplot vars *****
    ;*************************************************************************
    ;=================================
    ;=== Loop on downloading files ===
    ;=================================
    ; make remote path, local path, and download files
    pathformat='YYYYMM/YYYYMMDD.H'
    relpathnames =file_dailynames(file_format=pathformat, trange=trange)
    ; download data
    local_files = spd_download(remote_file=relpathnames, _extra=source)
    ; if downloadonly set, return
    if keyword_set(downloadonly) then return

    ;===================================
    ;=== Loop on reading data ===
    ;===================================
    for j=0,n_elements(local_files)-1 do begin
        file = local_files[j]

        if file_test(/regular,file) then begin
            dprint,'Loading Wp data file: ', file
            fexist = 1
        endif else begin
            dprint,'Wp data file ',file,' not found. Skipping'
            continue
        endelse

        ; create base time
        l=n_elements(relpathnames)
        year = (strmid(relpathnames[j mod l],7,4))
        month = (strmid(relpathnames[j mod l],11,2))
        day = (strmid(relpathnames[j mod l],13,2))
        basetime = time_double(year+'-'+month+'-'+day)

        ; read data
        sdata = read_ascii(file, data_start=2)
        rdata = transpose(sdata.field01[[2,14],*])


        ; append data and time index
        append_array, databuf, rdata
        append_array, timebuf, basetime + dindgen(1440)*60d

    endfor

    ;=======================================
    ;=== Loop on creating tplot variable ===
    ;=======================================
    if size(databuf,/type) eq 4 then begin

        ; tplot variable name
        tplot_name1 = 'wdc_mag_Wp_index'
        tplot_name2 = 'wdc_mag_Wp_nstn'

        ; for bad data
        wbad = where(databuf eq  999.000, nbad)
        if nbad gt 0 then databuf[wbad] = !values.f_nan

        store_data, tplot_name1, data={x:timebuf, y:reform(databuf[*,0])}, dlimit=tplot_dlimit
        store_data, tplot_name2, data={x:timebuf, y:reform(databuf[*,1])}, dlimit=tplot_dlimit


        ; add options
        options, tplot_name1, labels=['Wp'] , colors=[0],$
        ytitle = 'WDC_Wp', $
        ysubtitle = '[nT]'
        options, tplot_name2, labels=['Wp_nstn'] , colors=[0],$
        ytitle = 'WDC_Wp_nstn', $
        ysubtitle = ''
    endif

    ;print acknowledgment
    print, '**************************************************'
    print_str_maxlet, tplot_dlimit.data_att.acknowledgment
    print, '**************************************************'

    ; clear data and time buffer
    databuf = 0
    timebuf = 0


end
