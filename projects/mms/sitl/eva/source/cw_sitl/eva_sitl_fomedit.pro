;+
; NAME: EVA_SITL_FOMEDIT
; 
; COMMENT:
;   This widget allows the user to modify the segment he/she selected.
;   The information of the segment to be modified is store in the structure "segSelect".
;   When "Save" is chosen, the "segSelect" structure will be used to update FOM/BAK structures.
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2023-08-21 20:46:44 -0700 (Mon, 21 Aug 2023) $
; $LastChangedRevision: 32050 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_fomedit.pro $
;
PRO eva_sitl_FOMedit_event, ev
  widget_control, ev.top, GET_UVALUE=wid
  
  code_exit = 0
  segSelect = wid.segSelect; Each event will modify this "segSelect"
  
  idx = where(strmatch(tag_names(ev),'VALUE'),ct)
  if ct eq 1 then begin
    case size(ev.VALUE,/dimension) of
      0: evalue = ev.VALUE
      1: evalue = ev.VALUE[0]
      else: stop
    endcase
  endif
  
  case ev.id of
    wid.ssFOM: begin
      FOMvalue = (evalue < wid.fom_max_value) > wid.fom_min_value
      segSelect.FOM = FOMvalue
      end
    wid.sldStart: begin
      if wid.proj eq 'mms' then begin
        if n_elements(wid.wgrid) gt 1 then begin
          result = min(abs(wid.wgrid-evalue),segSTART)
          result = min(abs(wid.wgrid-segSelect.TE),segSTOP)
          len = segSTOP - segSTART
        endif else begin
          len = (segSelect.TE-evalue)/10.d0
        endelse
        txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
      endif else begin
        ptr = sppeva_sitl_get_block(evalue, segSelect.TE,/quiet)
        txtbuffs = 'SEGMENT SIZE: '+strtrim(string(ptr.length),2)+' blocks'
      endelse
      widget_control, wid.lblBuffs, SET_VALUE=txtbuffs
      segSelect.TS = evalue
      end
    wid.sldStop: begin
      if wid.proj eq 'mms' then begin
        if n_elements(wid.wgrid) gt 1 then begin
          result = min(abs(wid.wgrid-segSelect.TS),segSTART)
          result = min(abs(wid.wgrid-evalue),segSTOP)
          len = segSTOP - segSTART
        endif else begin
          len = (evalue-segSelect.TS)/10.d0
        endelse
        txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
      endif else begin
        ptr = sppeva_sitl_get_block(segSelect.TS,evalue,/quiet)
        txtbuffs = 'SEGMENT SIZE: '+strtrim(string(ptr.length),2)+' blocks'
      endelse
      widget_control, wid.lblBuffs, SET_VALUE=txtbuffs
      segSelect.TE = evalue
      end
    wid.bgMMS: begin
      widget_control, ev.id, GET_VALUE=value;get new obsset
      segSelect.OBSSET = eva_obsset_bitarray2byte(value)
      end
    wid.txtDiscussion: begin
      widget_control, ev.id, GET_VALUE=new_discussion;get new discussion
      segSelect.DISCUSSION = new_discussion[0]
      comlen = string(strlen(new_discussion[0]),format='(I4)')
      widget_control, wid.lblDiscussion, SET_VALUE='COMMENT: '+comlen+wid.DISLEN 
      end
    wid.btnSave: begin
      if total(eva_obsset_byte2bitarray(segSelect.OBSSET)) eq 0.0 then begin
        result = dialog_message('Please select at least one spacecraft.',/center)
        code_exit = 2
      endif else begin
        print,'EVA: ***** EVENT: btnSave *****'
        if strmatch(wid.proj,'mms') then begin
          print, '**************'
          
          eva_sitl_strct_update, segSelect,BAK=wid.state.pref.EVA_BAKSTRUCT
          eva_sitl_stack
        endif else begin
          sppeva_sitl_tplot_update, segSelect, wid.vvv
        endelse
        code_exit = 1
      endelse
    end
    wid.btnCancel: begin
      print,'EVA: ***** EVENT: btnCancel *****'
      code_exit = 1 ; Do nothing
    end
    else:
  endcase
  
  if code_exit then begin
    device, set_graphics=wid.old_graphics
    tplot,verbose=0
    widget_control, ev.top, /destroy
  endif else begin
    eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, wid.vvv, /rehighlight, $
      fom_min_value = wid.fom_min_value, fom_max_value=wid.fom_max_value
    str_element,/add,wid,'segSelect',segSelect
    widget_control, ev.top, SET_UVALUE=wid
  endelse
end

; INPUT:
;   STATE: state for cw_sitl; this information is needed to call >eva_sitl_update_board, wid.state, 1
PRO eva_sitl_FOMedit, state, segSelect, wgrid=wgrid, vvv=vvv, proj=proj, $
  fom_min_value = fom_min_value, fom_max_value=fom_max_value, basepos=basepos
  if xregistered('eva_sitl_FOMedit') ne 0 then return
  
  ;//// user setting  /////////////////////////////
  dTfrac          = 0.5; fraction of the current time range --> range of time change
  scroll          = 1.0 ; how many seconds to be moved by sliders
  drag            = 1   ; use drag keyword for sliders?
  if undefined(fom_min_value) then fom_min_value   = 2.0  ; min allowable value of FOM
  if undefined(fom_max_value) then fom_max_value   = 255.0 ; max allowable value of FOM
  dislen          = ' characters (max 250)'; label for the Discussion Text Field
  ;////////////////////////////////////
  
  ; initialize
  if undefined(proj) then proj='mms'
  device, get_graphics=old_graphics, set_graphics=6
  ;if n_elements(vvv) eq 0 then stop
  if undefined(vvv) then message,'Please specify vvv (eva_sitl_FOMedit)'
  eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, vvv, $
    fom_min_value = fom_min_value, fom_max_value=fom_max_value

  if n_elements(wgrid) eq 0 then message, "Need wgrid"
  
  time = timerange(/current)
  ts_limit = time[0]
  te_limit = time[1]
  idx = where(strmatch(strlowcase(tag_names(segSelect)),'ts_limit'),ct)
  if ct eq 1 then ts_limit = segSelect.TS_LIMIT 
  idx = where(strmatch(strlowcase(tag_names(segSelect)),'te_limit'),ct)
  if ct eq 1 then te_limit = segSelect.TE_LIMIT
  
  dTh = double(dTfrac)*(te_limit-ts_limit)
  Ts  = segSelect.TS
  Te  = segSelect.TE
  Tc  = 0.5*(Ts+Te)
  start_min_value = Ts-dTh > ts_limit
  start_max_value = Ts+dTh < Tc
  stop_min_value  = Te-dTh > Tc
  stop_max_value  = Te+dTh < te_limit
  
  if proj eq 'mms' then begin
    if n_elements(wgrid) gt 1 then begin
      result = min(abs(wgrid-Ts),segSTART)
      result = min(abs(wgrid-Te),segSTOP)
      len = segSTOP - segSTART
    endif else begin
      len = (Te-Ts)/10.d0
    endelse
    txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
  endif else begin
    print, Ts, Te
    print, '***********'
    PTR = sppeva_sitl_get_block(Ts, Te,/quiet)
    txtbuffs = 'SEGMENT SIZE: '+strtrim(string(PTR.LENGTH),2)+' blocks'
  endelse
  
  wid = {STATE:state, segSelect:segSelect, SCROLL:scroll, OLD_GRAPHICS:old_graphics, DISLEN:dislen, $
    START_MIN_VALUE: start_min_value, STOP_MIN_VALUE: stop_min_value, FOM_MIN_VALUE: fom_min_value, $
    START_MAX_VALUE: start_max_value, STOP_MAX_VALUE: stop_max_value, FOM_MAX_VALUE: fom_max_value,$
    WGRID: wgrid, vvv:vvv, proj:proj }
    
  ; widget layout
  
  base = widget_base(TITLE='Edit FOM',/column)
  
  disable=0
  
  if (segSelect.BAK) and (n_tags(segSelect) ge 16) then begin
    str_element,/add,wid,'lblBuffs',-1L
    str_element,/add,wid,'sldStart',-1L
    str_element,/add,wid,'sldStop',-1L
    lblTitle  = widget_label(base,VALUE='SEGMENT STATUS INFO')
    baseSeg = widget_base(base,/column,/base_align_left,/frame)
    valPlay = (segSelect.INPLAYLIST) ? 'Yes' : 'No'
    valPend = (segSelect.ISPENDING) ? 'Yes' : 'No'
    lblID     = widget_label(baseSeg,VALUE='ID: '+strtrim(string(segSelect.DATASEGMENTID),2))
    lblFOM    = widget_label(baseSeg,VALUE='FOM: '+string(segSelect.FOM,format='(F7.3)'))
    lblStatus = widget_label(baseSeg,VALUE='STATUS:  '+segSelect.STATUS)
    lblPlay   = widget_label(baseSeg,VALUE='inPLAYLIST: '+valPlay)
    lblPend   = widget_label(baseSeg,VALUE='isPENDING : '+valPend)
    lblLengths= widget_label(baseSeg,VALUE='SEGLENGTHS: '+strtrim(string(segSelect.SEGLENGTHS),2))
    lblSrcID  = widget_label(baseSeg,VALUE='SOURCE-ID: '+segSelect.SOURCEID)
    lblDiscuss= widget_label(baseSeg,VALUE='DISCUSSION: '+segSelect.DISCUSSION)
    lblStart  = widget_label(baseSeg,VALUE='FIRST BUFFER: '+time_string(segSelect.TS))
    lblStop   = widget_label(baseSeg,VALUE='LAST BUFFER: '+time_string(segSelect.TE-10.d0))
    lblCreate = widget_label(baseSeg,VALUE='CREATE-TIME: '+segSelect.CREATETIME)
    lblFinish = widget_label(baseSeg,VALUE='FINISH-TIME: '+segSelect.FINISHTIME)
    lblNumEval= widget_label(baseSeg,VALUE='NUM-EVAL-CYCLES: '+strtrim(string(segSelect.NUMEVALCYCLES),2))
    lblParamID= widget_label(baseSeg,VALUE='PARAMETER-SET-ID:'+segSelect.PARAMETERSETID)
    disable = strmatch(strlowcase(segSelect.STATUS),'*finished*') 
    if disable then ssFOM = -1 else ssFOM = eva_slider(base,title=' FOM ',VALUE=segSelect.FOM,MAX_VALUE=fom_max_value, MIN_VALUE=0) 
    str_element,/add,wid,'ssFOM',ssFOM
    ;txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
    str_element,/add,wid,'bgMMS',-1L
  endif else begin
    str_element,/add,wid,'ssFOM',eva_slider(base,title=' FOM ',VALUE=segSelect.FOM,MAX_VALUE=fom_max_value, MIN_VALUE=0)
    ;txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
    str_element,/add,wid,'lblBuffs',widget_label(base,VALUE=txtbuffs)
    str_element,/add,wid,'sldStart',eva_slider(base,title='Start',$
      VALUE=Ts, MIN_VALUE=start_min_value, MAX_VALUE=start_max_value,  WGRID=wgrid, /time)
    str_element,/add,wid,'sldStop',eva_slider(base,title='Stop ',$
      VALUE=Te, MIN_VALUE=stop_min_value, MAX_VALUE=stop_max_value, WGRID=wgrid, /time)
    str_element,/add,wid,'drpStatus',-1L
    ;-----------
    ; OBSSET
    ;-----------
    ProbeNamesMMS = ['MMS-1 ', 'MMS-2 ', 'MMS-3 ', 'MMS-4 ']
    str_element,/add,wid,'bgMMS',cw_bgroup(base, ProbeNamesMMS, /ROW, /NONEXCLUSIVE,$
      SET_VALUE=eva_obsset_byte2bitarray(segSelect.OBSSET),BUTTON_UVALUE=bua,ypad=0,space=0)    
  endelse
  
  
  ;-----------
  ; DISCUSSION
  ;-----------
  if disable then begin
    comment = 'This is a FINISHED segment. No need to edit.'
    txtDiscuss = -1
  endif else begin
    comlen = string(strlen(segSelect.DISCUSSION), format='(I4)')
    comment = 'COMMENT: '+comlen+wid.DISLEN
    txtDiscuss = widget_text(base,VALUE=segSelect.DISCUSSION,/all_events,/editable)
  endelse
  str_element,/add,wid,'lblDiscussion',widget_label(base,VALUE=comment)
  str_element,/add,wid,'txtDiscussion',txtDiscuss
  
  
  
  baseDeci = widget_base(base,/ROW)
  str_element,/add,wid,'btnSave',widget_button(baseDeci,VALUE='Save',ACCELERATOR = "Return",SENSITIVE=~disable)
  str_element,/add,wid,'btnCancel',widget_button(baseDeci,VALUE='Cancel')
  widget_control, base, /REALIZE
  
  ;-----------------
  ; WIDGET POSITION
  ;-----------------
  scr = get_screen_size()
  geo = widget_info(base,/geometry)
  if undefined(basepos) then basepos = state.pref.EVA_BASEPOS 
  ;basepos = state.pref.EVA_BASEPOS
  if basepos le 0 then begin
    xoffset = scr[0]*0.5-geo.xsize*0.5
  endif else begin
    xoffset = basepos
  endelse
  yoffset = scr[1]*0.5-geo.ysize*0.5
  widget_control, base, SET_UVALUE=wid, XOFFSET=xoffset, YOFFSET=yoffset
  xmanager, 'eva_sitl_FOMedit', base,GROUP_LEADER=state.GROUP_LEADER
END
