pro saveas_upper_flatfile,loadedData=loadedData,field_names=field_names,filename=filename,statuscode=statuscode,statusmsg=statusmsg,timeflag=timeflag,timerange=timerange

;dprint, field_names,format='("field_names: ",A)'
;dprint, filename,format='("filename: ",A)'

tgt_dirname=file_dirname(filename)

fi=file_info(tgt_dirname)
if ~fi.exists then begin
   statusmsg=string(tgt_dirname,format='("saveas_upper_flatfile: Save failed. Directory ",A," does not exist.")')
   statuscode=-1
   return
endif else if ~fi.write then begin
   statusmsg=string(tgt_dirname,format='("saveas_upper_flatfile: Save failed. Directory ",A," is not writeable by you.")')
   statuscode=-1
   return
endif

tgt_basename=file_basename(filename)
extension_pos=strpos(tgt_basename,'.',/reverse_search)
if (extension_pos GT 0) THEN BEGIN
   base_no_extension=strmid(tgt_basename,0,extension_pos)
ENDIF ELSE BEGIN
   base_no_extension=tgt_basename
ENDELSE

stripped_path=tgt_dirname+path_sep()+base_no_extension
; Make filenames for the DAT, DES, ABS, and HED components
dat_filename=stripped_path+'.dat'
des_filename=stripped_path+'.des'
abs_filename=stripped_path+'.abs'
hed_filename=stripped_path+'.hed'

; This file format only supports pathnames up to 44 characters long.

; We'll omit saving the full pathname to save space.  This is a  slight 
; abuse of the format -- the UCLA documentation clearly states that this field 
; in the .hed file denotes a "path", but a 44-character restriction
; on directory+filename is ludicrous, and nearly unusable.

short_filename=base_no_extension+'.dat'

if (strlen(short_filename) GT 44) then begin
   statuscode=-1
   statusmsg=string(short_filename,format='("saveas_upper_flatfile: Save failed. Output filename ",A,"exceeds 44 characters.")')
   return
endif

; Check that all filenames are writable

filearr=[dat_filename,des_filename,abs_filename,hed_filename]
fileinfo=file_info(filearr)
nowrite=where((fileinfo.exists EQ 1) AND (fileinfo.write EQ 0))
already_exists=where(fileinfo.exists EQ 1)

if (nowrite[0] NE -1) then begin
   statusmsg=['saveas_upper_flatfile: Save failed. The following files are not writable',filearr[nowrite]]
   statuscode=-1
   return
endif

if (already_exists[0] NE -1) then begin
   statusmsg=['saveas_upper_flatfile: The following files already exist. Do you wish to overwrite them?',filearr[already_exists]]
   answer=dialog_message(statusmsg,/question,/default_no)
   if (answer NE 'Yes') then begin
      statusmsg='saveas_upper_flatfile: Save cancelled by user.'
      statuscode=-1
      return
   endif
endif


varcount=n_elements(field_names)
dataptrs=ptrarr(varcount)

typecode_names=['undefined', 'byte', 'int', 'long','float', 'double', $
         'complex','string','struct','dcomplex','pointer','objref','uint',$
         'ulong','long64','ulong64'] 
type_codes = make_array(varcount,/long) ;to be filled later

descriptors=replicate({longname:'', shortname:'', units:'', typecode:'', timeflag:0, sort:'0'},varcount)

; check validity, make data pointers
for i=0,varcount-1 do begin

    ; Get the data object from loadedData
    
    groupObj=loadedData->getGroup(field_names[i])

    ; groupObj is guaranteed to be either 0, or a 1-element array of valid
    ; objects

    if obj_valid(groupObj[0])  then begin
       ; look for a trace within this group
       dataObj=groupObj[0]->getObject(field_names[i])
        if ~obj_valid(dataObj) then begin
           statusmsg='saveas_upper_flatfile: No data object found for field name '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
        endif
    endif else begin
       ; no group found by that name, try getting the object directly
       objects=loadedData->getObjects(name=field_names[i])
       if (n_elements(objects) GT 1) then begin
           statusmsg='saveas_upper_flatfile: Multiple data objects found for field name '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
       endif else if ~obj_valid(objects[0]) then begin
           statusmsg='saveas_upper_flatfile: No data object found for field name '+field_names[i]
           statuscode=-1
           if (timeflag) then ptr_free,dataptrs
           return
       endif
       dataObj=objects[0]
    endelse

    ; Process this dataObj
    ; Get data pointer and IsTime flag from dataObj

    dataObj->GetProperty,isTime=isTime,dataPtr=dataPtr,units=units,timeName=timeName

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
          statusmsg='saveas_upper_flatfile: No samples in specified time range for variable '+field_names[i]
          statusmsg=-1
          if (timeflag) then ptr_free,dataptrs
       endif

       dataPtr=ptr_new((*dataPtr)[tr_ind])  ; This needs to be cleaned up before exit to prevent a serious memory leak
    endif

    if (strlen(units) EQ 0) then units='unknown'

    ; Reject multi-dimensional or unequally sized arrays

    ndims=size(*dataPtr,/n_dimensions)
    nelems=n_elements(*dataPtr)
;    print,field_names[i],'   ndims: ',ndims,'   nelems: ',nelems
    if (ndims NE 1) then begin
       statusmsg=STRING(field_names[i],format='("saveas_upper_flatfile: multidimensional data not supported for field named ",A)')
       statuscode=-1
       if (timeflag) then ptr_free,dataptrs
       return
    endif
    if (i EQ 0) then begin
       first_elems=nelems
    endif else if (nelems NE first_elems) then begin
       statusmsg=STRING(field_names[i],format='("saveas_upper_flatfile: variables must have identical sample counts, invalid field ",A)')
       statuscode=-1
       if (timeflag) then ptr_free,dataptrs
       return
    endif

    if (isTime) then begin
      descriptors[i].timeflag=1
    endif
 
    descriptors[i].longname=field_names[i]
    descriptors[i].shortname=string(i,format='("c",I-2)') 
    descriptors[i].units=units
    data_value=(*dataPtr)[0]
    type_codes[i] = size(data_value,/type)
;    type_code=size(data_value,/type)
    case type_codes[i] of
       ; Bytes and 2 byte ints must be promoted
       1: begin
            descriptors[i].typecode='I4  '
          end
       2: begin
            descriptors[i].typecode='I4  '
          end
       ; 4 byte integer
       3: begin
            descriptors[i].typecode='I4  '
          end
       ; Single precision floating point
       4: begin
            descriptors[i].typecode='R4  '
          end
       ; Double precision floating point
       5: begin
            descriptors[i].typecode='D8  '
          end
       ; Unsigned ints promoted to 4 byte ints
       12:begin
            descriptors[i].typecode='I4  '
          end
       ; Unsigned longs converted to doubles after prompt
       13:begin
            answer = dialog_message('The data "'+field_names[i]+'" is composed of unsigned'+ $
                                    ' long integers that must be converted to double '+ $
                                    'precision floating point numbers before proceeding.'+ $
                                    '  Continue?', /question,/center)
            if answer eq 'No' then begin
              statusmsg='Unsupported datatype, conversion cancled by user'
              statuscode=-1
              if (timeflag) then ptr_free,dataptrs
              return
            endif else descriptors[i].typecode='D8  '
          end
       ; All other types are unsupported for this format
       else: begin
               statusmsg='Unsupported datatype ('+typecode_names[type_codes[i]]+') for field '+field_names[i]
               statuscode=-1
               if (timeflag) then ptr_free,dataptrs
               return
             end
    endcase
    
    ; Keep copy of data pointer
    dataptrs[i]=dataPtr
endfor

; Write DES (field descriptions) file
openw,lun,des_filename,/get_lun
for i=0,varcount-1 do begin
printf,lun,descriptors[i].longname,descriptors[i].shortname,descriptors[i].units,$
   descriptors[i].typecode,descriptors[i].sort,$
   format='(A-32,A-8,A-16,A-4,A-2)'
endfor
free_lun,lun

; Write empty ABS file
openw,lun,abs_filename,/get_lun
printf,lun,''
free_lun,lun

; Write HED file
owner=getenv('USER')
if (strlen(owner) EQ 0) then owner=getenv('LOGNAME')
if (strlen(owner) EQ 0) then owner='unknown_userid'

monthnames=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
daynames=['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
ts=time_struct(systime(/sec))
mon=monthnames[ts.month-1]
day=daynames[ts.dow]
datestr=day+' '+mon+' '+string(ts.date,format='(I02)')+ $
   ' '+string(ts.hour,ts.min,ts.sec,format='(I02,":",I02,":",I02)') + $
   ' '+string(ts.year,format='(I04)')
columns=varcount
rows=nelems
openw,lun,hed_filename,/get_lun
printf,lun,short_filename,datestr,owner,columns,rows,$
     format='(A-44,A-30,A-20,I3,I5)'
free_lun,lun

; Write binary DAT file

; This is not stated in the documentation, but the file format is
; supposed to be big-endian.

openw,lun,dat_filename,/get_lun,/swap_if_little_endian

for i=0L,nelems-1 do begin
  for j=0L,varcount-1 do begin
    if (type_codes[j] eq 1) || (type_codes[j] eq 2) || (type_codes[j] eq 12) then begin
      data_value=long( (*(dataptrs[j]))[i] )
    endif else if type_codes[j] eq 13 then begin
      data_value=double( (*(dataptrs[j]))[i] )
    endif else begin
      data_value=(*(dataptrs[j]))[i]
    endelse
    writeu,lun,data_value
  endfor
endfor

; Cleanup and return success
free_lun,lun
statuscode=0
statusmsg=STRING(filename,format='("Data successfully saved to ",A)')
if (timeflag) then ptr_free,dataptrs
return
end
