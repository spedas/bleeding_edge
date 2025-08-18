


;   ---- Scroll down for main function -------



;Function:
;  file_http_strip_domain
;Purpose:
;  removes the domain(http://domain.whatever/) from html link, if present. Otherwise, returns string unmodified
;Inputs: 
;  s: The string to have domain removed
;Returns:
;  s: with domain removed
function spd_download_strip_domain,s

 compile_opt idl2,hidden

  ;match a string containing the following in order
  ;#1 the beginning of the string
  ;#2 "http://"
  ;#2 followed by one or more characters that are not "/"
  ;#3 followed by one "/"
  ;#4 followed by 0 or more characters of any type
  m = stregex(s,"^(ftp)|(http)s?://[^/]+/",length=l,/fold_case)
  
  if m[0] ne -1 then begin
    return, strmid(s,l)
  endif else begin
    return, s
  endelse

end 
 


;Function:
;  file_http_is_parent_dir
;Purpose:
;  predicate function, checks whether the provided link is a parent to the current directory
;Inputs:
;  Current: Set to the full url for the current directory
;  Link: The link to be checked
;Returns: 
;  1: if link is to current's parent
;  0; if link is not to current's parent
function spd_download_is_parent_dir, current, link

   compile_opt idl2,hidden
  
  if n_elements(link) eq 0 then return,0
  if strlen(link) eq 0 then return,0
  
  ;match a string containing the following in order
  ;#1 the contents of the variable "link"
  ;#2 one or more characters that are not "/"
  ;#3 the "/" character
  ;#4 the end of the string
  
  ;Other notes:
  ;#1 link will always end in "/" if it is a directory.  So there is no need to specify it in the regex
  ;#2 strip domain will always return a string that does not begin with a "/" (relative link), so we add it back in
  return,stregex("/"+spd_download_strip_domain(current),escape_string(link)+"[^/]+/$",/boolean,/fold_case)
  
end




;+
;Function:
;  spd_download_extract
;
;Purpose:
;  Helper function to parse <a>(link) tags from html index files.
;
;Calling Sequence:
;  return_value =  spd_download_extract(string [,/relative] [,/normal]
;                                              [,no_parent_links=no_parent_links])
;
;Input:
;  string_array:  String array containing the html index file to be parsed
;  relative:  Set to strip out everything but the filename from a link
;  normal:  Set to links that don't have '*' or '?' 
;           (don't think this should every actually happen, but option retained just in case)
;  no_parent_links:  Set to the parent domain to automatically exclude backlinks to the parent directory
;
;Output:
;  return_value:  An empty string or array of strings with link destinations
;
;Notes:
;  Copied from file_http_copy subroutine extract_html_links_regex, original notes below:
;  
;     "The _regex version of this routine is replacing the original version because 
;      the old version made assumptions about the formatting of the .remote-index.html file
;      that were dependent upon the type of web server that was producing the file.  We think that 
;      these bugs took so long to show up because Apache servers are extremely common.
;      Modification prompted so that file_http_copy can work more reliably rbspice & rb-emfisis
;      New version: 
;      #1 Handles html that doesn't place the href attribute exactly one space after the link tag
;      #2 Handles cases where the server doesn't include newlines, or where multiple links are 
;         included per line of returned html by the server"
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-18 16:27:58 -0800 (Wed, 18 Feb 2015) $
;$LastChangedRevision: 17004 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_extract.pro $
;
;-
function spd_download_extract, string_array, $  
                               relative=relative, $
                               normal=normal, $
                               no_parent_links=no_parent_links
     
    compile_opt  idl2,hidden
   

links = ''

;This regex is a little tricky, most of the complexity is to prevent it from matching 
;two links when it should match one.
;
;  e.g. It could match <a href="blah"></a><a href="blah"></a> 
;       instead of     <a href="blah"> 
;       (matching between the first <a and the last >, rather than first & first)

if keyword_set(normal) then begin
  ;match a string containing the following in order
  ;#1 "<a " 
  ;#2 zero or more characters that are not '<' or '>'
  ;#3 "href="
  ;#4 '"' (quotation mark)
  ;#5 0 or more characters that are not '"' '*' or '?'
  ;#6 '"' (quotation mark)
  ;#7 0 or more characters that are not '<' or '>'
  ;#8 The '>' character
  ;
  ;Other notes:
  ;#1 The () are not a part of the pattern.  They indicate that anything matching inside the parentheses is a captured sub-expression
  link_finder_regex='<a [^>^<]*href="([^"^*^?]*)"[^<^>]*>'
endif else begin
  ;match a string containing the following in order
  ;#1 "<a " 
  ;#2 zero or more characters that are not '<' or '>'
  ;#3 "href="
  ;#4 '"' (quotation mark)
  ;#5 0 or more characters that are not '"'
  ;#6 '"' (quotation mark)
  ;#7 0 or more characters that are not '<' or '>'
  ;#8 The '>' character
  ;
  ;Other notes:
  ;#1 The () are not a part of the pattern.  They indicate that anything matching inside the parentheses is a captured sub-expression
  link_finder_regex='<a [^>^<]*href="([^"]*)"[^<^>]*>'
endelse


;perform search one line at a time
for i=0, n_elements(string_array)-1 do begin

  string = string_array[i]

  ;/subexp indicates that everything inside the () of the regex should be returned in the results so that they can be extracted
  pos = stregex(string,link_finder_regex,/subexp,length=length,/fold_case)
  
  while pos[1] ne -1 do begin 
    
    link = strmid(string,pos[1],length[1]) ; remove a copy of the link from the string
    
    string = strmid(string,pos[0]+length[0]) ; remove link from string, so that we can process the next string
       
    ;exclude parent links, if keyword set and domain provided
    if n_elements(no_parent_links) gt 0 then begin
      if spd_download_is_parent_dir(no_parent_links,link) then begin
        link = ''
      endif
    endif
       
    if keyword_set(relative) then begin
      
      ;match a string containing the following in order
      ;#1 a "/"
      ;#2 one or more characters that are not "/"
      ;#3 one or more "/" characters
      ;#4 the end of the string
      rel_pos = stregex(link,'/[^/]+/?$',/fold_case)
      if rel_pos[0] ne -1 then begin
        link = strmid(link,rel_pos+1)
      endif
    endif
    
    if strlen(link) gt 0 then begin
      if strlen(links[0]) gt 0 then begin
        links = [links,link]
      endif else begin
        links = [link]
      endelse
    endif
     
    pos = stregex(string,link_finder_regex,/subexp,length=length,/fold_case)
  endwhile

endfor

return, links

end