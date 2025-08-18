;+
;NAME:
; spd_ui_set_cursor
;
;PURPOSE:
;  Replaces the cursor on non-windows machines
;    
;CALLING SEQUENCE:
; spd_ui_set_cursor,win
; 
;INPUT:
; win: an IDLgrWindow
;
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_set_cursor.pro $
;
;------------------------------------------------------------------------------
pro spd_ui_set_cursor,win

  ;cursor_string = strarr(16,16)
  cursor_in = strarr(16)
  
  cursor_in = [ $  
        '     # # #      ', $  
        '   #   .   #    ', $  
        '       #        ', $  
        ' #     .     #  ', $  
        '       #        ', $  
        '#      .      # ', $  
        '      ###       ', $  
        '#.#.#.#.#.#.#.# ', $  
        '      ###       ', $  
        '#      .      # ', $  
        '       #        ', $  
        ' #     .     #  ', $  
        '       #        ', $  
        '  #    .    #   ', $  
        '     # # #      ', $  
        '                ']  
  
  
 ; cursor_string[*] = ' '
  ;cursor_string[*,6] = '.'
  ;cursor_string[*,8] = '.'
  ;cursor_string[6,*] = '.
  ;cursor_string[8,*] = '.'
  ;cursor_string[indgen(8)*2,7] = '#'
;  cursor_string[7,indgen(8)*2] = '#'
;  cursor_string[7,*] = '#'
;  cursor_string[*,7] = '#'
 ; cursor_string[6:8,6:8] = '#'
 ; cursor_string[7,7] = ' '
  
  ;for i = 0,15 do begin
  ;  cursor_in[i] = strjoin(cursor_string[*,i])
  ;endfor
  
  image = create_cursor(cursor_in,hotspot=hotspot,mask=mask)
 ; print,hotspot

 hotspot = [7,8]
  
  win->setCurrentCursor,image=image,hotspot=hotspot,mask=mask
  
end
