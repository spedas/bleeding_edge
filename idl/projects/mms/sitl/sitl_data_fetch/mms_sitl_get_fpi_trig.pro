; Routine to load the FPI trigger values for use by the SITL.
; 
;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2016-09-23 10:33:24 -0700 (Fri, 23 Sep 2016) $
;  $LastChangedRevision: 21907 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_fpi_trig.pro $



pro mms_sitl_get_fpi_trig, sc_id = sc_id

  date_strings = mms_convert_timespan_to_date()
  start_date = date_strings.start_date
  end_date = date_strings.end_date

  ; Conversion constants
  re=[86085.1,0.0129701,1.58431e+06,1.11870e+06]
  ri=[47652.2,0.0430813,0.0362016]

  ;on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'

  level = 'trig'
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
     
      
      mms_cdf2tplot, files_open

      ; Get useful ion triggers
      get_data, sc_id(j) + '_fpi_iPseudoContent', data = d
      
      ti = d.x
      ipseudodens = d.y
      
      get_data, sc_id(j) + '_fpi_iPseudoFlux_X_SC', data = d
      ipseudoxflux = d.y
      
      get_data, sc_id(j) + '_fpi_iPseudoFlux_Y_SC', data = d
      ipseudoyflux = d.y

      get_data, sc_id(j) + '_fpi_iPseudoFlux_Z_SC', data = d
      ipseudozflux = d.y
      
      ; Get useful electron triggers
      get_data, sc_id(j) + '_fpi_ePseudoContent', data = d
      
      te = d.x
      epseudodens = d.y
      
      get_data, sc_id(j) + '_fpi_ePseudoParaFlux', data = d
      epseudoflux = d.y
      
      get_data, sc_id(j) + '_fpi_ePseudoDirContent', data = d
      epseudopress = d.y
      
      ; Now we can start calculating stuff
      ;pseudo flux is unsigned, but the following quantities are likely to be useful
      ipseudovz=ipseudozflux/ipseudodens
      ;N/S component
      ipseudovxvy=sqrt(ipseudoxflux^2+ipseudoyflux^2)/ipseudodens
      ;in-plane

      epseudodens=epseudodens/re[0]
      ;panel 1
      elt=where(epseudodens lt 2., countelt)
      ;treat electron pressure differently for Ne < 2, Ne > 2
      egt=where(epseudodens ge 2., countegt)
      if countegt ne 0 then epseudopress[egt]=epseudopress[egt]/re[2]
      if countelt ne 0 then epseudopress[elt]=epseudopress[elt]/re[3]
      epseudoflux=epseudoflux/re[1]
      ;panel 2
      epseudotemp=1.6e-19/1.38e-23*epseudopress/epseudodens
      ;panel 3
      ;
      ipseudodens=ipseudodens/ri[0]
      ;panel 1
      ipseudovz=ipseudovz/ri[1]
      ;panel 4
      ipseudovxvy=ipseudovxvy/ri[2]
      ;panel 5

      ; store all this stuff
      
      store_data, ['*iPseudo*', '*ePseudo*', '*Nbursts*'], /delete
      
      ipint = interpol(ipseudodens, ti, te, /nan)
      
      store_data, sc_id(j) + '_fpi_pseudodens', data = {x:te, y:[[ipint], [epseudodens]]}
      options, sc_id(j) + '_fpi_pseudodens', labels = ['Ni', 'Ne']
      options, sc_id(j) + '_fpi_pseudodens', 'labflag', -1
      store_data, sc_id(j) + '_fpi_epseudoflux', data = {x:te, y:epseudoflux}
      store_data, sc_id(j) + '_fpi_epseudotemp', data = {x:te, y:epseudotemp}
      store_data, sc_id(j) + '_fpi_ipseudovz', data = {x:ti, y:ipseudovz}
      store_data, sc_id(j) + '_fpi_ipseudovxy', data = {x:ti, y:ipseudovxvy}
      
      ; Now do bent pipe b
      get_data, sc_id(j) + '_fpi_bentPipeB_X_DBCS', data = bentx
      get_data, sc_id(j) + '_fpi_bentPipeB_Y_DBCS', data = benty
      get_data, sc_id(j) + '_fpi_bentPipeB_Z_DBCS', data = bentz
      get_data, sc_id(j) + '_fpi_bentPipeB_Norm', data = bentmag
      
      bentb = [[bentmag.y*bentx.y], [bentmag.y*benty.y], [bentmag.y*bentz.y]]
      
      store_data, [sc_id(j) + '_fpi_bentPipeB_X_DBCS', sc_id(j) + '_fpi_bentPipeB_Y_DBCS', sc_id(j) + '_fpi_bentPipeB_Z_DBCS'], /delete
      
      store_data, sc_id(j) + '_fpi_bentPipeB_DBCS', data = {x:bentx.x, y:bentb}
      options, sc_id(j) + '_fpi_bentPipeB_DBCS', labels = ['Bx', 'By', 'Bz']
      options, sc_id(j) + '_fpi_bentPipeB_DBCS', 'labflag', -1
      
    endif else begin
      print, 'No FPI trigger data available locally or at SDC or invalid query!'
    endelse


  endfor
end