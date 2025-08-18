; Get HPCA data
;  Modified for HPCA by J. Burch
;

;  $LastChangedBy: moka $
;  $LastChangedDate: 2015-08-05 10:43:25 -0700 (Wed, 05 Aug 2015) $
;  $LastChangedRevision: 18400 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_hpca_basic.pro $


pro mms_sitl_get_hpca_basic, sc_id=sc_id, no_update = no_update, reload = reload, $
  level = level, include_level = include


  
 ; print, 'sc_id= ', sc_id
  ;print, 'level= ', level


  date_strings = mms_convert_timespan_to_date()
  start_date = date_strings.start_date
  end_date = date_strings.end_date

  ;on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'


  ;level = 'l1b'
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


 

  ;hpca_status = intarr(n_elements(sc_id))

  for j = 0, n_elements(sc_id)-1 do begin

;goto,jump34 

    if keyword_set(no_update) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
        instrument_id='hpca', mode=mode, $
        level=level, optional_descriptor='ion', /no_update
    endif else begin
      if keyword_set(reload) then begin
        mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
          instrument_id='hpca', mode=mode, $
          level=level, optional_descriptor='ion', /reload
      endif else begin
        mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
          instrument_id='hpca', mode=mode, $
          level=level, optional_descriptor='ion'
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
;        mode, 'hpca', level, sc_id(j), optional_descriptor='ion'
        sc_id(j), 'hpca', mode, level, optional_descriptor='ion'

    endif

    if login_flag eq 0 or file_flag eq 0 then begin
      ; We can safely verify that there is some data file to open, so lets do it

      if n_elements(local_flist) gt 1 then begin
        files_open = mms_sort_filenames_by_date(local_flist)
      endif else begin
        files_open = local_flist
      endelse
      ; Now we can open the files and create tplot variables
      ; First, we open the initial file
      
      
      hpca_struct = mms_sitl_open_hpca_basic_cdf(files_open(0))
;print, hpca_struct
      times = hpca_struct.times

      ispec = hpca_struct.data
      ispecname = sc_id(j)+'_hpca_hplus_RF_corrected'
      
      aspec = hpca_struct.data2
      aspecname = sc_id(j)+'_hpca_heplusplus_RF_corrected'

      ospec = hpca_struct.data4
      ospecname = sc_id(j)+'_hpca_oplus_RF_corrected'


      energies = hpca_struct.energies

      ; Concatenate data if more than one file
      if n_elements(files_open) gt 1 then begin
        for i = 1, n_elements(files_open)-1 do begin
          temp_struct = mms_sitl_open_hpca_basic_cdf(files_open(i))
          times = [times, temp_struct.times]
;          hplus_count_rate = [hplus_count_rate, temp_struct.hplus_count_rate]
          ispec = [ispec, temp_struct.data]
          aspec = [aspec, temp_struct.data2]
          ospec = [ospec, temp_struct.data4]

        endfor
      endif
      
  ispec = ispec[*,*,0]
  aspec = aspec[*,*,0]
  ospec = ospec[*,*,0]
  
  for m = 0, n_elements(files_open)-1 do begin
    for n = 0, 62 do begin
      if ispec[m,n] le 0.1 then begin
        ispec[m,n] = 0.1
      endif
      if ispec[m,n] le 0.1 then begin
        ispec[m,n] = 0.1
      endif
      if ispec[m,n] le 0.1 then begin
        ispec[m,n] = 0.1
      endif
      if ispec[m,n] le 0.1 then begin
        ispec[m,n] = 0.1        
      endif
    endfor
  endfor
 
      store_data, ispecname, data = {x:times, y:ispec, v:energies}
      store_data, aspecname, data = {x:times, y:aspec, v:energies}
      store_data, ospecname, data = {x:times, y:ospec, v:energies}

 
print, min(ispec), max(ispec), max(aspec), max(ospec);, aspec
  
    endif else begin
      print, 'No hpca data available locally or at SDC or invalid query!'
    endelse


  endfor
end
