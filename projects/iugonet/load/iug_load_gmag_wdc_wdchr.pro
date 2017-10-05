;+
;Procedure: IUG_LOAD_GMAG_WDC_WDCHR
;pro iug_load_gmag_wdc_wdchr, $
;    site = site, $
;    trange = trange, $
;    verbose = verbose, $
;    level = level, $
;    addmaster = addmaster, $
;    downloadonly = downloadonly, $
;    no_download = no_download
;
;Purpose:
;  Loading geomag hourly mean data in WDC format from WDC for Geomag Kyoto.
;
;Notes:
;  This procedure is called from 'iug_load_gmag_wdc' provided by WDC Kyoto.
;  References about Dst index and WDC hourly means record format:
;  http://wdc.kugi.kyoto-u.ac.jp/hyplt/format/wdchrformat.html
;  http://wdc.kugi.kyoto-u.ac.jp/dstae/format/dstformat.html
;
;Written by:  Daiki Yoshida,  Aug 2010
;Updated by:  Daiki Yoshida,  Sep 14, 2010
;Updated by:  Daiki Yoshida,  Sep 28, 2010
;Updated by:  Daiki Yoshida,  Nov 12, 2010
;Updated by:  Daiki Yoshida,  Jan 11, 2011
;Updated by:  Daiki Yoshida,  Mar 1, 2011
;
;-

pro iug_load_gmag_wdc_wdchr, $
    site = site, $
    trange = trange, $
    verbose = verbose, $
    level = level, $
    addmaster = addmaster, $
    downloadonly = downloadonly, $
    no_download = no_download
    
  if ~keyword_set(verbose) then verbose = 2
  if ~keyword_set(level) then level = 'final'
  
  if ~keyword_set(datatype) then datatype='gmag'
  vns = ['gmag']
  if size(datatype, /type) eq 7 then begin
    datatype = ssl_check_valid_name(datatype, vns, $
      /ignore_case, /include_all, /no_warning)
    if datatype[0] eq '' then return
  endif else begin
    message, 'DATATYPE kw must be of string type.', /info
    return
  endelse
  
  ; list of sites
  vsnames = 'kak dst'
  vsnames_sample = strsplit(vsnames, ' ', /extract)
  vsnames_all = iug_load_gmag_wdc_vsnames()
  
  ; validate sites
  if keyword_set(site) then site_in = site else site_in = vsnames_sample
  wdc_sites = ssl_check_valid_name(site_in, vsnames_all, $
    /ignore_case, /include_all, /no_warning)
  if wdc_sites[0] eq '' then return
  
  ; number of valid sites
  nsites = n_elements(wdc_sites)
  
  ; bad data
  missing_value = 9999
  
  
  for i = 0l, nsites - 1 do begin
  
    relpathnames = $
      iug_load_gmag_wdc_relpath(sname=wdc_sites[i], $
      res='hour', level=level, $
      trange=trange, addmaster=addmaster, /unique)
      
    ;print,relpathnames
      
    ; define remote and local path information
    source = file_retrieve(/struct)
    source.verbose = verbose
    source.local_data_dir = root_data_dir() + 'iugonet/wdc_kyoto/geomag/'
    source.remote_data_dir = 'http://wdc-data.iugonet.org/data/'
    if (keyword_set(no_download)) then source.no_server = 1
    
    ; download data
    local_files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
    print, local_files
    if keyword_set(downloadonly) then continue
    
    
    ; clear data and time buffer
    elemlist = ''
    elemnum = -1
    elemlength = 0
    
    basetime_start = !values.d_nan
    basetime_end = !values.d_nan
    basetime_resolution = 86400d
    data_resolution = 3600d

    ; scan data length and read time
    for j = 0l, n_elements(local_files) - 1 do begin
      file = local_files[j]
      
      if file_test(/regular,file) then begin
        dprint, 'Loading data file: ', file
        fexist = 1
      endif else begin
        dprint, 'Data file ', file, ' not found. Skipping'
        continue
      endelse
      
      openr, lun, file, /get_lun
      while (not eof(lun)) do begin
        line = ''
        readf, lun, line
        
        if ~ keyword_set(line) then continue
        dprint, line, dlevel=5
        
        name = strmid(line, 0, 3)
        if name ne strupcase(wdc_sites[i]) then continue
        
        year_lower = strmid(line, 3, 2)
        if strcmp(wdc_sites[i], 'dst', /fold_case) eq 1 then begin
          year_upper = strmid(line, 14, 2)
          year = year_upper + year_lower
        endif else begin
          year = iug_load_gmag_wdc_relpath_to_year(relpathnames[j], wdc_sites[i])
          if fix(strmid(year, 2, 2)) ne fix(year_lower) then begin
            dprint, 'invalid year value? (dir:' + year + ', data:' + year_lower + ')'
            continue
          endif
        endelse
        month = strmid(line,5,2)
        day = strmid(line,8,2)
        basetime = time_double(year+'-'+month+'-'+day) + data_resolution / 2

        if (finite(basetime_start, /nan)) then basetime_start = basetime $
        else if (basetime lt basetime_start) then basetime_start = basetime
        if (finite(basetime_end, /nan)) then basetime_end = basetime $
        else if (basetime_end lt basetime) then basetime_end = basetime

        element = strmid(line,7,1)     ; * for index
        version = strmid(line,13,1)    ; 0:realtime, 1:prov., 2+:final
        
        ; cache elements and count up
        for x = 0l, n_elements(elemlist) - 1 do begin
          if elemlist[x] eq element then begin
            elemnum = x
            break
          endif else begin
            elemnum = -1
          endelse
        endfor
        if elemnum eq -1 then begin
          ;printdat, elemlist
          ;printdat, elemlength
          append_array, elemlist, element
          append_array, elemlength, 0l
          elemnum = n_elements(elemlist) -1
        endif
        elemlength[elemnum] += 1
        
      endwhile
      free_lun,lun
    endfor
    
    ; if nodata
    dprint, size(elemlist,/n_dimensions), dlevel=5
    dprint, time_string([basetime_start, basetime_end]), dlevel=5
    if size(elemlist, /n_dimensions) eq 0 then continue
    if (finite(basetime_start, /nan) or $
        finite(basetime_end, /nan)) then continue


    ; create timebuf
    buf_size = long((basetime_end - basetime_start + basetime_resolution) / $
                    data_resolution)
    if buf_size le 0 then begin
      dprint, 'invalid time range (?)'
      continue
    end
    timebuf = basetime_start + dindgen(buf_size) * data_resolution

    if buf_size lt $
       max(elemlength) * long(basetime_resolution / data_resolution) then begin
      dprint, 'warning: length of timebuf is too small for the data.'
      dprint, 'timebuf length: ', buf_size
      dprint, 'max of data length: ', $
              max(elemlength) * long(basetime_resolution / data_resolution)
    endif

    
    ; setup databuf
    dprint, 'Data elements: ', elemlist
    databuf = replicate(!values.f_nan, buf_size, size(elemlist, /n_elements))
    elemnum = -1
    
    
    for j = 0l, n_elements(local_files) - 1 do begin
      file = local_files[j]
      
      if file_test(/regular, file) then begin
        ;dprint,'Loading data file: ', file
        fexist = 1
      endif else begin
        dprint,'Data file ',file,' not found. Skipping'
        continue
      endelse
      
      openr, lun, file, /get_lun
      while (not eof(lun)) do begin
        line=''
        readf, lun, line
        
        if ~ keyword_set(line) then continue
        dprint, line, dlevel=5
        
        name = strmid(line, 0, 3)
        if name ne strupcase(wdc_sites[i]) then continue
        
        year_lower = strmid(line, 3, 2)
        if strcmp(wdc_sites[i], 'dst', /fold_case) eq 1 then begin
          year_upper= strmid(line, 14, 2)
          year = year_upper + year_lower
        endif else begin
          year = iug_load_gmag_wdc_relpath_to_year(relpathnames[j], wdc_sites[i])
          if fix(strmid(year, 2, 2)) ne fix(year_lower) then begin
            dprint, 'invalid year value? (dir:' + year + ', data:' + year_lower + ')'
            continue
          endif
        endelse
        month = strmid(line,5,2)
        day = strmid(line,8,2)
        basetime = time_double(year+'-'+month+'-'+day) + data_resolution / 2
        
        element = strmid(line,7,1)     ; * for index
        version = strmid(line,13,1)    ; 0:realtime, 1:prov., 2+:final
        
        for x = 0l, n_elements(elemlist) - 1 do begin
          if elemlist[x] eq element then begin
            elemnum = x
            break
          endif else begin
            elemnum = -1
          endelse
        endfor
        if elemnum eq -1 then continue
        
        basevalue_str = strmid(line, 16, 4)
        if strlen(strtrim(basevalue_str, 2)) eq 0 then begin
          basevalue = 0l
        endif else begin
          basevalue = long(basevalue_str) ; unit 100 nT for index
        endelse
        variations = long(strmid(line, indgen(24)*4 +20 ,4))
        
        if element eq 'D' or element eq 'I' then begin
          value = float(variations) / 600. + float(basevalue)
        endif else begin
          value = float(variations) + float(basevalue * 100)
        endelse
        wbad = where(variations eq missing_value, nbad)
        if nbad gt 0 then value[wbad] = !values.f_nan
        
        idx = long((time_double(basetime) - basetime_start) / data_resolution)
        if (idx lt 0 or idx gt buf_size) then begin
          dprint, 'error: out of timerange?'
          continue
        endif
        databuf[idx, elemnum] = value
      endwhile
      free_lun,lun
   endfor

    ; exchange elements and elemlist
;    temp = databuf
;    order = sort(elemlist)
;    order = order[sort(elemlist)] ; this is key sentence
;    for j = 0l, n_elements(databuf)/n_elements(elemlist)-1 do begin
;      for k = 0l, n_elements(elemlist)-1 do begin
;         databuf(j,order(k))=temp(j,k)
;      endfor
;   endfor

;    elemlist = elemlist[sort(elemlist)]

    ; store data to tplot variables
    iug_load_gmag_wdc_create_tplot_vars, $
      sname = wdc_sites[i], $
      element = elemlist, $
      res = 'hour', level = level, $
      tplot_name, tplot_ytitle, tplot_ysubtitle, tplot_labels, $
      tplot_colors, dlimit
    store_data, $
      tplot_name, $
      data = {x:timebuf, y:databuf}, $
      dlimit = dlimit
    options, $
      tplot_name, $
      ytitle = tplot_ytitle, ysubtitle = tplot_ysubtitle, $
      labels = tplot_labels, colors = tplot_colors


    print, '**************************************************'
    print_str_maxlet, dlimit.data_att.acknowledgment
    print, '**************************************************'
    
    
    databuf = 0
    timebuf = 0
  endfor
  
end
