;+
; Function:
; MVN_MAG_L1_STS_READ
;
; PURPOSE:
; Convert magnetometer .sts to array of structures
;
; AUTHOR:
; Roberto Livi (rlilvi@ssl.Berkeley.edu) and Davin Larson
;
; CALLING SEQUENCE:
; data = MVN_MAG_STS_READ(filename,header=header)
;
; KEYWORDS:
; FILENAME: String containing .sts filename to be loaded
;
; NOTES:
;      Uses append_array.pro
;
; EXAMPLE:
;        IDL> data_structure = mvn_mag_sts_read( filename, header = header)
;
;
; HISTORY:
;
; VERSION:
;   $LastChangedBy: ali $
;   $LastChangedDate: 2023-10-21 18:50:42 -0700 (Sat, 21 Oct 2023) $
;   $LastChangedRevision: 32205 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_l1_sts_read.pro $
;-


function mvn_mag_l1_sts_read, filename, header_info = header_info
  message,'obsolete, replaced by mvn_mag_sts_read'


  ;###########################################################################
  ;Check file

  ;-----------------------------------
  ;No file error
  file=file_search(filename)
  if size(file,/type) eq 7 and file[0] eq '' then begin
    print, 'ERROR: File '+filename+' not found/loaded.'
    return,0
  endif




  ;###########################################################################
  ;Read file

  ;-----------------------------------
  ;Generate variables
  obj_num=0
  str_temp1=''
  str_temp2=''
  obj_struc={header:'',kernel_list:'',record:''}
  obj_str=''
  obj_lev=0
  obj_name=tag_names(obj_struc)
  openr, file_unit, file, /get_lun


  ;-----------------------------------
  ;Check if first object is 'file'
  readf, file_unit, str_temp1
  str_temp2=strsplit(str_temp1,'=',/extract)
  if n_elements(str_temp2) ne 2 then begin
    if str_temp2[1] ne 'file' then $
      print, 'ERROR: No file header.' $
    else print, 'ERROR: No object file'
    return,0
  endif
  obj_num++


  ;-------------------------------------
  ;Read all objects line by line
  ;and save as strings
  while obj_num gt 0 do begin
    readf, file_unit, str_temp1
    str_temp1=strtrim(str_temp1,2)
    str_temp2=strsplit(str_temp1,' ',/extract)
    append_array, obj_str, str_temp1
    append_array, obj_lev, obj_num
    if str_temp2[0] eq 'OBJECT' then obj_num++
    if str_temp2[0] eq 'END_OBJECT' then obj_num--
  endwhile





  ;###########################################################################
  ;Parse headers

  ;-----------------------------------
  ;Find object types
  nn=n_elements(obj_str)
  obj_pos=intarr(nn)
  for i=0, nn-1 do begin
    temp1=strpos(STRUPCASE(obj_str[i]),'OBJECT')
    temp2=strpos(STRUPCASE(obj_str[i]),'END_OBJECT')
    if temp1 ne -1 and temp2 eq -1 then obj_pos[i]=i $
    else obj_pos[i]=-1
  endfor
  obj_pos=obj_pos[where(obj_pos ne -1,cc_obj)]
  obj_type=strarr(cc_obj)
  for i=0., cc_obj-1 do begin
    temp=strsplit(obj_str[obj_pos[i]],'=',/extract)
    obj_type[i]=strtrim(temp[1],2)
  endfor



  ;-----------------------------------
  ;Find end_object
  nn=n_elements(obj_str)
  endobj_pos=fltarr(nn)
  for i=0., nn-1. do $
    endobj_pos[i]=strpos(STRUPCASE(obj_str[i]),'END_OBJECT')
  endobj_pos=where(endobj_pos ne -1)



  ;-----------------------------------
  ;Read header
  header_lev=obj_lev[obj_pos[where(obj_type eq 'HEADER',nheader)]]
  if nheader eq 0 then begin
    print, 'ERROR: No header object.'
    return,0
  endif
  pp=where(obj_lev eq header_lev[0])
  header=obj_str[pp[0]:pp[1]-1]
  header_struc={PROGRAM:'',CMD_LINE:'',DATE:'',HOST:'',COMMENT:'', TITLE:''}
  for i=0, n_elements(header)-1 do begin
    temp=strtrim(strsplit(header[i],'=',/extract),2)
    case temp[0] of
      'PROGRAM' :header_struc.program=temp[1]
      'CMD_LINE':header_struc.cmd_line=temp[1]
      'DATE'    :header_struc.date=temp[1]
      'HOST'    :header_struc.host=temp[1]
      'COMMENT' :header_struc.comment=temp[1]
      'TITLE'   :header_struc.title=temp[1]
      else: break
    endcase
  endfor



  ;-----------------------------------
  ;Read scalar info
  sca_pos=where(obj_type eq 'SCALAR',nsca)
  sca_info=replicate({NAME:'NaN',$
    ALIAS:'NaN',$
    FORMAT:'NaN',$
    TYPE:'NaN',$
    UNITS:'NaN'},nsca)
  for i=0, nsca-1 do begin
    temp=strtrim($
      strsplit($
      obj_str[obj_pos[sca_pos[i]]],'=',/extract),2)
    if n_elements(temp) eq 2 and $
      temp[0] eq 'OBJECT' then begin
      pos=obj_pos[sca_pos[i]]
      pp=0
      while temp[0] ne 'END_OBJECT' do begin
        case temp[0] of
          'NAME'  : sca_info[i].NAME   = temp[1]
          'ALIAS' : sca_info[i].ALIAS  = temp[1]
          'FORMAT': sca_info[i].FORMAT = temp[1]
          'TYPE'  : sca_info[i].TYPE   = temp[1]
          'UNITS' : sca_info[i].UNITS  = temp[1]
          else: break
        endcase
        pos=pos+1
        temp=strtrim($
          strsplit($
          obj_str[pos],'=',/extract),2)
      endwhile
    endif
  endfor


  ;-----------------------------------
  ;Read kernel list
  ker_pos=where(obj_type eq 'KERNEL_LIST',nker)
  kernel_files=''
  temp1=''
  iker=1.
  while temp1[0] ne 'END_OBJECT' do begin
    pos=obj_pos[ker_pos]+iker
    temp1=strtrim(strsplit(obj_str[pos],'=',/extract),2)
    temp2=strtrim(strsplit(temp1[0],' ',/extract),2)
    nn=n_elements(temp2)-1
    tt1=temp2[0]
    tt2=temp2[nn]
    if tt1 ne 'END_OBJECT' then begin
      append_array,kernel_files,tt2
      append_array,kernel_list,obj_str[pos]
    endif
    iker++;=iker+1.
  endwhile


  ;-----------------------------------
  ;Read vectors
  vec_pos=where(obj_type eq 'VECTOR',nvec)
  vec_info=replicate({NAME:'',$
    ALIAS:'',$
    FORMAT:'',$
    TYPE:'',$
    UNITS:'',$
    DIM:0,$
    VAR_TYPE:'',$
    VAR_NAME:''},nvec)
  vecs=''
  temp=['','']
  for i=0, nvec-1 do begin
    ivec=0
    pos=obj_pos[vec_pos[i]]+ivec
    temp=strtrim(strsplit(obj_str[pos],'=',/extract),2)
    while temp[0] ne 'END_OBJECT' do begin
      case temp[0] of
        'NAME'  : vec_info[i].NAME   = temp[1]
        'ALIAS' : vec_info[i].ALIAS  = temp[1]
        'FORMAT': vec_info[i].FORMAT = temp[1]
        'TYPE'  : vec_info[i].TYPE   = temp[1]
        'UNITS' : vec_info[i].UNITS  = temp[1]
        else: break
      endcase
      if temp[1] eq 'SCALAR' then begin
        while temp[0] ne 'END_OBJECT' do begin
          pos=obj_pos[vec_pos[i]]+ivec
          temp=strtrim(strsplit(obj_str[pos],'=',/extract),2)
          if temp[0] eq 'NAME' then $
            vec_info[i].VAR_NAME=vec_info[i].VAR_NAME+temp[1]+' '
          if temp[0] eq 'FORMAT' then begin
            temp1=strsplit(temp[1],',',/extract)
            temp1=strmid(temp1[1],0,1)
            if temp1 eq 'I' then tt='0'
            if temp1 eq 'F' then tt='0.D'
            vec_info[i].VAR_TYPE=vec_info[i].VAR_TYPE+tt+' '
          endif
          ivec=ivec+1
        endwhile
      endif
      pos=obj_pos[vec_pos[i]]+ivec
      temp=strtrim(strsplit(obj_str[pos],'=',/extract),2)
      ivec=ivec+1
    endwhile
    ive=ivec+1
    vec_info[i].dim=n_elements($
      strsplit($
      vec_info[i].var_name,' ',/extract))
  endfor





  ;-----------------------------------
  ;Find first line for formatting
  str_temp=''
  readf, file_unit, str_temp
  temp=strsplit(str_temp,' ',/extract)
  nn=n_elements(temp)
  var_locs=intarr(nn)
  add_len=0.
  for i=0, nn-1 do begin
    temp1=strpos(str_temp,temp[i])
    tot_len=strlen(str_temp)
    len=strlen(temp[i])
    var_locs[i]=temp1+add_len
    ;The first six columns are time
    ;elements (int), the rest float
    if i gt 6 and temp[i] ge 0 then var_locs[i]=var_locs[i]-1
    str_temp=strmid(str_temp,temp1+len,tot_len)
    add_len=add_len+temp1+len
  endfor

  free_lun,file_unit


  ;-----------------------------------
  ;Read record object
  fieldnames  = sca_info.name
  temp=sca_info.format
  fieldcount=n_elements(temp)
  fieldformat = strarr(2,fieldcount)
  fieldtype=intarr(fieldcount)
  for i=0, nsca-1 do fieldformat[*,i] = strsplit(temp[i],',',/extract)
  fieldformat = strmid(reform(fieldformat[1,*]),0,1)
  ppi=where(fieldformat eq 'I',cci)
  ppf=where(fieldformat eq 'F',ccf)
  if cci ne 0 then fieldtype[ppi]=2
  if ccf ne 0 then fieldtype[ppf]=4
  nvars = n_elements(fieldnames)
  if nvars ne 11 then begin
    print,'ERROR: Format structure changed in .sts file'
    return,0
  endif
  index=n_elements(endobj_pos)-1
  template={$
    VERSION:1.0,$
    DATASTART:endobj_pos[index]+2L,$
    DELIMITER:byte(32),$
    MISSINGVALUE:!VALUES.F_NAN,$
    COMMENTSYMBOL:';',$
    FIELDCOUNT:fieldcount,$
    FIELDTYPES:fieldtype,$
    FIELDNAMES:fieldnames,$
    FIELDLOCATIONS:var_locs,$
    FIELDGROUPS:indgen(fieldcount)}
  data_asc=read_ascii(file,template=template)
  nvals=n_elements(data_asc.year)




  ;-----------------------------------
  ;Convert time to unix time
  time_unix = replicate(time_struct(0D), n_elements(data_asc.year))
  time_unix.year = data_asc.year
  time_unix.doy = data_asc.doy
  time_unix.hour = data_asc.hour
  time_unix.min = data_asc.min
  time_unix.sec = data_asc.sec
  time_unix.fsec = double(data_asc.msec)/1000D
  doy_to_month_date, data_asc.year, data_asc.doy, month, date
  time_unix.month = month
  time_unix.date = date
  time_unix = time_double(time_unix)

  data_str0 = {time:0d, vec:[0.,0.,0.],range:0.}
  data_str = replicate(data_str0,nvals)

  data_str.time = time_unix
  data_str.vec[0] = data_asc.x
  data_str.vec[1] = data_asc.y
  data_str.vec[2] = data_asc.z
  data_str.range =  data_asc.range

  if 1 then begin

    ;-----------------------------------
    ;Find frame from filename
    sts_pos=strpos(file,'.sts')
    tn=['pl','ss','pc']
    spice_frames= ['MAVEN_SPACECRAFT','ss-?','pc-?']
    temp=[strpos(strmid(file,0,sts_pos[0]),tn[0]),$
      strpos(strmid(file,0,sts_pos[0]),tn[1]),$
      strpos(strmid(file,0,sts_pos[0]),tn[2])]
    pp=where(temp ne -1,cc)
    if cc eq 0 or cc gt 1 then begin
      print, 'ERROR: No frame designation '+$
        '(pl,ss,pc) identified'
      return,0
    endif
    frame=tn[pp[0]]
    spice_frame = spice_frames[pp[0]]
    ;  str_element, data_asc, 'frame', frame, /add


    ;-----------------------------------
    ;Create structures and arrays
    if 0 then begin
      for i=0, nvec-1 do begin
        cmd=''
        temp1=strsplit(vec_info[i].var_name,' ',/extract)
        temp2=strsplit(vec_info[i].var_type,' ',/extract)
        nn=n_elements(temp1)
        for ii=0, nn-1 do append_array,cmd,temp1[ii]+':data_asc.'+temp1[ii]
        tt1=execute(vec_info[i].name+'={'+strjoin(cmd,',')+'}')
        vec=strlowcase(vec_info[i].name)
        tt2=execute("str_element, data, '"+vec+"',"+vec+",/add")
      endfor
      str_element, data, 'time_unix',/add
    endif
    data=0
;    str_element, data, 'Creation_time',time_string(systime(1)), /add
    str_element, data, 'sts_file', filename, /add
    str_element, data, 'spice_frame',spice_frame, /add
    str_element, data, 'frame', frame, /add
    str_element, data, 'header_full', obj_str, /add
    str_element, data, 'header_info', header_struc, /add
    ;  str_element, data, 'scalar_info', sca_info, /add
    ;  str_element, data, 'vector_info', vec_info, /add
    ;  str_element, data, 'spice_kernels', kernel_files, /add
    str_element, data, 'spice_list', kernel_list,/add
  endif

  header_info = data
  return,data_str

end



