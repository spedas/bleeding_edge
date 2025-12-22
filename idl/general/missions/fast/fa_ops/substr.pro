;	@(#)substr.pro	1.1	
function substr, ss, from, to, num
;+
; NAME: SUBSTR
;
; PURPOSE:
;   a function for replacing substrings inside strings.
;
; CATEGORY: string manipulation
;
; INPUTS: SS - a string to be operated on.
;         FROM - subtring from SS, to be replaced 
;         TO - a string which will replace FROM
;         NUM - The first NUM occurrences of FROM in SS are replaced
;         with TO. 
;
; OUTPUTS: The return value is a string or array of strings, with the
;          requested replacements made. 
;
; RESTRICTIONS: Strings only, please. 
;
; EXAMPLE: tplot_date = substr('1997/08/21/15:00', '/', '-', 2),
;          i.e. replace the first two slashes with dashes. 
;
; MODIFICATION HISTORY: written on a slow day in July 1997, by Bill
;                       Peria, UCB/SSL
;
;-

if not defined(num) then num = 32767

nss = n_elements(ss)
ss_out = strarr(nss)

for i=0,nss-1L do begin
    to_len = strlen(to)
    from_len = strlen(from)
    pos = 0
    nextpos = strpos(ss[i],from,pos)
    ss_out[i] = ss[i]
    nrep = 0 
    
    while ((nextpos ge 0) and (nrep lt num)) do begin
        ss_out[i] = strmid(ss_out[i], 0, nextpos) + to +  $
          strmid(ss_out[i],nextpos + from_len,strlen(ss_out[i]))
        pos = nextpos + to_len
        nextpos = strpos(ss_out[i],from,pos)
        nrep = nrep + 1L
    endwhile
endfor

return, ss_out
end
