;+ 
;Procedure: THM_LOAD_SCM
;
;Purpose:  Loads THEMIS SCM data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, can be an array of strings 
;          or single string separate by spaces.  The default is 'all'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables 
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /no_download: use only files which are online locally.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as 
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info, set to 0 to or 1 to reduce output.
;  CLEANUP: Pass through to THM_CAL_SCM.PRO.
;  SCM_CAL: Structure containing the calibration parameters
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;  TYPE: Input, string.  Set to 'calibrated' or 'raw'.
;
; use_eclipse_corrections:  Only applies when loading and calibrating
;   Level 1 data. Defaults to 0 (no eclipse spin model corrections 
;   applied).  use_eclipse_corrections=1 applies partial eclipse 
;   corrections (not recommended, used only for internal SOC processing).  
;   use_eclipse_corrections=2 applies all available eclipse corrections.

;
;KEYWORDS FOR CALIBRATION PROCESS: These are passed through to the
;THM_SCM_CAL procedure:
;  in_suffix =  optional suffix to add to name of input data quantity, which
;          is generated from probe and datatype keywords.
;  out_suffix = optional suffix to add to name for output tplot quantity,
;          which is generated from probe and datatype keywords.
;  trange= array[2] string or double.  Limit calibration to specified time range
; 
;  nk =    N points of the cal-convolution kernel, if set, this value will
;          be used regardless of sample rate.
;  mk =    If nk is not set, set nk to (sample frequency)*mk, where sample
;          frequency is determined by the data. default 8 for scf, 4 for scp, 
;          and 1 for scw.
;  despin =classic despin algorithm. 0:off 1:on  Default is on.
;  n_spinfit=n spins to fit for misalignment, dc field calculation and 
;             optionally despin.
;  cleanup= type of cleanup (default is 'none'):
;          'spin' for only spin tones (power ripples) cleanup,
;          'full' for spin tones and 8/32 Hz tones
;          'none' for no cleanup processes.
;  wind_dur_1s = window duration for 8/32 Hz cleanup (has to be a multiple of 1s)
;          default is 1.
;  wind_dur_spin = spintone cleanup window duration as a multiple of the spin
;          period. Default is 1.
;  clnup_author = choice of cleanup routine (default is 'ole'):
;          'ccc' to use scm_cleanup_ccc 
;          'ole' to use spin_tones_cleaning_vector_v5 
;  fdet =  detrend freq. in Hz.  Detrend is implemented by subtracting a boxcar 
;          avg., whose length is determined by fdet.  
;          Use fdet=0 for no detrending.  Default is fdet=0.
;  fcut =  Low Frequency cut-off for calibration.  Default is 0.1 Hz.
;  fmin =  Min frequency for filtering in DSL system.  Default is 0 Hz.
;  fmax =  Max frequency for filtering in DSL system.  Default is Nyquist.
;  step =  Highest Processing step to complete.  Default is step 5.
;  dfb_butter = correct for DFB Butterworth filter response (defaut is true)
;  dfb_dig = correct for DFB Digital fiter response (default is true)
;  gainant = correct for antenna gain (default is true)
;  blk_con = use fast convolution for calibration and filtering.  
;          Block size for fast convolution will be equal to 
;          (value of blk_con) * (size of kernel).  blk_con = 8 by default.
;          set blk_con=0 to use brute-force convolution.
;  edge_truncate, edge_wrap, edge_zero= Method for handling edges in
;          step 3, cal-deconvolution.  For usage and exact specification of
;          these keywords, see docs for IDL convol function.  Default is to
;          zero data within nk/2 samples of data gap or edge.
;  coord = coordinate system of output.  Step 6 output can only be in DSL.
;  no_download=don't access internet to check for updated calibration files.
;  dircal= If set to a string, specifies directory of calibration files.
;          use /dircal or dircal='' to use calibration files in IDL source 
;          distribution.  
;Example:
;   thg_load_scm,level=1,/get_suppport_data,probe=['a', 'b']
;Notes:
;  This routine is (should be) platform independent.
;Modifications:
;  Added CLEANUP kw to pass through to THM_CAL_SCM.PRO, W.Michael Feuerstein,
;    4/21/2008.
;  30-may-2008 cg, added optional keyword SCM_CAL which is a structure 
;                  containing all the calibration parameters.
;                  modified the call to thm_cal_scm so that parameters
;                  can be used.
;  23-jul-2008, jmm, added _extra to allow SCM cal keywords to allow
;                    cal parameters to be set from the command line,
;                    also fixed bug where program would crash when
;                    called from the command line. Re-tabbed, to find
;                    an 'End of file encountered...' bug.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-05-18 12:58:23 -0700 (Mon, 18 May 2020) $
; $LastChangedRevision: 28711 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_load_scm.pro $
;-
pro thm_load_scm_post, sname = probe, datatype = dt, level = lvl, $
                       tplotnames = tplotnames, progobj = progobj, $
                       suffix = suffix, proc_type = proc_type, coord = coord, $
                       trange = trange, delete_support_data = delete_support_data, $
                       use_eclipse_corrections=use_eclipse_corrections, $
                       _extra = _extra, scm_cal = scm_cal

  if not keyword_set(suffix) then suffix = ''
  ;; remove suffix from support data
  ;; and add DLIMIT tags to data quantities
  for l = 0, n_elements(tplotnames)-1 do begin    
    tplot_var = tplotnames[l]
    dtl = strmid(tplot_var, 4, 3)
    get_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
    if size(/type,dl_str) eq 8 && dl_str.cdf.vatt.var_type eq 'data' $
      then begin
      if strmatch(lvl, 'l1') then begin
        unit = 'ADC'
        data_att = { data_type:'raw', coord_sys:'scm_sensor', $
                     units:unit}
        labels = [ 'b1', 'b2', 'b3']
      end else if strmatch(lvl, 'l2') then begin
        unit = dl_str.cdf.vatt.units
        
        str_element,dl_str.cdf.vatt,'coordinate_system',success=s
        if s then begin
          coord_sys = strlowcase(strmid(dl_str.cdf.vatt.coordinate_system, 0, 3))
          data_att = { data_type:'calibrated', coord_sys:coord_sys, $
                       units:unit}
        endif else begin
          data_att = { data_type:'calibrated', coord_sys:'none', $
            units:unit}
        endelse
        labels = [ 'bx', 'by', 'bz']
      end
      str_element, dl_str, 'data_att', data_att, /add
      colors = [2, 4, 6] 
      str_element, dl_str, 'colors', colors, /add
      str_element, dl_str, 'labels', labels, /add
      str_element, dl_str, 'labflag', 1, /add
      if keyword_set(suffix) then begin
        tplot_var_root = strmid(tplot_var, 0, $
          strpos(tplot_var, suffix, /reverse_search))
      endif else    tplot_var_root=tplot_var 
      str_element, dl_str, 'ytitle', tplot_var_root, /add
      If(strmatch(lvl, 'l1')) Then str_element, dl_str, 'ysubtitle', unit, /add
      store_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
    endif else begin
      ;; for support data,
      ;; rename original variable to exclude suffix
      if keyword_set(suffix) then begin
        tplot_var_root = strmid(tplot_var, 0, $
                                strpos(tplot_var, suffix, /reverse_search))
        store_data, delete = tplot_var
        if tplot_var_root then begin 
          store_data, tplot_var_root, data = d_str, limit = l_str, dlimit = dl_str
        endif
      endif
    endelse
  endfor

  ;; calibrate, if this is L1
  if strmatch(lvl, 'l1') then begin
    if ~keyword_set(proc_type) || strmatch(proc_type, 'calibrated') then begin
      If(is_struct(scm_cal) Eq 0) Then Begin ;not called from GUI
        If(keyword_set(suffix)) Then Begin ;set in_suffix = suffix, jmm, 2009-10-14
          thm_cal_scm, probe = probe, datatype = dt, trange = trange, in_suffix = suffix, $
            out_suffix = suffix, coord = coord, use_eclipse_corrections=use_eclipse_corrections, _extra = _extra
        Endif Else Begin
          thm_cal_scm, probe = probe, datatype = dt, trange = trange, coord = coord, use_eclipse_corrections=use_eclipse_corrections, _extra = _extra
        Endelse
      Endif Else Begin
 ;get cal params
        edge_truncate = 0
        edge_wrap = 0
        edge_zero = 0
        if scm_cal.edge eq 'Zero' then edge_zero = 1
        if scm_cal.edge eq 'Truncate' then edge_truncate = 1
        if scm_cal.edge eq 'Wrap' then edge_wrap = 1   
        if (scm_cal.nk eq '') && (scm_cal.mk eq '') then Begin
          if dt eq 'scf' then mk = 8
          if dt eq 'scp' then mk = 4
          if dt eq 'scw' then mk = 1
        endif  
        if scm_cal.mk ne '' then mk = fix(scm_cal.mk)
        if scm_cal.nk ne '' then mk = fix(scm_cal.nk)
        if scm_cal.cal_dir eq '' then Begin
          thm_cal_scm, probe = probe, datatype = dt, $
            in_suffix = scm_cal.in_suffix, $
            out_suffix = scm_cal.out_suffix, $
            trange = trange, $
            mk = mk, $         
            fdet = fix(scm_cal.det_freq), $
            despin = scm_cal.despin, $
            n_spinfit = fix(scm_cal.nspins), $
            cleanup = scm_cal.cleanup_type, $
            clnup_author = scm_cal.cleanup_author, $
            wind_dur_1s = float(scm_cal.win_dur_1s), $
            wind_dur_spin = float(scm_cal.win_dur_st), $
            fcut = float(scm_cal.low_freq), $
            fmin = float(scm_cal.freq_min), $
            fmax = float(scm_cal.freq_max), $
            step = scm_cal.psteps, $
            edge_wrap = edge_wrap, $
            edge_truncate = edge_truncate, $
            edge_zero = edge_zero, $
            no_download = scm_cal.download, $
            coord = scm_cal.coord_sys, $
            verbose = scm_cal.verbose, $
            dfb_dig = scm_cal.dfbdf, $
            dfb_butter = scm_cal.dfbb, $ 
            gainant = scm_cal.ag, $        
            use_eclipse_corrections=use_eclipse_corrections, $
            progobj = progobj
        endif else Begin
          thm_cal_scm, probe = probe, datatype = dt, $
            in_suffix = scm_cal.in_suffix, $
            out_suffix = scm_cal.out_suffix, $
            trange = trange, $
            mk = mk, $         
            fdet = fix(scm_cal.det_freq), $
            despin = scm_cal.despin, $
            n_spinfit = fix(scm_cal.nspins), $
            cleanup = scm_cal.cleanup_type, $
            clnup_author = scm_cal.cleanup_author, $
            wind_dur_1s = float(scm_cal.win_dur_1s), $
            wind_dur_spin = float(scm_cal.win_dur_st), $
            fcut = float(scm_cal.low_freq), $
            fmin = float(scm_cal.freq_min), $
            fmax = float(scm_cal.freq_max), $
            step = scm_cal.psteps, $
            dircal = scm_cal.cal_dir, $
            edge_wrap = edge_wrap, $
            edge_truncate = edge_truncate, $
            edge_zero = edge_zero, $
            no_download = scm_cal.download, $
            coord = scm_cal.coord_sys, $
            verbose = scm_cal.verbose, $
            dfb_dig = scm_cal.dfbdf, $
            dfb_butter = scm_cal.dfbb, $
            gainant = scm_cal.ag, $        
            use_eclipse_corrections=use_eclipse_corrections, $
            progobj = progobj
        endelse
      Endelse
    endif
  endif

  if keyword_set(delete_support_data) then $
    del_data, 'th'+probe+'_'+dt+'_hed'+suffix[0]

end

pro thm_load_scm, probe = probe, datatype = datatype, trange = trange, $
                  level = level, verbose = verbose, downloadonly = downloadonly, $
                  relpathnames_all = relpathnames_all, no_download = no_download, $
                  cdf_data = cdf_data, get_support_data = get_support_data, $
                  varnames = varnames, valid_names = valid_names, files = files, $
                  suffix = suffix, type = type, coord = coord, $
                  progobj = progobj, scm_cal = scm_cal, $
                  use_eclipse_corrections=use_eclipse_corrections,_extra = _extra

  if ~keyword_set(probe) then probe = ['a', 'b', 'c', 'd', 'e']

  if arg_present(relpathnames_all) then begin
    downloadonly = 1
    no_download = 1
  end

  if (n_elements(use_eclipse_corrections) LT 1) then begin
     ; Default to no eclipse corrections for now
     use_eclipse_corrections=0
  end
  
  vlevels = 'l1 l2'
  deflevel = 'l1'               ;jmm, 11-feb-2008
  lvl = thm_valid_input(level, 'Level', vinputs = vlevels, definput = deflevel, $
                        format = "('l', I1)", verbose = 0)
  if lvl eq '' then return

  if lvl eq 'l2' and keyword_set(type) then begin
    dprint,  "Type keyword not valid for level 2 data. We'll ignore it"
    type = 0b
  endif
  
  if lvl eq 'l1' then begin
    ;; default action for loading level 1 is to calibrate
    if ~keyword_set(type) || strmatch(type, 'calibrated') then begin
      ;; we're calibrating, so make sure we get support data
      if not keyword_set(get_support_data) then begin
        get_support_data = 1
        delete_support_data = 1
      endif
    endif
    if keyword_set(coord) then begin
      thm_cotrans, out_coord = vcoord, /valid_names, verbose = 0
      crd = ssl_check_valid_name(strlowcase(coord), vcoord)
      if not keyword_set(crd) then begin
        dprint,  '*** invalid coord specification'
        return
      endif
      if n_elements(crd) ne 1 then begin
        dprint,  '*** For Level=1, coord must specify a single coordinate system'
        return
      endif
    endif
  endif

;varformat='*' only works for L1 data, because each datatype only
;comes from one file
  If(lvl Eq 'l1') Then varformat_xxx = '*' Else varformat_xxx = ''
;Be sure to delete_support_data, if get_support_data is not set,
;because the varformat command will caues all data to be loaded.
  If(~keyword_set(get_support_data)) Then delete_support_data = 1

  thm_load_xxx, sname = probe, datatype = datatype, trange = trange, $
    level = lvl, verbose = verbose, downloadonly = downloadonly, $
    relpathnames_all = relpathnames_all, no_download = no_download, $
    cdf_data = cdf_data, get_cdf_data = arg_present(cdf_data), $
    get_support_data = get_support_data, $
    varnames = varnames, valid_names = valid_names, files = files, $
    vsnames = 'a b c d e', $
    type_sname = 'probe', $
    vdatatypes = 'scf scp scw', $
    vL2datatypes = 'scf scp scw scf_btotal scp_btotal scw_btotal', $
    file_vL2datatypes = 'scm', $
    vL2coord = 'dsl gse gsm none', $
    varformat = varformat_xxx, $
    vlevels = vlevels, $
    deflevel = deflevel, $
    vtypes = 'raw calibrated', $
    version = 'v01', $
    post_process_proc = 'thm_load_scm_post', $
    delete_support_data = delete_support_data, $
    proc_type = type, coord = coord, suffix = suffix, $
    progobj = progobj, $
    scm_cal = scm_cal, $
    use_eclipse_corrections=use_eclipse_corrections, $
    msg_out=msg_out, $
    _extra = _extra

;If valid names is set, both l1 and l2 are returned as valid levels
;and need to be passed out in the level variable
  if keyword_set(valid_names) then level = lvl
  if lvl[0] eq 'l1' && keyword_set(valid_names) then begin
    thm_cotrans, out_coord = coord, /valid_names, verbose = 0
    dprint, $
      string(strjoin(coord, ','), $
             format = '( "Valid '+lvl[0]+' coords:",X,A,".")')
  endif
  
  ;print any saved error messages now that loading is complete
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif
  
end
