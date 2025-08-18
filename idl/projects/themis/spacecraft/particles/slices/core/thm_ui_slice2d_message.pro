
;A procedure for the slices software to output usefull into to user via IDL console or THEMIS GUI
;
pro thm_ui_slice2d_message, msg, sb=sb, hw=hw, _extra = _extra

    compile_opt idl2, hidden
  
  p = 'THM_UI_SLICE2D: '
  pc = 0
  msg = string(msg)
  
  if obj_valid(hw) then begin
    hw->update,p+msg,_extra=_extra
  endif else begin
    pc++
  endelse
    
  if obj_valid(sb) then begin
    sb->update,msg
  endif else begin
    pc++
  endelse
  
  if pc ge 2 then print,p+msg

end
