;+
; PROCEDURE:
;         mms_load_state
;
; PURPOSE:
;         Load MMS state (position, attitude) data
;         NOTE: MEC data may also be loaded if the date is current date-4days
;               AND the level is not set to 'pred'
;
; KEYWORDS:
;         trange:     time range of interest [starttime, endtime] with the format 
;                     ['YYYY-MM-DD','YYYY-MM-DD'] or for more specifi times 
;                     ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss'] see examples below 
;         probes:     list of probes, valid values for MMS probes are ['*','1','2','3','4']
;                     where '*' specifies all probes. If no probe is specified the default 
;                     is all probes 
;         level:      ['def', 'pred'] for predicted or definitive attitude or position data. 
;                     the default is to search for definitive data first and if not found 
;                     search for predicted data. To turn this feature off use the keyword 
;                     pred_or_def (see below)
;         datatypes:  ephemeris and attitude data types include ['*','pos', 'vel', 'spinras', 'spindec'].
;                     If no value is given the default is '*' where all types will be loaded
;                     (all MEC values might also be loaded - see NOTE in 'PURPOSE' (above))
;         local_data_dir: local directory to store the CDF files; should be set if
;                     you're on *nix or OSX, the default currently assumes Windows 
;                     (c:\data\mms\)
;         source:     specifies a different system variable. By default the MMS mission 
;                     system variable is !mms
;         remote_data_dir: This is the URL of the server that can provide the data files. 
;                     if the software does not find a needed file in LOCAL_DATA_DIR, then it will 
;                     attempt to download the data from the URL and REMOTE_DATA_DIR is defined, 
;                     the software will attempt to download the file from REMOTE_DATA_DIR, place it 
;                     in LOCAL_DATA_DIR with the same relative pathname, and then continue 
;                     processing.
;         attitude_only: flag to only load L-right ascension and L-declination attitude data, this
;                     is only true for predicted data
;         ephemeris_only: flag to only load position and velocity data, this is only true for predicted data
;         no_download: set flag to use local data only (no download)
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;                     with "username" and "password" tags that include your SDC login information
;         tplotnames: names for tplot variables
;         pred_or_def: set this flag to turn off looking for predicted data if definitive not found
;                     (pred_or_def=0 will return only the level that was requested). The default is 
;                     to load predicted data if definitive data is not found 
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using this 
;                     load routine from a terminal without an X server running
;         suffix:     appends a suffix to the end of the tplot variable name. this is useful for 
;                     preserving original tplot variable. 
;         ascii:      force loading the state data from the ASCII files (will not use the MEC files)
;
; OUTPUT: tplot variables
;
; EXAMPLES: 
; 
;   MMS> tr=['2015-07-21','2015-07-22']
;   MMS> mms_load_state, probe='1', trange=tr
;   MMS> mms_load_state, probe='*', level='def', trange=tr
;   MMS> mms_load_state, probe=['1','3'], datatypes='pos', trange=tr
;   MMS> mms_load_state, probe=['1','3'], datatypes=['pos', 'spinras'], trange=tr
;   MMS> mms_load_state, probe=['1','2','3'], datatypes='*', level='pred', trange=tr
;   MMS> mms_load_state, probe='1', /attitude_only, trange=tr
;   MMS> mms_load_state, probe='*', /ephemeris_only, level='pred', trange=tr
;   
; NOTES:
;     The MMS plug-in in SPEDAS requires IDL 8.4 to access data at the LASP SDC
;    
;     1) See the following regarding rules for the use of MMS data:
;         https://lasp.colorado.edu/galaxy/display/mms/MMS+Data+Rights+and+Rules+for+Data+Use
;
;     2) CDF version 3.6.3+ is required to correctly handle leap seconds.  
;
;     3) If no level ('pred' or 'def') is specified the routine defaults to 'def'. When 'def' data is 
;        retrieved and the start time requested is the same as the time of the last available definitive 
;        file or near the current date it's possible that only partial definitive data is available or that 
;        no data is available. Partial data is due to the fact that MMS files don't go from 0-24hrs but 
;        rather start at ~midday. Whenever partial data is available a warning message is displayed in the 
;        console window and the partial data is loaded. 
;     
;        When no data is available the user is notified and no further action is taken. The user can re-request 
;        the data by adding or changing the keyword level to 'pred' or in the GUI by clicking on 'pred' in the 
;        level text box.
;        
;        Time frames can span several days or weeks. If long time spans start in the definitive range and
;        end in the predicted time range the user will get either partial 'def' or 'pred' depending on
;        what the level keyword is set to. 
;        
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-10-19 12:54:21 -0700 (Thu, 19 Oct 2017) $
;$LastChangedRevision: 24188 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_load_state.pro $
;-

pro mms_load_state, trange = trange_in, probes = probes, datatypes = datatypes, $
    level = level, local_data_dir = local_data_dir, source = source, $
    remote_data_dir = remote_data_dir, attitude_only=attitude_only, $
    ephemeris_only = ephemeris_only, no_download=no_download, login_info=login_info, $
    tplotnames = tplotnames, pred_or_def=pred_or_def, no_color_setup = no_color_setup, $
    suffix = suffix, ascii = ascii

    ; define probe, product, type, coordinate, and unit names
    p_names = ['1', '2', '3', '4']
    t_names = ['pos', 'vel', 'spinras', 'spindec']
    l_names = ['def', 'pred']    
    
;    if undefined(trange) then begin
;      dprint, dlevel = 0, 'Error loading MMS attitude data - no time range given.'
;      return
;    endif
    mec_flag= 0
    public = 0
      
    ; set up system variable for MMS if not already set    
    defsysv, '!mms', exists=exists
    if not(exists) then mms_init, no_color_setup = no_color_setup

    ;response_code = spd_check_internet_connection()
    response_code = 200

    ;combine these flags for now, if we're not downloading files then there is
    ;no reason to contact the server unless mms_get_local_files is unreliable
    if undefined(no_download) then no_download = !mms.no_download or !mms.no_server or (response_code ne 200)

    ; only prompt the user if they're going to download data
    if no_download eq 0 then begin
        status = mms_login_lasp(login_info = login_info, username=username)
        if status ne 1 then no_download = 1
        if username eq '' || username eq 'public' then public=1
    endif
    
    ; define cutoff date for retrieving attitude files from mec
    mec_cutoff_date = systime(/seconds)-60.*60.*24.*4.
    
    ; initialize undefined values
    if ~undefined(trange_in) && n_elements(trange_in) eq 2 $
      then trange_in = timerange(trange_in) $
      else trange_in = timerange()
    if undefined(probes) then probes = p_names else probes = strcompress(string(probes), /rem)
    if undefined(level) then level = 'def' else level = strlowcase(level)
    if undefined(datatypes) then datatypes = '*' else datatypes = strlowcase(datatypes) 
    if undefined(local_data_dir) then local_data_dir = !mms.local_data_dir
    if undefined(remote_data_dir) then remote_data_dir = !mms.remote_data_dir
    if undefined(pred_or_def) then pred_or_def=1 else pred_or_def=pred_or_def
    if not keyword_set(source) then source = !mms
    
    ; check for wild cards
    if probes[0] EQ '*' then probes = p_names
    if datatypes[0] EQ '*' then datatypes = t_names  
    if keyword_set(ephemeris_only) then begin
      datatypes = ['pos', 'vel']
      mec_varformat = '*_v_* *_r_*'
    endif
    if keyword_set(attitude_only) then begin 
      datatypes = ['spinras', 'spindec']
      mec_varformat = '*_ang_mom_* *_mec_L_vec'
    endif
    if keyword_set(attitude_only) && keyword_set(ephemeris_only) then begin
       dprint, 'mms_load_state error, cannot set both attitude_only and ephemeris_only keywords'
       return 
    endif
    
    ; allow users to pass probes as a list of ints
    probes = strcompress(string(probes), /rem)

    ; check for valid names
    for i = 0, n_elements(datatypes)-1 do begin
        idx = where(t_names eq datatypes[i], ncnt)
        if ncnt EQ 0 then begin
           dprint, 'mms_load_state error, found unrecognized datatypes: ' + datatypes[i]
           return
        endif
    endfor
    for i = 0, n_elements(level)-1 do begin
      idx = where(l_names eq level[i], ncnt)
      if ncnt EQ 0 then begin
        dprint, 'mms_load_state error, found unrecognized level: ' + level[i]
        return
      endif
    endfor
    for i = 0, n_elements(probes)-1 do begin
      idx = where(p_names eq probes[i], ncnt)
      if ncnt EQ 0 then begin
        dprint, 'mms_load_state error, found unrecognized probes: ' + probes[i]
        return
      endif
    endfor

    ; check for attitude data type mec cut off date
    att_idx = where(strpos(datatypes, 'spin') GE 0, natt)
    def_idx = where(strpos(level, 'def') GE 0, nlev)

     ; cutoff date is now defined to be 
     if trange_in[1] le mec_cutoff_date then begin
       mec_flag = 1
       eph_idx = where(strpos(datatypes, 'spin') EQ -1, neph)
     endif

    if keyword_set(ascii) then mec_flag = 0 ; user requested ASCII files
    
    ; get state data for each probe and data type (def or pred) 
    for i = 0, n_elements(probes)-1 do begin      
       for j = 0, n_elements(level)-1 do begin
            if mec_flag EQ 1 && level[j] NE 'pred' then begin
                 mms_load_mec, probe = probes[i], trange = trange_in, cdf_filenames=cdf_files, $
                  varformat=mec_varformat, suffix=suffix, /time_clip
                 if ~keyword_set(attitude_only) then begin
                    copy_data, 'mms'+probes[i]+'_mec_r_eci'+suffix, 'mms'+probes[i]+'_defeph_pos'+suffix
                    copy_data, 'mms'+probes[i]+'_mec_v_eci'+suffix, 'mms'+probes[i]+'_defeph_vel'+suffix
                 endif 
            endif else begin
                 mms_get_state_data, probe = probes[i], trange = trange_in, tplotnames = tplotnames, $
                   login_info = login_info, datatypes = datatypes, level = level[j], $
                   local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
                   no_download=no_download, pred_or_def=pred_or_def, suffix = suffix, $
                   public=public
            endelse
       endfor
    endfor

    ; time clip the data
    if ~undefined(tplotnames) then begin
        if (tplotnames[0] ne '') then begin
            time_clip, tplotnames, time_double(trange_in[0]), time_double(trange_in[1]), replace=1, error=error
        endif
    endif
end