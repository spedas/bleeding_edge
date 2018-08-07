;+
; PROCEDURE:
;         mms_load_eis
;         
; PURPOSE:
;         Load data from the MMS Energetic Ion Spectrometer (EIS)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. levels include 'l2', 'l1b' and 'l1a'
;                       The default if no level is specified is 'l1b'
;         datatype:     EIS data types include 'extof', 'phxtof', and 'electronenergy'.
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for EIS include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts']. 
;                       The default is 'flux'.
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: load support data (defined by VAR_TYPE="support_data" in the CDF)
;         tplotnames:   returns a list of the names of the tplot variables loaded by the load routine
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         no_interp:    if this flag is set no interpolation of the data will occur.
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
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public data)
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
;     load ExTOF burst data:
;     MMS1> mms_load_eis, probes='1', trange=['2015-12-23', '2015-12-24'],  datatype='extof', data_rate='brst', level='l2'
;            
;     load PHxTOF data:
;     MMS1> mms_load_eis, probes='1', trange=['2015-10-31', '2015-11-01'], datatype='phxtof', level='l2'
;     calculate the PHxTOF PAD for protons
;     MMS1> mms_eis_pad, probe='1', species='ion', datatype='phxtof', ion_type='proton', data_units='flux', energy=[0, 30], level='l2'
;
;     See mms_load_eis_crib.pro, mms_load_eis_burst_crib.pro,
;         and mms_load_eis_crib_qlplots.pro for usage examples
;         
;         
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;     Please see the EPD Data Products Guide for more information:
;     
;     https://lasp.colorado.edu/galaxy/display/mms/EPD+Data+Products+Guide 
;     
;     
;     Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;
; HISTORY:
;     09/15/2015 - Ian Cohen at APL: added modifications to omni-directional calculations to be able to handle 
;                  ExTOF and PHxTOF data
;     09/17/2015 - egrimes: large update, see svn log
;     12/15/2015 - icohen: added data_rate keyword and conditional definition of prefix in mms_eis_spin_avg and 
;                  mms_eis_omni to address burst variable name changes
;     4/20/2016  - egrimes added omni-directional spectra (without spin averaging)
;     4/28/2016  - egrimes changed no_interp options to include non-spin averaged omni-directional spectra
;                  changed default level to L2
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-08-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_load_eis.pro $
;-

pro mms_load_eis, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, data_units = data_units, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, no_interp = no_interp, $
                  suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
                  cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version, spdf = spdf, available = available, $
                  versions = versions, always_prompt = always_prompt, major_version=major_version, tt2000=tt2000

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'extof'
    if undefined(level) then level = 'l2' 
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(data_units) then data_units = 'flux'
    if undefined(suffix) then suffix = ''
    
    if undefined(varformat) then begin
        ; turn on get_support_data if the user doesn't specify a varformat
        if undefined(get_support_data) then get_support_data = 1 ; turn on support data by default, need the spin variable for spin averaging
    endif
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'epd-eis', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, available = available, versions = versions, always_prompt = always_prompt, $
        major_version=major_version, tt2000=tt2000
    
    ; don't try to calculate omnidirectional quantities if no data was loaded
    if undefined(tplotnames) || tplotnames[0] eq '' then return
    
    ; calculate the omni-directional quantities
    for probe_idx = 0, n_elements(probes)-1 do begin
        for datatype_idx = 0, n_elements(datatype)-1 do begin
            ;try both ions and electrons in case multiple datatypes were loaded
            this_datatype = datatype[datatype_idx]
            if (this_datatype eq 'electronenergy') then begin
              mms_eis_spin_avg, probe=probes[probe_idx], datatype='electronenergy', species='electron', data_units = data_units, suffix=suffix, data_rate = data_rate
              ; create spin averaged omni-directional spectra
              mms_eis_omni, probes[probe_idx], species='electron', datatype='electronenergy', tplotnames = tplotnames, suffix = suffix+'_spin', data_units = data_units, data_rate = data_rate
            
              ; create non-spin averaged omni-directional spectra
              mms_eis_omni, probes[probe_idx], species='electron', datatype='electronenergy', tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate            
            endif
            if (this_datatype eq 'extof') then begin
              mms_eis_spin_avg, probe=probes[probe_idx], datatype='extof', species='proton', data_units = data_units, suffix=suffix, data_rate = data_rate
              mms_eis_spin_avg, probe=probes[probe_idx], datatype='extof', species='oxygen', data_units = data_units, suffix=suffix, data_rate = data_rate
              mms_eis_spin_avg, probe=probes[probe_idx], datatype='extof', species='alpha', data_units = data_units, suffix=suffix, data_rate = data_rate
              ; create spin averaged omni-directional spectra
              mms_eis_omni, probes[probe_idx], species='proton', datatype='extof',tplotnames = tplotnames, suffix = suffix+'_spin', data_units = data_units, data_rate = data_rate
              mms_eis_omni, probes[probe_idx], species='alpha', datatype='extof',tplotnames = tplotnames, suffix = suffix+'_spin', data_units = data_units, data_rate = data_rate
              mms_eis_omni, probes[probe_idx], species='oxygen', datatype='extof',tplotnames = tplotnames, suffix = suffix+'_spin', data_units = data_units, data_rate = data_rate
              ; create non-spin averaged omni-directional spectra
              mms_eis_omni, probes[probe_idx], species='proton', datatype='extof',tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
              mms_eis_omni, probes[probe_idx], species='alpha', datatype='extof',tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
              mms_eis_omni, probes[probe_idx], species='oxygen', datatype='extof',tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
            
            endif
            if (this_datatype eq 'phxtof') then begin
              mms_eis_spin_avg, probe=probes[probe_idx], datatype='phxtof', species='proton', data_units = data_units, suffix=suffix, data_rate = data_rate
              mms_eis_spin_avg, probe=probes[probe_idx], datatype='phxtof', species='oxygen', data_units = data_units, suffix=suffix, data_rate = data_rate
              ; create spin averaged omni-directional spectra
              mms_eis_omni, probes[probe_idx], species='proton', datatype='phxtof',tplotnames = tplotnames, suffix = suffix+'_spin', data_units = data_units, data_rate = data_rate
              mms_eis_omni, probes[probe_idx], species='oxygen', datatype='phxtof',tplotnames = tplotnames, suffix = suffix+'_spin', data_units = data_units, data_rate = data_rate
               ; create non-spin averaged omni-directional spectra
              mms_eis_omni, probes[probe_idx], species='proton', datatype='phxtof',tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
              mms_eis_omni, probes[probe_idx], species='oxygen', datatype='phxtof',tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
            endif
            mms_eis_set_metadata, tplotnames, datatype = this_datatype, probe = probes[probe_idx], level=level, data_rate = data_rate, suffix = suffix, no_interp=no_interp
        endfor
    endfor
  ;  if undefined(no_interp) && data_rate eq 'srvy' then options, '*_omni*', no_interp=0, y_no_interp=0
end