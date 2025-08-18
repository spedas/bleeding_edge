;+
; PROCEDURE:
;         mms_load_scm
;         
; PURPOSE:
;         Load data from the MMS Search Coil Magnetometer (SCM)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss'] 
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. If 
;                       no probe is specified the default is '1'
;         level:        indicates level of data processing. scm levels include 'l1a', 'l1b', 
;                       'l2'. The default if no level is specified is 'l2'
;         datatype:     scm data types include ['cal', 'scb', 'scf', 'schb', 'scm', 'scs'].
;                       If no value is given the default is scsrvy for srvy data, and scb for brst data.
;         data_rate:    instrument data rates for MMS scm include 'brst' 'fast' 'slow' 'srvy'. 
;                       The default is 'srvy'. 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       ariable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load
;                       routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data 
;                       is found the existing data will be overwritten 
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
;     load scm burst data
;     MMS> mms_load_scm, trange=['2015-09-13',2015-09-14'], probes='1', level='l1b', $
;                    data_rate='brst', datatype='scb'
;
;     set time span and load probes 1 and 2 survey data
;     timespan, '2015-09-13', 1d
;     MMS> mms_load_scm, probes=['1','2'], level='l1b', data_rate='srvy', datatype='scm'
;
;     get list of valid scm rates, levels, and datatypes
;     MMS> mms_load_options, 'scm', rate=r, level=l, datatype=dt 
;     
;     See crib sheet mms_load_scm_crib.pro for more detailed usage examples
;     
; NOTES:
;    The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;    Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;          
;          
;    Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-12-04 14:03:21 -0800 (Wed, 04 Dec 2019) $
;$LastChangedRevision: 28081 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/scm/mms_load_scm.pro $
;-

pro mms_load_scm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, tplotnames = tplotnames, $
                  no_color_setup = no_color_setup, time_clip = time_clip, $
                  no_update = no_update, suffix = suffix, varformat = varformat, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version, $
                  spdf = spdf, available = available, versions = versions, $
                  always_prompt = always_prompt, major_version=major_version, tt2000=tt2000, $
                  download_only=download_only

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = ''
    if datatype[0] eq '*' then datatype = ['scsrvy', 'scb', 'schb']
    if undefined(level) then level = 'l2'
    if undefined(data_rate) then data_rate = 'srvy'
    ;if data_rate eq 'srvy' then datatype = 'scsrvy'
    if array_contains(data_rate, 'srvy') && ~array_contains(datatype, 'scsrvy') then append_array, datatype, 'scsrvy'
    if array_contains(data_rate, 'brst') && (~array_contains(datatype, 'scb') && ~array_contains(datatype, 'schb')) then append_array, datatype, ['scb', 'schb']
   ; if undefined(datatype) && data_rate eq 'brst' then datatype = 'scb'
    if undefined(time_clip) then time_clip = 1  ;to account for tt2000 time range set in meta data
    
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'scm', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, available = available, versions = versions, always_prompt = always_prompt, $
        major_version=major_version, tt2000=tt2000, download_only=download_only

    if keyword_set(download_only) then return
    
    if level eq 'l1a' then coord = '123'
    if level eq 'l1b' then coord = 'scm123'
    if level eq 'l2'  then coord = 'gse'
    
    for datatype_idx = 0, n_elements(datatype)-1 do begin
      mms_set_scm_options, tplotnames, prefix = 'mms' + probes, datatype = datatype[datatype_idx], coord=coord, suffix=suffix
    endfor
    
    
end