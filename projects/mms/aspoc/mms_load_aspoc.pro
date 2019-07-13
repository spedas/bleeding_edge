;+
; PROCEDURE:
;         mms_load_aspoc
;         
; PURPOSE:
;         Load data from the Active Spacecraft Potential Control (ASPOC)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. levels include ['l1b', 'l2', 'ql',
;                       'sitl']. The default when no level is specified is 'l2' for data type 
;                       'aspoc' and 'l1b' for all others.
;         datatype:     data types include ['asp1', 'asp2', 'aspoc'].
;                       If no value is given the default is 'aspoc'.
;         data_rate:    instrument data rates include ['srvy', 'sitl']. The default is 'srvy'.
;                       Note only 'srvy' is available for 'aspoc' data type. 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server running
;                       do not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found the existing data will be overwritten
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
;         versions: this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See mms_load_aspoc_crib.pro for usage details.
; 
;     load L2 data for MMS 1 for aspoc1 
;     MMS> mms_load_aspoc, trange=['2015-07-15', '2015-07-16'], level='l2', probe=1
; 
; NOTES:
;    The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;     
;    For more information, including the ASPOC Data Products Guide, see:
;      https://lasp.colorado.edu/mms/sdc/public/datasets/aspoc/
;   
;    Have questions regarding this load routine, or its usage?
;      https://groups.google.com/forum/#!forum/spedas
;          
;          
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-07-10 14:19:15 -0700 (Wed, 10 Jul 2019) $
;$LastChangedRevision: 27435 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/aspoc/mms_load_aspoc.pro $
;-

pro mms_load_aspoc, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, tplotnames = tplotnames, $
                  no_color_setup = no_color_setup, instrument = instrument, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  varformat = varformat, cdf_filenames = cdf_filenames, $
                  cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version, spdf = spdf, available = available, $
                  versions = versions, always_prompt = always_prompt, major_version=major_version, $
                  tt2000=tt2000, download_only=download_only
                  
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    ; for ASPOC data, datatype = instrument
    if undefined(datatype) then instrument = 'aspoc' else instrument = datatype
    if instrument eq 'asp1' || instrument eq 'asp2' then datatype = 'beam' else datatype = ''
    
   ; if undefined(level) && instrument eq 'aspoc' then level = 'l2' 
    if undefined(level) then level = 'l2' else level = strlowcase(level)
    ; add the level to the suffix to avoid clobbering l1b and l2 data
    if undefined(suffix) then suffix = '_'+level else suffix = '_' + level + suffix
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, available = available, versions = versions, always_prompt = always_prompt, $
        major_version=major_version, tt2000=tt2000, download_only=download_only
         
; Commented out the following because it doesn't seem to help anymore
; egrimes, 2/29/2016
; 
;    for tvar_idx = 0, n_elements(tplotnames)-1 do begin
;        tvar_name = tplotnames[tvar_idx]
;        if instrument ne 'aspoc' && strfilter(tvar_name, '*_asp_*') ne '' then begin
;            str_replace, tvar_name, '_asp_', '_'+instrument+'_'
;            tplot_rename, tplotnames[tvar_idx], tvar_name
;            tplotnames[tvar_idx] = tvar_name
;        endif
;    endfor
end