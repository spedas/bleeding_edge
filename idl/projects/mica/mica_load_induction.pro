;+
; NAME:
;   mica_load_induction
;
; PURPOSE:
;   This routine with load Magnetic Induction Coil Array (MICA) data into tplot variables.
;
; INPUT:
;   site_code:          abbreviated name of station. sites include:
;                       NAL, LYR, LOR, ISR, SDY, IQA, SNK, MCM, SPA, JBS, NEV, HAL, PG2[3,4,5]
; 
; KEYWORDS (commonly used by other load routines):
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         no_download:  set this flag to use local files only (used when user doesn't 
;                       have internet or already has a local copy of the file).
;                       Default value = 0 
;         no_time_clip: don't clip the data to the requested time range; note that if you do use
;                       this keyword you may load a longer time range than requested.
;         no_color_setup: don't setup the SPEDAS color tables (i.e., don't call spd_graphics_config)
;                       
; EXAMPLE:
;   mica_load_induction, 'NAL', trange=['2019-01-03','2019-01-04']
;   
; Written by: M. Chutter, November 15, 2019
;             University of New Hampshire
;-
pro mica_load_induction, $
   site_code, $
   trange = trange, $
   suffix = suffix, $
   no_download = no_download, $
   no_time_clip = no_time_clip, $
   no_color_setup=no_color_setup

  valid_sites=['NAL', 'LYR', 'LOR', 'ISR', 'SDY', 'IQA', 'SNK', 'MCM', 'SPA', 'JBS', $
               'NEV', 'HAL', 'PG2', 'PG3', 'PG4', 'PG5']
  if undefined(site_code) then begin
    print, 'A valid MICA site code name must be entered.'
    print, 'Current site codes include: '
    print, valid_sites
    return
  endif
  
  ; need to setup the SPEDAS color tables, in case they haven't been called yet
  if ~keyword_set(no_color_setup) then spd_graphics_config
   
  ;*** keyword set ***  
  if(not keyword_set(no_download)) then no_download=0 else no_download=1
  if(not keyword_set(no_time_clip)) then no_time_clip=0 else no__time_clip=1
  
  ;*** load CDF ***
  ;--- Create (and initialize) a data file structure 
  source = file_retrieve(/struct)

  ;--- Set parameters for the data file class 
  source.local_data_dir  = root_data_dir() + 'mirl/'
  
  if getenv('SPEDAS_DATA_DIR') ne '' then $
    !source.LOCAL_DATA_DIR = spd_addslash(getenv('SPEDAS_DATA_DIR'))+'mirl/'
    
  source.remote_data_dir = 'http://mirl.unh.edu/ULF/cdf/'

  ; check time range and set if needed
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  
  ; create the daily names based on the time range 
  daily_names = file_dailynames(trange=tr, /unique, times=times)
  years = strmid(daily_names,0,4)
  months = strmid(daily_names,4,2)
  
  for i=0,n_elements(site_code)-1 do begin

    ; check that the site is valid
    idx = where(strupcase(site_code[i]) EQ valid_sites, ncnt)
    if ncnt LT 1 then begin
      print, 'Site code '+site_code[i] + 'is not a valid MICA site code.'
      print, 'Current valid site codes include: '
      print, valid_sites
      return
    endif

    relpathnames  = strupcase(site_code[i]) + '/' $
        + years + '/' + months + '/' + $
        'mica_ulf_' + site_code[i] +'_' + $
        daily_names + '_v??.cdf'
 
    filenames = ''
    if no_download EQ 0 then begin
        ;--- Download the designated data files from the remote data server
        ;    if the local data files are older or do not exist. 
        dprint, dlevel=1, 'Downloading ' + relpathnames + ' to ' + source.local_data_dir
        filenames = spd_download(remote_file=relpathnames, $
                             remote_path=source.remote_data_dir, $
                             local_path=source.local_data_dir, $
                             no_download=no_download, $
                             _extra=source, /last_version)
        if undefined(filenames) or filenames[0] EQ '' then $
           dprint, devel=1, 'Unable to download ' + filename 
    endif
              
    ; if remote file not found or no_download set then look for local copy 
    if filenames[0] EQ '' or no_download NE 0 then begin
      localfilename=source.local_data_dir + strupcase(site_code[i]) + '/' $
        + years + '/' + months + '/' + $
        'mica_ulf_' + site_code[i] +'_' + $
        daily_names + '_v**.cdf'
      filenames=file_search(localfilename)
    endif
     
    local_test=file_test(filenames)         
    if(total(local_test) ge 1) then begin        
      ;--- print PI info and rules of the road
      for j=0,n_elements(filenames)-1 do begin
        gatt = cdf_var_atts(filenames[j])
        print, '**************************************************************************************'
        print, gatt.Logical_source_description
        print, ''
        print, 'PI: ', gatt.PI_name
        print, 'Affiliation: ', gatt.PI_affiliation
        print, ''
        print, ''
      endfor

      undefine, tplotnames      
      ;--- Load data into tplot variables
      if(not keyword_set(suffix)) then this_suffix='_'+site_code[i] else this_suffix='_'+site_code[i]+suffix

      cdf2tplot, file=filenames, verbose=source.verbose, $
        suffix=this_suffix, tplotnames=tplotnames

      get_data, 'spectra_x_1Hz' + this_suffix, data = spec_tmp
      w_fill = where(spec_tmp.y gt 1000., count)
      if count gt 0 then spec_tmp.y[w_fill] = !values.f_nan
      store_data, 'spectra_x_1Hz' + this_suffix, data = spec_tmp

      get_data, 'spectra_y_1Hz' + this_suffix, data = spec_tmp
      w_fill = where(spec_tmp.y gt 1000., count)
      if count gt 0 then spec_tmp.y[w_fill] = !values.f_nan
      store_data, 'spectra_y_1Hz' + this_suffix, data = spec_tmp

      get_data, 'spectra_x_5Hz' + this_suffix, data = spec_tmp
      w_fill = where(spec_tmp.y gt 1000., count)
      if count gt 0 then spec_tmp.y[w_fill] = !values.f_nan
      store_data, 'spectra_x_5Hz' + this_suffix, data = spec_tmp

      get_data, 'spectra_y_5Hz' + this_suffix, data = spec_tmp
      w_fill = where(spec_tmp.y gt 1000., count)
      if count gt 0 then spec_tmp.y[w_fill] = !values.f_nan
      store_data, 'spectra_y_5Hz' + this_suffix, data = spec_tmp

      ; check the time span of the data and clip if needed
      error = 0
      if n_elements(tr) eq 2 and tplotnames[0] ne '' then begin
          error=0
          if ~no_time_clip then time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
          if error EQ 1 then begin
            dprint, dlevel=1, 'The time requested for '+tplotnames+' is out of range'
            dprint, dlevel=1, 'No data was loaded for '+tplotnames
            del_data, tplotnames
            tplotnames=''
            return
          endif
     endif else begin
       dprint, dlevel=1, 'Unable to find ' + relpathnames
     endelse

  endif else begin
    dprint, dlevel=1, 'Unable to load ' + site_code[i] + ' for ' + time_string(trange)   
  endelse
  
  ; clean up names
  undefine, tplotnames

endfor   ; end of site loop

return
end

