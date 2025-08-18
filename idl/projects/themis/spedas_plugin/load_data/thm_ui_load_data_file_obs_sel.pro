;+ 
;NAME:
; thm_ui_load_data_file_obs_sel.pro
;
;PURPOSE:
; Controls actions that occur when selecting items in probe/station box.  Called
; by thm_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; thm_ui_load_data_file_obs_sel, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-11-05 10:38:06 -0800 (Thu, 05 Nov 2015) $
;$LastChangedRevision: 19267 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_obs_sel.pro $
;-
pro thm_ui_load_data_file_obs_sel, state

  Compile_Opt idl2, hidden
  
  pindex = widget_info(state.observList, /list_select)
  if ~array_equal(pindex, -1, /no_typeconv) then begin
  
    all_chosen = where(pindex Eq 0, nall)
    if(nall gt 0) then observ0 = (*state.validobserv)[1:*] $
      else observ0 = (*state.validobserv)[pindex]
    if (ptr_valid(state.observ)) then ptr_free, state.observ
    state.observ = ptr_new(observ0)
    
;    state.statusText->Update, h
;    state.historyWin->Update, 'LOAD DATA: ' + h
    
    instr_in = state.instr
    
    if (instr_in eq 'asi' or instr_in eq 'ask') then begin
      if ptr_valid(state.astation) then ptr_free, state.astation
      state.astation = ptr_new(observ0)
    endif else if (instr_in eq 'gmag') then begin
      if ptr_valid(state.station) then ptr_free, state.station
      state.station = ptr_new(observ0)
    endif else begin
    
      if(nall gt 0) then observ0 = (*state.validobserv)[1:5] $ ; make sure that asterisk doesn't
        else observ0 = (*state.validobserv)[pindex]            ; select flatsat probe
      if (ptr_valid(state.observ)) then ptr_free, state.observ
      state.observ = ptr_new(observ0)
      if ptr_valid(state.probe) then ptr_free, state.probe
      state.probe = ptr_new(observ0)
    end

    message_pre = 'Chosen '+state.observ_label
    h = spd_ui_multichoice_history(message_pre, observ0)
    ; Some old data from the DMI/DTU network is uncalibrated. Issue a warning if the user has selected such a site.
    ; lphilpott 2-mar-2012
    ; Expanding this warning to include all DTU and TGO sites. May be revised at later date when more is known about the
    ; data format, or format is changed.
    if(state.instr eq 'gmag') then begin
     ;uncal_site =['amk','atu','dmh','dnb','gdh','kuv','naq','nrd','sco','skt','svs','thl','umq','upn']
     uncal_site = ['amk','and','atu','bfe','bjn','dob','dmh','dnb','don','fhb','gdh','ghb','hop','jck','kar','kuv','lyr','nal','naq','nor','nrd','roe','rvk','sco','skt','sol','sor','stf','svs','tdc','thl','tro','umq','upn']
     matching_sites = strfilter(observ0,uncal_site, count=count)
     if(count gt 0) then begin
      h = h+ ' Warning: some data may be uncalibrated.'
     endif
     matching_all = strfilter(observ0,'* (All)', count=count)
     if count gt 0 then begin 
       thm_load_gmag_networks, gmag_networks=gmag_networks, gmag_stations=gmag_stations
     endif else begin
       thm_load_gmag_networks, gmag_networks=gmag_networks, gmag_stations=gmag_stations, selected_network=observ0 
     endelse
     dlist1 = ['* (All)', gmag_stations]
     state.dlist1 = ptr_new(dlist1)
     widget_control,state.level1List, set_value=dlist1
     
    endif
 
  endif else begin
  
    If(state.instr Eq 'asi' Or state.instr Eq 'ask') Then Begin
      If(ptr_valid(state.astation)) Then ptr_free, state.astation
      h = 'No Chosen Asi_station'
      state.statusText->Update, h
    Endif Else If(state.instr Eq 'gmag') Then Begin
     ; If(ptr_valid(state.station)) Then ptr_free, state.station
     ; h = 'No Chosen Gmag_station'
     ; state.statusText->Update, h
    Endif Else Begin
      If(ptr_valid(state.probe)) Then ptr_free, state.probe      
      ;h = 'probe = '+''''+''''
      h = 'No Chosen Probe'
      state.statusText->Update, h
    Endelse
    widget_control,state.observlist, set_value=*state.validobservlist
    return
  endelse

  state.statusText->Update, h
  state.historyWin->Update, 'LOAD DATA: ' + h
  
END
