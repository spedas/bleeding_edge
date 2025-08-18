;+
;NAME:  cdf_var_atts
;FUNCTION:   cdf_var_atts(id [,var[,attname]])
;PURPOSE:
;  Returns a structure that contains all the attributes of a variable within
;  a CDF file. If attname is provided then it returns the value of only that attribute.
;KEYWORDS:
;  DEFAULT: The default value of the attribute.
;  ATTRIBUTES=att  A named variable that returns an array of structures containing attribute info
;                  if this variable is passed in on subsequent calls to cdf_var_atts it can significantly
;                  improve performance.   OBSOLETE!!!
;USAGE:
;   atts = cdf_var_atts(file)  ; returns structure containing all global attributes
;   atts = cdf_var_atts(file
;INPUT:
;   id:         CDF file ID or filename.
;   var;        CDF variable name or number
;   attname:    CDF attribute name
;CREATED BY:    Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2020-05-04 17:46:15 -0700 (Mon, 04 May 2020) $
; $LastChangedRevision: 28667 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/cdf_var_atts2.pro $
;-

function  cdf_var_atts2,id0,var,attname,default=default,zvar=zvar, $
     convert_int1_to_int2=convert_int1_to_int2

if size(/type,id0) eq 7 then id=cdf_open(id0) else id=id0
t0=systime(1)
attstr = n_elements(default) ne 0 ? default : orderedHASH()  ; Define  default return value

quiet = !quiet
!quiet =  keyword_set(convert_int1_to_int2)  ; and !quiet

inq = cdf_inquire(id)

if n_elements(var) eq 0 then begin     ; Get all global attributes
    cdf_control,id,get_numattrs=na
    for a=0,na[0]+na[1]-1 do begin
        cdf_attinq,id,a,name,scope,maxent
        if strmid(scope,0,1) ne 'G' then continue   ;message,'Bad scope'
        gentry=0
        value = !null
        while( cdf_attexists(id, a, gentry) ) do begin
          cdf_attget, id, a, gentry, value_new
          value = [value,value_new]
          gentry = gentry+1
        endwhile
        if gentry eq 1 then value=value[0]
        attstr[name] = value        
      endfor
endif else begin      ; Get variable attributes
    varn = size(/type,var) eq 7 ? cdf_varnum(id,var,zvar) : var   ; use variable number to improve performance

    if keyword_set(attname) then begin   ; Get only one attribute
        if cdf_attexists(id,attname,varn,zvar=zvar) then cdf_attget,id,attname,varn,zvar=zvar,attstr
    endif else begin   ; Get a structure containing all variable attributes
        for a=0,inq.natts-1 do begin
            cdf_attinq,id,a,name,scope,maxent
            if strmid(scope,0,1) ne 'V' then continue   ;message,'Bad scope'
            if cdf_attexists(id,a,varn,zvar=zvar) then begin
                if keyword_set(names_only) then begin
                    if keyword_set(attstr) then attstr=[attstr,name] $
                    else attstr=name
                endif else begin
                    cdf_attget,id,a,varn,zvar=zvar,value,cdf_type=cdf_type
                    if  keyword_set(convert_int1_to_int2) and (cdf_type eq 'CDF_INT1') then begin
                        dprint,dlevel=4,'Warning converting attribute from INT1 to INT2'
                        value = value - (value ge 128) * 256
                    endif
                    if size(/type,value) eq 7 then if  strpos(value,'>$<') ge 1 then $
                        value = strsplit(/extract,value,'>$<')  ; break strings into arrays if separater token is found
                  ;  name = idl_validname(name,/convert_all)
                    attstr[name] = value
                endelse
            endif
        endfor

    endelse

endelse
done:

!quiet = quiet
;dprint,dlevel=8,format='(f8.3," secs to read attribute: ",a)',systime(1)-t0,n_elements(var) ne 0 ? string(var) : ''

if size(/type,id0) eq 7 then cdf_close,id
return,attstr

end


