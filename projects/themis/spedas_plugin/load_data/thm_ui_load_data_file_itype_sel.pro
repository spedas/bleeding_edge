;+ 
;NAME:
; thm_ui_load_data_file_itype_sel.pro
;
;PURPOSE:
; Controls actions that occur when Instrument Type menu is selected.  Called by
; thm_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; thm_ui_load_data_file_itype_sel, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2021-04-02 10:57:42 -0700 (Fri, 02 Apr 2021) $
;$LastChangedRevision: 29845 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_itype_sel.pro $
;-
pro thm_ui_load_data_file_itype_sel, state, from_coord_sel=from_coord_sel

  Compile_Opt idl2, hidden
  
  ; Get current instrument type from the data selection combobox
  instr_in = widget_info(state.itypeDroplist, /combobox_gettext)
  state.instr = strlowcase(strcompress(instr_in, /remove_all))
 
  ; handle different coordinate system abilities of load routines 
;  if (state.instr eq 'fgm') OR (state.instr eq 'scm') then begin
;    if ptr_valid(state.validcoords) then ptr_free, state.validcoords
;    validcoords = [ ' DSL ', ' GSM ', ' SSL ',' GSE ']
;    state.validcoords = ptr_new(validcoords)
;  endif else if (state.instr eq 'fit') OR (state.instr eq 'esa') then begin
;      if ptr_valid(state.validcoords) then ptr_free, state.validcoords
;      validcoords = [ ' DSL ', ' GSM ', ' GSE ']
;      state.validcoords = ptr_new(validcoords)
;  endif else begin
;      if ptr_valid(state.validcoords) then ptr_free, state.validcoords
;      validCoords = [ ' DSL ', ' GSM ', ' SPG  ', ' SSL ',' GSE ', ' GEI ',' SM ', ' SSE ', ' SEL ', ' GEO', ' MAG ']
;      state.validcoords = ptr_new(validcoords)
;  endelse
  
  ; make a list of valid coordinate systems 
  coord_sys_obj = obj_new('thm_ui_coordinate_systems')
  validCoords = coord_sys_obj->makeCoordSysList(/uppercase, instrument = state.instr)
  if ptr_valid(state.validcoords) then ptr_free, state.validcoords
  state.validcoords = ptr_new(validCoords)
  obj_destroy, coord_sys_obj


  ;determine whether to sensitize the raw button
  raw_id = widget_info(state.tab_id,find_by_uname='raw_data')
  if state.instr eq 'efi' || $
     state.instr eq 'fbk' || $
     state.instr eq 'fgm' || $
     state.instr eq 'mom'  then begin
     widget_control,raw_id,sensitive=1
  endif else begin
     widget_control,raw_id,sensitive=0
  endelse
  
  ;determine whether to sensitize the eclipse correction button
  eclipse_id = widget_info(state.tab_id,find_by_uname='eclipse')
  if state.instr eq 'esa' || $
     state.instr eq 'sst' || $
     state.instr eq 'fit' || $
     state.instr eq 'fgm' || $ 
     state.instr eq 'efi' || $
     state.instr eq 'scm' || $
     state.instr eq 'mom' then begin
     widget_control,eclipse_id,sensitive=1
  endif else begin
     widget_control,eclipse_id,sensitive=0
  endelse

  ; select output coords based on instrument
  if ~keyword_set(from_coord_sel) then begin

    if state.instr eq 'state' then begin
      new_coord = 'gei'
    endif else begin
      new_coord = 'dsl'
    endelse

    ;get combobox list so we can do this dynamically
    widget_control, state.coorddroplist, get_value=coord_list
    coord_match = where(new_coord eq strlowcase(coord_list), nc) 

    ;if the correct coord system was not found then it should be fixed
    if nc ne 1 then begin
      message, 'Could not determined default coordinate system for selected instrument: '+state.instr
    endif

    widget_control, state.coorddroplist, set_combobox_select=coord_match

  endif
  
  ; get output coordinates
  outCoord = widget_info(state.coordDroplist, /combobox_gettext)
  state.outCoord = strlowcase(strcompress(outCoord, /remove_all))

  if ~keyword_set(from_coord_sel) then begin
    if(ptr_valid(state.dtyp)) then ptr_free, state.dtyp
    if(ptr_valid(state.dtyp_pre)) then ptr_free, state.dtyp_pre
    state.dtyp_pre = ptr_new('')
  endif
 
  ; Get a list of data types that can be loaded for each instrument.
  dlist = thm_ui_valid_datatype(state.instr, ilist, llist)
  
  ; temporarily remove the "all processors" variables until data object can handle 3D data
  ; 2011-01-24 JWL  When the new FFF datatype was added, the number of
  ; ignored ("all FFT processors in one variable") data types at the head of 
  ; the list went from 6 (FFW,FFP) X (16,32,64) to 9 (FFW,FFP,FFF) X (16,32,64).
  ; The effect is that the 64-bin variables were not weeded out of the
  ; list of variables to avoid importing into the GUI, so users saw
  ; warning messages about "too many dimensions".
  
  if array_equal(state.instr, 'fft') then begin
    dlist = dlist[9:n_elements(dlist)-1]
    llist = llist[9:n_elements(llist)-1]
    ilist = ilist[9:n_elements(ilist)-1]
  endif
  
  dlist2_orig = *state.dlist2
  
  ; clear observatories, L1 and L2 datatype selections
  if ~keyword_set(from_coord_sel) then begin
    if(ptr_valid(state.dtyp1)) then ptr_free, state.dtyp1
    state.dtyp1 = ptr_new('')
    if(ptr_valid(state.dtyp2)) then ptr_free, state.dtyp2
    state.dtyp2 = ptr_new('')
    if(ptr_valid(state.observ)) then ptr_free, state.observ
    state.observ = ptr_new('')
    state.statusText->Update,'No Chosen data types or observatories'
  endif
  
  level1Label = widget_info(state.tab_id,find_by_uname='level1Label')
  widget_control, level1Label, set_value="Level 1:"
  
  CASE 1 OF 
      ; Spacecraft/probe data selected
      (state.instr ne 'ask' and $
       state.instr ne 'gmag' and $
       state.instr ne 'asi'): begin 
          
          state.observ_label = state.observ_labels[2]+':'
          validobserv = state.probes
          validobservlist = state.validProbes
          
          ; check for level 1 data
          xx1 = where(llist Eq 'l1', nxx1)
          If(nxx1 Gt 0) Then Begin
              dlist1_all = ['*', dlist[xx1]] 
              If(state.instr Eq 'fbk') Then Begin
                  dlist1_all = ['*', 'fb1', 'fb2', 'fbh']
              Endif
              If(state.instr Eq 'gmom') Then Begin
                dlist1_all = ['None']
              Endif
          Endif Else dlist1_all = 'None'
          
          ; check for level 2 data
          xx2 = where(llist Eq 'l2', nxx2)
          If(nxx2 Gt 0) Then Begin
              dlist2_all = ['*', dlist[xx2]]
        
              validcoords = strcompress(strlowcase(*state.validcoords), /remove_all)
              inval_coords = validcoords[where(state.outcoord ne validcoords)]
 
              for i=0,n_elements(inval_coords) - 1 do begin
                  f_str = '*_' + inval_coords[i]
                  if i gt 0 then invali = [invali, where(strmatch(dlist2_all, f_str) eq 1)] $
                    else invali = where(strmatch(dlist2_all, f_str) eq 1)
              endfor
        
              dlist2_all_t = dlist2_all
              invali_i = where(invali gt 0, n_invali)
        
              if n_invali eq 0 then begin
                  if array_equal(dlist2_all,'*',/no_typeconv) then dlist2_all = 'None'
              endif else if (state.instr ne 'sst') and (state.instr ne 'esa') $
                 and (state.instr ne 'mom') and (state.instr ne 'gmom') then begin ;don't remove coord selections from list l2 particles, jmm, 2017-09-06
                  invali = invali[where(invali gt 0, n_invali_i)]
                  dlist2_all_t[invali] = 'invalid'
                  dlist2_all = dlist2_all[where(dlist2_all_t ne 'invalid')]
                  if array_equal(dlist2_all,'*',/no_typeconv) then dlist2_all = 'None'
              endif
          endif else dlist2_all = 'None'
      
          if (state.instr eq 'fbk') || (state.instr eq 'fft') || $
             (state.instr eq 'mom') || (state.instr eq 'spin') || $
             (state.instr eq 'sst') || (state.instr eq 'gmom') || (state.instr eq 'esa') then begin
              widget_control, state.coordDroplist, Sensitive=0 ; Desensitize 'Output Coordinates' dropdown list
              state.outCoord = 'N/A'
          endif else begin
              widget_control, state.coordDroplist, /Sensitive
;              coord_index = widget_info(state.coordDroplist, /droplist_select)
              outCoord = widget_info(state.coordDroplist, /combobox_gettext)
              state.outCoord = strlowcase(strcompress(outCoord, /remove_all))
          endelse
      END
      ; All-sky imager keograms selected
      (state.instr eq 'ask'): begin 
          state.observ_label = state.observ_labels[0]+':'
          thm_load_ask, /valid_names, site=asi_stations
          validobserv = ['* (All)', asi_stations]
          validobservlist = validobserv
          validobserv = strlowcase(strcompress(validobserv, /remove_all))
          dlist1_all = ['*', dlist]
          dlist2_all = 'None'
          widget_control, state.coordDroplist, Sensitive=0
          state.outCoord = 'N/A'
      END
      ; Ground magnetometer selected
      (state.instr eq 'gmag'): begin 
          state.observ_label = state.observ_labels[1]+':'
          thm_load_gmag, /valid_names, site = gmag_stations          
          validobserv = ['* (All)', gmag_stations[sort(gmag_stations)]]
          
          level1Label = widget_info(state.tab_id,find_by_uname='level1Label')
          widget_control, level1Label, set_value="GMAG stations:"
          thm_load_gmag_networks, gmag_networks=gmag_networks, gmag_stations=gmag_stations, selected_network=selected_network
         
          validobserv = ['* (All)', gmag_networks]
          validobservlist = validobserv
          validobserv = strlowcase(strcompress(validobserv, /remove_all))
          dlist1_all = 'None'
          dlist2_all = ['*', dlist]
          widget_control, state.coordDroplist, Sensitive=0
          state.outCoord = 'N/A'
          dlist1_all = ['* (All)', gmag_stations]
      END 
      ELSE: ;print,'DTYPE_DLIST bomb.'
  ENDCASE
  
  widget_control, state.observLabel, set_value=state.observ_label
  if ~keyword_set(from_coord_sel) then  widget_control,state.observList, $
                                          set_value=validobservlist
  if ptr_valid(state.validobserv) then ptr_free, state.validobserv
  state.validobserv = ptr_new(validobserv)
  if ptr_valid(state.validobservlist) then ptr_free, state.validobservlist
  state.validobservlist = ptr_new(validobservlist)
  
  dlist1_all = dlist1_all[sort(dlist1_all)]
  dlist2_all = dlist2_all[sort(dlist2_all)]  
  
  dlist1 = dlist1_all & dlist2 = dlist2_all

  if keyword_set(from_coord_sel) then begin
    if ~array_equal(dlist2, dlist2_orig, /no_typeconv) then begin
      if(ptr_valid(state.dtyp2)) then ptr_free, state.dtyp2
      state.dtyp2 = ptr_new('')
      widget_control,state.level2List, set_value=dlist2
      if (ptr_valid(state.dlist2)) then ptr_free,state.dlist2
      state.dlist2 = ptr_new(dlist2)
    endif
  endif else begin
    widget_control,state.level1List, set_value=dlist1
    widget_control,state.level2List, set_value=dlist2
    if (ptr_valid(state.dlist1)) then ptr_free,state.dlist1
    if (ptr_valid(state.dlist2)) then ptr_free,state.dlist2
    state.dlist1 = ptr_new(dlist1)
    state.dlist2 = ptr_new(dlist2)
  endelse

  ; if there is only one datatype available automatically select *
  ; This assumes that the format of the lists will always be such that an * is given first
  ; and the list contains one element ('None') when there is no data.
  if n_elements(dlist1) eq 2 && n_elements(dlist2) eq 1 then begin ;ie only * and one datatype
    widget_control, state.level1List, set_list_select=0
    thm_ui_load_data_file_l1_sel, state
  endif
  if n_elements(dlist2) eq 2 && n_elements(dlist1) eq 1 then begin ;ie only * and one datatype
    widget_control, state.level2List, set_list_select=0
    thm_ui_load_data_file_l2_sel, state
  endif

  h = 'Selected Output Coordinates: '+state.outCoord
  state.historyWin->Update, h
  if keyword_set(from_coord_sel) then begin
    h = 'Selected Output Coordinates: '+state.outCoord
  endif else begin
    h = 'Selected Instrument Type: '+state.instr
  endelse
  state.statusText->Update, h
  state.historyWin->Update, 'LOAD DATA: ' + h

  RETURN
END
