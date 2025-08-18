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
;         level:        indicates level of data processing. levels include 'l1a', 'l1b'. 
;                       The default if no level is specified is 'l1b'
;         datatype:     eis data types include ['electronenergy', 'extof', 'partenergy', 'phxtof'].
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for eis include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts']. 
;                       The default is 'flux'.
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server runningdo 
;                       not set colors
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
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public access)
;
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See mms_load_eis_crib.pro, mms_load_eis_burst_crib.pro, 
;         mms_load_eis_crib_qlplots.pro, and mms_load_data_crib.pro for usage examples
; 
;     load ExTOF burst data:
;     MMS1> mms_load_eis, probes='1', trange=['2015-12-23', '2015-12-24'],  datatype='extof', data_rate='brst', level='l2'
;            
;     load PHxTOF data:
;     MMS1> mms_load_eis, probes='1', trange=['2015-10-31', '2015-11-01'], datatype='phxtof', level='l2'
;     calculate the PHxTOF PAD for protons
;     MMS1> mms_eis_pad, probe='1', species='ion', datatype='phxtof', ion_type='proton', data_units='flux', energy=[0, 30], level='l2'
;
; NOTES:
;     Please see the notes in mms_load_data for more information 
;     
;     
;     Have questions regarding this load routine, or its usage?
;          Send me an email --> egrimes@igpp.ucla.edu
;
; HISTORY:
;     09/15/2015 - Ian Cohen at APL: added modifications to omni-directional calculations to be able to handle 
;                  ExTOF and PHxTOF data
;     09/17/2015 - egrimes: large update, see svn log
;     12/15/2015 - icohen: added data_rate keyword and conditional definition of prefix in mms_eis_spin_avg and 
;                  mms_eis_omni to address burst variable name changes
;     
;$LastChangedBy: rickwilder $
;$LastChangedDate: 2016-04-07 12:43:36 -0700 (Thu, 07 Apr 2016) $
;$LastChangedRevision: 20745 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_eis.pro $
;-

pro mms_sitl_get_eis, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, data_units = data_units, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, no_interp = no_interp, $
                  suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
                  cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version, spdf = spdf

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'extof'
    if undefined(level) then level = 'l1b' 
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
        spdf = spdf
    
    ; don't try to calculate omnidirectional quantities if no data was loaded
    if undefined(tplotnames) || tplotnames[0] eq '' then return
    
    ; calculate the omni-directional quantities
    for probe_idx = 0, n_elements(probes)-1 do begin
        ;try both ions and electrons in case multiple datatypes were loaded
        if (datatype eq 'electronenergy') then begin
          mms_sitl_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='electron', data_units = data_units, suffix=suffix, data_rate = data_rate
          mms_sitl_eis_omni, probes[probe_idx], species='electron', datatype='electronenergy', tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units, data_rate = data_rate
        endif
        if (datatype eq 'extof') then begin
          mms_sitl_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='proton', data_units = data_units, suffix=suffix, data_rate = data_rate
          mms_sitl_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='oxygen', data_units = data_units, suffix=suffix, data_rate = data_rate
          mms_sitl_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='alpha', data_units = data_units, suffix=suffix, data_rate = data_rate
          mms_sitl_eis_omni, probes[probe_idx], species='proton', datatype='extof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units, data_rate = data_rate
          mms_sitl_eis_omni, probes[probe_idx], species='alpha', datatype='extof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units, data_rate = data_rate
          mms_sitl_eis_omni, probes[probe_idx], species='oxygen', datatype='extof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units, data_rate = data_rate
        endif
        if (datatype eq 'phxtof') then begin
          mms_sitl_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='proton', data_units = data_units, suffix=suffix, data_rate = data_rate
          mms_sitl_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='oxygen', data_units = data_units, suffix=suffix, data_rate = data_rate
          mms_sitl_eis_omni, probes[probe_idx], species='proton', datatype='phxtof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units, data_rate = data_rate
          mms_sitl_eis_omni, probes[probe_idx], species='oxygen', datatype='phxtof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units, data_rate = data_rate
        endif  
    endfor
    if undefined(no_interp) && data_rate eq 'srvy' then options, '*_omni_spin*', no_interp=0, y_no_interp=0
end