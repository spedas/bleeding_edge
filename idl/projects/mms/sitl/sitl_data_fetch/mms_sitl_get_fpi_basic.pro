; Get FPI data
;
;

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2016-03-30 10:18:16 -0700 (Wed, 30 Mar 2016) $
;  $LastChangedRevision: 20635 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_fpi_basic.pro $



pro mms_sitl_get_fpi_basic, sc_id=sc_id, no_update = no_update, reload = reload


date_strings = mms_convert_timespan_to_date()
start_date = date_strings.start_date
end_date = date_strings.end_date


;on_error, 2
if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
  'conflicting and should never be used simultaneously.'

level = 'sitl'
mode = 'fast'

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

;fpi_status = intarr(n_elements(sc_id))

for j = 0, n_elements(sc_id)-1 do begin

  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
      instrument_id='fpi', mode=mode, $
      level=level, /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
	instrument_id='fpi', mode=mode, $
	level=level, /reload
    endif else begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
	instrument_id='fpi', mode=mode, $
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

  file_flag = 0
  if login_flag eq 1 or local_flist(0) eq '' or !mms.no_server eq 1 then begin
    print, 'Unable to locate files on the SDC server, checking local cache...'
    mms_check_local_cache, local_flist, file_flag, $
      mode, 'fpi', level, sc_id(j)
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

    mms_parse_file_name, files_open, junk1, junk2 , junk3, junk4, $
                         junk5, version_strings, junk6, junk7, $
                         /contains_dir

    vstring = version_strings(0)
    vchop = strmid(vstring, 1, strlen(vstring))
    vsplit = strsplit(vchop, '.', /extract)
    vzscore = fix(vsplit(0))
    
    if vzscore ge 1 then begin
      fpi_struct = mms_sitl_open_fpi_new_cdf(files_open(0))
    endif else begin
      fpi_struct = mms_sitl_open_fpi_basic_cdf(files_open(0))
    endelse
    
    times = fpi_struct.times
    espec = fpi_struct.espec
    ispec = fpi_struct.ispec
    epadm = fpi_struct.epadm
    epadh = fpi_struct.epadh
    ndens = fpi_struct.ndens
    padval = fpi_struct.padval
    energies = fpi_struct.energies
    vdsc = fpi_struct.vdsc
    ispecname = fpi_struct.ispecname
    especname = fpi_struct.especname
    densname = fpi_struct.densname
    epadmname = fpi_struct.epadmname
    epadhname = fpi_struct.epadhname
    vname = fpi_struct.vname
    
    if vzscore ge 1 then begin
      bentb = fpi_struct.bentb
      bentmag = fpi_struct.bentmag
    endif


    ; Concatenate data if more than one file
    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        vstring = version_strings(i)
        vchop = strmid(vstring, 1, strlen(vstring))
        vsplit = strsplit(vchop, '.', /extract)
        vzscore = fix(vsplit(0))

        if vzscore ge 1 then begin
          temp_struct = mms_sitl_open_fpi_new_cdf(files_open(i))
        endif else begin
          temp_struct = mms_sitl_open_fpi_basic_cdf(files_open(i))
        endelse
        
        times = [times, temp_struct.times]
        espec = [espec, temp_struct.espec]
        ispec = [ispec, temp_struct.ispec]
        epadm = [epadm, temp_struct.epadm]
        epadh = [epadh, temp_struct.epadh]
        ndens = [ndens, temp_struct.ndens]
        vdsc = [vdsc, temp_struct.vdsc]
        
        if vzscore ge 1 then begin
          bentb = [bentb, temp_struct.bentb]
          bentmag = [bentmag, temp_struct.bentmag]
        endif
        
      endfor
    endif

    store_data, especname, data = {x:times, y:espec, v:energies}
    store_data, ispecname, data = {x:times, y:ispec, v:energies}
    store_data, epadmname, data = {x:times, y:epadm, v:padval}
    store_data, epadhname, data = {x:times, y:epadh, v:padval}
    store_data, densname, data = {x:times, y:ndens}
    store_data, vname, data = {x:times, y:vdsc}
    
    if vzscore ge 1 then begin
      store_data, sc_id(j) + '_fpi_bentPipeB_DSC', data={x:times, y:bentb}
      store_data, sc_id(j) + '_fpi_bentPipeB_MAG', data = {x:times, y:bentmag}
    endif
    
  endif else begin
    print, 'No FPI data available locally or at SDC or invalid query!'
  endelse


endfor
end
