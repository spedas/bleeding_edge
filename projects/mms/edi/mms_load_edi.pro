;+
; PROCEDURE:
;         mms_load_edi
;
; PURPOSE:
;         Load data from the Electron Drift Instrument (EDI) onboard MMS
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. Current level is ['ql','l1a']. 
;                       if no level is specified the routine defaults to 'ql' (for survey mode).
;         datatype:     data types include currently include ['efield', 'amb']. 
;                       the default is 'efield'
;         data_rate:    instrument data rates include ['brst', 'fast', 'slow', 'srvy']. 
;                       the default is 'srvy'
;         local_data_dir: local directory to store the CDF files; should be set if you're on
;                       *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
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
; OUTPUT:
;
; EXAMPLE:
;     See mms_load_edi_crib.pro for usage examples.
;     
;     load L2 EDI survey data
;     MMS>  mms_load_edi, data_rate='srvy', probes=probe, datatype='efield', trange=['2015-09-03', '2015-09-04']
;                
; NOTES:               
;    The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;    Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-08-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/edi/mms_load_edi.pro $
;-

pro mms_load_edi, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, $
    varformat = varformat, cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
    latest_version = latest_version, min_version = min_version, spdf = spdf, $
    available = available, versions = versions, always_prompt = always_prompt, $
    major_version=major_version, tt2000=tt2000

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'efield'
    if undefined(level) then level = 'l2'
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'
    ; load the support data - includes energy of measured electrons for ambient data
    ; delta +- time, velocity and energy for efield data
    if undefined(get_support_data) then get_support_data = 1 
    if undefined(cdf_version) and undefined(latest_version) and undefined(min_version) and undefined(major_version) then min_version = '0.0.1'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'edi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, available = available, versions = versions, always_prompt = always_prompt, $
        major_version=major_version, tt2000=tt2000
    
    for probe_idx = 0, n_elements(probes)-1 do mms_edi_set_metadata, tplotnames, prefix='mms'+strcompress(string(probes[probe_idx]), /rem), data_rate=data_rate, suffix=suffix

end