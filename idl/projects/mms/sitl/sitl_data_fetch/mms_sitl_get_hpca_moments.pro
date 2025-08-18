; Get HPCA data
;  Modified for HPCA by J. Burch
;

;  $LastChangedBy: moka $
;  $LastChangedDate: 2015-08-23 15:09:25 -0700 (Sun, 23 Aug 2015) $
;  $LastChangedRevision: 18583 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_hpca_moments.pro $


pro mms_sitl_get_hpca_moments, sc_id=sc_id, no_update = no_update, reload = reload, $
  level = level;, include_level = include


  
  ;sc_id = 'mms1'


  date_strings = mms_convert_timespan_to_date()
  start_date = date_strings.start_date
  end_date = date_strings.end_date

  ;on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'


;  level = 'l1b'
  if ~keyword_set(level) then level = 'l1b'
  
  mode = 'srvy'

  ; See if spacecraft id is set
  if ~keyword_set(sc_id) then begin
    print, 'Spacecraft ID not set, defaulting to mms1'
    sc_id = 'mms1'
  endif else begin
    ivalid = intarr(n_elements(sc_id))
    for j = 0, n_elements(sc_id)-1 do begin
      sc_id(j)=strlowcase(sc_id(j)) ; this turns any data type to a string
      if sc_id(j) ne 'mms1' and sc_id(j) ne 'mms2' and sc_id(j) ne 'mms3' and sc_id(j) ne 'mms4' then begin
        ivalid(j) = 1
      endif
    endfor
    if min(ivalid) eq 1 then begin
      message,"Invalid spacecraft ids. Using default spacecraft mms1",/continue
      sc_id='mms1'
    endif else if max(ivalid) eq 1 then begin
      message,"Both valid and invalid entries in spacecraft id array. Neglecting invalid entries...",/continue
      print,"... using entries: ", sc_id(where(ivalid eq 0))
      sc_id=sc_id(where(ivalid eq 0))
    endif
  endelse


  for j = 0, n_elements(sc_id)-1 do begin

;goto,jump34 

    if keyword_set(no_update) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
        instrument_id='hpca', mode=mode, $
        level=level, optional_descriptor='moments', /no_update
    endif else begin
      if keyword_set(reload) then begin
        mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
          instrument_id='hpca', mode=mode, $
          level=level, optional_descriptor='moments', /reload
      endif else begin
        mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
          instrument_id='hpca', mode=mode, $
          level=level, optional_descriptor='moments'
      endelse
    endelse

    loc_fail = where(download_fail eq 1, count_fail)

    if count_fail gt 0 then begin
      loc_success = where(download_fail eq 0, count_success)
      print, 'Some of the downloads from the SDC timed out. Try again later if plot is missing data.'
      if count_success gt 0 then begin
        local_flist = local_flist(loc_success)
      endif else if count_success eq 0 then begin
        login_flag = 1
      endif
    endif

    file_flag = 0


;jump34:dum='' 
;login_flag=1  


    if login_flag eq 1 then begin
      print, 'Unable to locate files on the SDC server, checking local cache...'
      mms_check_local_cache, local_flist, file_flag, $
        mode, 'hpca', level, sc_id(j), optional_descriptor='moments'
    endif

print, 'local_flist= ', local_flist


    if login_flag eq 0 or file_flag eq 0 then begin
      ; We can safely verify that there is some data file to open, so lets do it

      if n_elements(local_flist) gt 1 then begin
        files_open = mms_sort_filenames_by_date(local_flist)
      endif else begin
        files_open = local_flist
      endelse
      ; Now we can open the files and create tplot variables
      ; First, we open the initial file
         
      hpca_struct = mms_sitl_open_hpca_moments_cdf(files_open(0))
;print, hpca_struct
      times = hpca_struct.times
      hdens = hpca_struct.data5
      hdensname = sc_id(j)+'_hpca_hplus_number_density'
      odens = hpca_struct.data8
      odensname = sc_id(j)+'_hpca_oplus_number_density'
      hvel = hpca_struct.data20
      hvelname = sc_id(j)+'_hpca_hplus_bulk_velocity'
      ovel = hpca_struct.data23
      ovelname = sc_id(j)+'_hpca_oplus_bulk_velocity'
      htemp = hpca_struct.data24
      htempname = sc_id(j)+'_hpca_hplus_scalar_temperature'      
      otemp = hpca_struct.data25      
      otempname = sc_id(j)+'_hpca_oplus_scalar_temperature'
            
      ; Concatenate data if more than one file
      ;if n_elements(files_open) gt 1 then begin
      ;  for i = 1, n_elements(files_open)-1 do begin
      ;    temp_struct = mms_sitl_open_hpca_moments_cdf(files_open(i))
      ;    times = [times, temp_struct.times]
      ;       hdens = [hdens, temp_struct.data5]
      ;       odens = [odens, temp_struct.data8]
      ;       hvel = [hvel, temp_struct.data20]
      ;       ovel = [ovel, temp_struct.data23]
      ;       htemp = [htemp, temp_struct.data24]
      ;       otemp = [otemp, temp_struct.data25]
                        
;        endfor
;      endif
       
      store_data, hdensname, data = {x:times, y:hdens}
      store_data, odensname, data = {x:times, y:odens}
      store_data, hvelname, data = {x:times, y:hvel}
      store_data, ovelname, data = {x:times, y:ovel}
      store_data, htempname, data = {x:times, y:htemp}
      store_data, otempname, data = {x:times, y:otemp}

combined = sc_id(j)+'_hpca_hplusoplus_number_densities'
combined2 = sc_id(j)+'_hpca_hplusoplus_scalar_temperatures'

store_data, combined, data = [hdensname, odensname]
store_data, combined2, data = [htempname, otempname]
 
    endif else begin
      print, 'No hpca data available locally or at SDC or invalid query!'
    endelse

  endfor
end
