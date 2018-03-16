;+
; Procedure: secs_load_data
; 
; Keywords: 
;             trange:        time range of interest
;             datatype:      type of secs data to be loaded. Valid data types are: secs or SEC
;             suffix:        String to append to the end of the loaded tplot variables
;             prefix:        String to append to the beginning of the loaded tplot variables
;             /downloadonly: Download the file but don't read it  
;             /noupdate:     Don't download if file exists (partially implemented, need to test when 
;                            two tvars are requested)
;             /nodownload:   Don't download - use only local files
;             verbose:       controls amount of error/information messages displayed 
;             /get_stations: get list of stations used to generate this data
; 
; NOTE: 
; - Can only handle time ranges that don't overlap a day
; - Need to  No Update and No clobber
; - Need to correctly handle time clip
; - Add all standard tplot options
; - If no files downloaded notify user
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-02-13 15:32:14 -0800 (Mon, 13 Feb 2017) $
; $LastChangedRevision: 22769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/secs_load_data.pro $
;-

pro secs_load_data, trange = trange, datatype = datatype, suffix = suffix, prefix = prefix, $
                    downloadonly = downloadonly, no_update = no_update, no_download = no_download, $
                    verbose = verbose, get_stations = get_stations
                    
    compile_opt idl2
    
    ; handle possible server errors
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return
    endif

    ; initialize variables and parameters
    defsysv, '!secs', exists=exists
    if not(exists) then secs_init
    if undefined(suffix) then suffix = ''
    if undefined(prefix) then prefix = ''
    if not keyword_set(datatype) then datatype = '*'   
    if datatype[0] EQ '*' then datatype = ['eics', 'seca']
    if not keyword_set(source) then source = !secs
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()

    tn_list_before = tnames('*')
      
    ; extract date information
    tstart = time_string(tr[0])
    yr_start = strmid(time_string(tr[0]),0,4)
    mo_start = strmid(time_string(tr[0]),5,2)
    day_start = strmid(time_string(tr[0]),8,2)
    
    dur = (time_struct(tr[1])).sod - (time_struct(tr[0])).sod
    if dur EQ 0 then nfiles = 1 else nfiles = long(dur/10)
    dates = time_string(tr[0]+long(findgen(nfiles)*10)) 
    idx = strpos(dates[0], '/')     
    dates_str = strmid(dates,idx+1,2)+strmid(dates,idx+4,2)+strmid(dates,idx+7,2)
   
    ; loop for each type of data eics and seca
    for j = 0, n_elements(datatype)-1 do begin
    
        dirtype = strupcase(strmid(datatype[j],0,3))
        remote_path = source.remote_data_dir+dirtype+'S/'+yr_start+'/'+mo_start+'/'+day_start+'/'   
        local_path = source.local_data_dir+dirtype+'S/'+yr_start+'/'+mo_start+'/'+day_start+'/'
        filenames = dirtype+'S'+yr_start+mo_start+day_start+'_'+dates_str+'.dat'
        local_files = local_path + filenames
       
        files = spd_download(remote_file=filenames, remote_path=remote_path, $
                             local_path = local_path, no_download=no_download, $
                             no_update=no_update)
      
        if keyword_set(downloadonly) then continue

        ; can only read files that have been downloaded
        files = file_search(local_files, count=ncnt)
        if ncnt EQ 0 then continue

        case datatype[j] of
          ; Equivalent Ionospheric Currents
          'eics': eic_ascii2tplot, files, prefix=prefix, suffix=suffix, verbose=verbose, tplotnames=tplotnames
          ; Current Magnitudes
          'seca': sec_ascii2tplot, files, prefix=prefix, suffix=suffix, verbose=verbose, tplotnames=tplotnames
          else: dprint, dlevel = 0, 'Unknown data type!'
        endcase

      endfor
       
    ; load magnetometer stations
    if keyword_set(get_stations) then begin
       ; construct file name for download
       remote_path = source.remote_data_dir+'/Stations/'+yr_start+'/'+mo_start+'/'+day_start+'/'
       local_path = source.local_data_dir+'/Stations/'+yr_start+'/'+mo_start+'/'+day_start+'/'
       filename = 'Stat'+yr_start+mo_start+day_start+'.dat'
       local_file = local_path + filename
       found_file = file_search(local_file, count=ncnt)
       if keyword_set(nodownload) then begin
         ; let user know if there are no local files
         if ncnt LT 1 then begin
           dprint, dlevel = 0, ' No local files were found in: ' + local_path
           return
         endif
       endif else begin
         if (keyword_set(noupdate) && ncnt EQ 0) OR (~keyword_set(noupdate)) then $
           file = spd_download(remote_file=filename, remote_path=remote_path, $
                               local_path = local_path)
       endelse
       if ~keyword_set(downloadonly) then begin
          ; double check that files were downloaded and exist
          file = file_search(local_file, count=ncnt)
          if ncnt NE 0 then secs_stations2tplot, file, tr[0], prefix=prefix, suffix=suffix, verbose=verbose, tplotnames=tplotnames
       endif
    endif

    ; make sure some tplot variables were loaded
    tn_list_after = tnames('*')
    new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])
    
    ; check that some data was loaded
    if n_elements(new_tnames) eq 1 && is_num(new_tnames) then begin
        dprint, dlevel = 1, 'No new tplot variables were created.'
        return
    endif
        
end