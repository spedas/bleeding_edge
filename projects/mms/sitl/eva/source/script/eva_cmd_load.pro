;+
; NAME:
;   EVA_CMD_LOAD
;
; PURPOSE:
;   This is a command-line script for loading a set of parameters for SITL and/or EVA.
;   By default, this program loads variables as configured in EVA's "SITL_BASIC_DAYSIDE"
;   parameterSet from the latest ROI timerange. Use keywords for selecting another
;   parameterSet or timerange.
;
; OUTPUT:
;   a variety of tplot-variables as configured in the specified parameter-Set.
;
; KEYWORDS:
;    PARAMSET: The name of your preferred parameter-set (as configured in EVA) 
;              If not specified, the default is "SITL_Basic_Dayside"
;    PROBES:   List of probes, valid values for MMS probes are ['1','2','3','4'].
;              If no probe is specified the default is probe '3' (as it is in EVA)
;    TRANGE:   time range of interest [starttime, endtime] with the format
;              ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;              ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss'] 
;    TIMESPAN: Set this keyword if you would like to use the 'timespan' command
;              before calling this program.
;    PARAMLIST: A named variable that, if supplied, contains the list of 
;               loaded tplot-variables.
;
; EXAMPLES:
;
;  1. To load "SITL_Quick" parameters for MMS3 from the latest ROI
;  
;     MMS> eva_cmd_load, paramset='SITL_Quick', probe='3'
;
;  2. To load "SITL_QUICK" parameters for MMS3 from the ROI of 2016 January 7.
;     Here, the 'mms_get_roi' command is used to get the exact time range of the ROI. 
;  
;     MMS> eva_cmd_load, paramset='SITL_Quick', probe='3', trange=mms_get_roi('2016-01-07')
;
;  3. Do the same thing as #2, but by using the 'timespan' command
;
;     MMS> timespan,'2016-01-07/20:40',13,/hours
;     MMS> eva_cmd_load, paramet='SITL_Quick', probe='3', /timespan
;        
; CREATED BY: Mitsuo Oka   Jan 2016
;
; $LastChangedBy: moka $
; $LastChangedDate: 2020-05-12 14:46:27 -0700 (Tue, 12 May 2020) $
; $LastChangedRevision: 28688 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_cmd_load.pro $
;-
PRO eva_cmd_load,paramset=paramset,probes=probes,trange=trange,timespan=timespan,$
  login_info=login_info,paramlist=paramlist,force=force
  compile_opt idl2
  mms_init
  t0 = systime(/sec) ;temporary
  widget_note = 'You must have a valid MMS/SITL account in order to use EVA.'
  connected = mms_login_lasp(username = username, widget_note = widget_note)
  if (connected eq 0) then return 
  
  ;----------------
  ; ParameterSet
  ;----------------  
  if undefined(paramset) then paramset='SITL_Basic'
  paramset_tmp = strsplit(paramset,'.',/extract)
  paramset = paramset_tmp[0]
  ; 'dir' produces the directory name with a path separator character that can be OS dependent.
  dir = file_search(ProgramRootDir(/twoup)+'parameterSets',/MARK_DIRECTORY,/FULLY_QUALIFY_PATH,/FOLD_CASE); directory
  paramFileList = file_search(dir,'*',/FULLY_QUALIFY_PATH,count=cmax,/FOLD_CASE); full path to the files
  if cmax gt 0 then begin
    idx = where(strmatch(paramFileList,'*'+paramset+'*',/FOLD_CASE),ct)
    if ct eq 1 then begin
      filename = paramFileList[idx[0]]
    endif else begin
      msg = 'WARNING: Multiple parameterSets found with the string *'+paramset+'*. Please be more specific.'
      if ct eq 0 then msg = paramset+' is not found.'
      print, msg
      jdx = where(strmatch(paramFileList,'*_SITL_Basic.txt'),ccc)
      if ccc eq 1 then begin
        filename = paramFileList[idx[0]]
      endif else begin
        return
      endelse 
    endelse
  endif else begin
    print, 'WARNING: No parameter in the specified parameterSet'
    return
  endelse
  result = read_ascii(filename,template=eva_data_template())
  paramlist = result.param
  if n_elements(paramlist) eq 0 then begin
    print,'WARNING: Selected parameterSet not available.'
    return
  endif
  
  ;----------------
  ; Probes
  ;----------------
  if undefined(probes) then probes = ['3']
  
  ;---------------------------------
  ; Timerange
  ;---------------------------------
  if ~undefined(trange) and ~undefined(timespan) then begin
    print,'WARNING: cannot use both the trange and timespan keywords.'
    return
  endif
  if undefined(trange) and undefined(timespan) then begin;..... Current ROI
    status = mms_login_lasp(login_info = login_info)
    if status ne 1 then begin
      print, 'Log-in failed'
      return
    endif
    get_latest_fom_from_soc, fom_file, error_flag, error_msg
    if error_flag then message,'FOMStr not found in SDC. Ask Super SITL.'
    restore,fom_file
    mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
    if n_tags(unix_FOMstr) gt 0 then begin
      s = unix_FOMstr
      start_time = time_string(s.timestamps[0],precision=3)
      dtlast = s.TIMESTAMPS[s.NUMCYCLES-1]-s.TIMESTAMPS[s.NUMCYCLES-2]
      end_time = time_string(s.TIMESTAMPS[s.NUMCYCLES-1]+dtlast,precision=3)
    endif else begin
      print, 'FOMStr not valid. Ask Super SITL.'
      return
    endelse
  endif else begin
    if ~undefined(trange) && n_elements(trange) eq 2 then begin;.... TRANGE keyword
      t = timerange(trange)
    endif else begin;.............. 'timespan'
      t = timerange()
    endelse
    start_time = time_string(t[0],precision=3)
    end_time = time_string(t[1],precision=3)
  endelse
  
  ;---------------------------------
  ; Input Structure
  ;---------------------------------
  state = {paramlist_mms: paramlist, $
           probelist_mms: 'mms'+probes, $
           start_time   : start_time,$
           end_time     : end_time }

  ;---------------------------------
  ; Main Program
  ;---------------------------------
  result = eva_data_load_mms(state,/no_gui,force=force)  
  
  
  if strmatch(result,'Yes') then begin
    paramlist = strlowcase(state.paramlist_mms)
    probelist = state.probelist_mms
    result = eva_data_load_reformat(paramlist, probelist,/FOURTH)
    idx=where(paramlist eq 'mms_sroi',ct)
    if(ct gt 0) then begin
      eva_sitl_sroi_bar,trange=trange,sc_id=probelist[0];,colors=colors
    endif
  endif
  
  dt = systime(/sec)-t0
  strdt = strtrim(dt)+' sec'
  if dt gt 120.d0 then begin
    strdt = strtrim(dt/60.d0)+' min'
  endif
  dprint, dlevel=2, 'Total load time: '+strdt
END
