;+
; PROCEDURE:
;         mms_load_fsm
;
; PURPOSE:
;         Load MMS FSM data
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. the default if no level is specified is 'l3'
;         data_rates:   instrument data rate
;         local_data_dir: local directory to store the CDF files
;         source:       sets a different system variable. By default the MMS mission system variable
;                       is !mms
;         tplotnames:   returns a list of the loaded tplot variables
;         get_support_data: when set this routine will load any support data (support data is specified in the CDF file)
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using this load routine from a
;                       terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you
;                       do not use this keyword, you may load a longer time range than requested
;         no_update:    use local data only, don't query the SDC for updated files.
;         suffix:       append a suffix to tplot variables names
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval
;             (e.g., /latest_version)
;         major_version: only open the latest major CDF version (e.g., X in vX.Y.Z) in the requested time interval
;         min_version:   specify a minimum CDF version # to load
;         spdf:          grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         available:     returns a list of files available at the SDC for the requested parameters
;                        this is useful for finding which files would be downloaded (along with their sizes) if
;                        you didn't specify this keyword (also outputs total download size)
;         versions:      this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for your username and password;
;                        useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                        SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;
;
; EXAMPLE:
; 
;
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-07-10 14:19:15 -0700 (Wed, 10 Jul 2019) $
;$LastChangedRevision: 27435 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fsm/mms_load_fsm.pro $
;-


pro mms_load_fsm, trange = trange, probes = probes, datatype = datatype, $
  level = level, instrument = instrument, data_rate = data_rate, $
  local_data_dir = local_data_dir, source = source, $
  get_support_data = get_support_data, $
  tplotnames = tplotnames, no_color_setup = no_color_setup, $
  time_clip = time_clip, no_update = no_update, suffix = suffix, $
  varformat = varformat, cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
  latest_version = latest_version, min_version = min_version, $
  spdf = spdf, available = available, versions = versions, $
  always_prompt = always_prompt, major_version=major_version, $
  keep_flagged=keep_flagged, tt2000=tt2000, download_only=download_only

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  if undefined(probes) then probes = ['1'] ; default to MMS 1
  probes = strcompress(string(probes), /rem) ; force the array to be an array of strings
  if undefined(datatype) then datatype = '8khz' 
  if undefined(level) then level = 'l3'
  if undefined(instrument) then instrument = 'fsm'
  if undefined(data_rate) then data_rate = 'brst'
  if undefined(suffix) then suffix = ''
  if undefined(get_support_data) then get_support_data = 1 ; load the flags by default
  
  if ~undefined(varformat) && get_support_data eq 1 then begin
    dprint, dlevel = 0, 'Appending *flag* to requested varformat, so the data can be deflagged'
    if is_array(varformat) then begin
      append_array, varformat, '*flag*'
    endif else begin
      varformat += ' *flag*'
    endelse
  endif
  
  mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
    datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
    no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
    suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
    spdf = spdf, available = available, versions = versions, always_prompt = always_prompt, $
    major_version=major_version, tt2000=tt2000, download_only=download_only

  ; no reason to continue if the user only requested available data
  if keyword_set(available) || keyword_set(download_only) then return

  if undefined(tplotnames) then return


  for probe_idx = 0, n_elements(probes)-1 do begin
    this_probe = 'mms'+strcompress(string(probes[probe_idx]), /rem)

    for data_rate_idx = 0, n_elements(data_rate)-1 do begin
      this_data_rate = data_rate[data_rate_idx]
      if ~keyword_set(keep_flagged) then begin
        ; B-field data
        get_data, this_probe+'_'+instrument+'_b_mag_'+this_data_rate+'_'+level+suffix, data=b_data_mag, dlimits=mag_dl
        get_data, this_probe+'_'+instrument+'_b_gse_'+this_data_rate+'_'+level+suffix, data=b_data_gse, dlimits=gse_dl
        ; flags
        get_data, this_probe+'_'+instrument+'_flag_'+this_data_rate+'_'+level+suffix, data=flags
        if is_struct(flags) then begin
          bad_data = where(flags.Y ne 0, flag_count)
          if flag_count ne 0 then begin
            if is_struct(b_data_gse) then b_data_gse.Y[bad_data, *] = !values.d_nan
            if is_struct(b_data_mag) then b_data_mag.Y[bad_data, *] = !values.d_nan

            ; resave them
            if is_struct(b_data_gse) then store_data, this_probe+'_'+instrument+'_b_gse_'+this_data_rate+'_'+level+suffix, data=b_data_gse, dlimits=gse_dl
            if is_struct(b_data_mag) then store_data, this_probe+'_'+instrument+'_b_mag_'+this_data_rate+'_'+level+suffix, data=b_data_mag, dlimits=mag_dl
          endif
        endif
      endif

      mms_fsm_set_metadata, tplotnames, data_rate=data_rate[data_rate_idx], prefix=this_probe, level=level, suffix=suffix
    endfor
  endfor

end