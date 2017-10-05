
;+
;A procedure to match the background color of a bitmap to that of the OS GUI.
;Will be used to match icon backgrounds
;
;INPUT
;bitmap_array : three dimensional byte array representing an RGB bitmap image; read_bmp(<img>,/rgb)
;topbase : the top base widget of window housing the bitmap/widget
;
;-

pro spd_ui_match_background, topbase, bitmap_array

    compile_opt idl2, hidden

;Verify data type
  if size(bitmap_array, /n_dimensions) ne 3 or size(bitmap_array, /type) ne 1 then begin
    dprint,  'ERROR: Cannot match background on non bitmap arrays'
    return
  endif

;Transpose if not indexed by color (3dim byte array)
  if n_elements(bitmap_array[*,0,0]) gt 3 then bitmap_array = transpose(bitmap_array, [2,0,1])

;Take bottom left pixel as transparency color
  orig_color = bitmap_array[*,0,0]

;Get struct of system colors
  sys_colors=widget_info(topbase, /system_colors)

;Replace bitmap's "background" with the system's gui color
  for i=0, n_elements(bitmap_array[0,*,0])-1 do begin
    for j = 0, n_elements(bitmap_array[0,0,*])-1 do begin
      if ~in_set(bitmap_array[*,i,j] eq orig_color,0) then $
        bitmap_array[*,i,j] = byte(sys_colors.face_3d)
    endfor
  endfor 
  
;Transpose for display
  bitmap_array = transpose(bitmap_array, [1,2,0])
  
  return

end
