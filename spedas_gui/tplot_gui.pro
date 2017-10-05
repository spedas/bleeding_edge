;+ 
;NAME:  
;  tplot_gui
;  
;PURPOSE:
;  Imports and creates plot of tplot variable in SPD_GUI.
;  
;CALLING SEQUENCE:
;  tplot_gui, [datanames]
;  
;INPUT:
;  datanames: A string of space separated datanames.  Wildcard expansion is
;             supported.  If datanames is not supplied then the last values are
;             used. Each name should be associated with a data quantity.
;             (see the "STORE_DATA" and "GET_DATA" routines.) Alternatively 
;             datanames can be an array of integers or strings.  Run
;             "TPLOT_NAMES" to show the current numbering.
;          
;            
;            
;KEYWORDS:
;  /NO_VERIFY: Bypasses the Verify window before plotting the data in the GUI.
;              Intended to be used in cases when it is certain that the limits
;              and dlimits of the incoming tplot variables are complete and
;              correct (e.g. overview plot generation).  Use with caution.
;  /NO_DRAW: Data is loaded, but it is not plotted.
;  /no_update: data is loaded and added to plot, but update is not called.
;    (saves runtime when building up a plot from several calls)
;  /RESET: Sets the Reset keyword on SPD_GUI if gui is not already open. If
;          set, it will reset all internal gui settings. Otherwise, it will try
;          to load the state of the previous gui call.
;  /add_panel:  Adds data as a new panel in the current display
;  /overplot: alias for add_panel.   
;  template_filename : The file name of a previously saved spedas template document,
;                   can be used to store user preferences and defaults.
;  VAR_LABELS:  String [array]; Variable(s) used for putting labels along
;     the bottom. This allows quantities such as altitude to be labeled.  
;  TRANGE:   Time range for tplot. Two element array, can be string or double(time in unleaped seconds since 1970)
;            If this parameter is set current timespan will be ignored   
;        
;OUTPUT:
;  none
;  
;NOTES:
;  tplot_gui supports many of the same settings that are selected in tplot using options and tplot_options. 
;  
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-10-20 14:50:42 -0700 (Thu, 20 Oct 2016) $
;$LastChangedRevision: 22172 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/tplot_gui.pro $
;--------------------------------------------------------------------------------

pro spd_ui_tplot_gui_make_plots, newpanel, varname,template

  compile_opt idl2, hidden
    
  ; get group object and x-axis data quantity name
  group = !spedas.loadedData->getGroup(varname)
  
  if ~obj_valid(group) then return
  
  xname = group->getTimeName()
  
  ; get dlimits/limits and merge into superstructure
 
  !spedas.loadedData->getDataInfo,varname,limit=l,dlimit=dl
  extract_tags,dl,l

  if (size(dl, /type) eq 8) then begin
    if in_set('spec', strlowcase(tag_names(dl))) && dl.spec eq 1 then begin  ; create specplot
      
        groupname = group->getName()
        yname = group->getYaxisName()
        
        spd_ui_make_default_specplot, !spedas.loadedData, newpanel, xname,  $
                                      yname, groupname, template
      
    endif else begin    ; create lineplot
      
        ynames = group->getDataNames()
        
        for j=0, n_elements(ynames)-1 do begin
        
          spd_ui_make_default_lineplot, !spedas.loadedData, newpanel, xname, $
                                        ynames[j], template
        endfor
    endelse
  endif else begin   ; create lineplot
  
    ynames = group->getDataNames()
    
    for j=0, n_elements(ynames)-1 do begin
    
      spd_ui_make_default_lineplot, !spedas.loadedData, newpanel, xname, $
                                    ynames[j],template
    endfor
  endelse

end

pro tplot_gui, datanames,$
               no_verify=no_verify,$ 
               no_draw=no_draw,$
               no_update=no_update,$
               reset=reset,$
               add_panel=add_panel,$
               overplot=overplot,$
               template_filename=template_filename,$
               var_labels=var_label,$
               import_only=import_only,$
               trange=trange

  compile_opt idl2
  
  ; check type and dimension of input
  dt = size(/type,datanames)
  ndim = size(/n_dimen,datanames)
  
  ; check for valid input
  if dt ne 0 then begin
   if dt ne 7 or ndim ge 1 then dnames = strjoin(tnames(datanames,/all),' ') $
     else dnames=datanames
  endif else begin
    last_tplot = tnames(/tplot)
    dprint,'Recreating the last tplot command with the following tplot variables:'
    dprint, last_tplot
    dnames = strjoin(last_tplot,' ')
  endelse
   
  defsysv,'!spedas',exists=spd_exists ;check if prexisting gui
  
  if keyword_set(reset) || keyword_set(add_panel) || keyword_set(overplot) || ~spd_exists then begin
    newwin = 0
  endif else begin
    newwin = 1
  endelse
  
  ; check if gui already running, start if not
  if (xregistered('spd_gui') eq 0) then begin
    spd_gui, reset=reset,template_filename=template_filename
  endif else if keyword_set(reset) then begin
    widget_control,!spedas.GUIID,/destroy
    spd_gui, reset=reset,template_filename=template_filename
  endif else begin
  
    ;read template from file, if requested
    if keyword_set(template_filename) then begin
      open_spedas_template,template=template,filename=template_filename,$
        statusmsg=statusmsg,statuscode=statuscode
      if statuscode lt 0 then begin
        ok = dialog_message(statusmsg,/error,/center)
      endif else begin
        !spedas.windowstorage->setProperty,template=template
      endelse
    endif
    
  endelse
  
  !spedas.windowStorage->getProperty,template=template

 
  spd_ui_tplot_gui_load_tvars,dnames,no_verify=no_verify,out_names=out_names,all_names=all_names
 
  if n_elements(out_names) eq 0 then begin
  
    ;add buffer panel (keeps overview plots aligned)
    if keyword_set(add_panel) then begin
      spd_ui_make_default_panel, !spedas.windowStorage, template
    endif
    
    dprint,"No valid input names"
    return
    
  endif else begin 
    var_num = csvector(out_names,/l)
  endelse
 
  tplot_options,get_opt=opts
  str_element,opts,'var_label',opts_vars,success=s
  
  if n_elements(var_label) gt 0 then begin
    var_list = var_label
  endif else if s then begin
    var_list = opts_vars
  endif
  
  if n_elements(var_list) gt 0 then begin
    spd_ui_tplot_gui_load_tvars,var_list,no_verify=no_verify,out_names=out_varnames,all_names=all_varnames
    all_names = array_concat(all_names,all_varnames)
  endif 

  if n_elements(all_names) eq 0 then begin
    dprint,"No valid names"
    return
  endif  
  
  ;remove any duplicate names before verification
  all_names = all_names[uniq(all_names,sort(all_names))]

  ; verify incoming tplot variables
  ;spd_ui_verify_data,!spedas.guiId, varnames, !spedas.loadedData, $
  ;                   !spedas.windowStorage, !spedas.historywin, $
  ;                   success=success
  if ~keyword_set(no_verify) then begin
  
    dprint,'verify data for main plots'
    spd_ui_verify_data,!spedas.guiId, all_names, !spedas.loadedData, $
                       !spedas.windowStorage, !spedas.historywin, $
                       success=success,newnames=new_names
  
    if ~success then begin
      dprint,'Data verify canceled.'
      !spedas.historyWin->update,'Data verify canceled.'
      return
    endif
  
  endif else begin
    new_names=all_names
  endelse

  if ~keyword_set(no_draw) && ~keyword_set(import_only) then begin

    ;note it is important that pagesettings gets set one way or another by this block

    ; add new window to gui
    if newwin then begin
            
      if ~!spedas.windowStorage->add(isactive=1) then begin
        ok = error_message('Error initializing new window for TPLOT_GUI.',/traceback, /center, $
               title='Error in TPLOT_GUI')
        return
      endif  
    
    activeWindow = !spedas.windowStorage->GetActive()
    
    ; add window name to gui window menu
    activeWindow[0]->GetProperty, Name=name,settings=pagesettings
    spd_ui_tplot_gui_page_options,pagesettings
    !spedas.windowMenus->Add, name
    !spedas.windowMenus->Update, !spedas.windowStorage
      
     ; update draw object and draw new window
 ;    !spedas.drawObject->Update, !spedas.windowStorage, !spedas.loadedData
 ;   !spedas.drawObject->draw
    
    endif else begin
      activeWindow = !spedas.windowStorage->GetActive()
      ; add window name to gui window menu
      if ~obj_valid(activeWindow) then begin
        ok = error_message('Error, tplot_gui /add_panel called with no active window',/traceback, /center, $
          title='Error in TPLOT_GUI')
        return
      endif else begin
        activeWindow[0]->GetProperty,settings=pagesettings
        spd_ui_tplot_gui_page_options,pagesettings
      endelse
    endelse
    
;    if keyword_set(trange) && n_elements(trange) eq 2 then begin
;      ctrange = time_double(trange)
;    endif else begin
;      ;get current time range (as set by tlimit)
;      ctrange = timerange(/current)
;    endelse
    
    sub_idx = 0
     
    ; create a separate panel for each data quantity
    for i=0L, var_num-1 do begin
    
      ; create panel
      spd_ui_make_default_panel, !spedas.windowStorage, template,outpanel=newpanel
  
      add_names = csvector(i,out_names,/read)
     
      for j = 0,n_elements(add_names)-1 do begin
       idx = where(add_names[j] eq all_names,c)
       if c ne 1 then begin
         dprint,"Unexpected error detected"
         return
       endif
      
       spd_ui_tplot_gui_make_plots, newpanel, new_names[idx[0]],template
      endfor
      
      spd_ui_tplot_gui_panel_options,newpanel,varnames=add_names,allnames=all_names,newnames=new_names,trange=trange
      
    endfor
    
    spd_ui_tplot_gui_make_var_labels,newpanel,pagesettings,varnames=out_varnames,allnames=all_names,newnames=new_names
        
    if ~keyword_set(no_update) then begin
      !spedas.drawObject->update,!spedas.windowStorage, !spedas.loadedData
      !spedas.drawObject->draw
    endif
    
  endif

end
