PRO xtplot_panel_event, ev
  widget_control, ev.top, GET_UVALUE=wid
  case ev.id of
    wid.tnames: begin
      widget_control, wid.tnames, GET_VALUE=tnames
      dnames=wid.dnames_a
      widget_control, wid.dnames, SET_VALUE=array_union(dnames,tnames) ge 0
      end
    wid.dnames: begin
      widget_control, wid.tnames, GET_VALUE=tnames
      widget_control, wid.dnames, GET_VALUE=new_names
      if ev.select then tnames = [tnames,ev.value] $
        else begin
          w = where(tnames ne ev.value,c)
          if c ne 0 then tnames = tnames[w]
      endelse
      widget_control, wid.tnames, SET_VALUE = tnames
      end
    wid.apply: begin
      widget_control, wid.tnames, GET_VALUE=tnames
      xtplot, tnames
      ;widget_control, ev.top, /destroy
      end
    wid.close: widget_control, ev.top, /destroy
    else:
  endcase
END

PRO xtplot_panel,width=width
  this_screen_size = get_screen_size()
  if not keyword_set(width) then width = 500   
  xoffset = (this_screen_size[0]-width)*0.5 >0
  yoffset = this_screen_size[1]*0.3
  tnms   = tnames(/tplot); variables used in tplot
  dnames = tnames()   ; available variables
  str_element,/add,wid,'dnames_a',dnames
  
  base = widget_base(/column,title='XTPLOT Configure Panels', $
    scr_xsize=width, xoffset=xoffset, yoffset=yoffset)
    baseCont  = widget_base(base, /ROW)
      baseLeft  = widget_base(baseCont, /COLUMN, scr_xsize=width*0.48,/base_align_left)
        lblDnames = widget_label(baseLeft,VALUE='Available Variables')
        str_element,/add,wid,'dnames', CW_bgroup(baseLeft,dnames,/scroll,$
          x_scroll_size=width*0.48,y_scroll_size=300,$
          set_value=array_union(dnames,tnms) ge 0,/nonexcl,/return_name,space=0)
      baseRight = widget_base(baseCont, /COLUMN, scr_xsize=width*0.48,/base_align_left)
        lblTnames = widget_label(baseRight,VALUE='Selected Variables')
        str_element,/add,wid,'tnames', widget_text(baseRight,VALUE=tnms,/editable,/all,$
          xsize=width*0.48,ysize=24,/scroll) ; ysize is in unit of lines
    baseBtn = widget_base(base,/ROW,/align_center)
      str_element,/add,wid,'apply',widget_button(baseBtn, VALUE=' Apply ')
      str_element,/add,wid,'close',widget_button(baseBtn,VALUE=' Close ')
  widget_control, base, SET_UVALUE=wid
  widget_control, base, /REALIZE

  XMANAGER, 'xtplot_panel', base,/no_block
END
