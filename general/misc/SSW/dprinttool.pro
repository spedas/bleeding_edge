pro dprinttool_event,ev
   common dprint_com, dprint_struct
   on_error,2
   uname = widget_info(ev.id,/uname)
;   printdat,ev,uname
   dlvl = 5
   case uname of
     'DEBUG':   dprint,dlevel=dlvl,setdebug     = ev.str,  Uname+' Changed'
     'TRACE':   dprint,dlevel=dlvl,print_trace  = ev.index,Uname+' Changed'
     'DLEVEL':  dprint,dlevel=dlvl,print_dlevel = ev.select,Uname+' Changed'
     'DTIME':   dprint,dlevel=dlvl,print_time   = ev.select ,Uname+' Changed'
     'DDTIME':  dprint,dlevel=dlvl,print_dtime  = ev.select,Uname+' Changed'
     'UPDATE':  dprint,dlevel=0,'',sublevel=2
     'DERROR':  message,'User Forced Error!'
     'BREAK': begin
          dprint_struct.break_flag = ev.select
          dprint,'Break = ',strtrim(dprint_struct.break_flag,2)
     end
     'DONE' : WIDGET_CONTROL, ev.top, /DESTROY
     else: dprint,'Unknown event:', uname
   endcase
;   dprinttool,/update,''
   return
end




pro dprinttool,messagetext,update=update,sublevel=sublevel,prefix=prefix

dprint, '--------------',dlevel=99       ; Force dprint_com to be defined
common dprint_com, dprint_struct

if not keyword_set(update) then begin          ; Make the tool
   width = 50
   base = widget_base(/column,title='Dprint Tool')
   base1 = widget_base(base,/row)
   base11 = widget_base(base1)
   base12 = widget_base(base1,/column)
   STACK_ID  = widget_text(base11,uname='STACK',ysize=10,xsize=width)
 ;  DEBUG_ID  = widget_droplist(base12,title='Verbose:',value=strtrim(indgen(11),2),uname='DEBUG')
   DEBUG_ID  = widget_combobox(base12,value=strtrim(indgen(11),2),uname='DEBUG',edit=0)
   TRACE_ID  = widget_droplist(base12,Title='Trace:',value=['OFF','LAST','INDENT','ALL','NUM'],uname='TRACE')
   base121   = widget_base(base12,/nonexclusive)
   DLEVEL_ID = widget_button(base121, value ='Dlevel', uname ='DLEVEL' )
   DDTIME_ID = widget_button(base121, value ='Time', uname ='DTIME' )
   DDTIME_ID = widget_button(base121, value ='Delta time', uname ='DDTIME' )

   MENU_ID  = widget_button(base12,/menu,  value = 'Other', uname='MENU')

   BREAK_ID  = widget_button(MENU_ID, value = 'Request Break',uname='BREAK',/pushbutton_events)
   ERROR_ID  = widget_button(MENU_ID, value = 'Force Error',uname='DERROR')

   UPDATE_id = widget_button(menu_id,value='Update',uname='UPDATE')
   DONE_ID   = widget_button(MENU_ID, value = 'Done',uname='DONE')
 ;  menu2_id = widget_button(menu_id,value='button2',uname='BUTTON2')

   TEXT_ID   = widget_text(base,uname='TEXT',ysize=2);,xsize=width*2)
   widget_control, base,/realize
   xmanager, 'dprinttool', base  ,/no_block

   dprint_struct.widget_id = base
   dprint_struct.check_events =1
endif

;Update the tool

  if widget_info(/valid_id,dprint_struct.widget_id) eq 0 then begin
    dprint_struct.widget_id = 0L
    dprint_struct.check_events = 0
    return
  endif
  wid = dprint_struct.widget_id

; Get stack
  if n_elements(prefix) eq 0 then begin
    stack = scope_traceback(/structure,system=1)
    level = n_elements(stack)  -1
    if level gt 200 then begin
       Message,"Stack is too large! Runaway recursion?"
    endif
    if keyword_set(sublevel) then level -= sublevel
    level = level > 1
    stack = stack[0:level-1]
    levels = indgen(level)
    prefix=strtrim(levels,2)+'  '+stack.routine + string(stack.line,format='(" (",i0,")")')
  endif
  widget_control, widget_info(wid,find_by_uname='STACK'),set_value=prefix   ;,/no_copy
; Message
  widget_control, widget_info(wid,find_by_uname='TEXT'), set_value=messagetext  ;,/no_copy
; Dtime
  widget_control, widget_info(wid,find_by_uname='DDTIME') ,set_button= dprint_struct.print_dtime
  widget_control, widget_info(wid,find_by_uname='DTIME')  ,set_button= dprint_struct.print_time
  widget_control, widget_info(wid,find_by_uname='DLEVEL') ,set_button= dprint_struct.print_dlevel
  widget_control, widget_info(wid,find_by_uname='TRACE') ,set_droplist_select = dprint_struct.print_trace
  widget_control, widget_info(wid,find_by_uname='DEBUG') ,set_combobox_select = dprint_struct.debug

end









