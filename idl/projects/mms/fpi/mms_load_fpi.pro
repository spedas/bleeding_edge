;+
; PROCEDURE:
;         mms_load_fpi
;         
; PURPOSE:
;         Load data from the Fast Plasma Investigation (FPI) onboard MMS
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is probe '3'
;         level:        indicates level of data processing. FPI levels currently include 'l2', 
;                       'l1b', 'sitl', 'ql'. 
;         datatype:     valid datatypes are:
;                         Quicklook: ['des', 'dis'] 
;                         SITL: '' (none; loads both electron and ion data from single CDF)
;                         L1b/L2: ['des-dist', 'dis-dist', 'dis-moms', 'des-moms', 'dis-auxmoms', 'des-auxmoms', 'dis-partmoms', 'des-partmoms']
;         data_rate:    instrument data rates for MMS FPI include 'fast', 'brst'. 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   returns a list of the names of the tplot variables loaded by the load routine
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using  this load routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
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
;         center_measurement: set this keyword to shift the data to the center of the measurement interval
;                       using the DELTA_PLUS_VAR/DELTA_MINUS_VAR attributes
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
;     MMS>  timespan, '2015-09-19', 1, /day
;     load FPI burst mode data
;     MMS>  mms_load_fpi, probes = ['1'], level='l2', data_rate='brst', datatype='des-moms'
;     
;     load FPI FS data
;     MMS>  mms_load_fpi, probes='3', level='l2', data_rate='fast', datatype='des-moms'
;     
;     See mms_load_fpi_crib, mms_load_fpi_burst_crib, and mms_load_fpi_crib_qlplots
;     for usage examples
;
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;     Please see the notes at:
;        https://lasp.colorado.edu/galaxy/display/mms/FPI+Release+Notes
;        
;     Have questions regarding this load routine, or its usage?
;          https://groups.google.com/forum/#!forum/spedas
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-05-30 12:47:35 -0700 (Fri, 30 May 2025) $
;$LastChangedRevision: 33354 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi.pro $
;-

pro mms_load_fpi, trange = trange_in, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  autoscale = autoscale, varformat = varformat, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version, $
                  spdf = spdf, center_measurement=center_measurement, $
                  available = available, versions = versions, always_prompt = always_prompt, $
                  major_version=major_version, tt2000=tt2000, download_only=download_only

    if undefined(probes) then probes = ['3'] ; default to MMS 3
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    if undefined(level) then level = 'l2' 
    if undefined(data_rate) then data_rate = 'fast'
    if undefined(autoscale) then autoscale = 1
    if undefined(suffix) then suffix = ''
    ; 2/22/2016 - getting the support data, for grabbing the energy and PA tables
    ; so that we can hard code the variable names for these, instead of hard
    ; coding the tables directly
    if undefined(varformat) then begin
        ; turn on get_support_data if the user doesn't specify a varformat
        if undefined(get_support_data) then get_support_data = 1
    endif
;    if ~undefined(center_measurement) && ~array_contains(['l2', 'acr'], strlowcase(level)) then begin
;        dprint, dlevel = 0, 'Error, can only center measurements for L2/ACR FPI data.'
;        return
;    endif
    if ~undefined(center_measurement) && ~array_contains(['l2'], strlowcase(level)) then begin
        dprint, dlevel = 0, 'Error, can only center measurements for L2 FPI data.'
        return
    endif
;    if ~undefined(center_measurement) && ~undefined(varformat) && varformat ne '*' then begin
;        dprint, dlevel = 0, 'Error, cannot specify both the varformat keyword and center measurement keyword in the same call (measurements won''t be centered).'
;        return
;    endif

    if ~undefined(varformat) && (varformat[0] ne '*') then begin
      if is_array(varformat) then varformat = [varformat, '*Epoch*'] $
      else varformat = varformat + ' *Epoch*'
    endif
    
    ; different datatypes for burst mode files
    if data_rate eq 'brst' && (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist', 'dis-moms', 'des-moms']
    if (datatype[0] eq '*' || datatype[0] eq '') && level eq 'ql' then datatype=['des', 'dis']
    if (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist', 'dis-moms', 'des-moms', 'dis-momsaux', 'des-momsaux', 'dis-partmoms', 'des-partmoms']

    ; kludge for level = 'sitl' -> datatype shouldn't be defined for sitl data.
    if level eq 'sitl' || level eq 'trig' then datatype = '*'

    mms_load_data, trange = trange_in, probes = probes, level = level, instrument = 'fpi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf, center_measurement = center_measurement, available = available, $
        versions = versions, always_prompt = always_prompt, major_version=major_version, tt2000=tt2000, $
        download_only=download_only

    ; no reason to continue if the user only requested available data
    if keyword_set(available) || keyword_set(download_only) then return
    
    if undefined(tplotnames) then return

    ; the following kludge is due to the errorflags variable in the dist and moments files having the
    ; same variable name, so loading d?s-dist and d?s-moms files at the same time will overwrite
    ; one of the vars containing errorflags
    if array_contains(datatype, 'des-dist') && array_contains(datatype, 'des-moms') then begin
        ; delete the old errorflags var first
        del_data, '*_des_errorflags_*'
        del_data, '*_des_compressionloss_*'
        mms_load_data, trange = trange_in, probes = probes, level = level, instrument = 'fpi', $
            data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
            datatype = 'des-moms', get_support_data = 0, $
            tplotnames = tplotnames_errflags_emom, no_color_setup = no_color_setup, time_clip = time_clip, $
            no_update = no_update, suffix = suffix+'_moms', varformat = '*errorflags* *compressionloss*', $
            cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
            spdf = spdf, center_measurement=center_measurement, major_version=major_version, tt2000=tt2000
        mms_load_data, trange = trange_in, probes = probes, level = level, instrument = 'fpi', $
            data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
            datatype = 'des-dist', get_support_data = 0, $
            tplotnames = tplotnames_errflags_edist, no_color_setup = no_color_setup, time_clip = time_clip, $
            no_update = no_update, suffix = suffix+'_dist', varformat = '*errorflags* *compressionloss*', $
            cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
            spdf = spdf, center_measurement=center_measurement, major_version=major_version, tt2000=tt2000
    endif else begin
        if ~undefined(tplotnames) then begin
          for probe_idx = 0, n_elements(probes)-1 do begin
              this_probe = strcompress(string(probes[probe_idx]), /rem)
              if array_contains(datatype, 'des-dist') then begin
                tplot_rename, 'mms'+this_probe+'_des_errorflags_'+data_rate+suffix, 'mms'+this_probe+'_des_errorflags_'+data_rate+suffix+'_dist'
                tplot_rename, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_dist'
              endif
              if array_contains(datatype, 'des-moms') || array_contains(datatype, 'des') then begin
                tplot_rename, 'mms'+this_probe+'_des_errorflags_'+data_rate+suffix, 'mms'+this_probe+'_des_errorflags_'+data_rate+suffix+'_moms'
                tplot_rename, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_moms'
              endif
          endfor
        endif
    endelse

    if array_contains(datatype, 'dis-dist') && array_contains(datatype, 'dis-moms') then begin
        ; delete the old errorflags var first
        del_data, 'mms?_dis_errorflags_*'
        del_data, '*_dis_compressionloss_*'
        mms_load_data, trange = trange_in, probes = probes, level = level, instrument = 'fpi', $
            data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
            datatype = 'dis-moms', get_support_data = 0, $
            tplotnames = tplotnames_errflags_imom, no_color_setup = no_color_setup, time_clip = time_clip, $
            no_update = no_update, suffix = suffix+'_moms', varformat = '*errorflags* *compressionloss*',  $
            cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
            spdf = spdf, center_measurement=center_measurement, major_version=major_version, tt2000=tt2000
        mms_load_data, trange = trange_in, probes = probes, level = level, instrument = 'fpi', $
            data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
            datatype = 'dis-dist', get_support_data = 0, $
            tplotnames = tplotnames_errflags_idist, no_color_setup = no_color_setup, time_clip = time_clip, $
            no_update = no_update, suffix = suffix+'_dist', varformat = '*errorflags* *compressionloss*', $
            cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
            spdf = spdf, center_measurement=center_measurement, major_version=major_version, tt2000=tt2000
    endif else begin
        if ~undefined(tplotnames) then begin
          for probe_idx = 0, n_elements(probes)-1 do begin
              this_probe = strcompress(string(probes[probe_idx]), /rem)
              if array_contains(datatype, 'dis-dist') then begin
                tplot_rename, 'mms'+this_probe+'_dis_errorflags_'+data_rate+suffix, 'mms'+this_probe+'_dis_errorflags_'+data_rate+suffix+'_dist'
                tplot_rename, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_dist'
              endif
              if array_contains(datatype, 'dis-moms') || array_contains(datatype, 'dis') then begin
                tplot_rename, 'mms'+this_probe+'_dis_errorflags_'+data_rate+suffix, 'mms'+this_probe+'_dis_errorflags_'+data_rate+suffix+'_moms'
                tplot_rename, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_moms'
              endif
          endfor
        endif
    endelse
    ; add the errorflags variables to variables loaded
    append_array, tplotnames, tplotnames_errflags_emom
    append_array, tplotnames, tplotnames_errflags_edist
    append_array, tplotnames, tplotnames_errflags_imom
    append_array, tplotnames, tplotnames_errflags_idist
    
    ;;; end of kludge for errorflags variables
    
    ; since the SITL files contain both ion and electron data, and datatype = '*' doesn't work
    ; in our 'fix'/'calc' routines for the FPI metadata
    if level eq 'sitl' then datatype = ['des-dist', 'dis-dist']
    
    ; correct the energies in the spectra for each probe
    if ~undefined(tplotnames) && n_elements(tplotnames) ne 0 then begin
        for probe_idx = 0, n_elements(probes)-1 do begin
            this_probe = strcompress(string(probes[probe_idx]), /rem)

            ; calculate the averaged PAD from the low, mid, high-energy PAD variables
            mms_load_fpi_calc_pad, probes[probe_idx], level = level, datatype = datatype, $
                suffix = suffix, data_rate = data_rate
                
            ; fix some metadata
            mms_fpi_fix_metadata, tplotnames, prefix='mms'+probes[probe_idx], level = level, $
                suffix = suffix, data_rate = data_rate

            ; create the error bars
            ; moms
            mms_fpi_make_errorflagbars,'mms'+this_probe+'_dis_errorflags_'+data_rate+suffix+'_moms', level=level ; ions
            mms_fpi_make_errorflagbars,'mms'+this_probe+'_des_errorflags_'+data_rate+suffix+'_moms', level=level ; electrons
            ; dist
            mms_fpi_make_errorflagbars,'mms'+this_probe+'_dis_errorflags_'+data_rate+suffix+'_dist', level=level ; ions
            mms_fpi_make_errorflagbars,'mms'+this_probe+'_des_errorflags_'+data_rate+suffix+'_dist', level=level ; electrons
        
            ; do not need this bar for survey data, since all data are lossy compressed
            if data_rate eq 'brst' then begin
              mms_fpi_make_compressionlossbars,'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_dist'
              mms_fpi_make_compressionlossbars,'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_moms'
              mms_fpi_make_compressionlossbars,'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_dist'
              mms_fpi_make_compressionlossbars,'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_moms'
            endif else if data_rate eq 'fast' then begin
              ; compressionloss variables are always 1 for fast survey data, so the variables are always set to NRV
              ; in the file; we have to correct that below
              get_data, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_dist', data=compress
              if is_struct(compress) && n_elements(compress.Y) eq 1 then store_data, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_dist', data={x: compress.X, y: replicate(compress.Y, n_elements(compress.X))}
              if is_struct(compress) && n_elements(compress.Y) eq 1 then options, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_dist',colors=2,labels='DES '+data_rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2

              get_data, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_moms', data=compress
              if is_struct(compress) && n_elements(compress.Y) eq 1 then store_data, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_moms', data={x: compress.X, y: replicate(compress.Y, n_elements(compress.X))}
              if is_struct(compress) && n_elements(compress.Y) eq 1 then options, 'mms'+this_probe+'_des_compressionloss_'+data_rate+suffix+'_moms',colors=2,labels='DES '+data_rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2

              get_data, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_dist', data=compress
              if is_struct(compress) && n_elements(compress.Y) eq 1 then store_data, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_dist', data={x: compress.X, y: replicate(compress.Y, n_elements(compress.X))}
              if is_struct(compress) && n_elements(compress.Y) eq 1 then options, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_dist',colors=2,labels='DIS '+data_rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2

              get_data, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_moms', data=compress
              if is_struct(compress) && n_elements(compress.Y) eq 1 then store_data, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_moms', data={x: compress.X, y: replicate(compress.Y, n_elements(compress.X))}
              if is_struct(compress) && n_elements(compress.Y) eq 1 then options, 'mms'+this_probe+'_dis_compressionloss_'+data_rate+suffix+'_moms',colors=2,labels='DIS '+data_rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2

            endif
        endfor
    endif
end