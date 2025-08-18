;+
; PROCEDURE:
;         elf_load_eng
;
; PURPOSE:
;         Load the ELFIN engineering data 
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;                       Default: ['2022-08-19', '2022-08-20']
;         probes:       list of probes, valid values for elf probes are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         datatypes:    see list below 
;         data_rate:    instrument data rates are not applicable
;         level:        indicates level of data processing. levels include 'l1' and 'l2'
;                       The default if no level is specified is 'l1' (l1 default needs to be confirmed)
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
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         no_time_sort: set this flag if you don't want to order time and remove duplicates
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;
; EXAMPLES:
;         to load/plot the eng  data for probe a on 2/20/2019:
;         elf> elf_load_eng, probe='a', trange=['2016-02-20', '2016-02-21'], level='l1'
;         elf> tplot, 'ela_sips_5v0_voltage'
;
; NOTES:
;
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_load_eng.pro $
;-

pro elf_load_eng, trange = trange, probes = probes, datatype = datatype, $
  level = level, data_rate = data_rate, $
  local_data_dir = local_data_dir, source = source, $
  get_support_data = get_support_data, no_time_sort=no_time_sort, $
  tplotnames = tplotnames, no_color_setup = no_color_setup, $
  no_time_clip = no_time_clip, no_update = no_update, suffix = suffix, $
  varformat = varformat, cdf_filenames = cdf_filenames, $
  cdf_version = cdf_version, latest_version = latest_version, $
  min_version = min_version, cdf_records = cdf_records, $
  spdf = spdf, available = available, versions = versions, $
  always_prompt = always_prompt, major_version=major_version, tt2000=tt2000

  if undefined(probes) then probes = ['a','b'] else probes = strlowcase(probes) ; default to ELFIN A
  if probes[0] eq '*' then probes = ['a','b']
  probes = strcompress(string(probes), /rem) ; probes should be strings
  
  if undefined(trange) then trange = time_double(['2022-08-19', '2022-08-20']) else trange = trange

  if n_elements(probes) GT 2 then begin
    dprint, dlevel = 1, 'There are only 2 ELFIN probes - a and b. Please select again.'
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
  ; valid data types
;  valid_types = elf_load_options_eng()
    
  if undefined(datatype) then datatype = '' else datatype = strlowcase(datatype) ; this is the only type of mrm data
;  if datatype NE 'eng' then begin
;    dprint, dlevel = 1, 'Invalid data type. The only valid data type for eng is eng.'
;    return    
;  endif
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = ''

  elf_load_data, trange = trange, probes = probes, level = level, instrument = 'eng', $
    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
    datatype = datatype, get_support_data = get_support_data, no_time_sort=no_time_sort, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, no_time_clip = no_time_clip, $
    no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, spdf = spdf, tt2000=tt2000

  ; Set colors to RGB
;  if  ~undefined(tplotnames) && tplotnames[0] ne '' then begin
;    for i=0,n_elements(tplotnames)-1 do begin
;      elf_cal_eng, tplotnames[i]
;      options, /def, tplotnames[i], 'colors', [2,4,6]
;    endfor
;  endif

  ; no reason to continue if the user only requested available data
  if keyword_set(available) then return

  ; no reason to continue if no data were loaded
  if undefined(tplotnames) then return

end