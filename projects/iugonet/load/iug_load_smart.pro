;+
; :PROCEDURE: iug_load_smart
;
; :PURPOSE:
;    Load the solar image data in the FITS format obtained by the SMART telescope 
;    at the Hida Observatory, Kyoto Univ. Under some environment, you should set 
;    the following environment:
;               > setenv ROOT_DATA_DIR ~/data/
;               before you start the IDL.
;
; :Keywords:
;    datatype:  basically set the telescope (e.g., halpha)
;    filter:    filter name(s) (e.g., m05 )
;    lst:       set a named variable to return the URL list of data files
;    downloadonly: if set, then only download the data, do not load it into 
;               variables.
;
; :EXAMPLES:
;   timespan, '2005-08-03/05:00', 0.5, /hour
;   iug_load_smart,filter='p00'
;   iug_load_smart,filter='m08'
;   tplot_names
;   iug_plot2d_smart,'smart_t1_p00',4,4
;   iug_movie_smart,'smart_t1_m08'
;
; :Author:
; 	Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;       Satoru UeNo (E-mail: ueno@kwasan.kyoto-u.ac.jp)
;
; :HISTORY:
; 	2012/05/08: Created by TH
;       2012/05/17: Addition of FITS_READ and STORE_DATA by SU
;
;-
PRO iug_load_smart, datatype=datatype, filter=filter, $
          lst=lst, downloadonly=downloadonly, no_download=no_download

  ;===== Keyword check =====
  IF ~keyword_set(downloadonly) THEN downloadonly=0
  IF ~keyword_set(no_download) THEN no_download=0

  ;===== Datatype and Filter =====;
  datatype_all = strsplit('halpha', /extract)
  filter_all   = strsplit('m12 m08 m05 p00 p05 p08 p12', /extract)

  ;===== acknowledgement =====;
  acknowledgstring = 'If you have any questions or requests on the SMART-T1 data, ' + $
                     'please contact to smart@kwasan.kyoto-u.ac.jp .'

  ;===== Data directory =====;
  local_data_dir_tmpl = $
    root_data_dir() + 'iugonet/KwasanHidaObs/smart_t1/YYYY/MM/DD/fits/'

  ;===== Initialize the data load structure =====;
  source = file_retrieve( /struct )
  IF keyword_set(no_download) THEN source.no_download = 1

  ;===== Check the arguments =====;
  IF ~KEYWORD_SET(datatype) THEN datatype='halpha'
  IF ~KEYWORD_SET(filter) THEN filter='p00'
  datatype_arr = STRLOWCASE( ssl_check_valid_name( datatype, datatype_all, $
    /ignore_case, /include_all ) )
  filter_arr = STRLOWCASE( ssl_check_valid_name( filter, filter_all, $
    /ignore_case, /include_all ) )
  IF datatype_arr[0] EQ '' OR filter_arr[0] EQ '' THEN RETURN ;No valid datatype/filter
  
  ;===== Get the time range =====;
  get_timespan, tr
  tr_str = time_string(tr)
  STRPUT, tr_str, "T", 10 ;yyyy-mm-dd/hh:mm:ss --> yyyy-mm-ddThh:mm:ss
  
  ;===== Loop for loading data for each datatype =====;
  FOR i_dtype=0L, N_ELEMENTS(datatype_arr)-1 DO BEGIN
    datatype = datatype_arr[i_dtype]
    
    ;===== Loop for loading data for each filter =====;
    FOR i_filter=0L, N_ELEMENTS(filter_arr)-1 DO BEGIN
      filter = filter_arr[i_filter]
      
      ;===== Set keywords for MDDB query =====;
      mddb_base_url = 'http://search.iugonet.org/iugonet/open-search/'
      keyword='smart+AND+'+datatype+'+AND+'+filter+'+AND+fits'
      startdate = tr_str[0]
      enddate = tr_str[1]
      query = 'request?query='+keyword+'&ts='+startdate+'&te='+enddate+'&Granule=granule&rpp=300&'
      url_in = mddb_base_url+query
      
      ;===== Obtain the list of URLs of data files by throwing a query to MDDB =====;
      lst = get_source_url_list( url_in )
      IF N_ELEMENTS(lst) EQ 1 AND STRLEN(lst[0]) EQ 0 THEN BEGIN
        PRINT, 'iug_load_smart: No data file was hit by MDDB query!'
        CONTINUE
      ENDIF
      lst = lst[ SORT(lst) ] ;Sort the URL list
      
      ;===== Download  data files =====;
      loaded_flist = ''
      FOR i_lst=0L, N_ELEMENTS(lst)-1 DO BEGIN
        url = lst[i_lst]
        url_str = strsplit( url, '/', /extract )

        print,url_str

        nstr = N_ELEMENTS(url_str)
        fname = url_str[nstr-1]
        ;===== append_array, fname_arr, fname =====;
        syyyy = url_str[4] & smm = url_str[5] & sdd = url_str[6]
        local_data_dir = local_data_dir_tmpl
        pos = STRPOS( local_data_dir, 'YYYY' ) & STRPUT, local_data_dir, syyyy, pos
        pos = STRPOS( local_data_dir, 'MM' ) & STRPUT, local_data_dir, smm, pos
        pos = STRPOS( local_data_dir, 'DD' ) & STRPUT, local_data_dir, sdd, pos
        remote_data_dir = 'http://' + STRJOIN( url_str[1:(nstr-2)], '/' ) + '/'

        ;===== Download data files =====;
        source.local_data_dir = local_data_dir
        source.remote_data_dir = remote_data_dir
        fpath = ''
        fpath = spd_download(remote_file=fname, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
        
        IF fpath NE '' THEN append_array, loaded_flist, fpath
      ENDFOR

      ;===== Load data into tplot variables =====;
      IF(downloadonly eq 0) THEN begin
        databuf=intarr(n_elements(loaded_flist),512,512)

        ifile=0
        for j=0,n_elements(loaded_flist)-1 do begin
          file=loaded_flist[j]

          if file_test(/regular,file) then begin
            dprint,'Loading SMART_T1 H-alpha Full-disk Sun Image: ', file
            fexist = 1
          endif else begin
            dprint,'Loading SMART_T1 H-alpha Full-disk Sun Image ',file,' not found. Skipping'
            continue
          endelse

          ;===== Read Fits file (needs readfits.pro) =====;
          img=readfits(file, hd)

          dateobs=sxpar(hd,'DATE-OBS')
          pos=strpos(dateobs, 'T')
          datestr=strmid(dateobs, 0, pos)+'/'+strmid(dateobs, pos+1, strlen(dateobs)-pos-2)
          print, datestr

          timearr = time_double(datestr)      
          
          suncenX = sxpar(hd,'crpix1')
          dX = suncenX - 2049.
          suncenY = sxpar(hd,'crpix2')
          dY = suncenY - 2049.
          redimg = congrid(shift(img,-dX,-dY),512,512)

;          tvscl,congrid(img,512,512)
;          xyouts,10,10,file

          ;===== append_array,databuf,redimg
          databuf[ifile,*,*] = redimg
          append_array,timebuf,timearr
      
          ifile = ifile + 1
        endfor ; (j)

        if ifile eq 0 then begin
          print, 'No tplot variables loaded for datatype='+datatype+', filter='+filter+'.'
        endif else begin
          tplot_name = 'smart_t1_'+filter
          dlimit=create_struct('data_att',create_struct('acknowledgment', acknowledgstring, $
	                     'PI_NAME', 'SMART Developing Team'),'SPEC',1)
          store_data, tplot_name, data={x:timebuf, y:databuf}, dlimit=dlimit
          databuf = 0
          timebuf = 0
        endelse

      ENDIF

    ENDFOR ;Loop for filter_arr
  ENDFOR ;Loop for datatype_arr
  
  print,'*********************************************************************'
  print_str_maxlet, acknowledgstring, 80
  print,'*********************************************************************'
  
  RETURN
END

