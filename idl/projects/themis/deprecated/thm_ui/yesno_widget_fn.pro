;+
;NAME:
; yesno_widget_fn
;PURPOSE:
; Simple widget that asks for a yes or no
;CALLING SEQUENCE:
; yn=yesno_widget_fn(title, list = list, _extra = _extra)
;INPUT:
; title = a title, or a question
;OUTPUT:
; yn = 0 for no, 1 for yes
;KEYWORDS:
; list, a string array to put in the widget, as an aid
;HISTORY:
; 27-nov-2006, jmm, jimm@ssl.berkeley.edu
; 31-jul-2007, jmm, added /enable_yes_always button, default behavior
;              is to not allow this sort of thing
; 27-mar-2008, jmm, just added this comment to test SVN from my PC..
; 27-mar-2008, jmm, another comment to test SVN from my PC..
; 10-apr-2008, jmm, another test of SVN
; 29-apr-2008, jmm, another test of SVN
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-07-08 09:29:52 -0700 (Tue, 08 Jul 2014) $
;$LastChangedRevision: 15528 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/yesno_widget_fn.pro $
;
;-

Pro yesno_widget_event, event
  common yesno_widget_private, yn_sav, yes_always
  widget_control, event.id, get_uval = uval
  Case uval Of
    'YES':Begin
      widget_control, event.top, get_uval = state
      state.yesno = 1b
      yn_sav = 1b
      yes_always = 0b
      state.yesno_all = 0b
      widget_control, event.top, /destroy
    End
    'YES_TO_ALL':Begin
      widget_control, event.top, get_uval = state
      state.yesno = 1b
      yn_sav = 1b
      yes_always = 1b
      state.yesno_all = 1b
      widget_control, event.top, /destroy
    End
    'NO':Begin
      widget_control, event.top, get_uval = state
      state.yesno = 0b
      yn_sav = 0b
      yes_always = 0b
      state.yesno_all = 0b
      widget_control, event.top, /destroy
    End
  Endcase
Return
End
Pro yesno_widget, title_in, list = list, label = label, $
                  enable_yes_always = enable_yes_always, $
                  center=center, gui_id = gui_id, $
                  _extra = _extra

  If(keyword_set(gui_id)) Then Begin
      master = widget_base(/col, title = title_in, /modal, group_leader = gui_id)
  Endif Else master = widget_base(/col, title = title_in)
  submaster = widget_base(master, /col, /align_center)
  If(keyword_set(label)) Then Begin
    lbl = label
  Endif Else lbl = 'list'
  For j = 0, n_elements(lbl)-1 Do flabel = widget_label(submaster, value = lbl[j])
;list if needed
  If(is_string(list)) Then Begin
    listid = widget_base(submaster, /row, /align_center, /frame)
    lvllist = widget_text(listid, value = list, xsiz = strlen(list[0]), $
                          ysiz = n_elements(list) < 10, uval = 'LIST')
  Endif
  yes_button = widget_button(submaster, val = 'YES', uval = 'YES', $
                             /align_center, scr_xsize = 120)
  no_button = widget_button(submaster, val = 'NO', uval = 'NO', $
                            /align_center, scr_xsize = 120)
  If(keyword_set(enable_yes_always)) Then Begin
    yes_all_button = widget_button(submaster, $
                                   val = 'YES, AND DON''T ASK AGAIN', $
                                   uval = 'YES_TO_ALL', /align_center)
  Endif
  state = {master:master, yesno:0b, yesno_all:0b}
  
  if keyword_set(center) then begin
    centerTLB,master
  endif
  
  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'yesno_widget', master
  Return
End
Function yesno_widget_fn, title, _extra = _extra
  common yesno_widget_private, yn_sav, yes_always
  If(n_elements(yes_always) Gt 0) Then Begin
    If(yes_always) Then yn = 1b Else Begin
      yesno_widget, title, _extra = _extra
      yn = yn_sav
    Endelse
  Endif Else Begin
    yesno_widget, title, _extra = _extra
    yn = yn_sav
  Endelse

  Return, yn
End
