;+
;
;  Name: SPD_UI_LOAD_SPEDAS_ASCII
;  
;  Purpose: Loads data from a CDF chosen by user. Note that only CDFs that conform to SPEDAS standards can be opened. 
;  CDFs that do not conform may produce unhelpful error messages. 
;  
;  Inputs: 
;  info - The info structure from the main gui
;  ev - The event structure from the main gui
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
;$LastChangedRevision: 25538 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/load/ascii2tplot/spd_ui_load_spedas_ascii.pro $
;-
;pro spd_ui_load_spedas_ascii,info
pro spd_ui_load_spedas_ascii, info, ev
compile_opt idl2
  
  catch, Error_status
  if (Error_status NE 0) then begin
    statusmsg = !ERROR_STATE.MSG
    result=dialog_message('Error attempting to load ASCII. File may not conform to SPEDAS standards. See History for more details.', $
                            /INFO, /CENTER, TITLE='Load SPEDAS ASCII')
    info.historywin->Update,'Error attempting to load ASCII: '
    info.historywin->Update,statusmsg
    catch, /CANCEL
    return
  endif

  if (info.marking ne 0) || (info.rubberbanding ne 0) then begin
    return
  endif
  
  existing_tvar = tnames()
  info.ctrl = 0
 
;  fileName = dialog_pickfile(TITLE='Load SPEDAS ASCII', $
;    FILTER='*', DIALOG_PARENT=info.master, FILE=filestring, PATH=path, /MUST_EXIST, /FIX_FILTER)

  ret = spd_ui_load_spedas_ascii_sub(ev)
  
  if ret['success'] eq !FALSE then begin
    print, 'load SPEDAS ASCII is canceled'
    return
  endif
  
  fileName = ret['infile']
  format_type = ret['format_type']
  tformat = ret['tformat']
  tvar_column = ret['tvar_column']
  tvarnames = ret['tvarnames']
  delimiter = ret['delimiter']
  data_start = ret['data_start']
  comment_symbol = ret['comment_symbol']
  v_column = ret['v_column']
  vvec = ret['vvec']
  time_column = ret['time_column']
  input_time = ret['input_time']
  ;tplotgui_flg = ret['flag_tplot_Options']

  IF (is_string(fileName)) THEN BEGIN
    init_time=systime(/SEC)

  	;***** for test *****;
  	;tformat='YYYY-MM-DD hh:mm:ss.fff'
  	;delimiter=' '
  	;data_start=13
  	;tvar_column=[1, 2, 3, 4]
  	;tvarnames='kyumag_mag_asb_hdzf'
  	;********************;
  	
    ;ascii2tplot, files=fileName, format_type=0, tformat=tformat, $
    ascii2tplot, files=fileName, format_type=format_type, tformat=tformat, $
        tvar_column=tvar_column, tvarnames=tvarnames, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        v_column=v_column, vvec=vvec, $
        time_column=time_column, input_time=input_time
	;*****
  ;	cdf2tplot, file=fileName , get_support_data=1, all=1

    tplotvars = tnames(create_time=create_times)
    new_vars_ind = where(create_times gt init_time, n_new_vars_ind)
    
    if n_new_vars_ind gt 0 then begin
      ;print, 'stop'
      ;if tplotgui_flg then begin
        tplot_gui, tplotvars[new_vars_ind], /no_draw
      ;endif else begin
;        foreach elem, new_vars_ind do begin
;          spd_ui_tplot_gui_load_tvars, tplotvars[elem], NO_VERIFY=no_verify, $
;            OUT_NAMES=out_names, ALL_NAMES=all_names
;       
;          !SPEDAS.loadedData->SetDataInfo, $
;              tplotvars[elem], $
;              NEWNAME=tplotvars[elem],$
;              MISSION='Your_Data', $
;              OBSERVATORY='unknown', $
;              INSTRUMENT='unknown', $
;              UNITS='unknown', $
;              ST_TYPE='none',$
;              COORDINATE_SYSTEM='N/A', $
;              WINDOWSTORAGE=!SPEDAS.WINDOWSTORAGE, $
;              FAIL=fail
;        endforeach
     ; endelse
    
     ; delete any new tplot variables (but not ones that overwrote existing variables)
     if n_elements(existing_tvar) eq 1 then existing_tvar = [existing_tvar]
     if n_elements(tplotvars) eq 1 then tplotvars = [tplotvars]
     tvar_to_delete = ssl_set_complement(existing_tvar, tplotvars)
     store_data, delete=tvar_to_delete
    endif else begin
      statusmsg = 'Unable to load data from file '+fileName+'. File may not conform to SPEDAS standards.'
      result=dialog_message(statusmsg, $
                            /info,/center, title='Load SPEDAS ASCII')
      info.statusBar->Update, statusmsg
      info.historywin->Update,statusmsg
    endelse
  endif else begin
    info.statusBar->Update, 'Invalid Filename'
  endelse
  
end
