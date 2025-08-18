;+
; PROCEDURE:
;         mms_load_feeps
;         
; PURPOSE:
;         Load data from the Fly's Eye Energetic Particle Sensor (FEEPS) onboard MMS
; 
; KEYWORDS: 
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is '1'
;         level:        indicates level of data processing. levels include 'l2', 'l1b', 'l1a'. 
;                       The default if no level is specified is 'l2'
;         datatype:     feeps data types include:
;                       L2, L1b: ['electron', 'ion']
;                       L1a: ['electron-bottom', 'electron-top', 'ion-bottom', 'ion-top']
;                       If no value is given the default is 'electron' for L2/L1b data, and all
;                       for L1a data.
;         data_rate:    instrument data rates for feeps include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   specify units for omni-directional calculation and spin averaging
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using 
;                       this load routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use 
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
;         spdf: grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         num_smooth:   set this keyword to create a smoothed omni-directional spectra variable
;                      num_smooth=1.0, ~3 data points for 1 sec; use num_smooth=19.0 for smoothing over a full spin
;         available:    returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         ignore_telescopes: value (or array of values) representing telescope # to ignore while calculating omni-directional spectrograms
;         keep_bad_eyes: If set, do not remove bad eyes (defaults to false)
;
; OUTPUT:
;  
; EXAMPLE:
;     load electron data (srvy mode)
;     MMS> mms_load_feeps, probes='1', trange=['2015-12-15', '2015-12-16'], datatype='electron'
;     MMS> mms_feeps_pad,  probe='1', datatype='electron'
;     
;     See crib sheet mms_load_feeps_crib.pro for usage examples
;     
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;     Attempts to load FEEPS CDF files with different major versions (e.g., 5.5 and 6.1) will likely lead to 
;     errors; be sure to use the CDF version keywords to load only one major version at a time (e.g., /latest_version or /major_version)
;     
;     Due to a change in variable names, this routine currently only supports v5.5+ of the FEEPS CDFs
;   
;     Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;          
;          
;     The spectra variables created with "_clean" in their names have 
;       the 500 keV integral channel removed.
;     The spectra variables with '_sun_removed' in their names 
;       have the sun contamination removed 
;       
;       (*_clean_sun_removed variables have both the 500 keV integral 
;         channel removed and the sun contamination removed)
; 
;     FEEPS sensor eyes:
;     - Electron Eyes: 1, 2, 3, 4, 5, 9, 10, 11, 12
;     - Ion Eyes: 6, 7, 8
;     
;     8Sept17: Updated to use different active telescopes before/after the CIDP software update on 16 August 2017
;     14Sept17: Updated to use different active telescopes for level=SITL ^^
;     
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2024-03-27 16:34:54 -0700 (Wed, 27 Mar 2024) $
;$LastChangedRevision: 32511 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_load_feeps.pro $
;-
pro mms_load_feeps, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, data_units= data_units, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  varformat = varformat, cdf_filenames = cdf_filenames, $
                  cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version, spdf = spdf, num_smooth = num_smooth, $
                  available = available, versions = versions, always_prompt = always_prompt, $
                  major_version=major_version, no_flatfield_corrections=no_flatfield_corrections, $
                  tt2000=tt2000, ignore_telescopes=ignore_telescopes, download_only=download_only, keep_bad_eyes=keep_bad_eyes

    if undefined(level) then level_in = 'l2' else level_in = level
    if undefined(probes) then probes_in = ['1'] else probes_in = probes
    if undefined(datatype) then datatype_in = 'electron' else datatype_in = datatype
    if undefined(data_units) then data_units = ['count_rate', 'intensity']
    if undefined(data_rate) then data_rate_in = 'srvy' else data_rate_in = data_rate
    
    ; the following was added 26 May 2023 to fix issue with mixture of v6 and v7 files at the SDC
    ; these files are not compatible, so there are crashes when trying to load both at the same time
    if undefined(min_version) && undefined(latest_version) && undefined(cdf_version) && undefined(major_version) then major_version = 1b
    
    if undefined(min_version) && undefined(latest_version) && undefined(cdf_version) && undefined(major_version) then min_version = '5.5.0'
    if undefined(get_support_data) then get_support_data = 1 ; support data needed for sun removal and spin averaging
    l1a_datatypes = ['electron-bottom', 'electron-top', 'ion-top', 'ion-bottom']
    
    if level_in eq 'l1a' && ~is_array(ssl_set_intersection(l1a_datatypes, [datatype_in])) then begin
        dprint, dlevel = 0, 'Couldn''t find the datatype: "' + datatype_in + '" for L1a data; loading all data...'
        datatype_in = l1a_datatypes
    endif
    
    ; we need trange in this routine for the time dependent sun masks
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
    else tr = timerange()
    
    ; if the user requests a specific varformat, we'll need to load 
    ; the support data required for sun removal and spin averaging
    if ~undefined(varformat) && (varformat[0] ne '*') then begin
      if is_array(varformat) then varformat = [varformat, '*_spinsectnum', '*_pitch_angle'] $
      else varformat = varformat + ' *_spinsectnum *_pitch_angle'
    endif
    if ~undefined(varformat) && ~undefined(get_support_data) then undefine, get_support_data

    if undefined(keep_bad_eyes) then keep_bad_eyes=0
        
    mms_load_data, trange = tr, probes = probes_in, level = level_in, instrument = 'feeps', $
        data_rate = data_rate_in, local_data_dir = local_data_dir, source = source, $
        datatype = datatype_in, get_support_data=get_support_data, $ ; support data is needed for spin averaging, etc.
        tplotnames = tplotnames, no_color_setup = no_color_setup, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, available = available, versions = versions, always_prompt = always_prompt, $
        major_version=major_version, tt2000=tt2000, download_only=download_only
    
    if undefined(tplotnames) || tplotnames[0] eq '' || keyword_set(download_only) then return
    
    if level_in eq 'l1a' then return ; avoid the following for L1a data

    ; correct energy tables based on probe, sensor head and sensor ID
    mms_feeps_correct_energies, probes=probes_in, data_rate = data_rate_in, level = level_in, suffix = suffix, keep_bad_eyes=keep_bad_eyes
    
    ; apply flat field corrections for ions
    if undefined(no_flatfield_corrections) then mms_feeps_flat_field_corrections, probes = probes_in, data_rate = data_rate_in, suffix = suffix

    for probe_idx = 0, n_elements(probes_in)-1 do begin
      this_probe = string(probes_in[probe_idx])
      for datatype_idx = 0, n_elements(datatype_in)-1 do begin
        this_datatype = datatype_in[datatype_idx]
        
        ; remove bad eyes, bad energy channels
        mms_feeps_remove_bad_data, probe=this_probe, datatype=this_datatype, $
          data_rate=data_rate_in, level = level, suffix = suffix, trange=tr
        
        for data_units_idx = 0, n_elements(data_units)-1 do begin
          ; updated active eyes, 9/8/2017
          eyes = mms_feeps_active_eyes(tr, this_probe, data_rate_in, this_datatype, level, keep_bad_eyes=keep_bad_eyes)
          
          ; user requested to ignore a specific telescope
          if keyword_set(ignore_telescopes) then begin
            for ignore_idx=0, n_elements(ignore_telescopes)-1 do begin
              top_or_bottom = strmid(ignore_telescopes[ignore_idx], 0, 1) ; should be t (for top) or b (for bottom)
              if strlowcase(top_or_bottom) eq 't' then begin
                new_top_eyes = list(eyes['top'], /extract)
                eye_to_remove = where(new_top_eyes eq strjoin(strsplit(ignore_telescopes[ignore_idx], 't', /extract)), ignore_count)
                if ignore_count eq 0 then begin
                  dprint, dlevel=0, 'Telescope not found: ' + strcompress(string(ignore_telescopes[ignore_idx]), /rem)
                endif else begin
                  removed = new_top_eyes.remove(eye_to_remove)
                endelse
                eyes['top'] = new_top_eyes.toarray()
              endif else if strlowcase(top_or_bottom) eq 'b' then begin
                new_bot_eyes = eyes['bottom']
                new_bot_eyes = list(eyes['bottom'], /extract)
                eye_to_remove = where(new_bot_eyes eq strjoin(strsplit(ignore_telescopes[ignore_idx], 'b', /extract)), ignore_count)
                if ignore_count eq 0 then begin
                  dprint, dlevel=0, 'Telescope not found: ' + strcompress(string(ignore_telescopes[ignore_idx]), /rem)
                endif else begin
                  removed = new_bot_eyes.remove(eye_to_remove)
                endelse
                eyes['bottom'] = new_bot_eyes.toarray()
              endif else begin
                dprint, dlevel=0, 'Error, unknown telescope specified in the ignore_telescopes keyword.'
                return
              endelse
            endfor
          endif

          ; split the extra integral channel from all of the spectrograms
          mms_feeps_split_integral_ch, data_units[data_units_idx], this_datatype, this_probe, $
              suffix = suffix, data_rate = data_rate_in, level = level_in, sensor_eyes = eyes

          ; remove the sunlight contamination
          mms_feeps_remove_sun, probe = this_probe, datatype = this_datatype, level = level_in, $
              data_rate = data_rate_in, suffix = suffix, data_units = data_units[data_units_idx], $
              tplotnames = tplotnames, trange=tr, sensor_eyes = eyes
    
          ; calculate the omni-directional spectra
          mms_feeps_omni, this_probe, datatype = this_datatype, tplotnames = tplotnames, data_units = data_units[data_units_idx], $
              data_rate = data_rate_in, suffix=suffix, level = level_in, sensor_eyes = eyes
    
          ; calculate the spin averages
          mms_feeps_spin_avg, probe=this_probe, datatype=this_datatype, suffix = suffix, data_units = data_units[data_units_idx], $
              tplotnames = tplotnames, data_rate = data_rate_in, level = level_in
          
          ; calculate the smoothed products
          if ~undefined(num_smooth) then mms_feeps_smooth, probe=this_probe, datatype=this_datatype, $
            suffix=suffix, data_units=data_units[data_units_idx], data_rate=data_rate_in, level=level_in, num_smooth=num_smooth
        endfor
      endfor
    endfor
   
    if ~undefined(time_clip) then begin
      if (n_elements(tr) eq 2) and ~undefined(tplotnames) && (tplotnames[0] ne '') and ~undefined(time_clip) then begin
        time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
      endif
    endif
end