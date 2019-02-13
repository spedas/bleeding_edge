;+
; PROCEDURE:
;         mms_load_hpca
;         
; PURPOSE:
;         Load data from the MMS Hot Plasma Composition Analyzer (HPCA)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is '1'
;         level:        indicates level of data processing. levels include 'l2', 'l1b', 'sitl'. 
;                       the default if no level is specified is 'L2'.
;         datatype:     data types include (note that not all levels have all datatypes):
;                       L2: ['ion', 'moments']
;                       sitl, l1b: ['bkgd_corr', 'count_rate', 'flux', 'moments', 'rf_corr', 'vel_dist'].
;                       if no value is given the default is 'moments'.
;         data_rate:    instrument data rates include 'brst' and 'srvy'; the default is 'srvy'.
;         local_data_dir: local directory to store the CDF files
;         varformat:    format of the variable names in the CDF to load
;         source:       specifies a different system variable. By default the MMS system 
;                       variable is !mms
;         get_support_data: load support data (defined by VAR_TYPE="support_data" in the CDF)
;         tplotnames:   returns a list of the names of the tplot variables loaded by the load routine
;         no_color_setup: don't setup graphics configuration; this keyword is required when you're using this 
;                       load routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use this 
;                       keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found, the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable names
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval
;                       (e.g., /latest_version)
;         major_version: only open the latest major CDF version (e.g., X in vX.Y.Z) in the requested time interval
;         min_version:  specify a minimum CDF version # to load
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public data)
;         center_measurement: set this keyword to shift the data to the center of the measurement interval 
;                       using the DELTA_PLUS_VAR/DELTA_MINUS_VAR attributes
;         available: returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         disable_mem_usage: disable memory usage checks and warnings
; 
; 
; EXAMPLE:
;     Simple HPCA example:
;     MMS>  mms_load_hpca, probes='1', trange=['2015-12-15', '2015-12-16'], datatype='ion'
;
;     MMS>  mms_hpca_calc_anodes, fov=[0, 360] ; sum over the full field of view (FoV)
;     MMS>  tplot, 'mms1_hpca_hplus_flux_elev_0-360' ; plot the H+ spectra (full FoV)
;     
;     MMS> mms_hpca_spin_sum, probe='1'
;     MMS> tplot, ['mms1_hpca_hplus_flux_elev_0-360_spin', 'mms1_hpca_hplus_flux_elev_0-360']
;     
;     See crib sheets: mms_load_hpca_crib, mms_load_hpca_burst_crib, and mms_load_hpca_crib_qlplots
;     for more usage examples
;
; 
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;     The HPCA Data Products Guide can be found at:
;     
;     https://lasp.colorado.edu/galaxy/display/mms/HPCA+Data+Products+Guide
;     
;     Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;          
;     When loading HPCA energy spectra with this routine, all of the data are loaded in 
;        initially. To plot a meaningful spectra, the user must call mms_hpca_calc_anodes
;        to sum/average the data over the look directions for the instrument. This will append
;        the field of view (or anodes) used in the calculation to the name of the tplot variable.
; 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-02-12 11:11:47 -0800 (Tue, 12 Feb 2019) $
;$LastChangedRevision: 26611 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_load_hpca.pro $
;-

pro mms_load_hpca, trange = trange_in, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, varformat = varformat, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version, $
                  spdf = spdf, center_measurement = center_measurement, available = available, $
                  versions = versions, always_prompt = always_prompt, major_version=major_version, $
                  tt2000=tt2000, disable_mem_usage=disable_mem_usage
                
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'moments' else datatype = strlowcase(datatype)
    if undefined(level) then level = 'l2' else level = strlowcase(level)
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix=''
    if level ne 'l2' then begin
        ; old stuff for L1b/sitl files
        if undefined(varformat) then begin
          ;convert "datatypes" to actual datatype and varformat
          if n_elements(level) eq 1 && strlowcase(level) ne 'l1a' then begin
            ; allow for the following datatypes:
            ; count_rate, flux, vel_dist, rf_corr, bkgd_corr
            case datatype of
              'ion': varformat = '*'
              'combined': varformat = '*'
              'rf_corr': varformat = '*_RF_corrected'
              'count_rate': varformat = '*_count_rate'
              'flux': varformat = '*_flux'
              'vel_dist': varformat = '*_vel_dist_fn' ;naming no longer used 2016-04-01
              'bkgd_corr': varformat = '*_bkgd_corrected'
              'moments': varformat = '*'
              else: varformat = '*_RF_corrected'
            endcase
            if ~undefined(varformat) && varformat ne '*' then datatype = 'ion'
          endif
        endif
        if level eq 'sitl' then varformat = '*'
    endif else begin
        ; required to center the measurements
        if undefined(get_support_data) then get_support_data = 1
        if ~undefined(datatype) && n_elements(datatype) eq 1 && (datatype ne 'ion' && datatype ne 'moments') then begin
            dprint, dlevel = 0, "Unknown datatype: " + datatype + " for L2 HPCA data; expected 'ion' or 'moments', loading 'ion'"
            datatype='ion'
        endif
    endelse

    if ~undefined(varformat) && (varformat[0] ne '*') then begin
      if is_array(varformat) then varformat = [varformat, '*_ion_energy', '*_start_azimuth', 'Epoch*'] $
        else varformat = varformat + ' *_ion_energy *_start_azimuth Epoch*'
    endif
    if ~undefined(varformat) && ~undefined(get_support_data) then undefine, get_support_data
    
    if ~undefined(trange_in) && n_elements(trange_in) eq 2 $
      then tr = timerange(trange_in) $
    else tr = timerange()

    if array_contains(datatype, 'ion') and ~keyword_set(available) and ~keyword_set(disable_mem_usage) then begin
      mem_usage = long64(mms_estimate_mem_usage(tr, 'hpca'))
      mem_avail = get_max_memblock2()
      dprint, dlevel=0, 'WARNING: this call will use: ' + string(mem_usage) + ' MB / available: ' + string(mem_avail) + ' MB'
      if mem_usage ge mem_avail then begin
        dprint, dlevel = 0, "WARNING: this request will use all of your system's available memory!"
        dprint, dlevel = 0, "Try .continue to continue loading if you're brave enough; if you think this message is an error, please report it to egrimes@igpp.ucla.edu"
        stop
      endif
    endif

    mms_load_data, trange = tr, probes = probes, level = level, instrument = 'hpca', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, varformat = varformat, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, center_measurement = center_measurement, available = available, $
        versions = versions, always_prompt = always_prompt, major_version=major_version, tt2000=tt2000
    
    if undefined(tplotnames) then return

    ;copy ancillary data from support vars into 3D dist vars
    ;once CDFs are fully populated this should be removed
    mms_load_hpca_fix_dist, tplotnames, suffix = suffix
    
    ; check if the energy table for the flux/psd variables are all 0s
    ; if they are, use the hard coded table instead
    if array_contains(datatype, 'ion') && level eq 'l2' then begin
        vars_to_check = tnames('mms?_hpca_*plus_phase_space_density'+suffix)

        flux_vars_to_check = tnames('mms?_hpca_*plus_flux'+suffix)
        append_array, vars_to_check, flux_vars_to_check
        
        for psd_idx = 0, n_elements(vars_to_check)-1 do begin
            if vars_to_check[psd_idx] eq '' then continue
            get_data, vars_to_check[psd_idx], data=d, dlimits=psd_dl
            
            str_element, d, 'v2', energy_table, success=success
            
            ; check if the energy table is all 0s, if so, default to the hard-coded table
            wherezeros = where(energy_table eq 0, zerocount)
            if zerocount eq 63 then success = 0
            if ~success then begin
                ; energy table is all 0s, using hard coded table
                dprint, dlevel = 0, 'Found energy table with all 0s: ' + vars_to_check[psd_idx] + '; using hard-coded energy table instead'
                energy_table = mms_hpca_energies()
                store_data, vars_to_check[psd_idx], data={x: d.X, y: d.Y, v1: d.v1, v2: energy_table}, dlimits=psd_dl
            endif
        endfor
        
    endif

    ; if the user requested HPCA ion data, need to:
    ; 1) sum over anodes for normalized counts, count rate, 
    ;    RF and background corrected count rates
    ; 2) average over anodes for flux, velocity distributions
    ;if datatype eq 'ion' then mms_hpca_calc_anodes, tplotnames=tplotnames, fov=fov, probes=probes

    for probe_idx = 0, n_elements(probes)-1 do mms_hpca_set_metadata, tplotnames, prefix = 'mms'+probes[probe_idx], suffix=suffix
end
