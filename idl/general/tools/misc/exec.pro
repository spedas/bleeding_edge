;+
;WIDGET Procedure:
;  EXEC
;PURPOSE:
; Widget tool that executes a user specified routine. This tool runs in the background.
; Author:
;    Davin Larson - Feb 2012
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;
;-

PRO exec_event, ev   ; exec

    widget_control, ev.top, get_uvalue= wids   ; get all widget ID's
;    dprint,dlevel=4,phelp=2,ev,/no_check

    CASE ev.id OF
    wids.base:  begin                    ;  Timed events
        widget_control,wids.exec_text,get_value = exec_text
;        dprint,dlevel=5,/phelp,exec_text,/no_check
        widget_control,wids.poll_text,get_value = poll_text
        poll_time = double(poll_text)
        if keyword_set(exec_text) then begin
            for i=0,n_elements(exec_text)-1 do result=execute(exec_text[i])
        endif else dprint,'Nothing to Execute!'
        if widget_info(/button_set,wids.poll_button) then begin
            if 1 then begin
                poll_time = poll_time - (systime(1) mod poll_time)  ; sample on even boundaries
            endif
            WIDGET_CONTROL, wids.base, TIMER=poll_time
        endif
        return
    end
    wids.exec_button: begin
        widget_control,wids.exec_text,get_value = exec_text   ; Is this line needed?
        WIDGET_CONTROL, wids.base, TIMER=0            ; execute right away (on next call to check_event() )
    end
    wids.poll_button: begin
        widget_control,wids.exec_text,sensitive = (ev.select eq 0)
        if ev.select then widget_control,wids.base, TIMER=0   else widget_control,wids.base, TIMER=-1
    end
    wids.done: begin
        WIDGET_CONTROL, ev.TOP, /DESTROY
        dprint,dlevel=2,'Done with: EXEC '+strtrim(wids.base)
        return
    end
    else: begin
;        msg = string('Base ID is: ',wids.base)
;        dprint,msg
;        printdat,ev
;        printdat,info
        dprint,'Unknown event'
    end
    ENDCASE
END




PRO exec,base,exec_text=exec_text ,interval=poll_int,now=now,poll=repeater,done=done,ids=ids,title_suffix=title_suffix

if n_elements(poll_int) eq 1 then poll_text = strtrim(poll_int,2)
if ~(keyword_set(base) && widget_info(base,/managed) ) then begin
    ids = create_struct('base', WIDGET_BASE(/COLUMN ) )
    ids = create_struct(ids,'exec_text',   widget_text(ids.base,xsize=60, uname='EXEC_TEXT',value=exec_text,/editable,ysize=2))
    ids = create_struct(ids,'poll_base',   widget_base(ids.base,/row, uname='POLL_BASE'))
    ids = create_struct(ids,'exec_button', widget_button(ids.poll_base, uname='EXEC_BUTTON',value='Execute'))
    ids = create_struct(ids,'poll_base2',  widget_base(ids.poll_base ,/nonexclusive))
    ids = create_struct(ids,'poll_button', widget_button(ids.poll_base2,uname='POLL_BUTTON',value='Poll Interval:'))
    ids = create_struct(ids,'poll_text',   widget_text(ids.poll_base,xsize=6, uname='POLL_TEXT', value = keyword_set(poll_text) ? poll_text:'5',/editable, /no_newline))
    ids = create_struct(ids,'poll_lab',    widget_label(ids.poll_base,uname='POLL_LAB', value='Seconds  '))
    ids = create_struct(ids,'done',        WIDGET_BUTTON(ids.poll_base, VALUE='Exit', UNAME='DONE'))
    WIDGET_CONTROL, ids.base, SET_UVALUE=ids
    WIDGET_CONTROL, ids.base, /REALIZE
    title = 'EXEC ('+strtrim(ids.base,2)+')'
    widget_control, ids.base, base_set_title=title+ (keyword_set(title_suffix) ? ' - '+title_suffix : '')
    XMANAGER, 'exec', ids.base,/no_block
    dprint,dlevel=2,'Started: '+title
    base = ids.base
endif else begin
    widget_control, base,get_uvalue=ids
    if size(/type,exec_text) eq 7 then widget_control,ids.exec_text,set_value=exec_text
    if n_elements(poll_text) ne 0 then widget_control,ids.poll_text,set_value=poll_text
endelse
if n_elements(repeater) ne 0  then begin
    widget_control,ids.poll_button,set_button = keyword_set(repeater)
    widget_control,ids.exec_text,sensitive =  ~keyword_set(repeater)
    widget_control,ids.base,timer = keyword_set(repeater) ? 0 : -1
endif
if keyword_set(now) then widget_control,base,timer=0   ; imediate execution
if keyword_set(done) then  WIDGET_CONTROL,base, /DESTROY

END
