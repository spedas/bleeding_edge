;+
; PROCEDURE:
;         elf_load_FGM
;
; PURPOSE:
;         Load the ELFIN FGM
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;                       Default: ['2022-08-19', '2022-08-20']
;         probes:       list of probes, valid values for elf probes are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         datatype:     valid datatypes include level 1 - ['fgf', 'fgs'] and 
;                       level 2 -['fgf_dsl','fgf_gei','fgf_mag','fgs_dsl','fgs_gei','fgs_mag']
;         data_rate:    instrument data rates include ['srvy', 'fast']. The default is 'srvy'.
;         units:        units include ['ACD', 'nT'], the default is 'nT'
;         level:        indicates level of data processing. levels include 'l1' and 'l2'
;                       The default if no level is specified is 'l1' (l1 default needs to be confirmed)
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\elfin\)
;         source:       specifies a different system variable. By default the elf mission system
;                       variable is !elf
;         get_support_data: load support data, state and IGRF data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're
;                       using this load routine from a terminal without an X server running
;         no_time_clip: set this keyword to not clip the data to the requested time range; 
;         no_update:    set this flag to preserve the original data. if not set and newer data is
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval
;                       (e.g., /latest_version)
;         major_version: only open the latest major CDF version (e.g., X in vX.Y.Z) in the requested time interval
;         min_version:  specify a minimum CDF version # to load
;         cdf_records:  specify a number of records to load from the CDF files.
;                       e.g., cdf_records=1 only loads in the first data point in the file
;                       This is especially useful for loading S/C position for a single time
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         available:    returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         no_download:  this keyword will turn downloading off and look for the file locally
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         no_time_sort: set this flag if you don't want the time ordered
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;
; EXAMPLES:
;         to load/plot the FGM magnetometer data for probe a on 2/20/2019:
;         elf> elf_load_fgm, probe='a', trange=['2016-02-20', '2016-02-21'], level='l1'
;         elf> tplot, 'ela_fgs'
;
; NOTES:
;
; HISTORY:
;         egrimes, replaced new_tvars code with tplotnames and enabled calibration by default, 14 March 2019 
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_load_fgm.pro $
;-

pro elf_load_fgm, trange = trange, probes = probes, datatype = datatype, $
  level = level, data_rate = data_rate, no_time_sort=no_time_sort, $
  local_data_dir = local_data_dir, source = source, no_download=no_download, $
  get_support_data = get_support_data, no_cal=no_cal, units=units, $
  tplotnames = tplotnames, no_color_setup = no_color_setup, $
  no_time_clip = no_time_clip, no_update = no_update, suffix = suffix, $
  varformat = varformat, cdf_filenames = cdf_filenames, no_conversion=no_conversion, $
  cdf_version = cdf_version, latest_version = latest_version, $
  min_version = min_version, cdf_records = cdf_records, $
  spdf = spdf, available = available, versions = versions, $
  always_prompt = always_prompt, major_version=major_version, tt2000=tt2000

  ; check and/or initialize parameters
  if undefined(probes) then probes = ['a'] else probes=strlowcase(probes)
  ;if probes EQ ['*'] then probes = ['a', 'b']
  if n_elements(probes) GT 2 then begin
    dprint, dlevel = 1, 'There are 2 ELFIN probes - a and b. Please select again.'
    return
  endif
  ; check for valid probe names
  probes = strlowcase(probes)
  idx = where(probes EQ 'a', acnt)
  idx = where(probes EQ 'b', bcnt)
  if acnt EQ 0 && bcnt EQ 0 then begin
    dprint, dlevel = 1, 'Invalid probe name. Valid probes are a and/or b. Please select again.'
    return
  endif
  
  ;clear so new names are not appended to existing array
  undefine, tplotnames
  ; clear CDF filenames, so we're not appending to an existing array
  undefine, cdf_filenames

  if undefined(level) then level = 'l1'
  if undefined(datatype) then datatype = ['fgs'] else datatype=strlowcase(datatype)
  if datatype EQ ['*'] then datatype = ['fgs']
  if n_elements(datatype) EQ 1 then datatype=strsplit(datatype, ' ', /extract)
  idx = where(datatype EQ 'fgs', scnt)
  if scnt EQ 0 then begin
    dprint, dlevel = 1, 'Invalid data type. Valid types are fgs. Please select again.'
    return
  endif
  if undefined(units) then units='nT'
  idx = where(units EQ 'nT', ncnt)
  idx = where(units EQ 'ADC', adcnt)
  if ncnt EQ 0 && adcnt EQ 0 then begin
    dprint, dlevel = 1, 'Invalid unit. Valid units are nT or ACDC. Please select again.'
    return
  endif

  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy' else data_rate=strlowcase(data_rate)
  if data_rate EQ '*' then data_rate=['srvy']
  if undefined(no_cal) then no_cal = 0  
  if ~undefined(trange) then begin
    dur=time_double(trange[1])-time_double(trange[0])
    timespan, trange[0],dur,/sec
  endif else begin
    trange=time_double(['2022-08-19', '2022-08-20'])
  endelse

  elf_load_data, trange = trange, probes = probes, level = level, instrument = 'fgm', $
    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
    datatype = datatype, get_support_data = get_support_data, no_time_sort=no_time_sort, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, no_time_clip = no_time_clip, $
    no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, cdf_records = cdf_records, spdf = spdf, available = available, $
    versions = versions, tt2000=tt2000, no_download=no_download
 
  ; no reason to continue if no data were loaded
  if undefined(tplotnames) then return

  ; Perform pseudo calibration for level 1 fgm
  tname_fgs='el'+probes+'_fgs'
  idx = where(tplotnames eq tname_fgs, ncnt)
  if ncnt GT 0 and no_cal NE 1 then elf_cal_fgm, tplotnames[idx], level=level, error=error, units=units
  
  ;set colors
  if  ~undefined(tplotnames) && tplotnames[0] ne '' then begin
    for i=0,n_elements(tplotnames)-1 do begin
      get_data, tplotnames[i], data=d, dlimits=dl, limits=l
      options, /def, tplotnames[i], 'colors', ['b','g','r']
    endfor
  endif
  
  nidx=where(tplotnames EQ 'el'+probes+'_fgs_fsp_res_dmxl', ncnt)
  get_data, 'el'+probes+'_fgs_fsp_res_dmxl', data=fsp_res_dmxl, dlimits=fsp_res_dmxl_dl, limits=fsp_res_dmxl_l
  if ncnt GT 0 && (size(fsp_res_dmxl, /type)) EQ 8 then begin
    tdiff = fsp_res_dmxl.x[1:n_elements(fsp_res_dmxl.x)-1] - fsp_res_dmxl.x[0:n_elements(fsp_res_dmxl.x)-2]
    idx = where(tdiff GT 270., ncnt)
    append_array, idx, n_elements(fsp_res_dmxl.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[fsp_res_dmxl.x[0]]
      sz_endtimes=fsp_res_dmxl.x[n_elements(fsp_res_dmxl.x)-1]
      ts=time_struct(sz_starttimes[0])
      te=time_struct(sz_endtimes[0])
    endif else begin
      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = fsp_res_dmxl.x[0]
          sidx = 0
          this_e = fsp_res_dmxl.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = fsp_res_dmxl.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = fsp_res_dmxl.x[idx[sz]]
          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 15. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor
    endelse
  endif

  ; perform coordinate conversions from gei to NDW and OBW
  if ~keyword_set(no_conversion) then begin

  if  ~undefined(tplotnames) && tplotnames[0] ne '' then begin
    if size(fsp_res_dmxl, /type) EQ 8 then begin
      tr=timerange()
;      stop
      tr=time_double(trange)     
      ; will need position data for coordinate transforms
      elf_load_state, probe=probes, trange=tr, no_download=no_download, suffix='_fsp'
      ; verify that state data was loaded, if not print error and return
      if ~spd_data_exists('el'+probes+'_pos_gei_fsp',tr[0],tr[1]) then begin
        dprint, 'There is no data for el'+probes+'_pos_gei for '+ $
          time_string(tr[0])+ ' to ' + time_string(tr[1])
        dprint, 'Unable to perform fgs_fsp_res_gei coordinate transforms to ndw and obw'
      endif else begin
        ; Transform data to ndw coordinates
        tr=time_double(trange)
        elf_fgm_fsp_gei2ndw, trange=tr, probe=probes, sz_starttimes=sz_starttimes, sz_endtimes=sz_endtimes   
        ; Transform data to obw coordinates
        elf_fgm_fsp_gei2obw, trange=tr, probe=probes, sz_starttimes=sz_starttimes, sz_endtimes=sz_endtimes
      endelse
    endif
  endif
  endif
  
  ; check whether user wants support data tplot vars
  if ~keyword_set(get_support_data) then begin
    idx=where(strpos(tplotnames,'igrf') GT 0, ncnt)
    if ncnt GT 0 then begin
      del_data, '*fsp_igrf*
    endif
    idx=where(strpos(tplotnames, 'trend') GT 0, ncnt)
    if ncnt GT 0 then begin
      del_data, '*fsp_res_dmxl_trend'
    endif
    tn=tnames('*_fsp')
    if tn[0] ne '' then begin
      del_data, tn
    endif
  endif else begin
    copy_data, 'el'+probes+'_pos_gei_fsp', 'el'+probes+'_fgs_fsp_pos_gei'
    copy_data, 'el'+probes+'_vel_gei_fsp', 'el'+probes+'_fgs_fsp_vel_gei'
    copy_data, 'el'+probes+'_att_gei_fsp', 'el'+probes+'_fgs_fsp_att_gei'
    copy_data, 'el'+probes+'_att_solution_date_fsp', 'el'+probes+'_fgs_fsp_att_solution_date'
    copy_data, 'el'+probes+'_att_flag_fsp', 'el'+probes+'_fgs_fsp_att_flag'
    copy_data, 'el'+probes+'_att_spinper_fsp', 'el'+probes+'_fgs_fsp_att_spinper'
    copy_data, 'el'+probes+'_spin_orbnorm_angle_fsp', 'el'+probes+'_fgs_fsp_spin_orbnorm_angle'
    copy_data, 'el'+probes+'_spin_sun_angle_fsp', 'el'+probes+'_fgs_fsp_sun_angle'
    del_data, '*_fsp'
  endelse
  tplot_names
end