;+
;NAME: PSP_FLD_QF_FILTER
;
;DESCRIPTION:
; Removed flagged values from PSP FIELDS magnetometer tplot variables based 
; on selected quality flags.  See usage notes and available flag definitions 
; by calling with the /HELP keyword.
;
; For each TVAR passed in a new tplot variable is created with the filtered 
; data.  The new name is of the form:  <tvarname>_XXXXXX 
; where each 'XXX' is a 0 padded flag indicator sorted from lowest to highest.
; 
; So, psp_fld_qf_filter,'mag_RTN_1min_x',[4,16] results in tvar named "mag_RTN_1min_x_004016"
; Or, psp_fld_qf_filter,'mag_RTN_1min',0 results in tvar named "mag_RTN_1min_000"
; 
; Valid for variables of type:
;    '...psp_fld_l2_mag_...' (full res, 1 minute, or 4 Sa per cycle)
;    '...psp_fld_l2_rfs_...' (lfr and hfr) 
;  
;INPUT:
; TVARS:    (string/strarr) Elements are data handle names
;             OR (int/intarr) tplot variable reference numbers
; DQFLAG:   (int/intarr) Elements indicate which of the data quality flags
;             to filter on. From the set {0,1,2,4,8,16,32,64,128}   
;             Note: if using 0 or -1, no other flags should be selected for filter
;             -1: Keep cases with no set flags or only the 128 flag set 
;             0: No set flags. (default)
;             1: FIELDS antenna bias sweep
;             2: PSP thruster firing
;             4: SCM Calibration
;             8: PSP rotations for MAG calibration (MAG rolls)
;             16: FIELDS MAG calibration sequence
;             32: SWEAP SPC in electron mode
;             64: PSP Solar limb sensor (SLS) test
;             128: PSP spacecraft is off umbra pointing     
;
;KEYWORDS:
; HELP:   If set, print a listing of the available data quality flags and 
;         their meaning.
; VERBOSE:     Integer indicating the desired verbosity level. Default = 2
; 
;OUTPUTS:
; NAMES_OUT:  Named variable holding the tplot variable names created 
;             from this filter. Order corresponds to the input array of tvar
;             names, so that tvar[i] filtered is in names_out[i]
;
;EXAMPLE:
;   psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',0
;   psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',[16,32]
;   
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2021-01-29 11:52:15 -0800 (Fri, 29 Jan 2021) $
; $LastChangedRevision: 29636 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/misc/psp_fld_qf_filter.pro $
;-

pro psp_fld_qf_filter, tvars, dqflag,HELP=help, NAMES_OUT=names_out, $
                        verbose=verbose
                       
  compile_opt idl2

  names_out = []
  
  ; Handle HELP option
  @psp_fld_common
  if keyword_set(help) then begin
    print,mag_dqf_infostring,format='(A)'
    return
  endif
  
  ; Argument checking
  if n_params() eq 0 then begin
    dprint, dlevel=1, verbose=verbose, "Must supply a tplot variable"
    return
  endif
  if ~isa(verbose, 'INT') then verbose = 2
  if isa(dqflag, 'UNDEFINED') then dqflag = 0 else $
  if ~isa(dqflag, /INT) then begin
    dprint, dlevel=1, verbose=verbose, "DQFLAG must be INT or INT ARRAY"
    return
  endif

  foreach flg,dqflag do begin
    r = where([0,1,2,4,8,16,32,64,128,-1] eq flg, count)
    if count eq 0 then begin
      msg = ["Bad DQFLAG value ("+flg.ToString()+").", $
            "Must be in the set{0,1,2,4,8,16,32,64,128,-1}"]
      dprint, dlevel=1, verbose=verbose, msg, format='(A)'
      return
    endif
  endforeach

  if n_elements(dqflag) eq 1 then dqflag = dqflag[0]

  if isa(dqflag, /ARRAY) then begin
    r = where(dqflag eq 0, count)
    if count gt 0 then begin
      dprint, dlevel=1, verbose=verbose, "DQFLAG of 0 must be set by itself"
      return
    endif
    
    r = where(dqflag eq -1, count)
    if count gt 0 then begin
      dprint, dlevel=1, verbose=verbose, "DQFLAG of -1 must be set by itself"
      return
    endif
    
    dqflag = dqflag[sort(dqflag)]
  endif

  ; Create time specific quality flags as needed
  tn = tnames(tvars)
  r = where((tn.Matches('rfs_[lh]fr')) or $
        (tn.Matches('(mag_RTN|mag_SC)') and $
        not tn.Matches('(_zero|_MET|_range|_mode|_rate|_packet_index)')), count)
  if count ge 1 then begin
    valid_tn = tn[r]
    qf_target = []
    err_flg = []
    keep = []
    leave = []
    foreach tvar, valid_tn, i do begin
      get_data, tvar, data = d, dlimit = dl
      if tag_exist(dl,'qf_root') then begin
        keep = [keep, i]
        qf_root = dl.qf_root

        if tvar.Matches('rfs_[lh]fr') then begin
          ; Lots of possible epoch tags for the rfs data
          tag = '_' + dl.cdf.vatt.depend_0
        endif else if tvar.Matches('_1min') then tag = '_1min' $
        else if tvar.Matches('_4_Sa_per_Cyc') then tag = '_4_per_cycle' $
        else tag = '_hires'

        make_qf_var = !false
        tn_qf = tnames(qf_root+tag)
        if tn_qf eq '' then begin ; It doesn't already exist
          make_qf_var = !true
        endif else begin ; It exists. Is it the correct timerange?
          get_data, tn_qf, data=dqf
          if (dqf.x[0] ne d.x[0]) or (dqf.x[-1] ne d.x[-1]) then begin
            make_qf_var = !true
          endif
        endelse

        if make_qf_var then begin
          psp_fld_extend_epoch, qf_root, d.x, tag, err = err
          err_flg = [err_flg, err]
        endif else err_flg = [err_flg, 0]

        qf_target = [qf_target, qf_root+tag]        
      endif else leave = [leave, i]
    endforeach
  endif else begin
    print,"No valid variables for filtering
    return
  endelse

  ; Remove cases where no valid qf_root variable was set
  if n_elements(leave) gt 0 then begin
    dprint,dlevel=2,"Source quality flags missing. No filtered variabled created for: "
    dprint,dlevel=2,valid_tn[leave]
    dprint,dlevel=2,""
  endif
  valid_tn = valid_tn[keep]

  ; Remove cases where extend epoch could not work
  r = where(err_flg eq 0, /NULL, COMPLEMENT=rc)
  if n_elements(rc) gt 0 then begin
    dprint,dlevel=2,"Error creating matching time quality flags."
    dprint,dlevel=2,"No filtered variabled created for: ", valid_tn[rc]
    dprint,dlevel=2,""
  endif
    
  valid_tn = valid_tn[r]
  qf_target = qf_target[r]
  if n_elements(valid_tn) eq 0 then begin
    print,"No valid variables for filtering\n"
    return    
  endif
  
  ; Retrieve DQF array and flagged bits      
  ; 
  ;FIELDS quality flags. This is a bitwise variable, meaning that multiple flags
  ;can be set for a single time, by adding flag values. Current flagged values
  ;are: 1: FIELDS antenna bias sweep, 2: PSP thruster firing,
  ;4: SCM Calibration, 8: PSP rotations for MAG calibration (MAG rolls),
  ;16: FIELDS MAG calibration sequence, 32: SWEAP SPC in electron mode,
  ;64: PSP Solar limb sensor (SLS) test. 128: PSP spacecraft is off umbra
  ;pointing. A value of zero corresponds to no set flags.
  ;Not all flags are relevant to all FIELDS data products, refer to notes in the
  ;CDF metadata and on the FIELDS SOC website for information on how the various
  ;flags impact FIELDS data. Additional flagged items may be added in the future. 
  
  qfmap = hash(qf_target)
  foreach key,qfmap.keys() do begin
    qfmap[key] = hash(['dqf','dqfbits'])
    get_data,key,data=d
    bits2, d.y, dbits       
    qfmap[key, 'dqf'] = d.y
    qfmap[key, 'dqfbits'] = dbits
  endforeach  
  
  ; Handle -1 case (0 and 128) and return
  if isa(dqflag, /SCALAR) && (dqflag eq -1) then begin
    suffix = '_0-1'
    for i=0,valid_tn.length - 1 do begin
      dqf = qfmap[qf_target[i],'dqf']
      rgood = where((dqf eq 0) OR (dqf eq 128), /NULL, COMPLEMENT=r)
      get_data,valid_tn[i],data=d, dl=dl, l=l
      d.y[r,*] = !values.f_NAN
      if tag_exist(dl, 'ytitle',/quiet) then begin
        dl.ytitle = dl.ytitle +"!Cfilter"+suffix
      endif
      if tag_exist(l, 'ytitle',/quiet) then begin
        l.ytitle = l.ytitle +"!Cfilter"+suffix
      endif
      store_data,tnames(valid_tn[i])+suffix,data=d,dl=dl,l=l
      names_out = [names_out, tnames(valid_tn[i])+suffix]
    endfor
    return
  endif 


  ;handle case 0 and return
  if isa(dqflag, /SCALAR) && (dqflag eq 0) then begin
    suffix = '_000'
    for i=0,valid_tn.length - 1 do begin
      dqf = qfmap[qf_target[i],'dqf']
      rgood = where((dqf eq 0) , /NULL, COMPLEMENT=r)
      get_data,valid_tn[i],data=d, dl=dl, lim=l
      d.y[r,*] = !values.f_NAN
      if tag_exist(dl, 'ytitle',/quiet) then begin
        dl.ytitle = dl.ytitle +"!Cfilter"+suffix
      endif
      if tag_exist(l, 'ytitle',/quiet) then begin
        l.ytitle = l.ytitle +"!Cfilter"+suffix
      endif
      store_data,tnames(valid_tn[i])+suffix, data=d, dl=dl, lim=l
      names_out = [names_out, tnames(valid_tn[i])+suffix]
    endfor
    return
  endif 

  ; If not asking for 0 or -1, Find index of elements to remove based on DQFLAGS
  suffix = '_'
  bits2,0,mybits
  foreach flg,dqflag do begin
    suffix+= flg.ToString('(I03)')
    bits2,flg,flgbits
    mybits = mybits + flgbits
  endforeach
  for i=0,valid_tn.length - 1 do begin
    dqfbits = qfmap[qf_target[i],'dqfbits']
    dqf = qfmap[qf_target[i],'dqf']
    
    rem_mask = replicate(0, dqf.length)
    for j=0,mybits.length-1 do begin
      if mybits[i] eq 1 then begin
        r = where(dqfbits[i,*] eq 1, /NULL)
        rem_mask[r] = 1
      endif
    endfor
    rem_idx = where(rem_mask eq 1, /NULL)

    get_data,valid_tn[i],data=d, dl=dl, l=l
    d.y[rem_idx,*] = !values.f_NAN
    if tag_exist(dl, 'ytitle',/quiet) then begin
      dl.ytitle = dl.ytitle +"!Cfilter"+suffix
    endif
    if tag_exist(l, 'ytitle',/quiet) then begin
      l.ytitle = l.ytitle +"!Cfilter"+suffix
    endif
    str_element,dl,'qf_root',/DELETE
    store_data,tnames(valid_tn[i])+suffix, data=d, dl=dl, l=l
    names_out = [names_out, tnames(valid_tn[i])+suffix]    
  endfor  

end
