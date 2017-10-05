;Author: johnson $
;Date: 2012/05/02 21:29:57 $
;Header: /home/cdaweb/dev/control/RCS/TAGindex.pro,v 1.4 2012/05/02 21:29:57 johnson Exp johnson $
;Locker: johnson $
;Revision: 1.4 $
; Search the tnames array for the instring, returning the index in tnames
; if it is present, or -1 if it is not.
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
FUNCTION spd_cdawlib_tagindex, instring, tnames
;TJK 3/7/2000 change this to strip instring of any blanks since
;its possible that a variable name can have trialing blanks in it (new
;cdaw9 cdfs).
instring = STRUPCASE(strtrim(instring,2)) ; tagnames are always uppercase
a = where(tnames eq instring,count)
if count eq 0 then return, -1 $
else return, a[0]
end
