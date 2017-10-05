;+
;FUNCTION:
;  spd_ui_usingexponent
;
;PURPOSE:
;
;  Used to determine if any of a set of inputs will be put into exponential notation
;   
;Inputs:
;The data struct is an input to format annotation
;data.exponent values:
;0: autoformat
;1: decimal
;2: scientific
;3: base^x
;
;
;
;4: hexadecimal
;
;Outputs:
;Determine format type:
;---------------------
;The type of annotation to be returned is chosen below by setting the 'type' variable.
;0 - numerical format
;1 - sci-notation (also requires expsign=1 or -1)
;2 - e^x format
;3 - 10^x format
;
;Example:
;
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_usingexponent.pro $
;-

pro spd_ui_usingexponent,val,data,type=type,expsign=expsign

  compile_opt idl2,hidden

  lengthLimit=64 ;more decimal places than this is absurd
  neg=0
  dec=0
  precision = data.formatid-1 > 0  ;desired decimal precision

; This has to be 4 but then something else has to be set first

  if ~in_set('exponent',strlowcase(tag_names(data))) then $
    data = create_struct(data,'exponent',0b)

;Auto-Format
  if data.exponent eq 0 then begin

    spd_ui_getlengthvars, val, dec, neg
    check_dround, val, neg, dec, precision

    ;Check large values against precision
    if abs(val) ge 1 or val eq 0 then begin
      if dec gt (precision+1) then begin
        if data.scaling eq 1 then type = 3 else begin
          type = 1
          expsign = 1
        endelse
      endif else type = 0
    ;Check small values against precision
    endif else if val ne 0 then begin
      if ceil(abs(alog10(abs(val)))) gt (precision+1) then begin
        if data.scaling eq 1 then begin
          type = 3 
        endif else begin
          type = 1
          expsign = -1
        endelse
      endif else type = 0
    endif else begin
      dprint,  'Uncertain auto-format'
      type = -1
      return
    endelse
    
    ;Handle log scaling and integer type
    if data.scaling eq 2 then type = 2

;    if data.scaling eq 1 then type = 3
    if data.formatid eq 0 then type = 0
;Fix to double format
  endif else if data.exponent eq 1 then begin
    type = 0
;Fix to exponential format
  endif else if data.exponent eq 2 then begin
    type = 1
    if abs(val) ge 1 then begin
      expsign = 1
    endif else if val eq 0 then expsign = 0 $ 
      else expsign = -1
  endif else if data.exponent eq 3 then begin
    type = 3
  endif else if data.exponent eq 4 then begin 
    type = 4
  endif
  
 ;If double format will exceed length limit then switch to exponential
  if type eq 0 then begin
    if ((neg+dec) gt lengthLimit and data.formatid eq 0) $
      or ((neg+1+(precision+1)) gt lengthLimit) $
        then begin 
          type = 1
          if abs(val) ge 1 then begin
            expsign = 1
          endif else if val eq 0 then expsign = 0 $ 
            else expsign = -1
    endif
  endif 

end
