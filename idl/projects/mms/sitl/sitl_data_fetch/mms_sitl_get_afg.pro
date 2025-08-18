; PROCEDURE: mms_sitl_get_afg
;
; PURPOSE: Fetch DC magnetic field SITL products from the SDC for display using tplot.
;          The routine creates tplot variables based on the names in the mms CDF files.
;          The routine also provides predicted ephemeris data in tplot form.
;          Data files are cached locally in !mms.local_data_dir.
;
; KEYWORDS:
;
;   sc_id            - OPTIONAL. (String) Array of strings containing spacecraft
;                      ids for http query (e.g. 'mms1' or ['mms1', 'mms3']).
;                      If not used, or set to invalid sc_id, the routine defaults'
;                      to 'mms1'
;
;   no_update        - OPTIONAL. Set if you don't wish to replace earlier file versions
;                      with the latest version. If not set, earlier versions are deleted
;                      and replaced.
;
;   reload           - OPTIONAL. Set if you wish to download all files in query, regardless
;                      of whether file exists locally. Useful if obtaining recent data files
;                      that may not have been full when you last cached them.
;
;                      NOTE: no_update and reload should NEVER be simultaneously set. Will
;                      give an error if it happens.
;
; INITIAL VERSION: FDW 2015-04-14
; MODIFICATION HISTORY:
;
; LASP, University of Colorado
;
;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2016-10-04 16:18:06 -0700 (Tue, 04 Oct 2016) $
;  $LastChangedRevision: 22026 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_afg.pro $





pro mms_sitl_get_afg, sc_id=sc_id, no_update = no_update, reload = reload, level = level

  t = timerange(/current)
  st = time_string(t)
  start_date = strmid(st[0],0,10)
  end_date = strmatch(strmid(st[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(st[1],0,10)

  ;on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'

  if ~keyword_set(level) then begin
    level = 'ql'
  endif else begin
    if level ne 'ql' and level ne 'l1b' and level ne 'l2pre' and level ne 'l1a' then begin
      print, 'Invalid level, defaulting to ql'
      level = 'ql'
    endif
  endelse
  
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
  
  ;----------------------------------------------------------------------------------------------------------
  ; Check for AFG data first
  ;----------------------------------------------------------------------------------------------------------
  
  for j = 0, n_elements(sc_id)-1 do begin

    if keyword_set(no_update) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
        instrument_id='afg', mode=mode, $
        level=level, /no_update
    endif else begin
      if keyword_set(reload) then begin
        mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
          instrument_id='afg', mode=mode, $
          level=level, /reload
      endif else begin
        mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
          instrument_id='afg', mode=mode, $
          level=level
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

    ;
    ;if n_elements(local_flist) eq 1 and strlen(local_flist(0)) eq 0 then begin
    ;  login_flag = 1
    ;endif

    ; Now we need to do one of two things:
    ; If the communication to the server fails, or no data on server, we need to check for local data
    ; If the communication worked, we need to open the flist

    ; First lets handle failure of the server


    file_flag = 0
    if login_flag eq 1 or local_flist(0) eq '' or !mms.no_server eq 1 then begin
      print, 'Unable to locate files on the SDC server, checking local cache...'
      mms_check_local_cache, local_flist, file_flag, $
        mode, 'afg', level, sc_id(j)
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

;      mag_struct = mms_sitl_open_afg_cdf(files_open(0))
;      times = mag_struct.x
;      b_field = mag_struct.y
;      varname = mag_struct.varname
;
;      if n_elements(files_open) gt 1 then begin
;        for i = 1, n_elements(files_open)-1 do begin
;          temp_struct = mms_sitl_open_afg_cdf(files_open(i))
;          times = [times, temp_struct.x]
;          b_field = [b_field, temp_struct.y]
;        endfor
;      endif
;
;      store_data, varname, data = {x: times, y:b_field}

;      mag_struct = mms_sitl_open_afg_cdf(files_open(0))
;      times = mag_struct.x
;      b_field_pgsm = mag_struct.y_pgsm
;      pgsm_varname = mag_struct.pgsm_varname
;      b_field_dmpa = mag_struct.y_dmpa
;      dmpa_varname = mag_struct.dmpa_varname
;      etimes = mag_struct.ephemx
;      pos_vect = mag_struct.ephemy
;      evarname = mag_struct.ephem_varname
;
;      if n_elements(files_open) gt 1 then begin
;        for i = 1, n_elements(files_open)-1 do begin
;          temp_struct = mms_sitl_open_afg_cdf(files_open(i))
;          times = [times, temp_struct.x]
;          etimes = [etimes, temp_struct.ephemx]
;          pos_vect = [pos_vect, temp_struct.ephemy]
;          b_field_pgsm = [b_field_pgsm, temp_struct.y_pgsm]
;          b_field_dmpa = [b_field_dmpa, temp_struct.y_dmpa]
;        endfor
;      endif
;
;      store_data, pgsm_varname, data = {x: times, y:b_field_pgsm}
;      store_data, dmpa_varname, data = {x: times, y:b_field_dmpa}
;
;      if evarname ne '' then begin
;        store_data, evarname, data = {x: etimes, y:pos_vect}
;      endif else begin
;        print, 'No QL ephemeris in afg file for ' + sc_id[j]
;      endelse
    
    mms_cdf2tplot, files_open
    
    afg_vecname = sc_id(j) + '_afg_srvy_dmpa'
    split_vec, afg_vecname
        
    join_vec, [afg_vecname + '_0', afg_vecname + '_1', afg_vecname + '_2'], afg_vecname
    tplot_rename, afg_vecname + '_3', afg_vecname + '_btot'
    
    store_data, [afg_vecname + '_0', afg_vecname + '_1', afg_vecname + '_2'], /delete

    afg_vecname_gsm = sc_id(j) + '_afg_srvy_gsm_dmpa'
    split_vec, afg_vecname_gsm

    join_vec, [afg_vecname_gsm + '_0', afg_vecname_gsm + '_1', afg_vecname_gsm + '_2'], afg_vecname_gsm
    tplot_rename, afg_vecname_gsm + '_3', afg_vecname_gsm + '_btot'

    store_data, [afg_vecname_gsm + '_0', afg_vecname_gsm + '_1', afg_vecname_gsm + '_2'], /delete


    endif else begin
      print, 'No afg data available locally or at SDC or invalid query!'
    endelse

  endfor

end