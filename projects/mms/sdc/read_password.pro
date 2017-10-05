; Read a password from stdin echoing '*'s.
; Note, backspace will not work.
function read_password, prompt=prompt
  password = ''
  
  ; Print prompt, without new line.
  if n_elements(prompt) gt 0 then print, format='($, A)', prompt
  
  ; Gather characters until the user hits <return>.
  while (1) do begin
    ch = get_kbrd(/ESCAPE) ;read a character from the keyboard
    b = byte(ch)
    if (b eq 13 or b eq 10) then begin ;return
      print, '' ;get our new line back
      break ;get out of here
    endif
    password += ch ;append character to the password
    print, format='($, A)', '*' ;echo '*', no new line
  endwhile
   
  return, password
end
