;Name: spd_cdawlib_replace_bad_chars
;Purpose: to find "illegal" characters and replace them w/ the "replacement'
;character.
;
;calling sequence:
;	outstring = spd_cdawlib_replace_bad_chars(instring, repchar=repchar, found)
;
;arguments:
;		instring: input string or array of strings to examine
;		found: = 1 if bad characters are found and replaced
;		       = 0 if no bad characters are found.
;keyword:
;		repchar: character to replace bad character with
;			 the only valid values here are "$" and "_"
;			 default is "$"
; History:
;	RCJ 03/30/01 - Modified so this function works for array of strings too.
;			And initialized found=0L instead of 1L. Found becomes
;			1L if a bad char is replaced in a string.
;	RCJ 03/06/02 - Added code to check for strings starting in numbers.
;			Structure names cannot start with a number in IDL5.3,
;			and we were getting errors in spd_cdawlib_read_mycdf.
;
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------

function spd_cdawlib_replace_bad_chars, instring, repchar=repchar, found

badChars=['\','/','.','%','!','@','#','^','&','*','(',')','-','+','=', $
   '`','~','|','?','<','>',' ']

if not keyword_set(repchar) then repchar = "$"

if not(repchar eq "$" or repchar eq "_") then repchar = "$"

found = 0L

outstring = instring

;TJK 10/26/2005 - moved this section down below into the case statement
;if (strupcase(instring) eq 'FUNCTION') then begin
;  outstring = 'FUNCT'
;  found = 1L
;;  print, 'changing FUNCTION to FUNCT'
;  return, outstring
;endif

case (strupcase(instring)) of
    'FUNCTION': begin
            outstring = 'FUNCT'
            found = 1L
;            print, 'changing FUNCTION to FUNCT'
            return, outstring
          end
    'NE': begin
            outstring = 'NE$'
            found = 1L
            print, 'changing NE to NE$'
            return, outstring
        end
     'EQ':begin
            outstring = 'EQ$'
            found = 1L
            print, 'changing EQ to EQ$'
            return, outstring
          end
      else:
endcase      



for i=0,n_elements(instring)-1 do begin
   for k=0L,n_elements(badChars)-1 do begin
      outstring[i]=repchr(outstring[i],badChars[k],repchar)
   endfor
   if (instring[i] ne outstring[i]) then found = 1L
endfor

badnums=['0','1','2','3','4','5','6','7','8','9']

for i=0,n_elements(outstring)-1 do begin
   for k=0L,n_elements(badnums)-1 do begin
      if (strmid(outstring[i],0,1) eq badnums[k]) then outstring[i]='CDAW_'+outstring[i]
   endfor
   if (instring[i] ne outstring[i]) then found = 1L
endfor

return, outstring
end

