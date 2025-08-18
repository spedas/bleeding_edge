
;helper function
; Removes trailing zeros and/or decimal from string,
; Assumes trailing spaces have already been removed.
; if ideallen is given it will not reduce the length less than this (0 is not valid)
function remove_zeros, sval, ideallen=ideallen

    compile_opt idl2, hidden
  
  f = stregex(sval, '\.?0*$',length=len)
  if keyword_set(ideallen) then begin
    if (strlen(sval)-len) lt ideallen then begin
      newstr = strmid(sval, 0, ideallen )
      ; if this results in string ending in '.' then add in a space instead
      if strmid(newstr,strlen(newstr)-1,1) eq '.' then newstr=strmid(newstr,0,strlen(newstr)-1)+' '
      return, newstr
    endif else return, strmid(sval, 0, (strlen(sval)-len) )
  endif else return, strmid(sval, 0, (strlen(sval)-len) )

end

function remove_leading_F, sval
  sval = strtrim(sval)
  if strlen(sval) le 8 then return, sval
  if strmid(sval, 0, 4) eq 'FFFF' then begin
        sval = strmid(sval, 4, strlen(sval)-1)
  endif
  if strmid(sval, 0, 4) eq 'FFFF' then begin
    sval = strmid(sval, 4, strlen(sval)-1)
  endif
  return, sval
end

;+
;FUNCTION:
;  formatannotation
;
;PURPOSE:
;  This routine is used as a callback for axis labeling by IDLgrAxis
;  Because it is a callback routine, IDL requires it to have this specific form.
;  It is probably useful as a general purpose formatting routine, as well.
;   
;Inputs:
;Axis:Required by IDL, but ignored
;Index: Required by IDL, but ignored
;Value: Required The value to be formatted.
;Data:  Keyword,Required
;  The data struct holds the important information and has the following format:
;  data = {timeAxis:0B,  $ ;Should we format as time data?
;        formatid:0L,  $ ;Precision of returned value in sig figs 
;        scaling:0B,   $ ;0:Linear,1:Log10,2:LogN
;        exponent:0B,  $ ;(REQUIRED for non-time data)0:Auto-Format(see description),1:Numerical(double),2:Sci-Notation(1.2x10^3)
;        range:[0D,0D],$ ; The range field is optional.  If it is present in the struct, value will be interpreted a multiplier over the specified range.(generally this is used if the data is being stored as a proportion)
;        noformatcodes:0b,$ ; Optional, set to 1 to disable IDL formatting codes like !U
;        maxexplen:0L,$ ; Optional, if present and not equal -1 then exponents will be formatted to this length
;        negexp:0B} ; Optional, if present 1 indicates presence of a negative exponent on axis (only considered if maxexplen is also set and not -1)
;Auto-Format:
;If the number being formatted is too large or small to be displayed with the requested number of
;  significant figures then the number will be automatically displayed in scientific notation
;  (e.g. for 3 sig. figs '1234.5' will be shown as '1.23x10^3' and '.00012345' will be shown as '1.23x10^-4') 
;Values in log_10() space will be displayed as '10^1.2'
;Values in ln() space will be displayes as 'e^1.2'
;Integer formatting is not effected.
;
;Formatting Codes:
;Formatting codes are utilized to create superscripts and unicode characters that are displayd
;by IDLgraxis:
;  !z(00d7): Unicode multiplication symbol
;  !U      : Superscripts the following substring  
;
;Example:
;  print,formatannotation(0,0,1,data={timeaxis:0,formatid:7,scaling:0,exponent:0})
;  1.000000
;  print,formatannotation(0,0,.5,data={timeaxis:1,formatid:12,scaling:0,range:[time_double('2007-03-23'),time_double('2007-03-24')]})
;  082/12:00:00.000
;  print,formatannotation(0,0,4,data={timeaxis:0,formatid:5,scaling:2,exponent:0})
;  e!U4.0000
;  print,formatannotation(0,0,.25,data={timeaxis:0,formatid:5,scaling:1,range:[1,2],exponent:0})
;  10!U1.2500
;  print,formatannotation(0,0,1234,data={timeaxis:0,formatid:7,scaling:0,exponent:2})
;  1.234000!z(00d7)10!U3
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-06-05 10:01:44 -0700 (Thu, 05 Jun 2014) $
;$LastChangedRevision: 15308 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/formatannotation.pro $
;-
function formatannotation,axis,index,value,data=data
 
  compile_opt idl2
  
  str_element,data,'noformatcodes',noformatcodes,success=s
 
  if s eq 0 then begin
    noformatcodes = 0
  endif
  
  ;check if maxexplen is defined
  str_element,data,'maxexplen',maxexplen,success=s
 
  if s eq 0 then begin
    maxexplen = -1
  endif
    ;check if negexp is defined
  str_element,data,'negexp',negexp,success=s
 
  if s eq 0 then begin
    negexp = 0; nothing is done if no negative exponents are indicated
  endif
  
  ;CONSTANTS
  months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  
  if noformatcodes then begin
    expformat = '^'
    sciformat = 'e'
  endif else begin
    expformat = '!U'
    sciformat = '!3x!X10!U'
  endelse
  
;  numLimit = 10000000000
   roundingfactor = 1d-15
  
  ;print,value
  ;help,data,/str


  if finite(value,/nan) then begin
    ;print,strtrim(string(value))
    return,strtrim(string(value))
  endif 


  ; Range and rounding
  if in_set('range',strlowcase(tag_names(data))) then begin

    
     val = (value + data.range[0]/(data.range[1]-data.range[0]))*(data.range[1]-data.range[0])
     ;round values near 0
     relativecuttoff = (data.range[1]-data.range[0])*roundingfactor
     if val le relativecuttoff && val ge -relativecuttoff then begin
       val = 0
     endif
     ; the following code will round annotations like 999999 to 1000000 on non-time axes
     if ~data.timeaxis then begin
         rval = round(val)
         if abs(val - rval) lt roundingfactor then val = rval
     endif
  endif else begin
    val = value
  endelse
  
  
  ;Calculate real space value if necessary
  oval = 1d*val
  if data.scaling eq 1 then begin
    val = 10d^val
  endif else if data.scaling eq 2 then begin
    val = 1d*exp(val)
  endif else begin
    val = 1d*val
  endelse

  if ~finite(val) then begin
  ;  print,strtrim(string(val))
    return,strtrim(string(val))
  endif 


;  if in_set('formatstyle',strlowcase(tag_names(data))) then begin
;    formatstyle = data.formatstyle
;  endif else begin
;    formatstyle = 0
;  endelse


  ;correction factor for variation in exponential
  ;format across OS's (no longer necessary)
  ;format on Linux/Unix/OSX = '2.E+00'
  ;format on Windows = '2.E+000'
;  if !VERSION.OS_FAMILY eq 'Windows' then begin
;    os = 1
;  endif else begin
;    os = 0
;  endelse



;***************************
;Time Annotation Formatting
;***************************
  if data.timeAxis then begin
    
    ;round to nearest millisecond
    tm = (val - floor(val))*1000d
    val = floor(val) + round(tm)*10d^(-3)
    
    ts = time_struct(val)
    
    ;account for time_struct allowing fractional sec = 1
    ;this should take care of incrimenting other fields 
    ;(sec, min, hour, day, etc)
    if ts.fsec ge 1d then begin
      td = time_double(ts)
      ts = time_struct(td)
    endif
    
    if data.formatid eq 0 then begin
      return,string(ts.year,format='(I4.4)') + '-' + $
             months[ts.month-1] +'-'+ $
             string(ts.date,format='(I2.2)')
    endif else if data.formatid eq 1 then begin
      return,string(ts.year,format='(I4.4)') + '-' + $
             months[ts.month-1] +'-'+ $
             string(ts.date,format='(I2.2)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)')
    endif else if data.formatid eq 2 then begin
      return,string(ts.year,format='(I4.4)') + '-' + $
             months[ts.month-1] +'-'+ $
             string(ts.date,format='(I2.2)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)')
    endif else if data.formatid eq 3 then begin
      return,string(ts.year,format='(I4.4)') + '-' + $
             months[ts.month-1] +'-'+ $
             string(ts.date,format='(I2.2)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)') + '.' + $
             string(ts.fsec*1000,format='(I3.3)')
    endif else if data.formatid eq 4 then begin
      return,string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)')
    endif else if data.formatid eq 5 then begin
      return,string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)')    
    endif else if data.formatid eq 6 then begin
      return,string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)') + '.' + $ 
             string(ts.fsec*1000,format='(I3.3)')
    endif else if data.formatid eq 7 then begin
      return,string(ts.month,format='(I2.2)') + ':' + $
             string(ts.date,format='(I2.2)')
    endif else if data.formatid eq 8 then begin
      return,string(ts.month,format='(I2.2)') + '-' + $
             string(ts.date,format='(I2.2)')+ '/' + $        
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)')
    endif else if data.formatid eq 9 then begin
      return,string(ts.doy,format='(I3.3)')
    endif else if data.formatid eq 10 then begin
      return,string(ts.doy,format='(I3.3)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)')
    endif else if data.formatid eq 11 then begin
      return,string(ts.doy,format='(I3.3)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)')
    endif else if data.formatid eq 12 then begin
      return,string(ts.doy,format='(I3.3)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)') + '.' + $
             string(ts.fsec*1000,format='(I3.3)')
    endif else if data.formatid eq 13 then begin      
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.doy,format='(I3.3)')
    endif else if data.formatid eq 14 then begin  
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.doy,format='(I3.3)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)')
    endif else if data.formatid eq 15 then begin  
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.doy,format='(I3.3)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)')
    endif else if data.formatid eq 16 then begin
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.doy,format='(I3.3)') + '/' + $
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)') + '.' + $ 
             string(ts.fsec*1000,format='(I3.3)')
    endif else if data.formatid eq 17 then begin ;jmm, 9-may-2011
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.month, format = '(I2.2)') + '-' + $
             string(ts.date,format='(I2.2)')+ '/' + $        
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)')
    endif else if data.formatid eq 18 then begin ;jmm, 9-may-2011
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.month, format = '(I2.2)') + '-' + $
             string(ts.date,format='(I2.2)')+ '/' + $        
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)') + '.' + $
             string(ts.fsec*1000,format='(I3.3)')
    endif else if data.formatid eq 19 then begin ;jmm, 9-may-2011
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.month, format = '(I2.2)') + '-' + $
             string(ts.date,format='(I2.2)')+ 'T' + $        
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)')
    endif else if data.formatid eq 20 then begin ;jmm, 9-may-2011
      return,string(ts.year,format='(I4.4)') + '-' + $
             string(ts.month, format = '(I2.2)') + '-' + $
             string(ts.date,format='(I2.2)')+ 'T' + $        
             string(ts.hour,format='(I2.2)') + ':' + $
             string(ts.min,format='(I2.2)') + ':' + $
             string(ts.sec,format='(I2.2)') + '.' + $
             string(ts.fsec*1000,format='(I3.3)')
     endif else begin
       ok = error_message('Illegal annotation format',/traceback)
       return,''
     endelse


  endif else begin
  
;**************************
;Data Annotations Formating
;**************************
 
 
    ;Initializations for formatting    
    prefix = ''
    suffix = ''
    neg=0
    dec=0
    use_oval = 0
    precision = data.formatid-1 > 0  ;desired decimal precision (1 less than sig figs)
    negzero = ( (val eq 0) && (strmid(strtrim(val,1),0,1) eq '-') ) ? 1:0


    ;Determine format type:
    ;---------------------
    ;The type of annotation to be returned is chosen below by setting the 'type' variable.
    ;0 - numerical format
    ;1 - sci-notation (also requires expsign=1 or -1)
    ;2 - e^x format
    ;3 - 10^x format

    spd_ui_usingexponent,val,data,type=type,expsign=expsign
  
    ;if an error occurred return
    if type eq -1 then return,''



    ;Handle double format
    ;--------------------
    if type eq 0 then begin
      
      spd_ui_getlengthvars, val, dec, neg
    
      if data.formatid eq 0 then begin
        formatString = '(I' + strtrim(string(neg+dec,format='(I)'),2)+')'
        if precision lt dec then precision = dec < 9
      endif else begin
      
        ;use sig figs for consistancy with sci. not. if on auto-format
        if data.exponent eq 0 then begin
          p0 = abs(val) lt 1 ? 1:0
          prec = ((precision+1-dec+p0) > 0)
        endif else begin
          prec = precision
        endelse

        ;increment length if rounding will add digit
        check_dround, val, neg, dec, prec
        
        formatString = '(D' + strtrim(string(negzero+neg+dec+1+prec,format='(I)'),2)+$
                         '.' + strtrim(prec,2)+')'
      endelse
      
      
      
    ;Handle exponential (sci-notation) format
    ;----------------------------------------
    endif else if type eq 1 then begin
      
      spd_ui_getlengthvars, val, dec, neg
      
      if val eq 0 then $
        return, remove_zeros(string(val,format='(D'+strtrim(precision+2+negzero)+'.'+strtrim(precision)+')'))
      
      ;determine exponent (1,-1, 0)
      if expsign eq -1 then begin
        esign = '-'
        exponent = ceil(abs(alog10(abs(val))))
      endif else if expsign eq 1 then begin
        esign = ''
        exponent = floor(abs(alog10(abs(val))))
      endif else if expsign eq 0 then begin
        esign = ''
        exponent = 0
      endif
      
      val = val * (10d^exponent)^(-expsign)
  
      if ~finite(val) then return,strtrim(string(val))
  
      ;increment length if rounding will add digit
      check_eround, val, neg,dec, precision, exponent,expsign
      
      ;add desired exponent string
      if abs(val) ge 0 and abs(val) lt 10 then begin
        if maxexplen ne -1 and negexp eq 1 then begin;if needed add space at beginning to compensate for other annotations having neg exponent
          exponent = strtrim(exponent,2)
          if esign ne '-' then exponent=' '+exponent
          suffix = sciformat + esign + exponent
        endif else suffix = sciformat + esign + strtrim(exponent,2)
      endif else begin
        ;print, 'FormatAnnotation: Error creating exponent!'
        return,''
      endelse
      
      if data.formatid eq 0 then begin
        formatString = '(I' + strtrim(string(neg+dec,format='(I)'),2)+')'
      endif else begin
        formatString = '(D' + strtrim(string(neg+precision+2,format='(I)'),2)+'.' + $
                         strtrim(precision,2) + ')'
      endelse
    
    
    
    ;Handle e^x format
    ;(number should still be in ln() space at this point)
    ;---------------------------------------------------
    endif else if type eq 2 then begin
    
      if finite(oval, /infinity) then begin
        if oval lt 0 then $
          return, remove_zeros(string(0d,format='(D'+strtrim(precision+2)+'.'+strtrim(precision)+')')) $
            else return, 'Infinity'
      endif 
    
      spd_ui_getlengthvars, oval, dec, neg
      use_oval = 1
      
      ;increment length if rounding will add digit to exponent
      check_dround, oval, neg, dec, precision
  
      prec = ((precision+1-dec) > 0)
      formatString = '(D' + strtrim(string(neg+dec+prec+1+negzero,format='(I)'),2)+'.' + $
                       strtrim(prec,2) + ')'
  
      prefix = 'e' + expformat
      
  
  
    ;Handle 10^x format
    ;(number should still be in log_10() space at this point)
    ;-------------------------------------------------------
    endif else if type eq 3 then begin
    
      if finite(oval, /infinity) then begin
        if oval lt 0 then $
          return, remove_zeros(string(0d,format='(D'+strtrim(precision+2)+'.'+strtrim(precision)+')')) $
            else return, 'Infinity'
      endif 
      
      spd_ui_getlengthvars, oval, dec, neg
      use_oval = 1
  
      ;increment length if rounding will add digit to exponent
      check_dround, oval, neg, dec, precision
  
      prec = ((precision+1-dec) > 0)
      formatString = '(D' + strtrim(string(neg+dec+prec+1+negzero,format='(I)'),2)+'.' + $
                       strtrim(prec,2) + ')'
  
      prefix = '10' + expformat
      
    ; Hexadecimal format
    endif else if type eq 4 then begin 
   
      typecode=size(val,/type)
 
      if typecode eq 1 then begin  ; byte
        strvalue = strtrim(string(val,FORMAT='(Z2)'))       
      endif else if typecode eq 2 then begin ; int
        strvalue = strtrim(string(val,FORMAT='(Z4)'))     
      endif else if typecode eq 3 then begin ; long
        strvalue = strtrim(string(val,FORMAT='(Z8)'))     
      endif else begin  ; any other type
        strvalue = strtrim(string(val,FORMAT='(Z16)'))     
      endelse      
      
      ;return, remove_leading_F(strvalue) ;we should use this if we want to clip the leading FFFF FFFF (it happens with negative values)
      return, strvalue
      
    endif else begin
      ok = error_message('Illegal annotation type',/traceback)
      return,''
    endelse 
  
  
  
    ;Check that the format did not exceed max length and
    ;return formatted number
    ;----------------------------------
    if stregex(formatstring, '[0,1,2,3,4,5,6,7,8,9]+',/extract) ge 255 then return, 'Overflow'
  
;    if stregex( string(val,format=formatString), '[*]+', /bool) then begin
;      print, val, formatstring
;      stop
;    endif

    if maxexplen ne -1 then begin ;if annotation has an exponent and we are trying to line up annotations
      if use_oval then begin
        mainstr = string(oval,format=formatString)
        ; if some annotations on axis are negative add a space to nonneg ones so that the annotations aline correctly
        if negexp eq 1 then begin
          if strmid(mainstr,0,1) ne '-' then mainstr=' '+mainstr
        endif
        return, prefix + remove_zeros(mainstr,ideallen=maxexplen) + suffix 
      endif else begin ; in this case the exponent is in the suffix, adding space for nonneg exp is handled earlier in code
        if data.formatid eq 0 then return, prefix + string(val,format=formatString) + suffix
        return, prefix + remove_zeros(string(val,format=formatString)) + suffix
      endelse
    endif else begin
      if use_oval then begin
        return, prefix + remove_zeros(string(oval,format=formatString)) + suffix 
      endif else begin
        if data.formatid eq 0 then return, prefix + string(val,format=formatString) + suffix
        return, prefix + remove_zeros(string(val,format=formatString)) + suffix
      endelse
    endelse

  
  endelse ;end data formatting

end

