;+
;NAME:
;thm_ui_load_data_fn
;PURPOSE:
;A widget interface to load CDF data for whatever instrument
;CALLING SEQUENCE:
;varnames = thm_ui_load_data_fn(st_time, en_time, $
;                              dtype = dtype, $
;                              station = station, $
;                              astation = astation, $
;                              probe = probe)
;INPUT:
;st_time, en_time = start and end times in seconds from
;                   1-jan-1970 0:00
;KEYWORDS:
;dtype, the type of data, a string, of form
;       'instrument/datatype/datalevel', the default is 'gmag/mag/l2'
;station, the ground station of the gmag data, default is '*', for all
;astation, the ground station of the asi data, default is '*', for all
;probe = one or more of ['a','b','c','d','e'], default is ['a','b','c','d','e']
;scm_cal = a structure containing calibration parameters
;OUTPUT:
;varnames = an array of tplot variable names, to pass into tplot
;HISTORY:
; 22-sep-2006, jmm, jimm@ssl.berkeley.edu
; 23-oct-2006, jmm, changed to call cdf2tplot
; 30-oct-2006, jmm, changed again, to call load_thg_mag, also added 
;                   dtype and station as inputs
; 13-nov-2006, jmm, changed the argument list, now the output is a
;                   data id string, added a check for start time > end
;                   time
; 08-dec-2006, krb, changed load_thg_mag to thm_load_gmag
; 13-dec-2006, jmm, Added call to cdf2tplot for data for which there
;                   is no load program...
; 14-dec-2006, jmm, returns an array of variable names and
;                   subscripts, which should be easier to read..
; 15-dec-2006, jmm, Added calls to thm_load_fgm, fit, sst, efi,
;                   ask,probe can be an array
; 16-jan-2007, jmm, Add all of the thm_load routines
; 5-feb-2007,  jmm, update calls to load routines
; 10-apr-2007, jmm, removed history tracking, which is now handled in
;                   thm_gui_event, also changed dtype, station
;                   astation and probe to keywords
; 1-may-2007,  jmm, New version, new argument list,etc....
; 10-may-2007, jmm, New version, new argument list,etc... that last
;                   one lasted a long time, didn't it
; 30-jul-2007, jmm, allow for string time input, this is needed to
;                   run histories.
; 11-apr-2008, jmm, Added 'spin' ipnput option
; 21-apr-2008, WMFeuerstein, Changed THM_LOAD_SCM call as per Vassilis'
;                   instructions.
; 30-may-2008, cg,  added optional keyword scm_cal to pass in calibration
;                   parameters
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-26 16:47:04 -0800 (Thu, 26 Jan 2012) $
;$LastChangedRevision: 9627 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_load_data_fn.pro $
;
;-
Function thm_ui_load_data_fn, st_time0, en_time0, $
                              dtype = dtype0, $
                              station = station0, $
                              astation = astation0, $
                              probe = probe0, $
                              progobj = progobj, $
                              _extra = _extra, $
                              scm_cal = scm_cal

  @tplot_com
  otp = -1
  data_ss = -1
  
  ;database
  thm_init                      ;this should work
  
  ;Check time range here
  st_time = time_double(st_time0) & en_time = time_double(en_time0)
  ttest0 = time_double('2004-07-23/00:00:00')
  ttest1 = systime(/sec)+365.0*86400.0d0 ;add a year
  If(st_time Lt ttest0 Or st_time Gt ttest1 Or $
     en_time Lt ttest0 Or en_time Gt ttest1) Then Begin
    If(obj_valid(progobj)) Then $
      progobj -> update, 0.0, text = 'Invalid Time Input, No Data Loaded'
    dprint, 'Invalid Time Input, No Data Loaded'
    Return, otp
  Endif
  If(en_time Le st_time) Then Begin
    If(obj_valid(progobj)) Then $
      progobj -> update, 0.0, text = 'Start time LT end time, No Data Loaded'
    dprint, 'Start time LT end time,  No Data Loaded'
    Return, otp
  Endif
  If(n_elements(dtype0) Eq 0) Then dtype = 'gmag/mag/l2' $
  Else dtype = strlowcase(strcompress(dtype0, /remove_all))
  ndtype = n_elements(dtype)
  
  ;get the instrument type datatype and dlevel
  instr = strarr(ndtype) & iname = instr & dlvl = instr
  For j = 0, ndtype-1 Do Begin
    ppp = strsplit(dtype[j], '/', /extract)
    instr[j] = ppp[0]
    iname[j] = ppp[1]
    dlvl[j] = ppp[2]
  Endfor
  If(n_elements(station0) Eq 0) Then station = '*' $
  Else station = strlowcase(strtrim(station0, 2))
  If(n_elements(astation0) Eq 0) Then astation = '*' $
  Else astation = strlowcase(strtrim(astation0, 2))
  If(n_elements(probe0) Eq 0) Then probe = ['a', 'b', 'c', 'd', 'e'] $
  Else probe = strlowcase(strtrim(probe0, 2))

  ;Get the info for the data that has been loaded already
  If(is_struct(data_quants)) Then Begin
    tx0 = time_string(data_quants.trange)
    didx0 = data_quants.name+':'+tx0[0, *]+' To '+tx0[1, *]
  Endif Else didx0 = -1

  ;people are inconsistent in using the trange keyword, so set a
  ;timespan...:
  tt = [st_time, en_time]
  t1 = str2time(strmid(time_string(tt[0]), 0, 10))
  t2 = str2time(strmid(time_string(tt[1]-1.), 0, 10))
  ndays = 1+fix((t2-t1)/(24.*3600.))
  timespan, t1, ndays

;GMAG
  ss = where(instr Eq 'gmag')
  If(ss[0] Ne -1) Then Begin
    thm_load_gmag, site = station, trange = [st_time, en_time], $
      progobj = progobj
  Endif
;ASI
  ss = where(instr Eq 'asi')
  If(ss[0] Ne -1) Then Begin
    thm_load_asi, site = astation, trange = [st_time, en_time], $
      datatype = iname[ss], progobj = progobj
  Endif
;ASK
  ss = where(instr Eq 'ask')
  If(ss[0] Ne -1) Then Begin
    thm_load_ask, site = astation, trange = [st_time, en_time], $
      datatype = iname[ss], progobj = progobj
  Endif
;EFI
  ss = where(instr Eq 'efi')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
    ;load state data, if not there
    For j = 0, n_elements(probe)-1 Do Begin
      thm_ui_check4spin, 'th'+probe[j]+'_efi_dummy', vx1, vx1, h1, $
        probe_in = probe[j], trange = [st_time, en_time], $
        progobj = progobj
    Endfor
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        thm_load_efi, probe = probe, datatype = iname[ss[ssj]], $
          level = lvls[j], /get_support_data, trange = [st_time, en_time], $
          progobj = progobj
      Endif
    Endfor
  Endif
;FBK
  ss = where(instr Eq 'fbk')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        thm_load_fbk, probe = probe, datatype = iname[ss[ssj]], $
          level = lvls[j], /get_support_data, trange = [st_time, en_time], $
          progobj = progobj
      Endif
    Endfor
  Endif
;FFT
  ss = where(instr Eq 'fft')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        thm_load_fft, probe = probe, datatype = iname[ss[ssj]], $
          level = lvls[j], /get_support_data, trange = [st_time, en_time], $
          progobj = progobj
      Endif
    Endfor
  Endif
;FGM
  ss = where(instr Eq 'fgm')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss])
    lvls = dlvl[ss[u_lev]]
    ;load state data, if not there, if loading level 1 data
    ss1 = where(lvls Eq 'l1', nl1)
    If(nl1 Gt 0) Then Begin
      For j = 0, n_elements(probe)-1 Do Begin
        thm_ui_check4spin, 'th'+probe[j]+'_fgm_dummy', vx1, vx1, h1, $
          probe_in = probe[j], trange = [st_time, en_time], $
          progobj = progobj
      Endfor
    Endif
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        ;thm_load_fgm needs to be fooled here into reading the appropriate
        ;data for L2
        If(lvls[j] Eq 'l2') Then iname_tmp = strmid(iname[ss[ssj]], 0, 3) $
        Else iname_tmp = iname[ss[ssj]]
        thm_load_fgm, probe = probe, datatype = iname_tmp, $
          level = lvls[j], /get_support_data, trange = [st_time, en_time], $
          progobj = progobj
      Endif
    Endfor
  Endif
;FIT
  ss = where(instr Eq 'fit')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        thm_load_fit, probe = probe, datatype = iname[ss[ssj]], $
          level = lvls[j], /get_support_data, trange = [st_time, en_time], $
          progobj = progobj
      Endif
    Endfor
  Endif
;SCM
  ss = where(instr Eq 'scm')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
;load state data, if not there
    For j = 0, n_elements(probe)-1 Do Begin
      thm_ui_check4spin, 'th'+probe[j]+'_scm_dummy', vx1, vx1, h1, $
        probe_in = probe[j], trange = [st_time, en_time], $
        progobj = progobj
    Endfor
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        ; check for keyword
        if keyword_set(scm_cal) then Begin 
          thm_load_scm,probe=probe,datatype=iname[ss[ssj]],level=lvls[j], $
             /get_support_data, trange= [st_time,en_time], $
             progobj = progobj, coord='dsl', cleanup='full', $
             type='calibrated', scm_cal = scm_cal
        endif else begin
          print, "********ERROR*********"
        endelse
      Endif
    Endfor
  Endif
;MOM
  ss = where(instr Eq 'mom')
  If(ss[0] Ne -1) Then Begin
    lvl_1 = where(dlvl[ss] Eq 'l1',  nl1)
    If(nl1 Gt 0) Then Begin
      ssj = where(dlvl[ss] Eq 'l1')
      thm_load_mom, probe = probe, datatype = iname[ss[ssj]], /raw, $
        level = 'l1', trange = [st_time, en_time], progobj = progobj
    Endif
    lvl_2 = where(dlvl[ss] Eq 'l2',  nl2)
    If(nl2 Gt 0) Then Begin
      ssj = where(dlvl[ss] Eq 'l2')
      thm_load_mom, probe = probe, datatype = iname[ss[ssj]], $
        level = 'l2', trange = [st_time, en_time], progobj = progobj
    Endif
;    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
;    For j = 0, n_elements(lvls)-1 Do Begin
;      ssj = where(dlvl[ss] Eq lvls[j])
;      If(ssj[0] Ne -1) Then Begin
;        thm_load_mom, probe = probe, datatype = iname[ss[ssj]], $
;          level = lvls[j], trange = [st_time, en_time], $
;          progobj = progobj
;      Endif
;    Endfor
  Endif
;SST
  ss = where(instr Eq 'sst')
  If(ss[0] Ne -1) Then Begin
    u_lev = uniq(dlvl[ss]) & lvls = dlvl[ss[u_lev]]
    For j = 0, n_elements(lvls)-1 Do Begin
      ssj = where(dlvl[ss] Eq lvls[j])
      If(ssj[0] Ne -1) Then Begin
        thm_load_sst, probe = probe, datatype = iname[ss], $
          level = lvls[j], trange = [st_time, en_time], $
          progobj = progobj, /get_support_data
      Endif
    Endfor
  Endif
;ESA
  ss = where(instr Eq 'esa')
  If(ss[0] Ne -1) Then Begin
    lvl_1 = where(dlvl[ss] Eq 'l1',  nl1)
    If(nl1 Gt 0) Then Begin
      app_id = iname[ss[lvl_1]]
      ddd = strcompress(/remove_all, app_id)
      thm_load_esa_pkt, probe = probe, datatype = ddd, $
        /get_support_data, trange = [st_time, en_time]
    Endif
    lvl_2 = where(dlvl[ss] Eq 'l2',  nl2)
    If(nl2 Gt 0) Then Begin
      thm_load_esa, probe = probe, datatype = iname[ss[lvl_2]], level = 'l2', $
        /get_support, trange = [st_time, en_time], progobj = progobj
    Endif
  Endif
;STATE
  state_ss = where(instr Eq 'state')
  If(state_ss[0] Ne -1) Then Begin
    thm_load_state, probe = probe, datatype = iname[state_ss], $
      /get_support_data, /no_spin, trange = [st_time, en_time], progobj = progobj
  Endif
;What are the new structure elements?
  If(is_struct(data_quants)) Then Begin
    ndq = n_elements(data_quants)
    If(ndq Gt 1) Then Begin
      If(is_string(didx0)) Then Begin
        tx = time_string(data_quants.trange)
        didx = data_quants.name+':'+tx[0, *]+' To '+tx[1, *]
        new_flag = bytarr(ndq)
        For j = 0, ndq-1 Do Begin
          fff = where(didx0 Eq didx[j], nfff)
          If(nfff Eq 0) Then new_flag[j] = 1
        Endfor
        data_ss = where(new_flag Eq 1)
      Endif Else data_ss = 1+lindgen(n_elements(data_quants)-1)
;Here restrict to the input time range
;    thm_ui_only_trange, st_time, en_time, data_ss
;Here get the tplot variable names
      If(data_ss[0] Ne -1) Then Begin
        tplotvars = tnames()
        otp = tplotvars[data_ss-1]
      Endif Else otp = -1
    Endif Else Begin
      data_ss = -1
      otp = -1
    Endelse
  Endif Else Begin
    data_ss = -1
    otp = -1
  Endelse
  Return, otp
End
