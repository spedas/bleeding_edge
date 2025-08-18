pro str_replace,string1,old_substring,new_substring,reverse_search = rev

n = n_elements(string1)
for i=0L,n-1 do begin
   pos = strpos(reverse_search=rev,string1[i],old_substring)
   if pos lt 0 then continue
   string1[i] = strmid(string1[i],0,pos) + new_substring + strmid(string1[i],pos+strlen(old_substring))
endfor
return
end

