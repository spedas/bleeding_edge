;+
; PROCEDURE:
;         mms_load_dsp
;
; PURPOSE:
;         Load data from the Digital Signal Processing (DSP) board.
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. Current levels are ['l1b', 'l2']. 
;                       l2 data is available for 'slow' and 'fast' data rates
;                       l1b is available for 'srvy' data                       
;         datatype:     ['epsd', 'bpsd', 'swd']
;         data_rate:    instrument data rates include ['fast', 'slow', 'srvy']. 
;                       the default is 'srvy'. See level description above to determine which
;                       level data is available for a given data_rate.
;         local_data_dir: local directory to store the CDF files; should be set if you're on
;                       *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data:  loads any support data (support data is specified by var_type in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server running
;                       do not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not 
;                       use this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
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
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         available:    returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;
;
; EXAMPLE:
;    Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;          
;          
;     See mms_load_dsp_crib.pro for usage examples
;
;     ; set time frame and load edp level 2 data
;     MMS>  timespan, '2015-12-22', 1, /day
;     MMS>  mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='epsd', level='l2'
; 
; NOTES:
;    The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-08-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/dsp/mms_load_dsp.pro $
;-

pro mms_load_dsp, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, $
    varformat = varformat, cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
    latest_version = latest_version, min_version = min_version, spdf = spdf, $
    available = available, versions = versions, always_prompt = always_prompt, $
    major_version=major_version, tt2000=tt2000

    if undefined(probes) then probes = [1, 2, 3, 4] ; default to MMS 1
    if undefined(datatype) then datatype = ['epsd', 'bpsd','tdn', 'swd']
    if undefined(level) then level = ['l1a', 'l1b', 'l2'] else level = strlowcase(level)
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'
    
    if array_contains(level, 'l1a') || array_contains(level, 'l1b') then begin
        if array_contains(datatype, 'bpsd') then begin
            datatype_l1 = ['179', '17a', '17b']
            suffixes = '_'+['x', 'y', 'z']+suffix

            for datatype_idx = 0, n_elements(datatype_l1)-1 do begin
                mms_load_data, trange = trange, probes = probes, level = level, instrument = 'dsp', $
                    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
                    datatype = datatype_l1[datatype_idx], get_support_data = get_support_data, $
                    tplotnames = tplotnames_out, no_color_setup = no_color_setup, time_clip = time_clip, $
                    no_update = no_update, suffix = suffixes[datatype_idx], varformat = varformat, $
                    cdf_filenames = cdf_filenames_out, cdf_version = cdf_version, $
                    latest_version = latest_version, min_version = min_version, spdf = spdf, available = available, $
                    versions = cdf_versions_out, always_prompt = always_prompt, major_version=major_version, tt2000=tt2000
                append_array, tplot_names_full, tplotnames_out
                append_array, cdf_filenames_full, cdf_filenames_out
                append_array, versions_full, cdf_versions_out
            endfor
        endif
        if array_contains(datatype, 'epsd') then begin
            datatype_l1 = ['173', '174', '175', '176', '177', '178']
            suffixes = '_'+['x', 'y', 'z', 'x', 'y', 'z']+suffix
            ; only grab l1b if the user requested both l1a and l1b
            if array_contains(level, 'l1a') and array_contains(level, 'l1b') then $
                level = ssl_set_complement(['l1a'], level) 

            for datatype_idx = 0, n_elements(datatype_l1)-1 do begin
                mms_load_data, trange = trange, probes = probes, level = level, instrument = 'dsp', $
                    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
                    datatype = datatype_l1[datatype_idx], get_support_data = get_support_data, $
                    tplotnames = tplotnames_out, no_color_setup = no_color_setup, time_clip = time_clip, $
                    no_update = no_update, suffix = suffixes[datatype_idx], varformat = varformat, $
                    cdf_filenames = cdf_filenames_out, cdf_version = cdf_version, $
                    latest_version = latest_version, min_version = min_version, spdf = spdf, available = available, $
                    versions = cdf_versions_out, always_prompt = always_prompt, major_version=major_version, tt2000=tt2000
                append_array, tplot_names_full, tplotnames_out
                append_array, cdf_filenames_full, cdf_filenames_out
                append_array, versions_full, cdf_versions_out
            endfor
        endif
    endif
    if array_contains(level, 'l2') then begin
        for datatype_idx = 0, n_elements(datatype)-1 do begin
            mms_load_data, trange = trange, probes = probes, level = level, instrument = 'dsp', $
                data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
                datatype = datatype[datatype_idx], get_support_data = get_support_data, $
                tplotnames = tplotnames_out, no_color_setup = no_color_setup, time_clip = time_clip, $
                no_update = no_update, suffix = suffix, varformat = varformat, $
                cdf_filenames = cdf_filenames_out, cdf_version = cdf_version, $
                latest_version = latest_version, min_version = min_version, spdf = spdf, available = available, $
                versions = cdf_versions_out, always_prompt = always_prompt, major_version=major_version, tt2000=tt2000
            append_array, tplot_names_full, tplotnames_out
            append_array, cdf_filenames_full, cdf_filenames_out
            append_array, versions_full, cdf_versions_out
        endfor
        
    endif
    if ~undefined(tplot_names_full) then tplotnames = tplot_names_full
    if ~undefined(cdf_filenames_full) then cdf_filenames = cdf_filenames_full
    if ~undefined(versions_full) then versions = versions_full

    for level_idx = 0, n_elements(level)-1 do begin
      ; set some of the metadata
      mms_dsp_fix_metadata, tplotnames, prefix = 'mms' + probes, instrument = 'dsp', $
        data_rate = data_rate, suffix = suffix, level=level[level_idx]
    endfor
end