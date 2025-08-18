;+
;PROCEDURE:
;  TPLOT_ADD_CDF_STRUCTURE, tplot_vars, ...
;   
;PURPOSE:  
;  In order to be saved in CDF file using TPLOT2CDF, tplot variable must have CDF
;  structure as a tplot option (see OPTIONS) 
;  The attributes of the tplot data (x, y or v) are stored in the CDF structure
;  CDF.VARS     - structure of attributes that describe the data (tplot y variable)
;  CDF.DEPEND_0 - structure of attributes that describe the time (tplot x variable)
;  CDF.DEPEND_1 - structure of attributes that supporting data (tplot v or v1 variable)
;  CDF.DEPEND_2 - structure of attributes that supporting data (tplot v2 variable)
;  CDF.DEPEND_3 - structure of attributes that supporting data (tplot v3 variable)
;  
;  Each structure of attributes must have following fileds:
;  CATDESC, DISPLAY_TYPE ,FIELDNAM, LABLAXIS, UNITS (automatically defined for time), VAR_TYPE
;  FILLVAL, VALIDMIN, VALIDMAX, FORMAT defined based on the nature of the data
;  
;  If CDF structure already defined in the tplot variable the defined fields of 
;  the CDF strucutre will remane the same. This means, if there was any mistake 
;  (e.g. wrong Epoch format), then CDF structure must be recreated (for example, using /new keyword).  
;  
;  TPLOT_ADD_CDF_STRUCTURE adds appropriate CDF structure and defines some of the attributes base on the tplot data
;  This procedure must be called before tplot2cdf. Alternatively, keyword /default of tplto2cdf2 can be used.
;  Most of the attributes are defined as 'undefined' ans should be specify.  
;  
;  If tplot has 2d y, but variable v, that suppose to describe second dimension 
;  is absent, then v will be created as an index of the second dimension of y
;  If "labels" field is found in metadata (dlimits.lables) of the tplot variable and if number of elements 
;  along second dimention of y is the same as number of labels, then v variable
;  will be prepared to be LABL_PTR_1. 
;  TPLOT_ADD_CDF_STRUCTURE supports only LABL_PTR_1 (one label pointer) case. 
;   
;  If tplot has n-d y but number of dimensions does not correspond to number or 
;  supporting variables (x, v or v1, v2 ...) then extra supporting variables (v1, v2 ...) will be removed.
;  This behaivour ensures the saving of the tplot into CDF file. 
;  
;  If tplot variable has only x, then data variable y = x will be created. 
;   
;INPUT:
;   tplot_vars: (string or array of strings) Tplot variable name, or list of the tplot variables  
;   
;KEYWORDS:
;   TT2000: (flag) Indicates that time should be included as TT2000
;           If x type is double, x will be converted to LONG64 using CDF_PARSE_TT2000
;   NEW: (flag) Create new CDF structure or ignore existing CDF structure
;
;EXAMPLES:   
;   store_date, 'example_tplot',data={x:time_double('2001-01-01')+[1, 2, 3],y:[10, 20, 30]}
;   tplot_add_cdf_structure, 'example_plot'  
;   tplot2cdf, filename='example_cdf_file', tvars='example_plot'
;  
;  See crib_tplot2cdf_basic for additional examples 
;
;CREATED BY:
;  Alexander Drozdov
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2023-06-05 13:04:09 -0700 (Mon, 05 Jun 2023) $
; $LastChangedRevision: 31884 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/tplot_add_cdf_structure.pro $
;-

pro tplot_add_cdf_structure, tplot_vars, tt2000=tt2000, new=new

  compile_opt idl2
  ; resolve dependences
  FORWARD_FUNCTION cdf_default_vars_structure, cdf_default_vars_structure
  RESOLVE_ROUTINE, 'cdf_default_cdfi_structure', /IS_FUNCTION, /NO_RECOMPILE

  for i=0,n_elements(tplot_vars)-1 do begin
    get_data,tplot_vars[i],data=d,alimits=s
    
    if is_struct(s) then t = STRUPCASE(TAG_NAMES(s)) else t = ''
           
    ; get original structure if exist
    if array_contains(t, 'CDF') and ~KEYWORD_SET(new) then cdf_struct = s.cdf else cdf_struct = {}
    vars = cdf_default_vars_structure()
    depend_0 = cdf_default_vars_structure()
    
    ; extract data (up to 4D arrays)
    str_element,d,'x',value=x
    str_element,d,'y',value=y
    str_element,d,'v',value=v            
    str_element,d,'v1',value=v1
    str_element,d,'v2',value=v2
    str_element,d,'v3',value=v3
    if ~is_struct(d) then x = d
    
    ; extract metadata
     metadata = spd_extract_tvar_metadata(tplot_vars[i])
     
     if ~is_struct(metadata) then continue
    
    ; Getting additional metadata
    if array_contains(t, 'DATA_ATT') then data_att_t = STRUPCASE(TAG_NAMES(s.DATA_ATT)) else data_att_t = ''
    
    ; determine if coordinate system is defined
    str_element,metadata,'COORDINATE_SYSTEM','' ,/add
    if array_contains(data_att_t, 'COORD_SYS') then str_element,metadata,'COORDINATE_SYSTEM',s.DATA_ATT.COORD_SYS ,/add
    if array_contains(data_att_t, 'COORDINATE_SYSTEM') then str_element,metadata,'COORDINATE_SYSTEM',s.DATA_ATT.COORDINATE_SYSTEM ,/add        
    
    ; cases:
    ; d is an array
    ; d has x
    ; d has x and y
    ; d has x and 2d y but no v
    ; d has x and y and 1d v     
    ; d has x and y and 2d v
    
; === CDF_EPOCH ===    
    if ~undefined(x) then begin
      depend_0.name = 'Epoch'
      attr = *depend_0.attrptr
      if KEYWORD_SET(tt2000) then begin
      ; Convert time to tt2000 if double is detected  
      if  size(x,/type) eq 5 then begin ; double x detected
        x = CDF_PARSE_TT2000(time_string(x,tformat='YYYY-MM-DDThh:mm:ss.fffffffff')) ; convert to TT2000       
        ;save modified tplot        
        dt = CREATE_STRUCT('x',x) ; create structure with new time         
        if ~is_struct(d)  then d = CREATE_STRUCT('x',x) ; create, or recreate structure
        extract_tags,d,dt ; we use extract_tags to copy dt.x to structure d, which comes from tplot 
        store_data,tplot_vars[i],data=d ; save new data into tplot var                 
      endif else begin
        if size(x,/type) ne 14 then dprint,'Warning: x type is not LONG64 as requred by TT2000',dlevel=1        
      endelse
      
      depend_0.datatype = 'CDF_TIME_TT2000'
      str_element,attr,'FILLVAL',-9223372036854775808LL ,/add
      str_element,attr,'VALIDMIN',CDF_PARSE_TT2000('1990-01-01T00:00:00.000000000') ,/add
      str_element,attr,'VALIDMAX',CDF_PARSE_TT2000('2100-01-01T00:00:00.000000000') ,/add
      attr.FORMAT = ' '
      attr.UNITS  = 'ns'              
      str_element, attr,'TIME_BASE','J2000',/add  ; Additional attibute is added for netCDF files
      endif else begin        
      if size(x,/type) ne 5 then dprint,'Warning: x type is not double. You may expect error using tplot2cdf. CDF structure must be recreated. Use /new flag to create new CDF strucure',dlevel=1      
      depend_0.datatype = 'CDF_EPOCH'                 
      str_element,attr,'FILLVAL',-1.0d31 ,/add
      str_element,attr,'VALIDMIN',0.0d ,/add
      str_element,attr,'VALIDMAX',time_epoch('9999-12-31:23:59:59.999'),/add
      attr.FORMAT = ' '
      attr.UNITS  = 'ms'      
      str_element, attr,'TIME_BASE','0AD',/add  ; Additional attibute is added for netCDF files
      end
      
      depend_0.attrptr = ptr_new(attr)  
    endif
    
; === CDF_EPOCH16 is disabled ===    
;    if ~undefined(x) then begin
;      depend_0.name = 'Epoch'      
;      depend_0.datatype = 'CDF_EPOCH16'
;      tformat = 'YYYY-MM-DD:hh:mm:ss.ffffffffffff'            
;      depend_0.attrptr = ptr_new(CREATE_STRUCT($
;         'FILLVAL',-1.0E31,$
;         'VALIDMIN',time_epoch16('0000-01-01:00:00:00.000000000000',tformat=tformat),$
;         'VALIDMAX',time_epoch16('9999-12-31:23:59:59.999999999999',tformat=tformat),$
;         'UNITS',''
;          *depend_0.attrptr))
;    endif

    if undefined(y) then y = x ; We add extra variable y equal x if has not been defined.
    
    if ~undefined(y) then begin
      vars.name = tplot_vars[i]     
      vars.datatype = idl2cdftype(y, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill, format_out=format_out)  
      attr = *vars.attrptr 
      str_element,attr,'FILLVAL',vfill,/add
      str_element,attr,'VALIDMIN',vmin,/add
      str_element,attr,'VALIDMAX',vmax,/add
      attr.FORMAT = format_out      
      str_element, attr,'DEPEND_0','Epoch',/add
      
      ; Add metadata
      if ((metadata.catdesc ne '') and (attr.CATDESC eq 'none')) then attr.CATDESC = metadata.catdesc
      if ((metadata.units ne '') and (attr.UNITS eq 'undefined')) then attr.UNITS = metadata.UNITS
      if ((metadata.ytitle ne '') and (attr.LABLAXIS eq 'undefined')) then attr.LABLAXIS = metadata.ytitle
      if (metadata.COORDINATE_SYSTEM ne '') then str_element, attr,'COORDINATE_SYSTEM',metadata.COORDINATE_SYSTEM ,/add      
      
      
      vars.attrptr = ptr_new(attr)       
      
      dy = dimen(y)      
     ;  === Checking the missing v(#) if we have [2|3|4]D y ===
      CASE ndimen(y) OF
        2: begin           
             if undefined(v) then begin
              ; If variable has predefined labels, we go we LABL_PTR_1, otherwise we put indexes instead
              ; The label must have the same number of dimentions as data
              ; Next, the attibutes of the label variable will be defined based on exitance of LABL_PTR_1 attribute
                                           
              if (dy[1] eq dimen(metadata.labels) and ~array_equal(metadata.labels, '')) then begin
                v = metadata.labels
                attr = *vars.attrptr 
                str_element,attr,'LABL_PTR_1',tplot_vars[i] + '_v',/add
                vars.attrptr = ptr_new(attr)
              endif else begin
                v = INDGEN(dy[1]) ; just indexing
              endelse
             endif
             if ~undefined(x) then ds = {x:x,y:y,v:v} else ds = {y:y,v:v}
           end           
        3: begin
             if undefined(v1) then v1 = INDGEN(dy[1]) ; just indexing 
             if undefined(v2) then v2 = INDGEN(dy[2]) ; just indexing
             if ~undefined(x) then ds = {x:x,y:y,v1:v1,v2:v2} else ds = {y:y,v1:v1,v2:v2} 
           end
        4: begin
             if undefined(v1) then v1 = INDGEN(dy[1]) ; just indexing 
             if undefined(v2) then v2 = INDGEN(dy[2]) ; just indexing 
             if undefined(v3) then v3 = INDGEN(dy[3]) ; just indexing 
             if ~undefined(x) then ds = {x:x,y:y,v1:v1,v2:v2,v3:v3} else ds = {y:y,v1:v1,v2:v2,v3:v3}
           end
     else: begin
            if ~undefined(x) then ds = {x:x,y:y} else ds = {y:y} ; default (assuming 1d)
           end
      ENDCASE
        store_data, tplot_vars[i],data= ds ; save possible v(#) into the tplot variable
              
    endif else begin ; no y
      ; this case if tplot is 1d
      vars = depend_0
      UNDEFINE, depend_0
    endelse


    if ~undefined(v) || ~undefined(v1) then begin      
      if ~undefined(v1) then v_str = '_v1' else  v_str = '_v'
      if ~undefined(v1) then v = TEMPORARY(v1) 
      
      depend_1 = cdf_default_vars_structure()
      depend_1.name = tplot_vars[i] + v_str
      depend_1.datatype = idl2cdftype(v, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill, format_out=format_out)      
      attr = *depend_1.attrptr
      
      
      ; Check if v is LABL_PTR_1
      varsattr = *vars.attrptr
      str_element, varsattr, 'LABL_PTR_1', success=s
      if s then begin ; LABL_PTR_1 found! v is the label
        if(attr.CATDESC  eq 'none') then attr.CATDESC = 'Label of ' + tplot_vars[i]
        if(attr.FIELDNAM eq 'none') then attr.FIELDNAM = 'Label of ' + tplot_vars[i]
        if(attr.VAR_TYPE eq 'undefined') then attr.VAR_TYPE = 'metadata'
        depend_1.recvary = 0b ; metadata does not changhe with time
        depend_1.attrptr = ptr_new(attr) ; save the atributes
      endif else begin ; If not, then this vatiable should be processed as the supporting data variable
                
                        
        str_element,attr,'FILLVAL',vfill,/add
        str_element,attr,'VALIDMIN',vmin,/add
        str_element,attr,'VALIDMAX',vmax,/add
        attr.FORMAT = format_out
       depend_1.attrptr = ptr_new(attr) ; save the atributes
        ; Add metadata
        if ((metadata.ztitle ne '') and (attr.LABLAXIS eq 'undefined')) then attr.LABLAXIS = metadata.ztitle

        str_element, *vars.attrptr,'DEPEND_1',depend_1.name,/add
        ; if v is 2d
        if ndimen(v) gt 1 then begin
          ; in this case first dimension of v is time (we don't check the actual number of records)
          ; vars.attrptr = ptr_new(CREATE_STRUCT('DEPEND_0','Epoch',*vars.attrptr)) ; one line addition to the attribute structure
          str_element, *depend_1.attrptr,'DEPEND_0','Epoch',/add
        endif else begin
          ; if v is 1d then it does not change in time
          depend_1.recvary = 0b
        endelse
      endelse                  
    endif
    
    if ~undefined(v2) then begin
      depend_2 = cdf_default_vars_structure()
      depend_2.name = tplot_vars[i] + '_v2'
      depend_2.datatype = idl2cdftype(v2, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill, format_out=format_out)
      attr = *depend_2.attrptr
      str_element,attr,'FILLVAL',vfill,/add
      str_element,attr,'VALIDMIN',vmin,/add
      str_element,attr,'VALIDMAX',vmax,/add
      attr.FORMAT = format_out
      depend_2.attrptr = ptr_new(attr)
      str_element, *vars.attrptr,'DEPEND_2',depend_2.name,/add

      ; if v is 2d
      if ndimen(v2) gt 1 then begin
        ; in this case first dimension of v is time (we don't check the actual number of records)
        ; vars.attrptr = ptr_new(CREATE_STRUCT('DEPEND_0','Epoch',*vars.attrptr)) ; one line addition to the attribute structure
        str_element, *depend_2.attrptr,'DEPEND_0','Epoch',/add
      endif else begin
        ; if v is 1d then it does not change in time
        depend_2.recvary = 0b
      endelse
    endif
    
    if ~undefined(v3) then begin
      depend_3 = cdf_default_vars_structure()
      depend_3.name = tplot_vars[i] + '_v3'
      depend_3.datatype = idl2cdftype(v3, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill, format_out=format_out)
      attr = *depend_3.attrptr
      str_element,attr,'FILLVAL',vfill,/add
      str_element,attr,'VALIDMIN',vmin,/add
      str_element,attr,'VALIDMAX',vmax,/add
      attr.FORMAT = format_out
      depend_3.attrptr = ptr_new(attr)
      str_element, *vars.attrptr,'DEPEND_3',depend_3.name,/add

      ; if v is 2d
      if ndimen(v3) gt 1 then begin
        ; in this case first dimension of v is time (we don't check the actual number of records)
        ; vars.attrptr = ptr_new(CREATE_STRUCT('DEPEND_0','Epoch',*vars.attrptr)) ; one line addition to the attribute structure
        str_element, *depend_3.attrptr,'DEPEND_0','Epoch',/add
      endif else begin
        ; if v is 1d then it does not change in time
        depend_3.recvary = 0b
      endelse
    endif
    
    ; This function does not rewrite existing VARS, DEPEND_0 and DEPEND_1 
    if is_struct(cdf_struct) then t = STRUPCASE(TAG_NAMES(cdf_struct)) else t = ''
    if ~array_contains(t, 'VARS') then cdf_struct = CREATE_STRUCT(cdf_struct, {VARS:vars})
    if ~undefined(depend_0) and ~array_contains(t, 'DEPEND_0') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_0:depend_0})
    if ~undefined(depend_1) and ~array_contains(t, 'DEPEND_1') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_1:depend_1})    
    if ~undefined(depend_2) and ~array_contains(t, 'DEPEND_2') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_2:depend_2})
    if ~undefined(depend_3) and ~array_contains(t, 'DEPEND_3') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_3:depend_3})
    options,tplot_vars[i],'CDF',cdf_struct
  endfor
end
