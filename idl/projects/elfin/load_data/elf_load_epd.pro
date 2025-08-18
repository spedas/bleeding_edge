;+
; PROCEDURE:
;         elf_load_epd
;
; PURPOSE:
;         Load the ELFIN EPD
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;                       Default: ['2022-08-19', '2022-08-20']
;         probes:       list of probes, valid values for elf probes are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         datatype:     valid datatypes include level 1 - ['pif', 'pef']  (there may be 
;                       survey data for epd but it has not yet been downloaded ['pis', 'pes']
;         data_rate:    instrument data rates include ['fast']. There may be srvy (survey data
;                       is not yet available).
;         level:        indicates level of data processing. levels include 'l1' and 'l2'
;                       The default if no level is specified is 'l1' 
;         type:         ['raw','cps', 'nflux', 'eflux']  (eflux not fully tested)
;         full_spin:    data defaults to half_spin resolution, set this flag to return full_spin resolution
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\elfin\)
;         source:       specifies a different system variable. By default the elf mission system
;                       variable is !elf
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're
;                       using this load routine from a terminal without an X server running
;         no_time_clip: don't clip the data to the requested time range; note that if you do use
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         no_suffix:    keyword to turn off automatic suffix of data type (e.g. '_raw' or '_nflux)
;                       note that no_suffix will override whatever value of suffix may have been passed in
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         cdf_records:  specify a number of records to load from the CDF files.
;                       e.g., cdf_records=1 only loads in the first data point in the file
;                       This is especially useful for loading S/C position for a single time
;         no_download:  specify this keyword to load only data available on the local disk
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         no_time_sort:  set this flag to not order time and remove duplicates
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         no_spec:      flag to set tplot options to linear rather than the default of spec
;
; EXAMPLES:
;         to load/plot the EPD data for probe a on 2/20/2019:
;         elf> elf_load_epd, probe='a', trange=['2019-07-26', '2019-07-27'], level='l1', data_type='pif_counts'
;         elf> tplot, 'ela_pif'
;
; NOTES:
;
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_load_fgm.pro $
;-
pro elf_load_epd, trange = trange, probes = probes, datatype = datatype, $
  level = level, data_rate = data_rate, no_spec = no_spec, no_time_sort=no_time_sort, $
  local_data_dir = local_data_dir, source = source, resolution=resolution, $
  get_support_data = get_support_data, type=type, no_suffix=no_suffix, $
  tplotnames = tplotnames, no_color_setup = no_color_setup, $
  no_time_clip = no_time_clip, no_update = no_update, suffix = suffix, $
  varformat = varformat, cdf_filenames = cdf_filenames, no_download=no_download, $
  cdf_version = cdf_version, cdf_records = cdf_records, $
  spdf = spdf, versions = versions, tt2000=tt2000, $
  nspinsinsum=my_nspinsinsum
;stop  
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = time_double(['2022-08-19', '2022-08-20'])

  if undefined(probes) then probes = ['a', 'b'] 
  if probes EQ ['*'] then probes = ['a', 'b']
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
  
  if undefined(level) then level = ['l1'] 
  if level EQ '*' then level = ['l1'] 

  ; check for valid datatypes for level 1 NOTE: we only have l1 data so far
  ; NOTE: Might need to add pis, and pes
  if undefined(datatype) then datatype=['pef', 'pif','pes', 'pis'] else datatype = strlowcase(datatype)
  if datatype[0] EQ '*' then datatype=['pef', 'pif','pes', 'pis']
  if n_elements(datatype) EQ 1 then datatype=strsplit(datatype, ' ', /extract)
  idx = where(datatype EQ 'pif', icnt)
  idx = where(datatype EQ 'pef', ecnt)
  idx = where(datatype EQ 'pis', sicnt)
  idx = where(datatype EQ 'pes', secnt)
  if icnt EQ 0 && ecnt EQ 0 && sicnt EQ 0 && secnt EQ 0 then begin
    dprint, dlevel = 1, 'Invalid data type name. Valid types are pef, pif. Please select again.'
    return
  endif
  
  if undefined(data_rate) then data_rate = ['fast'] else data_rate=strlowcase(data_rate)
  if data_rate EQ '*' then data_rate = ['fast']  ;, 'srvy'] NO SURVEY DATA YET

  if undefined(type) then type='nflux' else type=type
  if type EQ 'cal' || type EQ 'calibrated' then type='nflux'
  if undefined(suffix) OR keyword_set(no_suffix) then suffix = ''
  if undefined(resolution) then resolution=['halfspin','fullspin']
  if level eq 'l2' then begin
    if type NE 'nflux' and type NE 'eflux' then begin
      dprint, dlevel = 1, 'Invalid level 2 data type. Defaulting to nflux'
    endif
  endif
  
  Case type of
    'raw': unit = 'counts/sector'
    'cps': unit = 'counts/s'
    'nflux': unit = '#/(scm!U2!NstrMeV)'
    'eflux': unit = 'keV/(scm!U2!NstrMeV)'
    else: begin     ; default to nflux if user didn't enter type
      unit = '#/(scm!U2!NstrMeV)'
      type = 'nflux'
    end
  endcase

  elf_load_data, trange = tr, probes = probes, level = level, instrument = 'epd', $
    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
    datatype = datatype, get_support_data = get_support_data, no_time_sort=no_time_sort, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, no_time_clip = no_time_clip, $
    no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, cdf_records = cdf_records, spdf = spdf, $
    versions = versions, tt2000=tt2000, no_download=no_download

  ; no reason to continue if no data were loaded
  if undefined(tplotnames) || tplotnames[0] EQ '' then begin
    dprint, dlevel = 1, 'No data was loaded for EPD for ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
    return
  endif

  ; Level 1 Post processing - calibration and fix meta data 
  if level eq 'l1' then elf_epd_l1_postproc, tplotnames, trange=trange, type=type, suffix=suffix, $
    my_nspinsinsum=my_nspinsinsum, unit=unit, no_spec=no_spec, no_download=no_download

  ; Level 2 Post processing - calibration and fix meta data
  if level eq 'l2' then begin
    elf_epd_l2_postproc, tplotnames, probes=probes   ;, full_spin=full_sping
  endif
   
END
