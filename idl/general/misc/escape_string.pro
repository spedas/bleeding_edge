;+
;function: escape_string
;
;purpose: adds \ to escape a list of characters
;
;inputs:
;  s: The string to be escaped
;  list=list: an array of characters to be escaped.  If not set, defaults to the regex set  ['[',']','{','}','\','^','$','.','|','?','*','+','(',')']
;      
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-06-11 21:39:46 -0700 (Tue, 11 Jun 2013) $
; $LastChangedRevision: 12513 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/escape_string.pro $
;-

function escape_string,s,list=list

  compile_opt idl2
  
  s_out = s
  
  if n_elements(list) eq 0 then list = ['\','[',']','{','}','^','$','.','|','?','*','+','(',')']
  
  for i = 0,n_elements(list)-1 do begin
    s_out = strjoin(strsplit(s_out,list[i],/extract),'\'+list[i])
  endfor
  
  return,s_out
  
end