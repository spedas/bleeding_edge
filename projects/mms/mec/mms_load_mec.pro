;+
; PROCEDURE:
;         mms_load_mec
;
; PURPOSE:
;         Load the attitude/ephemeris data from the LANL MEC files
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         datatype:     valid datatypes include ['ephts04d', 'epht89q', 'epht89d']
;                       default is 'ephts04d'
;         data_rate:    instrument data rates include ['srvy', 'brst']. The default is 'srvy'.
; 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system
;                       variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're
;                       using this load routine from a terminal without an X server running
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
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;
; EXAMPLES:
;         to load/plot the S/C position data for probe 3 on 2/20/2016:
;         MMS> mms_load_mec, probe=3, trange=['2016-02-20', '2016-02-21']
;         MMS> tplot, 'mms3_mec_r_gsm'
;
; NOTES:
;    MISSING DATA: if the MEC data are missing for a date you suspect should contain data (>30 days ago), 
;                  try loading the datatype 'epht89d' instead of the default of 'epht04d'.
;                  There are sometimes issues with creating the Tsyganenko 04 data products,
;                  which leads to the default 'epht04d' files not being available. The 'epht89d' files
;                  contain the same ephemeris data - the only difference are the data products that rely on 
;                  the field model. 
;                  
; 
;    The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
; 
;    Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;          
;          
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-07-10 14:19:15 -0700 (Wed, 10 Jul 2019) $
;$LastChangedRevision: 27435 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_load_mec.pro $
;-

pro mms_load_mec, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, $
    varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, latest_version = latest_version, $
    min_version = min_version, cdf_records = cdf_records, $
    spdf = spdf, available = available, versions = versions, $
    always_prompt = always_prompt, major_version=major_version, tt2000=tt2000, $
    download_only=download_only

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'ephts04d'
    if undefined(level) then level = 'l2'
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'mec', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        cdf_records = cdf_records, spdf = spdf, available = available, versions = versions, $
        always_prompt = always_prompt, major_version=major_version, tt2000=tt2000, download_only=download_only
        
    ; no reason to continue if the user only requested available data
    if keyword_set(available) || keyword_set(download_only) then return
    
    ; no reason to continue if no data were loaded
    if undefined(tplotnames) then return

    ; turn the right ascension and declination of the L vector into separate tplot variables
    ; this is for passing to dmpa2gse.
    for probe_idx = 0, n_elements(probes)-1 do begin
        if tnames('mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_L_vec'+suffix) ne '' then begin
            split_vec, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_L_vec'+suffix, $
                names_out=ras_dec_vars     
            copy_data, ras_dec_vars[0], 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defatt_spinras'+suffix
            copy_data, ras_dec_vars[1], 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defatt_spindec'+suffix
        endif else dprint, dlevel = 1, 'No right ascension/declination of the L-vector found.'
        ; fix the metadata
        mms_mec_fix_metadata, probes[probe_idx], suffix = suffix
    endfor

end