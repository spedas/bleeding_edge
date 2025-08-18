;+  
;NAME:
;  ssl_newline
;
;PURPOSE:
;  Returns a cross-platform newline character.
;  Specifically, used in the dialog_message boxes, which tend to
;  print junk characters if character 13 is used on non-windows platforms
;
;CALLING SEQUENCE:
;  newline = ssl_newline()
;  string = line1 + ssl_newline() + line2
;
;INPUT:
; none
; 
;OUTPUT:
; Newline character
;
;HISTORY:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-10-28 12:44:04 -0700 (Mon, 28 Oct 2013) $
;$LastChangedRevision: 13414 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/SSW/ssl_newline.pro $
;-----------------------------------------------------------------------------------

function ssl_newline

    compile_opt idl2, hidden

  if (strlowcase(!version.os_family) eq 'windows') then begin
    return,string(13B) + string(10B)
  endif else begin
    return,string(10B)
  endelse

end