PRO xtplot_options_exe, wid
@xtplot_com.pro
  widget_control, wid.txtExec, GET_VALUE=cmd
  if strlen(cmd[0]) ne 0 then rst = execute(cmd[0])
END

PRO xtplot_options_csrUpdate,wid, d
@xtplot_com.pro
  widget_control,wid.bgpCsrS,GET_VALUE=csr_selected
  
  xtplot_options_csrErase,wid
  
  if csr_selected[0] then begin
    get_data, xtplot_vnameA, data=DD
    if strmatch(size(DD,/tname),'STRUCT') then begin
      xtplot_pcsrA = xtplot_pcsrA + d
      xtplot_tcsrA = DD.x[xtplot_pcsrA]
      xtplot_timebar,xtplot_tcsrA,/transient
    endif
  endif
  
  if csr_selected[1] then begin
    get_data, xtplot_vnameB, data=DD
    if strmatch(size(DD,/tname),'STRUCT') then begin
      xtplot_pcsrB = xtplot_pcsrB + d
      xtplot_tcsrB = DD.x[xtplot_pcsrB]
      xtplot_timebar,xtplot_tcsrB,/transient
    endif
  endif
END

PRO xtplot_options_csrErase,wid
@xtplot_com.pro
  widget_control,wid.bgpCsrS,GET_VALUE=csr_selected
  if csr_selected[0] then xtplot_timebar,xtplot_tcsrA,/transient
  if csr_selected[1] then xtplot_timebar,xtplot_tcsrB,/transient
END

PRO xtplot_options_setcsr, csr_selected
@xtplot_com.pro
  nc = total(csr_selected)
  print, 'nc=',nc
  tplot
  ctime,myt,myy,myz,inds=inds,vinds=vinds,vname=vname,/exact,/silent,npoints=nc
  if nc eq 2 then begin
    xtplot_pcsrA = inds[0]
    xtplot_tcsrA = myt[0]
    xtplot_vnameA = vname[0]
    xtplot_pcsrB = inds[1]
    xtplot_tcsrB = myt[1]
    xtplot_vnameB = vname[1]
    xtplot_timebar,myt[0],/transient
    xtplot_timebar,myt[1],/transient
  endif else begin
    if csr_selected[0] then begin 
      xtplot_pcsrA = inds[0]
      xtplot_tcsrA = myt[0]
      xtplot_vnameA = vname[0]
    endif
    if csr_selected[1] then begin
      xtplot_pcsrB = inds[0]
      xtplot_tcsrB = myt[0]
      xtplot_vnameB = vname[0]
    endif
    xtplot_timebar,myt[0],/transient
  endelse
 
  
  if csr_selected[0] then begin
    print, 'CsrA variable : ', xtplot_vnameA
    print, 'CsrA time     : ', time_string(xtplot_tcsrA)
    print, 'CsrA point    : ', xtplot_pcsrA
    print, ''
  endif
  if csr_selected[1] then begin
    print, 'CsrB variable : ', xtplot_vnameB
    print, 'CsrB time     : ', time_string(xtplot_tcsrB)
    print, 'CsrB point    : ', xtplot_pcsrB
    print, ''
  endif  
END

PRO xtplot_options_event, ev
@xtplot_com.pro
  widget_control, ev.top, GET_UVALUE=wid
  exit_code = 0
  case ev.id of
    wid.btnP: begin
      widget_control,wid.txtInc, GET_VALUE=d
      xtplot_options_csrUpdate,wid, abs(float(d[0]))
      xtplot_options_exe,wid
      end
    wid.btnM: begin
      widget_control,wid.txtInc,GET_VALUE=d
      xtplot_options_csrUpdate,wid, float(d[0])*(-1)
      xtplot_options_exe,wid
      end
    wid.btnCsrSet:  begin
      widget_control,wid.bgpCsrS,GET_VALUE=csr_selected
      xtplot_options_setcsr, csr_selected
      end     
    wid.txtExec: begin
      xtplot_options_exe,wid
      end
    wid.close: exit_code = 1
    else:
  endcase
  
  widget_control, ev.top, SET_UVALUE=wid
  if exit_code then begin
    widget_control, ev.top, /destroy
  endif
END

PRO xtplot_options,width=width
@tplot_com.pro
@xtplot_com.pro

  ; window
  this_screen_size = get_screen_size()
  if not keyword_set(width) then width = 300
  xoffset = (this_screen_size[0]-width)*0.5 >0
  yoffset = this_screen_size[1]*0.3 
  
  ; tplot variable names
  tpv_opt_tags = tag_names(tplot_vars.options)
  idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
  if icnt gt 0 then begin
    dnames=tplot_vars.options.datanames
  endif else begin; no data names in tplot_vars.options
    dprint,dlevel=0,verbose=verbose,'No valid variable names found to tplot (use TPLOT_NAMES to display)'
    return
  endelse
  dnarr = strsplit(dnames,/extract)
  xtplot_pcsrA = 0
  xtplot_pcsrB = 0
  xtplot_tcsrA = 0
  xtplot_tcsrB = 0
  xtplot_vnameA = dnarr[0]
  xtplot_vnameB = dnarr[0]
  xtplot_var1  = 0
  xtplot_var2  = 0
  xtplot_var3  = 0
  
  base = widget_base(title='XTPLOT AutoExec',xoffset=xoffset, yoffset=yoffset,/column);scr_xsize=width)
  
  baseTab = widget_tab(base,/align_center)
    baseAutoCommand = widget_base(baseTab,title='Auto Exec',/column)
      str_element,/add,wid,'bgpCsrS',cw_bgroup(baseAutoCommand, ['Csr A','Csr B'], /ROW, /NONEXCLUSIVE, $
        SET_VALUE=[1,0]) 
      str_element,/add,wid,'btnCsrSet',widget_button(baseAutoCommand,VALUE='Set Cursor(s)')
      baseCtrl = widget_base(baseAutoCommand,/row)
        str_element,/add,wid,'btnM',widget_button(baseCtrl,VALUE='  <  ')
        str_element,/add,wid,'txtInc',widget_text(baseCtrl,value='1',/editable,xsize=5)
        str_element,/add,wid,'btnP',widget_button(baseCtrl,VALUE='  >  ')
      lblExec = widget_label(baseAutoCommand,VALUE='IDL Command:')
      str_element,/add,wid,'txtExec', widget_text(baseAutoCommand,value='xtplot_example',/editable)
  
  str_element,/add,wid,'close',widget_button(base,VALUE=' Close ')
        
  widget_control, base, SET_UVALUE=wid
  widget_control, base, /REALIZE
  
  XMANAGER, 'xtplot_options', base,/no_block
END