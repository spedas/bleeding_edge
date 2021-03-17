;+
;FUNCTION:   minmax,array
;PURPOSE:  returns a two element array of min, max values
;INPUT:  array
;KEYWORDS:
;  MAX_VALUE:  ignore all numbers greater than this value
;  MIN_VALUE:  ignore all numbers less than this value
;  POSITIVE:   forces MINVALUE to 0
;
;CREATED BY:    Davin Larson
;LAST MODIFICATION:     @(#)minmax.pro	1.2 02/04/17
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-16 13:00:06 -0800 (Wed, 16 Dec 2020) $
; $LastChangedRevision: 29505 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/minmax.pro $

;-
;  MXSUBSCRIPT:  Named variable in which maximum subscript is returned NOT WORKING

function minmax,tdata,  $
   MAX_VALUE = max_value,  $ ; ignore all numbers >= max_value
   MIN_VALUE = min_value,  $ ; ignore all numbers <= min_value
   POSITIVE = positive, $   ;  forces min_value to 0
   absolute = absolute, $   ;  looks at only absolute value of inputs
   SUBSCRIPT_MIN = subscript_min, $   ; Not yet implemented
   SUBSCRIPT_MAX = subscript_max, $   ; Not yet implemented
   NAN = nan, $   ; Not yet implemented
   MXSUBSCRIPT=subs

on_error,2
if keyword_set(positive) then min_value = 0

dtype = size(/type,tdata)
badreturn = make_array(2,type=dtype)

w = where(finite(tdata),count)
if count eq 0 then return,badreturn
data = tdata[w]

if keyword_set(absolute) then begin
  data = abs(data)
endif


if n_elements(max_value) then begin
   w = where( data lt max_value ,count)
   if count eq 0 then return,badreturn
   data = data[w]
endif

if n_elements(min_value) then begin
   w = where( data gt min_value, count)
   if count eq 0 then return,badreturn
   data = data[w]
endif


mx = max(data,MIN=mn)
return,[mn,mx]
end

