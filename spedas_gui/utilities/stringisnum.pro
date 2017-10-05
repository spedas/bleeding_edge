;+
;Function: stringIsNum
;
;Purpose: Determines if a given string is a number or not.
;
;Inputs: str : the string to be checked
;
;Output: Returns 1 if yes, or if no
;
;
;EXAMPLES:
; if stringIsNum(s) then print, strtrim(double(s),2)
; 
;  % Compiled module: STRINGISNUM.
;SPEDAS> print,stringisnum('hello')
;       0
;SPEDAS> print,stringisnum('1.234')
;       1
;SPEDAS> print,stringisnum('1.234e4')
;       1
;SPEDAS> print,stringisnum('1B')
;       1
;SPEDAS> print,stringisnum(' 1 ')
;       1
;SPEDAS> print,stringisnum(' 1Hello ')
;       0
;SPEDAS> print,stringisnum(' 1D ')
;       1
;SPEDAS> print,stringisnum(' Hello ')
;       0
;       
;  Notes: String must be only a numerical string and leading or trailing whitespace
;         if true is to be returned.  Strings that include other non-numerical characters
;         will return false even if they have numerical sub-strings.
;
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/stringisnum.pro $
;-
function stringIsNum,str

  s = strtrim(str,2)
 
  if $ 
              stregex(s,'^[[:digit:]]+[Bb]$') ne -1 || $  ; EX:  1B
              stregex(s,'^[[:digit:]]+[Uu]*([Ss]|[Ll]{1,2})$') ne -1 || $ ;EX: 1US,1L,1LL,1ULL   
              stregex(s,'^[[:digit:]]+[Uu]$') ne -1 || $ ;EX: 1u
              stregex(s,'^\.+[[:digit:]]+[eEdD][+-]+[[:digit:]]+$') ne -1  ||$ ; EX: .1e+5, .1e-5
              stregex(s,'^\.+[[:digit:]]+[eEdD][[:digit:]]*$') ne -1  ||$ ; EX: .1d,.1e5 
              stregex(s,'^\.+[[:digit:]]+$') ne -1 || $  ; EX: .12342123
              stregex(s,'^[[:digit:]]+\.*[[:digit:]]*[eEdD][+-]+[[:digit:]]+$') ne -1  ||$ ; EX: 1.1e+5, 1.1e-5
              stregex(s,'^[[:digit:]]+\.*[[:digit:]]*[eEdD][[:digit:]]*$') ne -1  ||$ ; EX: 1.1d,1.1e5, 1e5 
              stregex(s,'^[[:digit:]]+\.*[[:digit:]]*$') ne -1 $ ; EX: 1.1,1. 
  then return,1 else return,0

end 
