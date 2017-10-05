pro write_fieldnames,lun,fieldnames,sepstring
for i=0,n_elements(fieldnames)-1 do begin
     if (i GT 0) THEN printf,lun,sepstring,format='($,A1)'
     printf,lun,fieldnames[i],format='($,A)'   
endfor
printf,lun,''
end

pro write_tecplothdr,lun,fieldnames,sepstring,sampcount
printf,lun,format='("VARIABLES = ",$)'
for i=0,n_elements(fieldnames)-1 do begin
     if (i GT 0) THEN printf,lun,sepstring,format='($,A1)'
     printf,lun,fieldnames[i],format='($,A)'   
endfor
printf,lun,''
printf,lun,sampcount-1,format='("ZONE I=",I,", J=1, K=1, F=POINT")'
end


;+
;NAME:
; saveas_ascii.pro
;
;PURPOSE:
; Saves SPEDAS Loaded Data variables in ASCII format.
;
;INPUT & KEYWORDS:
;  loadedData:  SPEDAS GUI loaded data object
;  timefmt: Index specifying which format to use for time quantities.
;           (passed to formatannotation.pro)
;  fmt_code: Index specifying which format to use for data.
 ;           (passed to formatannotation.pro)
;  timeStringFmt: String specifying a custom time format.
;                 See TFORMAT keyword for time_string.pro for usage.
;                 This keyword will override TIMEFMT.
;  local_time: Flag to use local time instead of UTC, only valid if
;              used with TIMESTRINGFMT
;
;OTHER:
; Documentation for this procedure is incomplete.
;
;-
pro saveas_ascii,loadedData=loadedData,field_names=field_names, $
                 timefmt=timefmt, local_time=local_time, $ 
                 timeStringFmt=timeStringFmt, $
                 fmt_strings=fmt_strings, fmt_code=fmt_code, $
                 sepstring=sepstring, filename=filename, $
                 flagstring=flagstring, hdrfmt=hdrfmt, $
                 statuscode=statuscode,statusmsg=statusmsg, $
                 timeflag=timeflag,timerange=timerange, $
                 yaxisflag=yaxisflag
;dprint, flagstring,format='("flagstring: ",A)'
;dprint, field_names,format='("field_names: ",A)'
;dprint, timefmt,format='("timefmt: ",I)'
;dprint, sepstring,format='("sepstring: ->",A,"<-")'
;dprint, filename,format='("filename: ",A)'
;dprint, timeflag,format='("timeflag: ",I)'
;dprint, timerange[0],timerange[1],format='("Start: ",F20.6," End: ",F20.6)'

; Do we need to strip out yaxis components?

if (yaxisflag EQ 1) then begin
   matchflags=strmatch(field_names,'*yaxis*',/fold_case)
   yaxis_ind=where(matchflags,ycount,complement=normal_ind)
   if (ycount EQ n_elements(field_names)) then begin
      statusmsg='saveas_ascii: No field names left after removing yaxis components.'
      statuscode=-1
      return
   endif
   field_names=field_names[normal_ind]
endif

tgt_dirname=file_dirname(filename)

fi=file_info(tgt_dirname)
if ~fi.exists then begin
   statusmsg=string(tgt_dirname,format='("saveas_ascii: Save failed. Directory ",A," does not exist.")')
   statuscode=-1
   return
endif else if ~fi.write then begin
   statusmsg=string(tgt_dirname,format='("saveas_ascii: Save failed. Directory ",A," is not writeable by you.")')
   statuscode=-1
   return
endif

fi=file_info(filename)
if (fi.exists AND ~fi.write) then begin
   statusmsg=string(filename,format='("saveas_ascii: Save failed. File ",A," exists, and is not writeable by you.")')
   statuscode=-1
   return
end else if (fi.exists) then begin
   statusmsg=string(filename,format='("saveas_ascii: File ",A," already exists. Do you wish to overwrite it?")')
   answer=dialog_message(statusmsg,/question,/default_no)
   if (answer NE 'Yes') then begin
      statusmsg='saveas_ascii: Save cancelled by user.'
      statuscode=-1
      return
   endif
 
endif

varcount=n_elements(field_names)
dataptrs=ptrarr(varcount)
axis_structs=replicate({scaling:0, timeAxis:0, formatid:fmt_code},varcount)
; check validity, make data pointers
for i=0,varcount-1 do begin

    groupObj=loadedData->getGroup(field_names[i])

    ; groupObj is guaranteed to be either 0, or a 1-element array of valid 
    ; objects

    if obj_valid(groupObj[0])  then begin
       ; look for a trace within this group
       dataObj=groupObj[0]->getObject(field_names[i])
        if ~obj_valid(dataObj) then begin
           statusmsg='saveas_ascii: No data object found for field name '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
        endif
    endif else begin
       ; no group found by that name, try getting the object directly
       objects=loadedData->getObjects(name=field_names[i])
       if (n_elements(objects) GT 1) then begin
           statusmsg='saveas_ascii: Multiple data objects found for field name '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
       endif else if ~obj_valid(objects[0]) then begin
           statusmsg='saveas_ascii: No data object found for field name '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
       endif
       dataObj=objects[0]         
    endelse

    ; Process this dataObj 
    ; Get data pointer and IsTime flag from dataObj

    dataObj->GetProperty,isTime=isTime,dataPtr=dataPtr,timeName=timeName

    ; If start/stop times are specified, make a copy of the data array
    ; restricted to the time range.

    if (timeflag EQ 1) then begin
       if (isTime EQ 1) then begin
          ; Case 1: this is a time variable, so test the values directly.
         tr_arr=*dataPtr
         tr_ind=where( (tr_arr GE timerange[0]) AND (tr_arr LE timerange[1]),tr_count) 
       endif else begin
          ; Case 2: not a time variable, so get the corresponding array
          ;   of times, test those, then apply those indices to the data
          ;   array.
          time_objs=loadedData->GetObjects(name=timeName)
          time_objs[0]->GetProperty,dataPtr=tr_dataPtr
          tr_arr=*tr_dataPtr
          tr_ind=where( (tr_arr GE timerange[0]) AND (tr_arr LE timerange[1]),tr_count) 
       endelse

       if (tr_count EQ 0) then begin
           statusmsg='saveas_ascii: No samples in specified time range for variable '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
       endif
       
       dataPtr=ptr_new((*dataPtr)[tr_ind])  ; This needs to be cleaned up before exit to prevent a serious memory leak
    endif

    ; Reject multi-dimensional or unequally sized arrays

    ndims=size(*dataPtr,/n_dimensions)
    nelems=n_elements(*dataPtr)
;    print,field_names[i],'   ndims: ',ndims,'   nelems: ',nelems
    if (ndims NE 1) then begin
       statusmsg=STRING(field_names[i],format='("saveas_ascii: multidimensional data not supported for field named ",A)')
       statuscode=-1
       ; Clean up 
       if (timeflag) then ptr_free,dataptrs
       return
    endif
    if (i EQ 0) then begin
       first_elems=nelems
    endif else if (nelems NE first_elems) then begin
       statusmsg=STRING(field_names[i],format='("saveas_ascii: variables must have identical sample counts, invalid field ",A)')
       statuscode=-1
       if (timeflag) then ptr_free,dataptrs
       return
    endif

    ; Time variables are treated differently -- they have their own set
    ; of ASCII formats.

    if (isTime) then begin
       axis_structs[i].timeAxis=1
       axis_structs[i].formatid=timefmt
;       print,field_names[i],format='("Time variable found:  ", A)'
    endif

    ; Keep copy of data pointer
    dataptrs[i]=dataPtr
endfor

openw,lun,filename,/get_lun

; Write header lines, if requested

case hdrfmt of
   0: BEGIN
      END
   1: write_fieldnames,lun,field_names,sepstring
   2: write_tecplothdr,lun,field_names,',',first_elems
   ELSE: BEGIN
         END
ENDCASE

; Write data using requested format

for i=0L,nelems-1 do begin
   for j=0L,varcount-1 do begin
     if (j GT 0) THEN printf,lun,sepstring,format='($,A1)'
     data_value=(*(dataptrs[j]))[i]
     type_code=size(data_value,/type)
     if (axis_structs[j].timeAxis EQ 1) then begin
        if keyword_set(timeStringFmt) then begin
          ;use custom time format
          printf,lun,time_string(data_value,tformat=timeStringFmt,local=local_time),format='($,A)'
        endif else begin
          ;use indexed time format
          printf,lun,formatannotation(0,0,data_value,data=axis_structs[j]),format='($,A)'
        endelse
     endif else if ((type_code EQ 4) OR (type_code EQ 5)) THEN BEGIN
        data_string=strtrim(string(data_value,format=fmt_strings[fmt_code]),2)
        ; Use default format if data_value overflows preferred format
        if (strpos('*',data_string) NE -1) then begin
           data_string=string(data_value)
        endif else if ~finite(data_value) then data_string=flagstring
        printf,lun,data_string,format='($,A)'
     endif else begin
        printf,lun,string(data_value),format='($,A)'
     endelse
   endfor
   printf,lun,''
endfor

; Cleanup and return success
free_lun,lun
statuscode=0
statusmsg=STRING(filename,format='("Data successfully saved to ",A)')
if (timeflag) then ptr_free,dataptrs
return
end
