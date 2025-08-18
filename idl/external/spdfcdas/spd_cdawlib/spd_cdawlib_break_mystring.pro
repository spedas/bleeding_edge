;Author: johnson $
;Date: 2012/05/03 16:10:43 $
;Header: /home/cdaweb/dev/control/RCS/break_mySTRING.pro,v 1.4 2012/05/03 16:10:43 johnson Exp johnson $
;Locker: johnson $
;Revision: 1.4 $
;+------------------------------------------------------------------------
; NAME: BREAK_MYSTRING
; PURPOSE: 
;       Convert a string into a string array given a delimiting character 
; CALLING SEQUENCE:
;       out = break_mystring(instring)
; INPUTS:
;       instring = input text string
; KEYWORD PARAMETERS:
;       delimiter = character to parse by.  Default = ' '
; OUTPUTS:
;       out = string array
; AUTHOR:
;       Jason Mathews, NASA/GSFC/Code 633,  June, 1994
;       mathews@nssdc.gsfc.nasa.gov    (301)286-6879
; MODIFICATION HISTORY:
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
;
FUNCTION spd_cdawlib_break_mystring, s, DELIMITER=delimiter
; Validate the input parameters
s_size=size(s) & n_size=n_elements(s_size)
if (s_size[(n_size - 2)] ne 7) then begin
  print,'ERROR>Argument to spd_cdawlib_break_mystring must be of type string'
  return,-1
endif
if s eq '' then return, [ '' ]
if n_elements(delimiter) eq 0 then delimiter = ''
; dissect the string
byte_delim = Byte( delimiter ) ; convert string to byte delimiter
result = Where( Byte(s) eq byte_delim[0], count ) ; count occurences
result = StrArr( count+1 ) & pos = -1
if (count gt 0) then begin
  for i=0, count-1 do begin
    oldpos = pos + 1
    pos = StrPos(s, delimiter, oldpos)
    result[i] = StrMid(s, oldpos, pos-oldpos)
  endfor
endif
pos = pos + 1
result[count] = StrMid( s, pos, StrLen(s) - pos )
return, result
end


