;+
; Function: get_token
;
; Purpose: this routine performs the meat of the work for the mini language lexical analyzer.
;          It will identify and return the next token in its string input.  It uses a series
;          of regular expressions to identify various tokens.
;          
; Input: s: A string from which the token is taken
; 
; Output: A struct describing a token or an error struct
; 
; 
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-10-25 17:48:17 -0700 (Tue, 25 Oct 2016) $
; $LastChangedRevision: 22195 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/get_token.pro $
;- 

function get_token,s

COMPILE_OPT idl2

tok = {type:'',name:'',value:'',index:0}

;note that the order of the statements below is important
;since the regex operator is greedy, it may interpret
;incorrectly if conditionals are reordered.

;newline
if strlen(s) eq 0 then begin

  tok.type = 'endline'

  tok.name = '<cr>'
  
  tok.value = tok.name

;ampersand
endif else if stregex(s,'(^&$|^&[^&])',/boolean) then begin  ;line terminate with single ampersand

  tok.type = 'termination' 
  
  tok.name = '&'
  
  tok.value = tok.name
  
;dollar sign sys call
;endif else if stregex(s,'^\$.*[^[:blank:]]+.*',length=l) ne -1 then begin
;
;  tok.type = 'syscall'
;  
;  tok.name = strmid(s,0,l)
;  
;  tok.value = tok.name
;
;;dollar sign line extender
;endif else if stregex(s,'^\$[[:blank:]]*',/boolean) then begin 
;
;  tok.type = 'continuation'
;
;  tok.name = '$'
;  
;  tok.value = tok.name
;;whitespace
endif else if stregex(s,'^[[:blank:]]',/boolean) then begin

  tok.type = 'whitespace'
  
  tok.name = ' '
  
  tok.value = tok.name

;comment
endif else if stregex(s,'^;.*',length=l) ne -1 then begin

  tok.type = 'comment'
  
  ;remove any trailing spaces from the comment
  tok.name = strtrim(strmid(s,0,l))
  
  tok.value = tok.name
  
;single quoted string
endif else if stregex(s,"^'.*'",length=l) ne -1 then begin

  tok.type = 'string'
  
  st = strmid(s,1,l-1)
  
  ;since regex matches greedily
  ;make sure it only grabs one
  ;string
  
   n = stregex(st,"^'.*'")
  
  if n ne -1 then begin
  
    tok.name = strmid(s,0,2)
  
  endif else begin
  
    n = stregex(st,"[^\\]'.*'")

    if n eq -1 then begin

      tok.name = strmid(s,0,l)
    
    endif else begin
  
      tok.name = strmid(s,0,n+3)

    endelse
  
  endelse 
  
  tok.value = tok.name

;double quoted string  
endif else if stregex(s,'^".*"',length=l) ne -1 then begin

  tok.type = 'string'
  
  st = strmid(s,1,l-1)
  
  ;since regex matches greedily
  ;make sure it only grabs one
  ;string
  n = stregex(st,'^".*"')
  
  if n ne -1 then begin
  
    tok.name = strmid(s,0,2)
  
  endif else begin
  
    n = stregex(st,'[^\\]".*"')

    if n eq -1 then begin

      tok.name = strmid(s,0,l)
    
    endif else begin
  
      tok.name = strmid(s,0,n+3)

    endelse
  
  endelse
  
  tok.value = tok.name
  
;number
;This tokenizes slightly differently than idl
;IDL allows numbers like "5e-".  This expression is illegal in this tokenizer
;Any dangling punctuation will be treated as part of the next expression
;although 5e-5 will be treated as 5.00000e-05
endif else if $ 
              stregex(s,'^[[:digit:]]+[Bb]',length=l) ne -1 || $  ; EX:  1B
              stregex(s,'^[[:digit:]]+[Uu]*([Ss]|[Ll]{1,2})',length=l) ne -1 || $ ;EX: 1US,1L,1LL,1ULL   
              stregex(s,'^[[:digit:]]+[Uu]',length=l) ne -1 || $ ;EX: 1u
              stregex(s,'^\.+[[:digit:]]+[eEdD][+-]+[[:digit:]]+',length=l) ne -1  ||$ ; EX: .1e+5, .1e-5
              stregex(s,'^\.+[[:digit:]]+[eEdD][[:digit:]]*',length=l) ne -1  ||$ ; EX: .1d,.1e5 
              stregex(s,'^\.+[[:digit:]]+',length=l) ne -1 || $  ; EX: .12342123
              stregex(s,'^[[:digit:]]+\.*[[:digit:]]*[eEdD][+-]+[[:digit:]]+',length=l) ne -1  ||$ ; EX: 1.1e+5, 1.1e-5
              stregex(s,'^[[:digit:]]+\.*[[:digit:]]*[eEdD][[:digit:]]*',length=l) ne -1  ||$ ; EX: 1.1d,1.1e5, 1e5 
              stregex(s,'^[[:digit:]]+\.*[[:digit:]]*',length=l) ne -1 $ ; EX: 1.1,1. 
then begin

  tok.type = 'number'

  tok.name = strlowcase(strmid(s,0,l))
  
  tok.value = tok.name

;endif else if stregex(s,'^([().,{}?]|\[|]|->|[:]{1,2})',length=l) ne -1 then begin
endif else if stregex(s,'^([(),])',length=l) ne -1 then begin

  tok.type = 'punctuation'
  
  tok.name = strmid(s,0,l)
  
  tok.value = tok.name

endif else if stregex(s,'^([#]{1,2}|\*|\+|-|/|\<|\>|[Aa][Nn][Dd]|[Ee][Qq]|[Gg][Ee]|[Gg][Tt]|[Ll][Ee]|[Ll][Tt]|[Mm][Oo][Dd]|[Nn][Ee]|[Oo][Rr]|[Xx][Oo][Rr]|\^)?=',length=l) ne -1 then begin

  tok.type = 'assignment'
  
  tok.name = 'asm'
  
  tok.value = strlowcase(strmid(s,0,l))
  

;endif else if stregex(s,'^([\(\)\*\^/\<\>~\?,\{}=]|\[|]|[+#-]{1,2}|&&|\|\|)',length=l) ne -1 then begin
;endif else if stregex(s,'^([*^/<>~]|&&|\|\||[#+-]{1,2}|[Aa][Nn][Dd]|[Ee][Qq]|[Gg][Ee]|[Gg][Tt]|[Ll][Ee]|[Ll][Tt]|[Mm][Oo][Dd]|[Nn][Ee]|[Oo][Rr]|[Xx][Oo][Rr]|[Nn][Oo][Tt])',length=l) ne -1 then begin
;endif else if stregex(s,'^([*^/<>~]|&&|\|\||[#]{1,2}|[+]{1,2}|[-]{1,2}|\$\+|[Aa][Nn][Dd]|[Ee][Qq]|[Gg][Ee]|[Gg][Tt]|[Ll][Ee]|[Ll][Tt]|[Mm][Oo][Dd]|[Nn][Ee]|[Oo][Rr]|[Xx][Oo][Rr]|[Nn][Oo][Tt])',length=l) ne -1 then begin
;arimethetic character operators
endif else if stregex(s,'^([*^/<>~]|&&|\|\||[#]{1,2}|[+]{1,2}|[-]{1,2}|\$\+)',length=l) ne -1 then begin
  
  tok.type = 'operator'
  
  tok.name = strlowcase(strmid(s,0,l))  
  
  tok.value = tok.name
  
;character operators that could appear as variable substrings
end else if stregex(s,'^([Aa][Nn][Dd]|[Ee][Qq]|[Gg][Ee]|[Gg][Tt]|[Ll][Ee]|[Ll][Tt]|[Mm][Oo][Dd]|[Nn][Ee]|[Oo][Rr]|[Xx][Oo][Rr]|[Nn][Oo][Tt]) ',length=l) ne -1 then begin
  
  tok.type = 'operator'

  tok.name = strlowcase(strmid(s,0,l-1))

  tok.value = tok.name
  
end else if stregex(s,'^[@!]?[[:alnum:]_]+',length=l) ne -1 then begin ;$ no longer legal inside variable name(to support $+ operator)

  tok.type = 'identifier'

  tok.name = strlowcase(strmid(s,0,l))
  
  tok.value = tok.name


endif else begin

  tok.type = 'error'
  
  tok.name = 'lexical error'
  
  tok.value = s

endelse

return, tok

end