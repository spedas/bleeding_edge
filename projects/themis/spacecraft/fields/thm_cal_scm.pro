;+
;NAME:
; thm_cal_scm
;PURPOSE:
; calibrate THEMIS SCM data
;
;    The processing is done in 6 successive steps (Step 1 is the first)
; ----------- by default, processing stops after step 5.
;
;     # 0: counts, NaN inserted into each gap for proper tplotting
;     # 1: Volts,  spinning sensor system, with    DC field
;     # 2: Volts,  spinning sensor system, without DC field[, xy DC field in nT]
;     # 3: nTesla, spinning sensor system, without DC field
;     # 4: nTesla, spinning SSL    system, without DC field
;     # 5: nTesla, fixed DSL system, without DC field, filtered <fmin
;     # 6: nTesla, fixed DSL system, with xy DC field
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., calibrate data for all
;          available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be calibrated/created.
;          The default is 'scf', 'scp', and 'scw', that is, SCM full mode,
;          particle burst mode and waves burst mode data, with no diagnostic
;          outputs.
;          Each mode of output has its own set of possible diagnostic outputs:
;          'sc?_dc', 'sc?_misalign' and 'sc?_iano', where ? can be
;          f, p or w.  To calibrate all modes loaded and create all diagnostic
;          outputs you can specify 'all'.
;          diagnostic outputs: raw data in Volts, dc field, axis misalignment
;          (angle between x and y axes in degrees),
;          and iano (data quality flag).  Created with '_dc',
;          '_misalign', and '_iano' suffixes, respectively.
;  in_suffix =  optional suffix to add to name of input data quantity, which
;          is generated from probe and datatype keywords.
;  out_suffix = optional suffix to add to name for output tplot quantity,
;          which is generated from probe and datatype keywords.
;  trange= array[2] string or double.  Limit calibration to specified time range
;
;
; use_eclipse_corrections:  Only applies when loading and calibrating
;   Level 1 data. Defaults to 0 (no eclipse spin model corrections 
;   applied).  use_eclipse_corrections=1 applies partial eclipse 
;   corrections (not recommended, used only for internal SOC processing).  
;   use_eclipse_corrections=2 applies all available eclipse corrections.
;
;  nk =    N points of the cal-convolution kernel, if set, this value will
;          be used regardless of sample rate.
;  mk =    If nk is not set, set nk to (sample frequency)*mk, where sample
;          frequency is determined by the data. default 8 for scf, 4 for scp,
;          and 1 for scw.
;  despin =classic despin algorithm. 0:off 1:on  Default is on.
;n_spinfit=n spins to fit for misalignment, dc field calculation and
;          optionally despin.
; cleanup= type of cleanup (default is 'none'):
;          'spin' for only spin tones (power ripples) cleanup,
;          'full' for spin tones and 8/32 Hz tones
;          'none' for no cleanup processes.
; wind_dur_1s = window duration for 8/32 Hz cleanup (has to be a multiple of 1s)
;          default is 1.
; wind_dur_spin = spintone cleanup window duration as a multiple of the spin
;          period. Default is 1.
; clnup_author = choice of cleanup routine (default is 'ole'):
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
;  verbose=set to zero to eliminate output.  currently only works with
;          valid_names
;valid_names=use /valid_names to print out values for probe, datatype, coord
;          and return those in named variables passed in to corresponding
;          keywords.
;
;optional parameters:
;
;  thx_scx      --> input data (t-plot variable name)
;  thx_scx_hed  --> header information for input data (t-plot variable name)
;
;Example:
;      tha_cal_fgm, probe = 'a', datatype= 'scp'
;
;HISTORY:
; 13-mar-2007, jmm, jimm@ssl.berkeley.edu
; June-2007, krb, Based on Patrick Robert's cowave_THEscmwf.f
; 25-sept-2007, krb, kenneth.r.bromund@nasa.gov
;   merged in changes to version 893, made on 16-jul-2007 by
;   olivier.LeContel@cetp.ipsl.fr, including Olivier Le Contel cleanup routine
;   (spin_tones_cleaning_vector_v5) in thm_cal_scm
; 23-jul-2008, jmm, added _extra to allow keyword inheritance
; jan-2010, ole@lpp.polytechnique.fr
; Modification to add Nan value only for last batch
; in step 6, start_step condition has been commented
; in outputs to tplot section, mode has been replaced by strlowcase(mode)
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2016-12-20 16:18:08 -0800 (Tue, 20 Dec 2016) $
;$LastChangedRevision: 22467 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_cal_scm.pro $
;-

pro thm_scm_sensor_to_SSL, xfo, yfo, zfo, nbp
  r2 = xfo*xfo + yfo*yfo + zfo*zfo

  x = -0.537691*xfo + 0.843131*yfo +0.004316*zfo
  y = -0.843039*xfo - 0.537696*yfo +0.012899*zfo
  z =  0.013196*xfo + 0.003295*yfo +0.999913*zfo

  p2 = x*x + y*y + z*z

  ;; test if no modulo difference
  diff = sqrt(p2) - sqrt(r2)
  epsi = (sqrt(p2)+sqrt(r2))/2.e4
  bad = where(abs(diff) gt epsi, nbad)
  if nbad gt 0 then $
    dprint,  '*** sensor to SSL : modulo has changed, diff= ', max(abs(diff))

  xfo = x
  yfo = y
  zfo = z
end

Pro thm_cal_scm, probe = probe, datatype = datatype, $
                 in_suffix = in_suffix, out_suffix = out_suffix, $
                 trange = trange, $ ;time_range
                 nk = k_nk, $  ;N points of the cal-convolution kernel
                 mk = k_mk, $ ; set nk to multiple of sample frequency
                 fdet = k_fdet, $ ;detrend frequency
                 despin = k_despin, $ ; classic despin 0:off 1:on
                 n_spinfit = k_n_spinfit, $ ;; n spins to fit for misalignment,
                 ;; dc field calculation and despin.
                 cleanup = str_cleanup, $      ;'full' (8/32Hz+spin),'spin' or 'none'
                 clnup_author = str_clnup_author, $ ;'ole' for Olivier 'ccc' for Chris Chaston
                 wind_dur_1s = k_wind_dur_1s, $ ;window duration for 8/32Hz cleanup
                 wind_dur_spin = k_wind_dur_spin,$;window duration spin cleanup
                 fcut = k_fcut, $           ;Frequency cut-off for calibration
                 fmin = k_fmin, $           ;Min frequency for filtering
                 fmax = k_fmax, $           ;Max frequency for filtering
                 step = k_step, $ ;Highest Processing step to complete
                 dircal = k_dircal,  $      ;directory of calibration files
                 calfile = k_calfile, $     ;override automatic cal file name
                 fsamp = fsamp, $           ; sample rate.  output.
                 blk_con=k_blk_con, $
                 edge_truncate=edget, edge_wrap=edgew, edge_zero=edgez, $
                 no_download=no_download, $ ; don't look on web for cal file
                 coord = k_coord, verbose=verbose, valid_names=valid_names, $
                 dfb_dig=k_dfb_dig, dfb_butter=k_dfb_butter, $
                 gainant=k_gainant, $
                 progobj = progobj, $ ;20-jul-2007, jmm
                 plotk = plotk, $
                 alt_scw = alt_scw, $
                 use_eclipse_corrections=use_eclipse_corrections, $
                 _extra = _extra, $ ;23-jul-2008, jmm
                 thx_scx, thx_scx_hed

  thm_init
; If verbose keyword is defined, override !themis.verbose
  vb = size(verbose, /type) ne 0 ? verbose : !themis.verbose

  ;; implement the 'standard' interface as a wrapper around the original
  ;; interface if no positional parameters are present.

  if n_params() eq 0 then begin
    vprobes = ['a', 'b', 'c', 'd', 'e']
;    Valid datatypes include the raw data in Volts, dc field, axis misalignment,
;          and iano (data quality flag).  Created with '_dc',
;          '_misalign', and '_iano' suffixes, respectively.

    vdatatypes = ['scf', 'scp', 'scw', $
                  'scf_dc', 'scf_misalign', 'scf_iano', $
                  'scp_dc', 'scp_misalign', 'scp_iano', $
                  'scw_dc', 'scw_misalign', 'scw_iano']
; consider adding _despin, _noise_1s, _cl, _noise_sp and _cl_sp datatypes.

    defdatatypes = ['scf', 'scp', 'scw']
    if keyword_set(valid_names) then begin
      probe = vprobes
      datatype = vdatatypes
      thm_cotrans, out_coord = k_coord, /valid_names, verbose = 0
      if keyword_set(vb) then begin
        dprint, string(strjoin(vprobes, ','), $
                               format = '( "Valid probes:",X,A,".")')
        dprint, string(strjoin(vdatatypes, ','), $
                               format = '( "Valid datatypes:",X,A,".")')
        dprint, string(strjoin(k_coord, ','), $
                               format = '( "Valid coords:",X,A,".")')
      endif
      return
    endif
    if not keyword_set(probe) then probes = vprobes $
    else probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
    if not keyword_set(probes) then return

    if not keyword_set(datatype) then dts = defdatatypes $
    else dts = ssl_check_valid_name(strlowcase(datatype), vdatatypes, $
                                    /include_all)
    if not keyword_set(dts) then return

    for i = 0, n_elements(probes)-1 do begin
      p_i = probes[i]
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = 'Processing Probe: '+ p_i
      dprint, dlevel = 4,  'Processing Probe: ', p_i
;If alt_scw is set, then degap the SCW data
      If(keyword_set(alt_scw)) Then temp_scw_degap, p_i

      for j = 0, n_elements(defdatatypes)-1 do begin
        dt_j = defdatatypes[j]
        dt_j_types = strfilter(dts, dt_j+'*', count = n_dt_j_types)
        if n_dt_j_types gt 0 then begin
          in_name = 'th'+p_i+'_'+dt_j
          hed_name = 'th'+p_i+'_'+dt_j+'_hed' 
          
          If(obj_valid(progobj)) Then progobj -> update, 0.0, text = 'Calibrating: '+ dt_j_types
          dprint, dlevel = 4,  'Calibrating: ', dt_j_types
          thm_cal_scm, in_name, hed_name, in_suffix = in_suffix, $
            out_suffix = out_suffix, datatype = dt_j_types, $
            trange = trange, $
            nk = k_nk, $
            mk = k_mk, $
            fdet = k_fdet, $
            despin = k_despin, $
            n_spinfit = k_n_spinfit, $
            cleanup = str_cleanup, $
            clnup_author = str_clnup_author, $
            wind_dur_1s = k_wind_dur_1s, $
            wind_dur_spin = k_wind_dur_spin, $
            fcut = k_fcut, $
            fmin = k_fmin, $
            fmax = k_fmax, $
            step = k_step, $
            dircal = k_dircal,  $
            calfile = k_calfile, $
            fsamp = fsamp, $
            blk_con = k_blk_con, $
            edge_truncate = edget, edge_wrap = edgew, $
            edge_zero = edgez, $
            no_download = no_download, coord = k_coord, $
            dfb_dig = k_dfb_dig, dfb_butter = k_dfb_butter, $
            gainant = k_gainant, $
            verbose = verbose, valid_names = valid_names, $
            alt_scw = alt_scw, $
            use_eclipse_corrections=use_eclipse_corrections, $
            progobj = progobj, plotk = plotk
        endif
      endfor
    endfor
    return
  endif else if n_params() lt 2 then begin
    dprint,  'for usage, type:'
    dprint,  "doc_library, 'thm_cal_scm'"
    return
  endif

; ---------------------------------------------------------------------------
; Here begins the code that gets called if positional parameters are provided
; ---------------------------------------------------------------------------

  if not keyword_set(in_suffix) then in_suff = '' ELSE in_suff = in_suffix
  if not keyword_set(out_suffix) then out_suff = '' ELSE out_suff = out_suffix

;instead of reading the rff_header, create the variables using the IDL
;create rff routine, I doubt if any is needed.

;Figure out what probe and mode, from the filename
  get_data, thx_scx+in_suff, time_scx, data_scx, dlimit = dlim_scx

;unpack the header data
  get_data, thx_scx_hed, time_scx_hed, val_scx_hed
  
  if out_suff[0] ne '' then begin
    copy_data, thx_scx_hed, thx_scx_hed + out_suff[0]
    store_data, thx_scx_hed, /delete 
    thx_scx_hed= thx_scx_hed + out_suff[0]
  end

; test if data is present and in raw form.
  if size(dlim_scx, /type) ne 8 then begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
      '*** '+thx_scx+in_suff+' does not exist, skipping.'
    dprint,  '*** ', thx_scx+in_suff, " does not exist, skipping."
    return
  endif

  if thm_data_calibrated(dlim_scx) then begin
    in_step = dlim_scx.data_att.step
    dprint,  '*** Input data already calibrated to step: ', in_step
    message, '*** Aborted: Currently can only use raw data as input'
    return
  endif

; get info needed to unpack the state data
  temp = file_basename(dlim_scx.cdf.filename)
  temp = strsplit(temp, '_', /extract)
  probe = strlowcase(strmid(temp[0], 2, 1))
  thx = 'th'+probe
  probe_n = byte(probe)-96
  probe_n = probe_n[0]
  str_probe_n = string(probe_n, format = '(I1)')
  mode = temp[2]

;unpack the state variables
  get_data, 'th'+probe+'_state_spinphase', time_thx_state, val_thx_spinpha
  get_data, 'th'+probe+'_state_spinper', time_thx_state, val_thx_spinper

; test if auxiliary data is present
  if size(val_scx_hed, /n_dim) ne 2 then begin
    dprint,   '*** ', thx_scx_hed, " does not exist:  "
    message, "   Aborted:  Support data not found."
  endif

  if size(val_thx_spinpha, /n_dim) ne 1 || $
    size(val_thx_spinper, /n_dim) ne 1 then begin
;load the state data if not present, jmm, 2008-11-04
    dprint, dlevel = 4, 'loading state data'
    tr0 = minmax(time_scx)
    dur = (tr0[1]-tr0[0])/86400.0d0 ;duration in days
    timespan, tr0[0], dur
    thm_load_state, probe = probe[0], /get_support_data
    get_data, 'th'+probe+'_state_spinphase', time_thx_state, val_thx_spinpha
    get_data, 'th'+probe+'_state_spinper', time_thx_state, val_thx_spinper
    if size(val_thx_spinpha, /n_dim) ne 1 || $
      size(val_thx_spinper, /n_dim) ne 1 then message, '*** Aborted: No state data available'
  endif

; ----------------------------------------------------
; Process calibration parameters, set default vaules.
; ----------------------------------------------------
;These keywords replace the subroutine r_inpara_rts
  If size(k_mk, /type) ne 0 Then mk = k_mk Else begin
    case mode of
      'scf': mk = 8
      'scp': mk = 4
      'scw': mk = 1
      else: begin
        mk = 1
        dprint,  '*** unknown or unset mode, mk set to 1'
      endelse
    endcase
  endelse
  If size(k_nk, /type) ne 0 Then nk = k_nk Else nk = 0
  If size(k_fdet, /type) ne 0 Then fdet = k_fdet Else fdet = 0.0
  if size(k_despin, /type) ne 0 Then despin = k_despin Else despin = 1
  if size(k_n_spinfit, /type) ne 0 Then $
    n_spinfit = k_n_spinfit else n_spinfit = 2

  if not keyword_set(str_cleanup) then cleanup = 'none' $
  else cleanup = ssl_check_valid_name(strlowcase(str_cleanup), $
                                      ['none', 'full', 'spin'])

  if not keyword_set(cleanup) then return
  cleanup = cleanup[0]

  if not keyword_set(str_clnup_author) then clnup_author = 'ole' $
  else clnup_author = ssl_check_valid_name(strlowcase(str_clnup_author), $
                                           ['ole', 'ccc'])
  if not keyword_set(clnup_author) then return
  clnup_author = clnup_author[0]

  if size(k_wind_dur_1s, /type) ne 0 Then $
    wind_dur_1s = k_wind_dur_1s Else wind_dur_1s = 1.0
  if size(k_wind_dur_spin, /type) ne 0 Then $
    wind_dur_spin = k_wind_dur_spin Else wind_dur_spin = 1.0
  If size(k_fcut, /type) ne 0 Then fcut = k_fcut Else fcut = 0.1
  If size(k_fmin, /type) ne 0 Then fmin = k_fmin Else fmin = 0.0
  If size(k_fmax, /type) ne 0 Then fmax = k_fmax Else fmax = 0.0
  if size(k_step, /type) ne 0 then step = k_step Else step = 5
  if size(k_step, /type) ne 0 then start_step = k_step Else start_step = 5
  if size(k_blk_con, /type) ne 0 then blk_con = k_blk_con Else blk_con = 8
  if size(k_dfb_butter, /type) ne 0 then $
    dfb_butter = k_dfb_butter Else dfb_butter = 1
  if size(k_dfb_dig, /type) ne 0 then dfb_dig = k_dfb_dig Else dfb_dig = 1
  if size(k_gainant, /type) ne 0 then gainant = k_gainant Else gainant = 1

  ;; check value of fcut for lower frequency limit of calibration
  if fcut lt 0.001 then begin
    fcut = 0.001
    dprint, dlevel = 4,  'fcut < 0.001, set to ', fcut
  endif

  if keyword_set(k_coord) then begin
    thm_cotrans, out_coord = vcoord, /valid_names, verbose = 0
    coord = ssl_check_valid_name(strlowcase(k_coord), vcoord)
    if not keyword_set(coord) then begin
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        '*** invalid coord specification'
      dprint,  '*** invalid coord specification'
      return
    endif
    if n_elements(coord) ne 1 then begin
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        '*** coord must specify a single coordinate system'
      dprint,  '*** coord must specify a single coordinate system'
      return
    endif
    if step eq 5 then begin
      if strlowcase(coord) eq 'ssl' then begin
        If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
          '*** Warning: step 5 requested, with coord=SSL, setting step = 4'
        dprint,  '*** Warning: step 5 requested, with coord=SSL, setting step = 4'
        step = 4
      endif else if strlowcase(coord) ne 'dsl' && fmin lt fcut  then begin
        fminnew = fcut
        If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
          '*** Warning: for step 5 output in coord sys other than DSL, '
        dprint,  '*** Warning: for step 5 output in coord sys other than DSL, '
        If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
          'fmin must be >fcut, inital fmin = '+strcompress(/remove_all, string(fmin))+$
          ' set to fcut = '+strcompress(/remove_all, string(fminnew))
        dprint,  '    fmin must be >fcut'
        dprint,  '    inital fmin=', fmin, ' set to fcut =', fminnew
        fmin = fminnew
      endif
    endif
  endif

; * warning for step > 6
  if step gt 6 then begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
      '*** Warning : step requested = '+strcompress(/remove_all, string(step))+$
      '    Step 6 is maximum allowed, set to 6'
    dprint,  '*** Warning : step requested =', step
    dprint,  '    Step 6 is maximum allowed, set to 6'
    dprint,  '    use thm_cotrans to get output in GSE or GSM'
    step = 6
  endif

  dprint, dlevel = 4,  'thm_cal_scm parameters:'
  dprint, dlevel = 4,  format = "('            nk: ', I4)", nk
  dprint, dlevel = 4,  format = "('            mk: ', I4)", mk
  dprint, dlevel = 4,  format = "('          fdet: ', f6.1)", fdet
  dprint, dlevel = 4,  format = "('        despin: ', I4)", despin
  dprint, dlevel = 4,  format = "('     n_spinfit: ', I4)", n_spinfit
  dprint, dlevel = 4,  format = "('       cleanup: ', A4)", cleanup
  switch cleanup of
    'spin':
    'full': dprint, dlevel = 4,  format = "(' 1st av. wind.: spin per. * ', f4.1)", wind_dur_spin
    else:
  endswitch
  case cleanup of
    'full': dprint, dlevel = 4,  format = "(' 2nd av. wind.: ', f6.1)", wind_dur_1s
    else:
  endcase
  dprint, dlevel = 4,  format = "('          fcut: ', f8.3)", fcut
  dprint, dlevel = 4,  format = "('          fmin: ', f8.3)", fmin
  dprint, dlevel = 4,  format = "('          fmax: ', f8.3)", fmax
  dprint, dlevel = 4,  format = "('          step: ', I4)", step
  dprint, dlevel = 4,  format = "('       gainant: ', I4)", gainant
  dprint, dlevel = 4,  format = "('       dfb_dig: ', I4)", dfb_dig
  dprint, dlevel = 4,  format = "('    dfb_butter: ', I4)", dfb_butter
  if keyword_set(coord) then $
    dprint, dlevel = 4,  format = "('         coord: ', A4)", coord
  dprint, dlevel = 4,  '----------------------------------------------------------'

; generate name of calibration file
; the cal files are per spacecraft
  IF size(/type, k_dircal) EQ 0 Then begin
     ;; read calibration files from data repository, rather than source
    cal_relpathname = thx+'/l1/scm/0000/THEMIS_SCM'+str_probe_n+'.cal'
    calfile = spd_download(remote_file=cal_relpathname, _extra = !themis, $
                            no_download = no_download)
  Endif else begin
    if size(/type, k_dircal) EQ 7 and keyword_set(k_dircal) then begin
      dircal = k_dircal
    endif else begin
      dirscm = routine_info('thm_cal_scm', /source)
      dirscm = file_dirname(dirscm.path)
      DPRINT, DLEVEL = 4,  '   dirscm: ', dirscm
      dircal = filepath(root_dir = dirscm, 'scm/cal')
    endelse
    DPRINT, DLEVEL = 4,  '   dircal: ', dircal
    calfile = 'THEMIS_SCM'+str_probe_n+'.cal'
    calfile = filepath(root_dir = dircal, calfile)
  endelse
  DPRINT, DLEVEL = 4,  '   calfile: ', calfile

; initialize gainant ( ensures that cal file is read once and only once;
;  sets parameters for future calls )
  void = thm_scm_gainant_vec(/init, gainant = gainant, $
                             dfb_butter = dfb_butter, dfb_dig = dfb_dig)

; this code replaces scm_reduce_period_V3
; no need to reduce state data, so scm_reduce_period{S1,S4} are omitted.
  if keyword_set(trange) and n_elements(trange) eq 2 then begin
    t1 = time_double(trange[0])
    t2 = time_double(trange[1])

    wave_in_range = where(time_scx ge t1 and time_scx le t2, n)
    if n gt 0 then begin
      data_scx = data_scx[wave_in_range, *]
      time_scx = time_scx[wave_in_range]
    endif else begin
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'no data in trange'+time_string(trange)
      dprint, dlevel = 4,  'no data in trange', time_string(trange)
      return
    endelse
  endif

;Get SCM sample frequency from the header. This is scm_get_sample_rate.
  val_scx_apid = reform(uint((32b*val_scx_hed[*, 0]/32b))*uint(256) $
                        + uint(val_scx_hed[*, 1]))
  TMrate = 2.^(reform(val_scx_hed[ *, 14]/16b)+1)
  ;;dec2hex
  apid_str = strtrim(string( val_scx_apid(0, 0), format = '(Z)'), 2)
  DPRINT, DLEVEL = 4,  'apid=', apid_str

;; Conversion of TM data in Volts

; do the stuff scm_create_rff does, without writing to a new file:
; interpolation of sample rate aligned on scm time
  If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
    'Sample rate interpolation...'
  dprint, dlevel = 4,  'Sample rate interpolation...'
  thm_scm_rate_interpol, time_scx_hed, TMrate, time_scx, SA_rate
  
; interpolation of spin phase
  If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
    'Phase interpolation using spin model data...'
  dprint, dlevel = 4,  'Phase interpolation using spin model data...'

  model = spinmodel_get_ptr(probe[0],use_eclipse_corrections=use_eclipse_corrections)
  If(obj_valid(model)) Then Begin
    spinmodel_interp_t, model = model, time = time_scx, $
      spinphase = sp_phase, spinper = spinper_xxx, $
      use_spinphase_correction = 1 ;a la J. L.
  Endif

  iano = intarr(n_elements(time_scx))

  ;; process continuous stretches of data in separate batches:
  ;; they require differing kernel sizes, based on sample rate, spin rate

  ;; ---------------------
  ;; Step 0
  ;; ---------------------

  ;; find sample rate changes, data gaps and time reversals

  ;; find data rates in this file.
  rates = SA_rate[UNIQ(SA_rate, SORT(SA_rate))]
  if nk EQ 0 then nks = rates*mk ;; nks is the set of various kernel sizes
  fsamp = rates
  n_rates = n_elements(rates)
  If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
    '   Sample frequencies found: '+strcompress(/remove_all, string(rates))
  dprint, dlevel = 4,  '   Sample frequencies found: ', rates
  ;; find data gaps, working with one sample rate at a time.
  for r = 0, n_rates-1 do begin
    fe = rates[r]
    If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
      '   Searching for discontinuities in data at samp. freq.: '+$
      strcompress(/remove_all, string(fe))+'   dt: '+strcompress(/remove_all, string(1.0/fe))
    dprint, dlevel = 4,  '   Searching for discontinuities in data at samp. freq.: ', fe
    dprint, dlevel = 4,  '   dt: ', 1.0/fe
    ind_r = where(SA_rate eq fe)
    dt = time_scx[ind_r[1:*]]-time_scx[ind_r]
    reverse = where(dt lt 0, n_reverse)
    if n_reverse gt 0 then $
      iano[ind_r[reverse]] = 16 ; time reverse
    discontinuity = where(abs(dt-1.0/fe) gt 2.0e-5, n_discont)
    if n_discont gt 0 then $
      iano[ind_r[discontinuity]] = 17 ; discontinuity in time

     ;; discontinuity in sample rate (Minor bug: some changes in sample rate
     ;; can be mislabled as discontinuities in time)
    iano[ind_r[n_elements(ind_r)-1]] = 22

  endfor

  ;; Prepare to process data in batches, applying steps 1-6 on each batch

  coord_sys = 'scs'
  units = 'counts'

  errs = where(iano ge 15, n_batches)

  If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
    'Number of continuous batches: '+strcompress(/remove_all, string(n_batches))
  dprint, dlevel = 4,  'Number of continuous batches: ', n_batches

  ;; size of output arrays includes a space for one NaN after each batch,
  ;; except the last one if the lines noted L2 data are uncommented


  nout = n_elements(time_scx)+ n_batches -1 ; -1 to be added to be consistent with L2 data provided by jmm

  out_scx = fltarr(nout, 3)
  out_scx_dc = fltarr(nout, 2)
  out_scx_misalign = fltarr(nout)

  iano_out = fltarr(nout)
  data_scx_out = fltarr(nout, 3)
  time_scx_out = dblarr(nout)

  ind0 = 0
  for batch = 0, n_batches-1 do begin
    ind1 = errs[batch]
    nbp = ind1-ind0+1
    ind1_ref = ind1
    dprint, dlevel = 4,  '----------------------------------------------------------'
    dprint, dlevel = 4,  '----------------------------------------------------------'
    If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
      'Batch #'+strcompress(/remove_all, string(batch))+$
      ' Nbp of the batch = '+strcompress(/remove_all, string(nbp))+', duration is '+$
      strcompress(/remove_all, string(float(nbp)/fe))+ ' sec.'
    dprint, dlevel = 4,  'Batch #', batch
    dprint, dlevel = 4,  'Nbp of the batch=', nbp, ', so duration is ', float(nbp)/fe, ' sec.'
;
;    The processing is done in 6 successive steps
;
;     # 1: Volts,  spinning sensor system, with    DC field
;     # 2: Volts,  spinning sensor system, without DC field, xy DC field in nT
;     # 3: nTesla, spinning sensor system, without DC field
;     # 4: nTesla, spinning SSL    system, without DC field
;     # 5: nTesla, fixed DSL system, without DC field
;     # 6: nTesla, fixed DSL system, with xy DC field

;-----------------------------------------------------
;     Get auxiliary data
;-----------------------------------------------------
     ;; use most recent value of spin period available before start of batch
    tsp = val_thx_spinper[max([0, where(time_thx_state le time_scx[ind0])])]
    fs = 1./tsp
     ;; sample (echantillonage) frequency
    fe = SA_rate[ind0]

     ;; adjust kernel size automatically to sample frequency
    if n_elements(nks) gt 0 then nk = fe * mk

    fnyq = fe/2.  ; nyquist frequnecy (called fmax in cowave_THEscmwf)

    dprint, dlevel = 4,  'Sample frequency: ', fe, ' Hz'

     ;; check value of fcut for calibration
    if fmin lt 0.0 then begin
      f1 = 0.
      dprint, dlevel = 4,  'fmin < 0, set to ', f1
    endif else f1 = fmin

    if fmax le f1 then begin
      f2 = fnyq
      dprint, dlevel = 4,  'fmax < fmin, set to Nyquist= ', fnyq
    endif else f2 = fmax        ;jmm, 13-mar-2008

    xfo = data_scx[ind0:ind1, 0]
    yfo = data_scx[ind0:ind1, 1]
    zfo = data_scx[ind0:ind1, 2]

     ;;------------------------------
     ;; processing step 1
     ;;------------------------------
     ;; Convert to Volts, flag saturation and nulls.


    if step ge 1 then begin
      dprint, dlevel = 4,  '-----------------------------------------------------'
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'step 1: TM data in spinning system [Volt] with  DC'
      dprint, dlevel = 4,  'step 1: TM data in spinning system [Volt] with    DC'

      calfactor = (10.04/2.^16)
      xfo *= calfactor
      yfo *= calfactor
      zfo *= calfactor

      units = 'V'

        ;;thm_scm_testsatura

    endif

    if step ge 2 then begin
      dprint, dlevel = 4,  '-----------------------------------------------------'
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'step 2: TM data in spinning system [Volt] without DC'
      dprint, dlevel = 4,  'step 2: TM data in spinning system [Volt] without DC'

        ;; get antenna response at spin frequency
      thm_scm_modpha, thm_scm_gainant_vec(fs, 1, calfile, fe), rfsx, phafsx
      thm_scm_modpha, thm_scm_gainant_vec(fs, 2, calfile, fe), rfsy, phafsy
      thm_scm_modpha, thm_scm_gainant_vec(fs, 3, calfile, fe), rfsz, phafsz
      dprint, dlevel = 4,  'Spin Frequency: ', fs
      dprint, dlevel = 4,  'Transfer function at spin frequency:'
      dprint, dlevel = 4,  'rfsx (V/nT),phafsx (d.) =', rfsx, phafsx
      dprint, dlevel = 4,  'rfsy (V/nT),phafsy (d.) =', rfsy, phafsy
      dprint, dlevel = 4,  'rfsz (V/nT),phafsz (d.) =', rfsz, phafsz

        ;; spin phase
      sph = SP_phase[ind0:ind1]

        ;; check for abnormally incrementing spin phase, and
        ;; interpolate over the bad points, jmm, 4-nov-2008
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'number of spins in this batch= '+strcompress(/remove_all, string(nbp*fs/fe))
      dprint, dlevel = 4,  'number of spins in this batch= '+strcompress(/remove_all, string(nbp*fs/fe))
      dph = SP_phase[ind0+1:ind1]-SP_phase[ind0:ind1-1]
      dph_neg = where(dph lt 0, n_dph_neg)
      if n_dph_neg gt 0 then dph[dph_neg]+= 360.0
      sph_test = abs(dph - 360.0*fs/fe) gt (360.0*fs/fe * 0.01)
      bad_sph = where(sph_test, n_bad_sph)
      if n_bad_sph gt 0 then begin
        If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
          '*** n bad spin phase values: '+strcompress(/remove_all, string(n_bad_sph))+$
          ' out of '+ strcompress(/remove_all, string(nbp))
        dprint, dlevel = 4,  '*** n bad spin phase values: ', n_bad_sph, ' out of ', nbp
        ok_sph = where(sph_test Eq 0, n_ok_sph)
        If(n_ok_sph Le 1) Then Begin
          If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
            '*** Not enough good spin phase values for interpolation, Proceeding with calculation anyway'
          dprint,  '*** Not enough good spin phase values for interpolation'
          dprint,  '*** Proceeding with calculation anyway'
        Endif Else Begin
          If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
            '*** Interpolating bad spin phase values'
          dprint,  '*** Interpolating bad spin phase values'
          tsph = time_scx[ind0:ind1]
          sph[bad_sph] = interpol(sph[ok_sph], tsph[ok_sph], tsph[bad_sph])
        Endelse
      endif

        ;; Initial centering of waveforms -- supbtract average values
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'Initial centering of the waveforms: '
      dprint, dlevel = 4,  'Initial centering of the waveforms: '

      xavg = total(xfo)/nbp
      yavg = total(yfo)/nbp
      zavg = total(zfo)/nbp

      xfo -= xavg
      yfo -= yavg
      zfo -= zavg

        ;; calculate sine fit for calculation of misalignment angle and
        ;; classic_despin

      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'Spin fit: batch #'+strcompress(/remove_all, string(batch))+$
        ' number of spins = '+strcompress(/remove_all, string(nbp*fs/fe))
      dprint, dlevel = 4,  'Spin fit: '

      thm_scm_casinus_vec, xfo, fe, fs, n_spinfit, $
        axvo, phaxvo, n, nbi, xsub, fe_max = 128
;Try a reduced value of n_spinfit (1.25) if this failed:
      If(mode Eq 'scw' And (n_elements(axvo) Eq 1 And axvo[0] Eq 0)) Then Begin
         n_spinfit_temp = 1.25
         Dprint, '*** Recalculating, using 1.25 for n_spinfit'
         thm_scm_casinus_vec, xfo, fe, fs, n_spinfit_temp, $
                              axvo, phaxvo, n, nbi, xsub, fe_max = 128
      Endif Else n_spinfit_temp = n_spinfit
      thm_scm_casinus_vec, yfo, fe, fs, n_spinfit_temp, $
        ayvo, phayvo, n, nbi, ysub, fe_max = 128
      thm_scm_casinus_vec, zfo, fe, fs, n_spinfit_temp, $
        azvo, phazvo, n, nbi, zsub, fe_max = 128

      dl = {labels: [ 'x', 'y', 'z'], labflag: 1, colors: [ 2, 4, 6]}

      if despin gt 0 then begin
           ;; *   Remove the sine signal
        If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
          'Removing sine signal: batch #'+ $
          strcompress(/remove_all, string(batch))
        dprint, dlevel = 4,  'Removing sine signal: '

        xfo = xsub
        yfo = ysub
        zfo = zsub

        if cleanup ne 'none' then begin
              ;;storing the _despin waveform

          wf_scx_despin = dblarr(nbp, 3)

          wf_scx_despin[*, 0]  = xfo
          wf_scx_despin[*, 1]  = yfo
          wf_scx_despin[*, 2]  = zfo
          thscs_despin = thx_scx+'_despin'+out_suff[0]

          store_data, thscs_despin, $
            data = {x:time_scx[ind0:ind1], y:wf_scx_despin}, dl = dl
        endif
      endif

        ;;;;;;;;;;;;;;;;;;;;; CLEANUP PART (TO BE CHECKED)
      if cleanup eq 'spin' then begin
           ;; *   Remove only spin tones (power ripples)
           ;; *   for ex. fast survey mode (scf) nominally at 8Hz
           ;; *   but be careful possible range is 2-256 Hz
           ;; *   or rarely particle burst (scp) at 2, 4 and 8Hz

           ;; cleanup of spin tones (power ripples)
           ;; window duration has to be equal to
           ;; a multiple of the spinperiod
        wind_dur_sp = tsp * wind_dur_spin
        str_wind_dur_sp = string(wind_dur_sp, format = '(f5.2)')
        samp_per = 1./fe
        dprint, dlevel = 4,  '*** Only spin tones cleanup ***'
        dprint, dlevel = 4,  'window duration for spin tones cleanup (sec) = ', $
          wind_dur_sp, FORMAT = '(a,e12.2)'
        dprint, dlevel = 4,  'sample period (sec) = ', samp_per, FORMAT = '(a,e12.5)'
        
        time_scx_cl0 = time_scx[ind0:ind1]
        n_cl         = n_elements(time_scx_cl0)
        
        wf_scx = dblarr(n_cl, 3)

        wf_scx[*, 0]  = xfo
        wf_scx[*, 1]  = yfo
        wf_scx[*, 2]  = zfo

        case clnup_author of
          'ole': begin
            spin_tones_cleaning_vector_v5, time_scx_cl0, wf_scx, $
              wind_dur_sp, samp_per, $
              time_scx_cl_sp, wf_noise_sp, $
              wf_scx_cl_sp, nbwind_sp, $
              nbpts_cl_sp

            ;;storing waveform after spintones cleanup
            
            thscs_noise_sp = thx_scx+'_noise_sp'+out_suff[0]
            store_data, thscs_noise_sp, $
              data = {x:time_scx_cl_sp, y:wf_noise_sp}, dl = dl

            thscs_cl_sp = thx_scx+ '_cl_sp'+out_suff[0]
            store_data, thscs_cl_sp, $
              data = {x:time_scx_cl_sp, y:wf_scx_cl_sp}, dl = dl

            xfo      = wf_scx_cl_sp[*, 0]
            yfo      = wf_scx_cl_sp[*, 1]
            zfo      = wf_scx_cl_sp[*, 2]
          end
          'ccc': begin
            thscs_noisy = {x:time_scx_cl0, y:wf_scx}
            thscs_cl_sp = scm_cleanup_ccc(thscs_noisy, $
                                          ave_window = wind_dur_sp, $
                                          min_num_windows = 2)

                 ;;storing waveform after spintones cleaning
            thscs_cleaned = thx_scx+'cl_sp'+out_suff[0]
            store_data, thscs_cleaned, data = thscs_cl_sp, dl = dl

            xfo      = thscs_cl_sp.y[*, 0]
            yfo      = thscs_cl_sp.y[*, 1]
            zfo      = thscs_cl_sp.y[*, 2]
            nbpts_cl_sp = n_elements(thscs_cl_sp.x)
          end
        endcase
        ind1     = ind0 + nbpts_cl_sp-1L
        nbp      = ind1-ind0+1
        If(n_elements(axvo) Gt 1) Then Begin
          axvo     = axvo[0:nbp-1]
          phaxvo   = phaxvo[0:nbp-1]
          ayvo     = ayvo[0:nbp-1]
          phayvo   = phayvo[0:nbp-1]
          azvo     = azvo[0:nbp-1]
          phazvo   = phazvo[0:nbp-1]
        Endif Else Begin
          axvo = replicate(axvo[0], nbp)
          phaxvo = replicate(phaxvo[0], nbp)
          ayvo = replicate(ayvo[0], nbp)
          phayvo = replicate(phayvo[0], nbp)
          azvo = replicate(azvo[0], nbp)
          phazvo = replicate(phazvo[0], nbp)
        Endelse
      endif

      if cleanup eq 'full' then begin
           ;; *   Remove spin tones (power ripples)
           ;; *   and 8/32 Hz tones
           ;; *   for ex. particle burst (scp) nominally at 128 Hz
           ;; *   but possible range is 2-256 Hz
           ;; *   and wave burst (scw) nominally at 8192 Hz
           ;; *   but possible range is 512-8192 Hz

           ;; cleaning of spin tones (power ripples)
           ;; window duration has to be equal to
           ;; a multiple of the spinperiod

        wind_dur_sp = tsp * wind_dur_spin
        str_wind_dur_sp = string(wind_dur_sp, format = '(f5.2)')
        samp_per = 1./fe
        
        dprint, dlevel = 4,  '*** Full cleanup (spin tones and 8/32 Hz) ***'
        dprint, dlevel = 4,  'window duration for spin tones cleanup (sec) = ', $
          wind_dur_sp, FORMAT = '(a,e12.2)'
        dprint, dlevel = 4,  'sample period (sec) = ', samp_per, FORMAT = '(a,e12.5)'
        
        time_scx_cl0 = time_scx[ind0:ind1]
        n_cl         = n_elements(time_scx_cl0)
        
        wf_scx = dblarr(n_cl, 3)
        
        wf_scx[*, 0]  = xfo
        wf_scx[*, 1]  = yfo
        wf_scx[*, 2]  = zfo
        
        case clnup_author of
          'ole': begin
            spin_tones_cleaning_vector_v5, time_scx_cl0, wf_scx, $
              wind_dur_sp, samp_per, $
              time_scx_cl_sp, wf_noise_sp, $
              wf_scx_cl_sp, nbwind_sp, $
              nbpts_cl_sp

                 ;;storing waveform after spintones cleanup

            thscs_noise_sp = thx_scx+'_noise_sp'+out_suff[0]
            store_data, thscs_noise_sp, $
              data = {x:time_scx_cl_sp, y:wf_noise_sp}, dl = dl
            thscs_cl_sp = thx_scx+ '_cl_sp'+out_suff[0]
            store_data, thscs_cl_sp, $
              data = {x:time_scx_cl_sp, y:wf_scx_cl_sp}, dl = dl

          end
          'ccc': begin
            thscs_noisy = {x:time_scx_cl0, y:wf_scx}
            thscs_cl_sp = scm_cleanup_ccc(thscs_noisy, $
                                          ave_window = wind_dur_sp, $
                                          min_num_windows = 2)
            
            ;;storing waveform after spintones cleaning
            
            thscs_cleaned_sp = thx_scx+'_cl_sp'+out_suff[0]
            store_data, thscs_cleaned_sp, data = thscs_cl_sp, dl = dl
            
          end
        endcase

           ;; cleaning 8/32 Hz 1s phase locked noise
           ;; window duration has to be a multiple of 1s

        str_wind_dur_1s = string(wind_dur_1s, format = '(f4.1)')
        dprint, dlevel = 4,  'window duration for 8/32 Hz cleanup (sec) = ', $
          wind_dur_1s, FORMAT = '(a,e12.2)'
        
        case clnup_author of
          'ole': begin
            spin_tones_cleaning_vector_v5, time_scx_cl_sp, wf_scx_cl_sp, $
              wind_dur_1s, samp_per, $
              time_scx_cl, wf_scx_noise_1s, $
              wf_scx_cl, nbwind, nbpts_cl

                 ;;storing after 8/32 Hz cleaning
            
            thscs_noise_1s = thx_scx+'_noise_1s'+out_suff[0]
            store_data, thscs_noise_1s, $
              data = {x:time_scx_cl, y:wf_scx_noise_1s}, dl = dl
            thscs_cl = thx_scx+'_cl'+out_suff[0]
            store_data, thscs_cl, data = {x:time_scx_cl, y:wf_scx_cl}, dl = dl
            
            xfo      = wf_scx_cl[*, 0]
            yfo      = wf_scx_cl[*, 1]
            zfo      = wf_scx_cl[*, 2]
          end
          'ccc': begin
            thscs_cl = scm_cleanup_ccc(thscs_cl_sp, ave_window = wind_dur_1s, $
                                       min_num_windows = 2)
            
            ;;storing after 8/32 Hz cleaning
            
            thscs_cleaned = thx_scx+'_cl'+out_suff[0]
            store_data, thscs_cleaned, data = thscs_cl, dl = dl
            
            xfo      = thscs_cl.y[*, 0]
            yfo      = thscs_cl.y[*, 1]
            zfo      = thscs_cl.y[*, 2]
            nbpts_cl = n_elements(thscs_cl.x)
          end
        endcase
        ind1     = ind0 + nbpts_cl-1L
        nbp      = ind1-ind0+1L
        
        If(n_elements(axvo) Gt 1) Then Begin
          axvo     = axvo[0:nbp-1]
          phaxvo   = phaxvo[0:nbp-1]
          ayvo     = ayvo[0:nbp-1]
          phayvo   = phayvo[0:nbp-1]
          azvo     = azvo[0:nbp-1]
          phazvo   = phazvo[0:nbp-1]
        Endif Else Begin
          axvo = replicate(axvo[0], nbp)
          phaxvo = replicate(phaxvo[0], nbp)
          ayvo = replicate(ayvo[0], nbp)
          phayvo = replicate(phayvo[0], nbp)
          azvo = replicate(azvo[0], nbp)
          phazvo = replicate(phazvo[0], nbp)
        Endelse
      endif

      if cleanup eq 'none' then begin
        dprint, dlevel = 4,  '***   no cleanup processes   ***'
      endif

      if nbp lt nbi then begin
        iano[ind0:ind1] = iano[ind1] ; flag all points
      endif

      ;; Determine antenna misalignment.
      ;; this is cal_depoint (vectorized)
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'Antenna Misalignment Calculation: batch #'+strcompress(/remove_all, string(batch))
      dprint, dlevel = 4,  'Antenna Misalignment Calculation: '

        ;; compute spin sine in nT
      bpx = axvo/rfsx
      bpy = ayvo/rfsy
      bpz = azvo/rfsz

        ;; calculate the misalignment of Z axis from spin axis
      deno = sqrt(bpx*bpx + bpy*bpy + bpz*bpz)
      null_deno = where(deno le 1.e-10, n_null_deno)
      if n_null_deno gt 0 then deno[null_deno] = !values.f_nan

      sd = bpz*sqrt(2.)/deno
      
      misalign = sd + !values.f_nan
      
      sd_good = where(abs(sd) LE 1., n_sd_good)
      if n_sd_good gt 0 then $
        misalign[sd_good] = asin(sd[sd_good])*180/!dpi
      
      ;; if fdet is not zero, then detrend to remove low frequency
      if fdet gt 0 then begin
        nsmooth = long(fe/fdet+0.5)
        If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
          ' Sample rate, fdetrend='+strcompress(/remove_all, string(fe))+', '+$
          strcompress(/remove_all, string(fdet))+$
          '    Number of points for smoothing : ' +strcompress(/remove_all, string(nsmooth))
        dprint, dlevel = 4,  '    Sample rate, fdetrend=', fe, fdet
        dprint, dlevel = 4,  '    Number of points for smoothing : ', nsmooth

        if nsmooth gt nbp then begin
          If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
            '*** batch '+strcompress(/remove_all, string(batch))+': Detrend frequency too small'
          dprint, dlevel = 4,  '*** batch ', batch, 'Detrend frequency too small'
          iano[ind0:ind1] = iano[ind1] ; flag all points
        endif
        if nsmooth lt 2 then begin
          If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
            '*** batch '+strcompress(/remove_all, string(batch))+': Detrend frequency too high'
          dprint, dlevel = 4,  '*** batch ', batch, 'Detrend frequency too high'
          iano[ind0:ind1] = iano[ind1] ; flag all points
        endif
        xfo -= smooth(xfo, nsmooth, /edge_truncate)
        yfo -= smooth(yfo, nsmooth, /edge_truncate)
        zfo -= smooth(zfo, nsmooth, /edge_truncate)
      endif

        ;; final centering of waveform

      xavg = total(xfo)/nbp
      yavg = total(yfo)/nbp
      zavg = total(zfo)/nbp
      xfo -= xavg
      yfo -= yavg
      zfo -= zavg

; *** Computation of the X-Y values of the DC field in fixed DSL system

; *   X,Y amplitude and phase are computed in sensor system
; *   Transformation to SSL is a rotation of about 45 + 12.4 degres
; *   and must be consistent with the Sensor_to_SSL matrix
; *   Tranformation from SSL to DSL is a rotation of sun pulse phase.

      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'Computation of the DC field in the spin plane:'
      dprint, dlevel = 4,  'Computation of the DC field in the spin plane:'

      rotdeg = 45. + 12.45 + sph
      phaxc = -(phaxvo-phafsx-rotdeg)
      phayc = -(phayvo-phafsy-rotdeg)

      depha = phayc-phaxc
      depha = (phayvo-phaxvo) mod 360
      gt180 = where(depha gt 180, n_gt180)
      if n_gt180 gt 0 then depha[gt180] -= 360

      lt_180 = where(depha lt -180, n_lt_180)
      if n_lt_180 gt 0 then depha[lt_180] += 360

        ;;print, 'In sensor system,  bpx,phaxvo,phafsx =',bpx,phaxvo,phafsx
        ;;print, 'In sensor system,  bpy,phayvo,phafsy =',bpy,phayvo,phafsy
        ;;print, 'In DSL, after cal, phaxc,phayc,diff=',phaxc,phayc,depha

      bdcx = bpx*sin((phaxc)*!dpi/180.)
      bdcy = bpy*sin((phayc)*!dpi/180.)

        ;;print, 'X,Y of DC field in DSL=',bdcx,bdcy

;; save values of dc field and misalignment for storage in tplot
;; insert a NaN in the gap
		; Modification added in order to add a Nan only for the last batch
		; to be consistent with L2 data provided by jmm
      if batch eq n_batches-1 then begin

        out_scx_misalign[ind0+batch:ind1+batch] = misalign
        out_scx_dc[ind0+batch:ind1+batch, 0] = bdcx
        out_scx_dc[ind0+batch:ind1+batch, 1] = bdcy
        
      endif else begin

        out_scx_misalign[ind0+batch:ind1+batch] = misalign
        out_scx_misalign[ind1+batch+1:ind1_ref+batch+1] = !values.f_nan
        
        out_scx_dc[ind0+batch:ind1+batch, 0] = bdcx
        out_scx_dc[ind0+batch:ind1+batch, 1] = bdcy

        out_scx_dc[ind1+batch+1:ind1_ref+batch+1, *] = !values.f_nan
      endelse
    endif

    if step ge 3 then begin
      dprint, dlevel = 4,  '-----------------------------------------------------'
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'step 3: Calibrated data in sensor spinning system [nT] without DC'
      dprint, dlevel = 4,  'step 3: Calibrated data in sensor spinning system [nT]'+$
        ' without DC'
      
      dprint, dlevel = 4,  'Deconvolution-calibration ...'
      dprint, dlevel = 4,  'Sample rate        =', fe
      dprint, dlevel = 4,  'Size of FIR kernel =', nk

      if keyword_set(plotk) and batch eq 0 then begin
        my_plotk = 'step3_response.png'
      endif else my_plotk = ''
;thm_scm_deconvo_vec will fail if there are not enough good data points
      good_data = where(finite(xfo+yfo+zfo), ngood)
      If(ngood Gt nk) Then Begin
        thm_scm_deconvo_vec, xfo, nbp, nk, fcut, fnyq, fe, $
          'thm_scm_gainant_vec', $
          1, calfile, 0., blk_con = blk_con, $
          edge_t = edget, edge_w = edgew, edge_z = edgez, $
          plotk = my_plotk

        thm_scm_deconvo_vec, yfo, nbp, nk, fcut, fnyq, fe, $
          'thm_scm_gainant_vec', $
          2, calfile, 0., blk_con = blk_con, $
          edge_t = edget, edge_w = edgew, edge_z = edgez
        thm_scm_deconvo_vec, zfo, nbp, nk, fcut, fnyq, fe, $
          'thm_scm_gainant_vec', $
          3, calfile, 0., blk_con = blk_con, $
          edge_t = edget, edge_w = edgew, edge_z = edgez
        units = 'nT'
      Endif Else Begin
        dprint, dlevel = 4,  'Deconvolution is not possible'
        dprint, dlevel = 4,  'Nbp = ', nbp
        dprint, dlevel = 4,  'Ngood = ', ngood
        dprint, dlevel = 4,  'NK = ', nk
      Endelse
    endif

    if step ge 4 then begin
      dprint, dlevel = 4,  '-----------------------------------------------------'
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'step 4: Calibrated data in SSL spinning system [nT] without DC'
      dprint, dlevel = 4,  'step 4: Calibrated data in SSL spinning system [nT]'+$
        ' without DC'
      dprint, dlevel = 4,  'Performing rotation: '
      thm_scm_sensor_to_SSL, xfo, yfo, zfo, nbp

      coord_sys = 'ssl'
      
    endif

    if step ge 5 then begin
      dprint, dlevel = 4,  '-----------------------------------------------------'
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'step 5: Calibrated data in DSL system [nT] without DC '+$
        strcompress(/remove_all, string(f1))+' '+$
        strcompress(/remove_all, string(f2))
      dprint, dlevel = 4,  'step 5: Calibrated data in DSL system [nT]'+$
        ' without DC', f1, f2
      dprint, dlevel = 4,  'Performing rotation in spin plane: '
      
      sinphi = sin(sph/180.0*!dpi)
      cosphi = cos(sph/180.0*!dpi)
      xo = cosphi*xfo - sinphi*yfo
      yo = sinphi*xfo + cosphi*yfo
      xfo = xo
      yfo = yo

        ;; filter in fixed system between f1 and f2 (optional)
      if (abs(f1) le 1.e-6 && abs(f2-fnyq) le 1.e-6) then begin
        dprint, dlevel = 4,  'no need to apply filtering'
      endif else begin
;thm_scm_deconvo_vec will fail if there are not enough good data points
        good_data = where(finite(xfo+yfo+zfo), ngood)
        If(ngood Gt nk) Then Begin
          ;; deconvo w/o gain just does filtering:
          dprint, dlevel = 4,  'Applying filter in DSL system'

          if keyword_set(plotk) and batch eq 0 then begin
            my_plotk = 'step5_response.png'
          endif else my_plotk = ''
          
          thm_scm_deconvo_vec, xfo, nbp, nk, f1, f2, fe, '', $
            1, void, 0., blk_con = blk_con, $
            edge_t = edget, edge_w = edgew, edge_z = edgez, $
            plotk = my_plotk
          thm_scm_deconvo_vec, yfo, nbp, nk, f1, f2, fe, '', $
            2, void, 0., blk_con = blk_con, $
            edge_t = edget, edge_w = edgew, edge_z = edgez
          thm_scm_deconvo_vec, zfo, nbp, nk, f1, f2, fe, '', $
            3, void, 0., blk_con = blk_con, $
            edge_t = edget, edge_w = edgew, edge_z = edgez
        Endif Else Begin
          dprint, dlevel = 4,  'Deconvolution is not possible'
          dprint, dlevel = 4,  'Nbp = ', nbp
          dprint, dlevel = 4,  'Ngood = ', ngood
          dprint, dlevel = 4,  'NK = ', nk
          xfo[*] = !values.F_nan & yfo[*] = !values.F_nan & yfo[*] = !values.F_nan
        Endelse
      endelse

      coord_sys = 'dsl'

    endif

    if step ge 6 then begin
      dprint, dlevel = 4,  '-----------------------------------------------------'
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        'step 6: Calibrated data in DSL system [nT] with DC '+$
        strcompress(/remove_all, string(f1))+' '+$
        strcompress(/remove_all, string(f2))
      dprint, dlevel = 4,  'step 6: Calibrated data in DSL system [nT]'+$
        ' with DC', f1, f2

        ;if start_step gt 2 then begin
        ;   print, "*** Must start with step 2 in order to do step 6"
        ;endif else begin
      dprint, dlevel = 4,  "    Adding DC components of B in spin plane."
      xfo += bdcx
      yfo += bdcy
    endif

     ;; place data into output arrays, placing NaN in gap
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 ; Modification added in order to add a Nan only for the last batch
	 ; to be consistent with L2 data provided by jmm
    if batch eq n_batches-1 then begin

      time_scx_out[ind0+batch:ind1_ref+batch] = time_scx[ind0:ind1_ref]

      data_scx_out[ind0+batch:ind1_ref+batch, *] = data_scx[ind0:ind1_ref, *]

      out_scx[ind0+batch:ind1+batch, 0] = xfo
      out_scx[ind0+batch:ind1+batch, 1] = yfo
      out_scx[ind0+batch:ind1+batch, 2] = zfo

      iano_out[ind0+batch:ind1_ref+batch] = iano[ind0:ind1_ref]

    endif else begin
      time_scx_out[ind0+batch:ind1_ref+batch] = time_scx[ind0:ind1_ref]
      time_scx_out[ind1_ref+batch+1]          = time_scx[ind1_ref] + 1.0/fe

      data_scx_out[ind0+batch:ind1_ref+batch, *] = data_scx[ind0:ind1_ref, *]
      data_scx_out[ind1_ref+batch+1, *]          = !values.f_nan

      out_scx[ind0+batch:ind1+batch, 0] = xfo
      out_scx[ind0+batch:ind1+batch, 1] = yfo
      out_scx[ind0+batch:ind1+batch, 2] = zfo

      out_scx[ind1+batch+1:ind1_ref+batch+1, *] = !values.f_nan

      iano_out[ind0+batch:ind1_ref+batch] = iano[ind0:ind1_ref]
      iano_out[ind1_ref+batch+1]          = !values.f_nan
    endelse

    ind0 = ind1_ref+1L

  endfor

;------------------
; outputs to tplot
;------------------
  thx_scx_out = thx_scx+out_suff[0]

; diagnostic outputs:
  dprint, dlevel = 4,  'datatype = ', datatype
  dprint, dlevel = 4,  'mode = ', strlowcase(mode)
  if strfilter(datatype, strlowcase(mode)+'_misalign') ne '' then $
    store_data, thx_scx+'_misalign', data = {x:time_scx_out, y:out_scx_misalign}
  if strfilter(datatype, strlowcase(mode)+'_dc') ne '' then $
    store_data, thx_scx+'_dc', data = {x:time_scx_out, y:out_scx_dc}
  if strfilter(datatype, strlowcase(mode)+'_iano') ne '' then $
    store_data, thx_scx+'_iano', data = {x:time_scx_out, y:iano_out}
  

; store the calibrated output, along with metadata
  dl = dlim_scx
  str_element, dl, 'data_att', data_att, success = has_data_att

;; if nks is not defined, it means that a constant value was specified for nk
;; for the sake of printout, we are now free to set nks to nk
  if n_elements(nks) eq 0 then nks = nk

  str_Nk    = string(Nks, format = '(i6)')
  str_Despin = string(Despin, format = '(i1)')
  str_N_spinfit = string(N_spinfit, format = '(i1)')
  str_Fdet  = string(Fdet, format = '(f7.2)')
  str_Fcut  = string(Fcut, format = '(f6.2)')
  str_Fmin  = string(Fmin, format = '(f7.2)')
  str_Fmax  = string(Fmax, format = '(f7.2)')
  str_step  = string(step, format = '(i1)')
  str_Fsamp = string(Rates, format = '(f5.0)')
  ; CorADB = Correction applied for Antenna, Digital Filter, Butterworth Filter
  str_CorADB = string(gainant, dfb_dig, dfb_butter, format = '(3i1)')

  case cleanup of
    'none': str_cleanup_param = ', cleanup ('+clnup_author+')='+cleanup
    'spin': str_cleanup_param = ', cleanup ('+clnup_author+')='+cleanup+$
      ', 1st av. wind.='+str_wind_dur_sp
    'full': str_cleanup_param = ', cleanup ('+clnup_author+')='+cleanup+$
      ', 1st av. wind.='+str_wind_dur_sp+$
      ', 2nd av. wind.='+str_wind_dur_1s
  endcase

  str_param =  'Nk='+str_Nk[0]+ $
    ', Step='+str_step+' ,Despin='+str_Despin+$
    ', N_spinfit='+str_n_spinfit+ $
    str_cleanup_param+$
    ', Fdet='+str_Fdet+'Hz, Fcut='+str_Fcut+'Hz, Fmin=' $
    +str_Fmin+ 'Hz, Fmax='+str_Fmax+'Hz'+ ', CorADB='+str_CorADB
  
  if has_data_att then begin
    str_element, data_att, 'data_type', 'calibrated', /add
  endif else data_att = { data_type: 'calibrated' }
  str_element, data_att, 'coord_sys',  coord_sys, /add
  str_element, data_att, 'units', units, /add
  str_element, data_att, 'fsamp', Rates, /add
  str_element, data_att, 'nk', Nks, /add
  str_element, data_att, 'despin', Despin, /add
  str_element, data_att, 'n_spinfit', N_spinfit, /add
  str_element, data_att, 'cleanup_'+clnup_author, cleanup, /add
  if cleanup eq 'spin' then str_element, data_att, 'first_av_wind', wind_dur_sp, /add
  if cleanup eq 'full' then begin
    str_element, data_att, 'first_av_wind', wind_dur_sp, /add
    str_element, data_att, 'second_av_wind', wind_dur_1s, /add
  endif
  str_element, data_att, 'fdet', Fdet, /add
  str_element, data_att, 'fcut', Fcut, /add
  str_element, data_att, 'fmin', Fmin, /add
  str_element, data_att, 'fmax', Fmax, /add
  str_element, data_att, 'step', step, /add
  str_element, data_att, 'gainant', gainant, /add
  str_element, data_att, 'dfb_dig', dfb_dig, /add
  str_element, data_att, 'dfb_butter', dfb_butter, /add
  str_element, data_att, 'str_CorADB', str_CorADB, /add
  str_element, data_att, 'str_cal_param', str_param, /add
  str_element, dl, 'data_att', data_att, /add
  ;str_ytitle_original = strmid(tplot_var, 0, $
  ;  strpos(tplot_var, suffix, /reverse_search))
  str_element, dl, 'ytitle', string( 'th'+probe+' '+mode, str_Fsamp[0], units, format = '(A,"!C",A,"!C[",A,"]")'), /add
  str_element, dl, 'ysubtitle', /delete
  str_element, dl, 'labels', [ 'x', 'y', 'z'], /add
  str_element, dl, 'labflag', 1, /add
  str_element, dl, 'colors', [ 2, 4, 6], /add
  str_element, dl, 'color_table', 39, /add
  
  store_data, thx_scx_out, data = {x:time_scx_out, y:out_scx}, dl = dl

  if keyword_set(coord) then begin
    if step eq 6 && strlowcase(coord) ne 'dsl' then begin
      If(obj_valid(progobj)) Then progobj -> update, 0.0, text = $
        '*** Warning: for step 6 data can only be provided in DSL, coord keyword ignored'
      dprint,  '*** Warning: for step 6 data can only be provided in DSL, coord'
      dprint,  '    keyword ignored'
    endif else begin
      if step eq 0 then begin
        dprint,  '*** Warning: for step 0 data, no despinning has been performed, '
        dprint,  '    coord keyword is incompatible with sensor coord sys (SCS)'
      endif
      thm_cotrans, thx_scx_out, out_coord = coord, use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
      options, thx_scx_out, 'ytitle', 'th'+probe+'_'+mode, /def
      ccc  = strupcase(coord)
      get_data, thx_scx_out, dlimits = dl
      str_element, dl, 'ysubtitle', '[nT '+ccc[0]+']', /add
      store_data, thx_scx_out, dlimits = dl
;      options, thx_scx_out, 'ysubtitle', '[nT '+ccc[0]+']'
;      will not retain Upper case units
    endelse
  endif

end
