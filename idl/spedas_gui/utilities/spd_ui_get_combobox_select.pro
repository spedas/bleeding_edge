
;+
; Purpose:
;   Return the index of specified combobox widget's current selection.
;
; Arguments:
;   BASE:  Widget ID of base existing above the combobox in the widget heirarchy
;   UNAME: Uname of the combobox widget
; 
; Return Value:
;   Index of the specified combobox widget's current selection.
; 
; Usage:
;   idx = spd_ui_get_combobox_select(top_base, 'my_combobox')
; 
; Notes:
;
;
;-
function spd_ui_get_combobox_select, base, uname

    compile_opt idl2,hidden
  
  ;get widget id
  combo = widget_info(base,find_by_uname=uname)

  ;get currect selection and array of all values for this widget
  text = widget_info(combo,/combobox_gettext)
  widget_control,combo,get_value=names
  
  ;return index
  return,where(text eq names)
  
end
