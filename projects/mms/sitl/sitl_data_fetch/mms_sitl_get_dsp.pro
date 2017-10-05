;+
; PROCEDURE: mms_load_dsp
;
; PURPOSE: Fetches desired data from the DSP (Digital Signal Processing) Board.
;
; INPUT:
; :Keywords:
;    trange       : OPTIONAL - time range of desired data. Ex: ['2015-05-01', '2015-05-02']
;                    Default input is timespan input.
;    sc_id        : OPTIONAL - desired spacecraft, Ex: 'mms1','mms2', etc.
;                    Default input is all s/c
;    data_rate    : OPTIONAL - desired data sampling mode, Example: mode='srvy'
;                             due to cataloging at the SDC, WE REQUIRE YOU LOAD ONLY ONE MODE AT A TIME
;                    Default input - srvy mode
;    level        : OPTIONAL - desired level, options are level 1a, 1b, ql, 2
;                    Default input - all levels
;    datatype    : OPTIONAL - desired data type. Ex: ['epsd', 'tdn', 'swd']
;                    Default input - all data types!
;
;    no_update    : OPTIONAL - /no_update to ensure your current data is not reloaded due to an update at the SDC
;    reload       : OPTIONAL - /reload to ensure current data is reloaded due to an update at the SDC
;    DO NOT DO BOTH /NO_UPDATE AND /RELOAD TOGETHER. THAT IS SILLY!
;    get_support_data  : OPTIONAL - /get_support_data to get support data within the CDF
;   

;
;
; OUTPUT: tplot variables listed at the end of the procedure
; :Author: Katherine Goodrich, contact: katherine.goodrich@colorado.edu
;-
; MODIFICATION HISTORY:
;
;
;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-11-18 10:28:18 -0800 (Wed, 18 Nov 2015) $
;  $LastChangedRevision: 19405 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_dsp.pro $

pro mms_sitl_get_dsp, trange=trange, sc_id=sc_id, $
  data_rate=data_rate, level=level, datatype=datatype, $
  no_update=no_update, reload=reload, get_support_data=get_support_data
  
  ; Handle trange
  if not keyword_set(trange) then begin
    t = timerange(/current)
    st = time_string(t)
    datestrings=mms_convert_timespan_to_date()
    start_date = datestrings.start_date
    end_date = datestrings.end_date
  endif else begin
    t0 = time_double(trange[0])
    t1 = time_double(trange[1])
    t = [t0, t1]
    st = time_string(t)
    start_date = strmid(trange[0],0,10) + '-00-00-00'
    end_date = strmatch(strmid(trange[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(trange[1],0,10)
    end_date = end_date + '-23-59-59'
  endelse
  
  instrument_id = 'dsp'
  
;  status = mms_login_lasp(login_info = login_info)
;  if status ne 1 then return
  
  if not keyword_set(sc_id) then sc = ['mms1', 'mms2', 'mms3', 'mms4'] else sc = sc_id
  
  ;if not keyword_set(sc) then sc = ['mms1', 'mms2', 'mms3', 'mms4']  
  if not keyword_set(data_rate) then mode = 'srvy' else mode = data_rate
  if n_elements(mode) gt 1 then begin
    dprint, 'Cannot select more than one mode at a time.'
    print, 'Please confine your query to one mode (Ex: mode="srvy")'
    print, 'Exiting, MMS_LOAD_DSP, no tplot variables loaded'
    return
  endif

  if not keyword_set(datatype) then datatype = ['epsd', 'bpsd','tdn', 'swd']
  if not keyword_set(level) then level = ['l1a', 'l1b', 'l2']
  if keyword_set(no_update) and keyword_set(reload) then begin
    dprint, 'Keywords NO_UPDATE and RELOAD are incompatible and cannot be called at once'
    print, 'You silly person.'
    print, 'Exiting, MMS_LOAD_DSP, no tplot variables loaded'
    return
  endif
  if size(sc, /type) ne 7 then sc = strtrim(string(sc),1)
  sc_len = strlen(sc)

  if sc_len[0] eq 1 then sc = 'mms'+sc
  sc_len = strlen(sc)
  if sc_len[0] ne 4 or total(strmatch(['mms1', 'mms2', 'mms3', 'mms4'],sc[0])) eq 0 then begin
    dprint, 'MMS_LOAD_EDP: INVALID SC ENTRY. VALID INPUTS EITHER "MMS#" OR "#"'
    print, 'Exiting, MMS_LOAD_DSP, no tplot variables loaded'
    return
  endif
  
  if keyword_set(get_support_data) then var_type = ['support_data', 'data'] else var_type = 'data'
  
  ;names = []
    
  if total(strmatch(level, 'l1a')) eq 1 or total(strmatch(level, 'l1b')) eq 1 then begin
    if total(strmatch(datatype, 'bpsd')) eq 1 then begin
      data_type_l1 = ['179', '17a', '17b']
      finfo = mms_get_science_file_info(sc_id=sc, $
        instrument_id=instrument_id, data_rate_mode=mode, $
        data_level=level, descriptor=data_type_l1, start_date=start_date, end_date=end_date)
      if strlen(finfo[0]) eq 0 then begin
        print, 'MMS_LOAD_DSP: COULD NOT FIND ANY DATA MATCHING CRITERIA:'
        print, 'TIME RANGE = ', st
        print, 'SC = ', sc
        print, 'DATA_TYPE = bpsd'
        print, 'LEVEL = ', level
        print, 'MODE = ', mode
        print, 'PLEASE ALTER SEARCH'
        print, 'NO BPSD tplot variables loaded'
      endif else begin
        mms_data_fetch, flist, login_flag, dwnld_flag, sc_id=sc, $
          instrument_id=instrument_id, mode=mode, level=level, optional_descriptor=data_type_l1, $
          no_update=no_update, reload=reload
        nf = n_elements(flist)
        mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
          descriptors, version_strings, start_strings, years, /contains_dir
;        if nf gt 1 then begin 
;          flist = flist[sort(sc_ids)]
;          flist = mms_sort_filenames_by_date(flist)
;        endif        
        
        ind = sort(descriptors)
        ;  flist = flist[ind]
        dtypes = descriptors[ind]
        dtypes = dtypes[uniq(dtypes)]
        nd = n_elements(dtypes)
        mds = modes[sort(modes)]
        mds = mds[uniq(mds)]
        nm = n_elements(mds)
        for obs = 0, n_elements(sc) -1  do begin
          mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
            types, version_strings, start_strings, years, /contains_dir
          ind = where(sc_ids eq sc[obs])
          if total(ind) eq -1 then break
          fles = flist[ind]
          for d=0, nd-1 do begin
            dtyp = dtypes[d]
            mms_parse_file_name, fles, sc_ids, inst_ids, modes, levels, $
              descriptors, version_strings, start_strings, years, /contains_dir
            ind = where(descriptors eq dtyp)
            if total(ind) eq -1 then break
            fles1 = fles[ind]

            for m=0, nm-1 do begin
              mde = mds[m]
              mms_parse_file_name, fles1, sc_ids, inst_ids, modes, levels, $
                descriptors, version_strings, start_strings, years, /contains_dir
              ind = where(modes eq mde)
              if total(ind) eq -1 then break
              fles2 = fles1[ind]
              fles2 = mms_sort_filenames_by_date(fles2)
              cdfi = cdf_load_vars(fles2, var_type=var_type, varnames=varnames)
              oldname = varnames[0]
              cdf_info_to_tplot, cdfi
              case dtyp of
                '179': newname = oldname + '_x'
                '17a': newname = oldname + '_y'
                '17b': newname = oldname + '_z'
              endcase
              get_data, oldname, data=data, dlim=dlim, lim=lim
              store_data, newname, data=data, dlim=dlim, lim=lim
              del_data, oldname
              ;names = [names, newname]
              append_array, names, newname

            endfor
          endfor
        endfor

      endelse  
    endif
    if total(strmatch(datatype, 'epsd')) eq 1 then begin
      data_type_l1 = ['173', '174', '175', '176', '177', '178']
      ;in the event of both level 1a and level 1b selected, default goes to level 1b
      if total([strmatch(level, 'l1a'), strmatch(level, 'l1b')]) eq 2 then lower_level = 'l1b' else lower_level = level

      finfo = mms_get_science_file_info(sc_id=sc, $
        instrument_id=instrument_id, data_rate_mode=mode, $
        data_level=lower_level, descriptor=data_type_l1, start_date=start_date, end_date=end_date)
      if strlen(finfo[0]) eq 0 then begin
        print, 'MMS_LOAD_DSP: COULD NOT FIND ANY DATA MATCHING CRITERIA:'
        print, 'TIME RANGE = ', st
        print, 'SC = ', sc
        print, 'DATA_TYPE = epsd'
        print, 'LEVEL = ', lower_level
        print, 'MODE = ', mode
        print, 'PLEASE ALTER SEARCH'
        print, 'NO EPSD tplot variables loaded'
      endif else begin
        mms_data_fetch, flist, login_flag, dwnld_flag, sc_id=sc, $
          instrument_id=instrument_id, mode=mode, level=lower_level, optional_descriptor=data_type_l1, $
          no_update=no_update, reload=reload
        nf = n_elements(flist)
        mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
          descriptors, version_strings, start_strings, years, /contains_dir
;        if nf gt 1 then begin 
;          flist = flist[sort(sc_ids)]
;          flist = mms_sort_filenames_by_date(flist)
;        endif        
        
        ind = sort(descriptors)
        ;  flist = flist[ind]
        dtypes = descriptors[ind]
        dtypes = dtypes[uniq(dtypes)]
        nd = n_elements(dtypes)
        mds = modes[sort(modes)]
        mds = mds[uniq(mds)]
        nm = n_elements(mds)
        for obs = 0, n_elements(sc) -1 do begin
          mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
            types, version_strings, start_strings, years, /contains_dir
          ind = where(sc_ids eq sc[obs])
          if total(ind) eq -1 then break
          fles = flist[ind]
          for d=0, nd-1 do begin
            dtyp = dtypes[d]
            mms_parse_file_name, fles, sc_ids, inst_ids, modes, levels, $
              descriptors, version_strings, start_strings, years, /contains_dir
            ind = where(descriptors eq dtyp)
            if total(ind) eq -1 then break
            fles1 = fles[ind]

            for m=0, nm-1 do begin
              mde = mds[m]
              mms_parse_file_name, fles1, sc_ids, inst_ids, modes, levels, $
                descriptors, version_strings, start_strings, years, /contains_dir
              ind = where(modes eq mde)
              if total(ind) eq -1 then break
              fles2 = fles1[ind]
              fles2 = mms_sort_filenames_by_date(fles2)
              cdfi = cdf_load_vars(fles2, var_type=var_type, varnames=varnames)
              oldname = varnames[0]
              cdf_info_to_tplot, cdfi
              case dtyp of
                '173': newname = oldname+'_x'
                '174': newname = oldname+'_y'
                '175': newname = oldname+'_z'
                '176': newname = oldname+'_x'
                '177': newname = oldname+'_y'
                '178': newname = oldname+'_z'
              endcase
              get_data, oldname, data=data, dlim=dlim, lim=lim
              store_data, newname, data=data, dlim=dlim, lim=lim
              del_data, oldname
              ;names = [names, newname]
              append_array, names, newname
            endfor
          endfor
        endfor

;        for f=0, nf-1 do begin
;          cdf2tplot, flist[f], varnames=varnames
;          mms_parse_file_name, flist[f], sc_ids, inst_ids, modes, levels, $
;            types, version_strings, start_strings, years, /contains_dir
;          oldname = varnames[0]
;          newname = ''
;          case types of
;            '173': newname = oldname+'_x'
;            '174': newname = oldname+'_y'
;            '175': newname = oldname+'_z'
;            '176': newname = oldname+'_x'
;            '177': newname = oldname+'_y'
;            '178': newname = oldname+'_z'
;          endcase
;          get_data, oldname, data=data, dlim=dlim, lim=lim
;          store_data, newname, data=data, dlim=dlim, lim=lim
;          del_data, oldname
;        endfor

      endelse
    endif
  endif
  if total(strmatch(level, 'l2')) eq 1 then  begin
    finfo = mms_get_science_file_info(sc_id=sc, $
      instrument_id=instrument_id, data_rate_mode=mode, $
      data_level=level, descriptor=datatype, start_date=start_date, end_date=end_date)
    if strlen(finfo[0]) eq 0 then begin
      dprint, 'COULD NOT FIND ANY DATA MATCHING CRITERIA:'
      print, 'TIME RANGE = ', st
      print, 'SC = ', sc
      print, 'DATA_TYPE = ', datatype
      print, 'LEVEL = ', 'l2'
      print, 'MODE = ', mode
      print, 'PLEASE ALTER SEARCH'
      print, 'No tplot variables loaded'
    endif 
    if strlen(finfo[0]) ne 0 then begin
      mms_data_fetch, flist, login_flag, dwnld_flag, sc_id=sc, $
        instrument_id=instrument_id, mode=mode, level='l2', optional_descriptor=datatype, $
        no_update=no_update, reload=reload
      mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
        descriptors, version_strings, start_strings, years, /contains_dir
      
; sort filenames by data type, then mode, then date
      ind = sort(descriptors)
    ;  flist = flist[ind]
      dtypes = descriptors[ind]
      dtypes = dtypes[uniq(dtypes)]
      nd = n_elements(dtypes)
      mds = modes[sort(modes)]
      mds = mds[uniq(mds)]
      nm = n_elements(mds)
      for obs = 0, n_elements(sc) -1  do begin
        mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
          descriptors, version_strings, start_strings, years, /contains_dir
        ind = where(sc_ids eq sc[obs])
        if total(ind) eq -1 then break
        fles = flist[ind]
        for d=0, nd-1 do begin
          dtyp = dtypes[d]
          mms_parse_file_name, fles, sc_ids, inst_ids, modes, levels, $
            descriptors, version_strings, start_strings, years, /contains_dir
          ind = where(descriptors eq dtyp)
          if total(ind) eq -1 then break
          fles1 = fles[ind]
          for m=0, nm-1 do begin
            mde = mds[m]
            mms_parse_file_name, fles1, sc_ids, inst_ids, modes, levels, $
              descriptors, version_strings, start_strings, years, /contains_dir
            ind = where(modes eq mde)
            if total(ind) eq -1 then break
            fles2 = fles1[ind]
            fles2 = mms_sort_filenames_by_date(fles2)
            cdfi = cdf_load_vars(fles2, var_type=var_type)
            cdf_info_to_tplot, cdfi, tplotnames=tplotnames
            append_array, names, tplotnames
          endfor
        endfor
      endfor
    
         
    endif
  endif
  PRINT, 'LOADED THE FOLLOWING VARIABLES:'
  tplot_names, names, /sort

end

