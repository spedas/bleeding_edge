;+
;PROCEDURE:
;  TPLOT2CDF, ...
;   
;PURPOSE:
;  Save tplot variables into cdf file
;  tplot variable must have appropriate CDF structure as the option (limits) (see TPLOT_ADD_CDF_STRUCTURE, OPTIONS)
;  Time (x variable of tplot) must be in SPEDAS (unix) format if TT2000 keyword is not specified, (see TIME_DOUBLE)
;   
;KEYWORDS:
;   FILENAME: (string) Name of the cdf file to be saved. .cdf extension can be omitted.
;   TVARS: (string or array of strings) Tplot variable name, or list of the tplot variables to be saved 
;   DEFAULT_CDF_STRUCTURE: (flag) Create default CDF structure in tplot variables                   
;   COMPRESS_CDF: (int) Compress CDF file. See CDF_COMPRESSION
;   G_ATTRIBUTES: (struct) Global attributes of CDF file
;   TT2000: (flag) Indicates that time is in TT2000 format.
;  
;  Additional keywords:    
;   INQ: (struct) Structure of CDF file parameters, see TPLOT2CDF_SAVE_VARS code
;
;EXAMPLES:   
;   store_date, 'example_tplot',data={x:time_double('2001-01-01')+[1, 2, 3],y:[10, 20, 30]}
;   tplot2cdf, filename='example_cdf_file', tvars='example_plot', /default  
;   
;   store_date, 'example_tplot2',data={x:time_double('2001-01-02')+[1, 2],y:[10, 20]}
;   tplot2cdf, filename='example_cdf_file2', tvars=['example_plot', 'example_tplot2'], /default
;  
;  See crib_tplot2cdf_basic for additional examples 
;
;CREATED BY:
;  Alexander Drozdov
;  
;   
; $LastChangedBy: haraday $
; $LastChangedDate: 2024-03-26 01:20:29 -0700 (Tue, 26 Mar 2024) $
; $LastChangedRevision: 32507 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/tplot2cdf.pro $
;-

pro tplot2cdf, filename=filename, tvars=tplot_vars, inq=inq_structure, g_attributes=g_attributes_custom,tt2000=tt2000, default_cdf_structure=default_cdf_structure, compress_cdf=compress_cdf 
  
  compile_opt idl2
  FORWARD_FUNCTION cdf_default_inq_structure, cdf_default_g_attributes_structure  
  RESOLVE_ROUTINE, 'cdf_default_cdfi_structure', /IS_FUNCTION, /NO_RECOMPILE
   
  if undefined(filename) then BEGIN
    print, "ERROR: Missing CDF filename"
    return 
  endif
  
  if undefined(default_cdf_structure) then default_cdf_structure = 1b
  
  if undefined(inq_structure) then inq_structure = cdf_default_inq_structure()
  g_attributes_structure = cdf_default_g_attributes_structure()
  if ~undefined(g_attributes_custom) then begin
    g_tag = tag_names(g_attributes_custom)
    for i=0,N_ELEMENTS(g_tag)-1 do begin    
      str_element,g_attributes_structure,g_tag[i],g_attributes_custom.(i),/add
    endfor
  endif else begin
    get_data, tplot_vars[0], dlimits=dl
    
;    if ~is_struct(dl) || ~is_struct(dl.cdf) || ~is_struct(dl.cdf.gatt) then begin
;      dprint, dlevel=0, 'Error, no global attributes structure found; using the default..'
;      g_attributes_custom = g_attributes_structure
;    endif else g_attributes_custom = dl.cdf.gatt
; Previous code block does not work if dlimits are defined, but
; without cdf. Instead only set the attributes if dl.cdf.gatt exists
; and is a structure. jmm, 2022-06-14
    g_attributes_custom = g_attributes_structure
    if is_struct(dl) then begin
       if tag_exist(dl, 'cdf') then begin
          if is_struct(dl.cdf) && tag_exist(dl.cdf, 'gatt') then begin
             if is_struct(dl.cdf.gatt) then g_attributes_custom = dl.cdf.gatt
          endif
       endif
    endif
    
    g_tag = tag_names(g_attributes_custom)
    for i=0,N_ELEMENTS(g_tag)-1 do begin
      str_element,g_attributes_structure,g_tag[i],g_attributes_custom.(i),/add
    endfor
  endelse
  
  
  ; main structure
  idl_structure = {FILENAME:filename,$
    INQ: inq_structure,$
    g_attributes: g_attributes_structure,$
    NV: 0$
  }
      
  ; main arrays of data
  VARS = []   
  EpochVARS = []  
  SupportVARS1 = []
  SupportVARS2 = []
  SupportVARS3 = []
  
  EpochType = 'CDF_EPOCH' ; default Epoch type
  if KEYWORD_SET(tt2000) then EpochType = 'CDF_TIME_TT2000'
  
  ; main loop
  for i =0,N_ELEMENTS(tplot_vars)-1 do begin    
    ; add default attributes. 
    ; this option will not overwrite existing fields
    tname = tplot_vars[i]

    if KEYWORD_SET(default_cdf_structure) then tplot_add_cdf_structure,tname,tt2000=tt2000
    
    get_data,tname,data=d,alimit=s, dlimits=dl
    
    str_element,s,'CDF',SUCCESS=cdf_s
    if cdf_s eq 0 || ~is_struct(s) then begin
      print, "ERROR: Missing CDF structure in tplot variable " + tname
      print, "Use tplot_add_cdf_structure procedure to define CDF structure or use /default_cdf_structure keyword"
      continue
    endif
        
    ; extract data
    str_element,d,'x',value=x
    str_element,d,'y',value=y
    str_element,d,'v',value=v
    str_element,d,'v1',value=v1
    str_element,d,'v2',value=v2
    str_element,d,'v3',value=v3
    if ~is_struct(d) then x = d

           
    ; here we don't check existence of CDF structure, it must be defined before
    ; we also don't check existence of x field
    VAR = s.CDF.VARS

    t = TAG_NAMES(s.CDF)
    
    if ~undefined(x) then begin
      ; Work with Epoch first
      ;
      ; If user defined only one x variable in tplot we consider it as Epoch
      ; In this case CDF may contain only one field VARS wich is Epoch  
      EpochName = 'Epoch'
      if s.CDF.VARS.DATATYPE eq EpochType then begin
        EpochVAR = s.CDF.VARS      
        ;if(undefined(y)) then begin 
          ;y = x          
          ;VAR.Name = tname
        ;end        
        ; UNDEFINE, VAR ; remove var
      endif
      
      if array_contains(t,'DEPEND_0') then begin
        ;if s.CDF.DEPEND_0.DATATYPE eq EpochType then EpochVAR  = s.CDF.DEPEND_0
        EpochVAR  = s.CDF.DEPEND_0
      endif
      
      if undefined(EpochVAR) then begin
        print, "ERROR: Missing valid Epoch in tplot variable " + tname
        print, "Check DATATYPE of the Epoch in CDF structure. CDF_Epoch cannot be used with TT2000 flag"
        return
      endif
      
      if KEYWORD_SET(tt2000) then begin
        ; === CDF_TIME_TT2000 ===
        ; is long 64 ?? No? - exit!
        if size(x,/type) ne 14 then begin
          print, "ERROR: type of TT2000 time in tplot variable " + tname + " is not long64"
          return
        endif
        EpochVAR.DATAPTR = ptr_new(x, /NO_COPY)
        EpochVAR.DATATYPE = 'CDF_TIME_TT2000' ;Set datatype to CDF_TIME_TT2000, jmm 2023-01-24
     endif else begin      
        ; === CDF_EPOCH ===
        ; Time should be in SPEDAS format, which is UNIX time.
        ; Add variable and convert it into Epoch
        if size(x,/type) ne 5 then begin
          print, "ERROR: type of Epoch in tplot variable " + tname + " is not double"      
          return
        endif    
        EpochVAR.DATAPTR = ptr_new(time_epoch(x), /NO_COPY)    
      end
      

      
      InArray = 0 ; flag of having Epoch in array EpochVARS  
      for j=0,N_ELEMENTS(EpochVARS)-1 do begin
       if size(*EpochVARS[j].DATAPTR, /type) eq size(*EpochVAR.DATAPTR,/type) then begin
        if ARRAY_EQUAL(*EpochVARS[j].DATAPTR, *EpochVAR.DATAPTR) then begin
          InArray = 1
          EpochName = EpochVARS[j].NAME
        endif
       endif
      endfor
      
      if InArray eq 0 then begin ; add new epoch variable
        EpochN = N_ELEMENTS(EpochVARS)
        if EpochN gt 0 then EpochName = EpochName + '_' + strtrim(string(EpochN),1)
        EpochVAR.NAME = EpochName ; name      
        (*Epochvar.ATTRPTR).VAR_TYPE = 'support_data' ; Automaticaly change attributes for Epoch variable      
        EpochVARS = array_concat(EpochVAR,EpochVARS)       
      endif
          
    endif ; x
    
    ;
    ; Then we work with supporting data (1), same scenario
    ;   
    if ~undefined(v1) then v = TEMPORARY(v1) ; Use v1 isdead of v if we have v1         
    if array_contains(t,'DEPEND_1') then begin
     SupportName1 = s.CDF.DEPEND_1.NAME
     SupportVAR = s.CDF.DEPEND_1
     SupportVAR.DATAPTR = ptr_new(v, /NO_COPY)
     
     InArray = 0
     for j=0,N_ELEMENTS(SupportVARS1)-1 do begin
      if size(*SupportVARS1[j].DATAPTR, /type) eq size(*SupportVAR.DATAPTR, /type) then begin
       if ARRAY_EQUAL(*SupportVARS1[j].DATAPTR, *SupportVAR.DATAPTR, /QUIET) then begin
         InArray = 1
         SupportName1 = SupportVARS1[j].NAME
       endif
      endif 
     endfor
   
     if InArray eq 0 then begin ; add new support variable
       attr = *SupportVAR.ATTRPTR               
    
       if ndimen(v) eq 2 then str_element, attr,'DEPEND_0',EpochName,/add ; if support variable is 2d, then the first dimension corresponds to time               
       if STRCMP(attr.VAR_TYPE, 'undefined') then attr.VAR_TYPE = 'support_data' ;Change attributes for support variable variable
       SupportVAR.ATTRPTR = ptr_new(attr)
       SupportVARS1 = array_concat(SupportVAR,SupportVARS1)       
     endif
    endif
    
    ;
    ; supporting data (2)
    ;    
    if array_contains(t,'DEPEND_2') then begin
      SupportName2 = s.CDF.DEPEND_2.NAME
      SupportVAR = s.CDF.DEPEND_2
      SupportVAR.DATAPTR = ptr_new(v2, /NO_COPY)

      InArray = 0
      for j=0,N_ELEMENTS(SupportVARS2)-1 do begin
       if size(*SupportVARS2[j].DATAPTR, /type) eq size(*SupportVAR.DATAPTR, /type) then begin
        if ARRAY_EQUAL(*SupportVARS2[j].DATAPTR, *SupportVAR.DATAPTR, /QUIET) then begin
          InArray = 1
          SupportName2 = SupportVARS2[j].NAME
        endif
       endif
      endfor

      if InArray eq 0 then begin ; add new support variable
        attr = *SupportVAR.ATTRPTR
        if ndimen(v2) eq 2 then str_element, attr,'DEPEND_0',EpochName,/add ; if support variable is 2d, then the first dimension corresponds to time
        if STRCMP(attr.VAR_TYPE, 'undefined') then attr.VAR_TYPE = 'support_data' ;Change attributes for support variable variable
        SupportVAR.ATTRPTR = ptr_new(attr)
        SupportVARS2 = array_concat(SupportVAR,SupportVARS2)
      endif
    endif
    
    ;
    ; supporting data (3)
    ;
    if array_contains(t,'DEPEND_3') then begin
      SupportName3 = s.CDF.DEPEND_3.NAME
      SupportVAR = s.CDF.DEPEND_3
      SupportVAR.DATAPTR = ptr_new(v3, /NO_COPY)

      InArray = 0
      for j=0,N_ELEMENTS(SupportVARS3)-1 do begin
       if size(*SupportVARS3[j].DATAPTR, /type) eq size(*SupportVAR.DATAPTR, /type) then begin
        if ARRAY_EQUAL(*SupportVARS3[j].DATAPTR, *SupportVAR.DATAPTR, /QUIET) then begin
          InArray = 1
          SupportName3 = SupportVARS3[j].NAME
        endif
       endif
      endfor

      if InArray eq 0 then begin ; add new support variable
        attr = *SupportVAR.ATTRPTR
        if ndimen(v3) eq 2 then str_element, attr,'DEPEND_0',EpochName,/add ; if support variable is 2d, then the first dimension corresponds to time
        if STRCMP(attr.VAR_TYPE, 'undefined') then attr.VAR_TYPE = 'support_data' ;Change attributes for support variable variable
        SupportVAR.ATTRPTR = ptr_new(attr)
        SupportVARS3 = array_concat(SupportVAR,SupportVARS3)
      endif
    endif

    ;
    ; Now work with the data
    ;
    if ~undefined(VAR) then begin
      attr = *VAR.ATTRPTR
      if STRCMP(attr.VAR_TYPE, 'undefined') then attr.VAR_TYPE = 'data' ;Change attributes for data variable variable
      if ~tag_exist(attr, 'DISPLAY_TYPE') then str_element, attr, 'DISPLAY_TYPE', 'time_series', /add
      
      if STRCMP(attr.DISPLAY_TYPE, 'undefined') then begin
        attr.DISPLAY_TYPE = 'time_series' ; if display type is not defined we assume that it is a time_series        
        if array_contains(t,'DEPEND_1') then begin
          spec = 0
          str_element,s,'spec',spec ; determine if tplot variable is a spectrogram
          if spec eq 1 then begin
            attr.DISPLAY_TYPE = 'spectrogram'
          endif else begin
            attr.DISPLAY_TYPE = 'stack_plot'
          endelse
        endif
      endif
      if array_contains(t,'DEPEND_0') then str_element, attr,'DEPEND_0',strjoin(strsplit(EpochName, '-', /extract), '_'),/add            
      if array_contains(t,'DEPEND_1') then str_element, attr,'DEPEND_1',strjoin(strsplit(SupportName1, '-', /extract), '_'),/add 
      if array_contains(t,'DEPEND_2') then str_element, attr,'DEPEND_2',strjoin(strsplit(SupportName2, '-', /extract), '_'),/add
      if array_contains(t,'DEPEND_3') then str_element, attr,'DEPEND_3',strjoin(strsplit(SupportName3, '-', /extract), '_'),/add

      VAR.ATTRPTR = ptr_new(attr)
      VAR.DATAPTR = ptr_new(y, /NO_COPY)
            
      VARS = array_concat(VAR,VARS)
    endif    
  endfor
    
  VARS = array_concat(VARS,SupportVARS1)
  VARS = array_concat(VARS,SupportVARS2)
  VARS = array_concat(VARS,SupportVARS3)
  VARS = array_concat(VARS, EpochVARS)
  
  idl_structure.NV = N_ELEMENTS(VARS)
  str_element, idl_structure,'VARS',VARS,/add
  ;help, idl_structure
  tplot2cdf_save_vars, idl_structure, filename, compress_cdf=compress_cdf
end   
