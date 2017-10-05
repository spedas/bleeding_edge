; function: str_sub,string, old_substring, new_substring
; Purpose: Replaces a substring with a new string
; Author: Davin Larson

function str_sub,string1,old_substring,new_substring,reverse_search = rev,environment=check_environment

string2 = string1

for i=0,n_elements(string2)-1 do begin
  if keyword_set(check_environment) || ~keyword_set(old_substring) then begin
    pos1 = strpos(string2[i],'${')
    pos2 = strpos(string2[i],'}',pos1)
    while (pos2 ge 0) do begin
      evar = strmid(string2[i],pos1+2,pos2-pos1-2)
      string2[i] = strmid(string2[i],0,pos1) +   getenv(evar) + strmid(string2[i], pos2+1)   
      pos1 = strpos(string2[i],'${')
      pos2 = strpos(string2[i],'}',pos1)
    endwhile  
  endif
  if keyword_set(old_substring) then begin
    pos = strpos(reverse_search=rev,string2[i],old_substring)
    while pos ge 0 do begin
      string2[i] = strmid(string2[i],0,pos) + new_substring + strmid(string2[i],pos+strlen(old_substring))
      pos = strpos(reverse_search=rev,string2[i],old_substring,pos+1)
    endwhile    
  endif
endfor
return,string2
end
