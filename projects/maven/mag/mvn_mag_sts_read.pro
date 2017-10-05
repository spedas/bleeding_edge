;+
; PROCEDURE: 
;	MVN_MAG_STS_READ
;
; PURPOSE: 
;	Read magnetometer .sts files
;
; AUTHOR: 
;	Roberto Livi (rlilvi@ssl.Berkeley.edu)  and Davin Larson
;
; CALLING SEQUENCE:
;       
;
; KEYWORDS:
;	FILENAME: String containing .sts filename to be loaded
;
; NOTES:
;      Uses append_array.pro
;
; EXAMPLE:
;     IDL> data_structure = mvn_mag_sts_read( filename, header = header)   
;         
; HISTORY:
;
; VERSION:
;   $LastChangedBy: rlivi2 $
;   $LastChangedDate: 2014-10-03 15:10:00 -0500 (Fri, 03 Otc 2014)$
;   $LastChangedRevision: 2014-10-03 15:10:00 -0500 (Fri, 03 Otc 2014)$
;   $URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/projects/general/CDF/mag_sts_to_cdf.pro$
;-


function mvn_mag_sts_read, filename,$
                           header=header



  ;;-------------------------------------------------
  ;;Check if file exists
  file=file_search(filename)
  if size(file,/type) eq 7 and file[0] eq '' then begin
     print, 'ERROR: File '+filename+' not found/loaded.'
     return,0
  endif

  ;;-------------------------------------------------
  ;; Load file
  openr, file_unit, file, /get_lun
  nrows = file_lines(file) 

  ;;-----------------------------------
  ;; Extract information from filename
  rootdir='';!ROOTDIR
  temp1=strsplit(filename,'_',/extract)
  mission=temp1[0]
  instr=temp1[1]
  level=temp1[2]
  doy=temp1[3]
  year=strmid(doy,0,4)
  doy=strmid(doy,5,3)
  ymd=temp1[4]
  month=strmid(ymd,4,2)
  day=strmid(ymd,6,2)
  

  ;;-------------------------------------------------
  ;; 1. Save each line into head_str as a string 
  ;; 2. Locate start/stop indices of object:
  ;;   a. HEADER 
  ;;   b. KERNEL_LIST
  ;;   c. VECTOR
  ;;   d. SCALAR
  head_str    = strarr(1000)
  head_temp   = ''
  obj_counter = 0
  obj_num     =-1
  while obj_num ne 0 do begin     
     if obj_num lt 0 then obj_num = 0
     readf, file_unit, head_temp
     head_str[obj_counter] = head_temp
     str_temp1 = strtrim(head_temp,2)
     str_temp2 = strtrim(strsplit(str_temp1,'=',/extract),2)
     append_array, obj_str, str_temp1
     if n_elements(str_temp2) gt 1 then begin 
        case str_temp2[0] of
           'OBJECT':begin
              append_array, last_item, str_temp2[1]
              obj_num++
              append_array, sta_ind, obj_counter
           end
           'NAME':       append_array, nam_start, obj_counter
           'ALIAS':      append_array, ali_start, obj_counter
           'TYPE':       append_array, typ_start, obj_counter
           'UNITS':      append_array, uni_start, obj_counter
           'FORMAT':     append_array, for_start, obj_counter
           else: break
        endcase
        case str_temp2[1] of
           'FILE':       append_array, fil_start, obj_counter
           'HEADER':     append_array, hea_start, obj_counter
           'KERNEL_LIST':append_array, ker_start, obj_counter
           'VECTOR':     append_array, vec_start, obj_counter
           'SCALAR':     append_array, sca_start, obj_counter
           'RECORD':     append_array, rec_start, obj_counter
           'NAME':       append_array, nam_start, obj_counter
           'ALIAS':      append_array, ali_start, obj_counter
           'TYPE':       append_array, typ_start, obj_counter
           'UNITS':      append_array, uni_start, obj_counter
           'FORMAT':     append_array, for_start, obj_counter
           else: break
        endcase
     endif else begin
        if str_temp2[0] eq 'END_OBJECT' then begin
           append_array, end_ind, obj_counter
           obj_num--
           nnn=n_elements(last_item)
           ;;------------------------
           ;;Match to start of object
           if nnn eq 0 then stop, 'Not within object.'
           li=last_item[nnn-1]           
           case li of
              'VECTOR':     append_array, vec_stop, obj_counter
              'SCALAR':     append_array, sca_stop, obj_counter
              'HEADER':     append_array, hea_stop, obj_counter
              'RECORD':     append_array, rec_stop, obj_counter
              'FILE':       append_array, fil_stop, obj_counter
              'KERNEL_LIST':append_array, ker_stop, obj_counter
              else: break              
           endcase
           if nnn gt 1 then last_item=last_item[0:nnn-2] else last_item=''
        endif
     endelse
     obj_counter++
  endwhile
  head_str=head_str[0:obj_counter-1]

  ;;----------------------------------------------
  ;; Parse Header Object
  ;;Check if header exists
  header = head_str[hea_start[0]:hea_stop[0]]
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

  ;;-----------------------------------
  ;;Parse Kernel List
  kernels = head_str[ker_start[0]:ker_stop[0]]
  for i=1, n_elements(kernels)-2 do begin
     temp1=strtrim(strsplit(head_str[ker_start[0]+i],'=',/extract),2)
     temp2=strtrim(strsplit(temp1[0],' ',/extract),2)
     nn=n_elements(temp2)-1
     tt1=temp2[0]
     tt2=temp2[nn]
     if tt1 ne 'END_OBJECT' then $
        append_array,kernel_files,tt2     
  endfor
  
  ;;----------------------------------------------
  ;;Create data structure
  nsca = n_elements(sca_start)  
  for isca = 0, nsca-1 do begin
     start = sca_start[isca]
     stopp = sca_stop[isca]
     pp_vec = where(vec_stop  gt stopp and $
                    vec_start lt start,nvec)
     ;;---------------------------
     ;;Scalar with no vector
     if nvec eq 0 then begin
        pp_name   = where(nam_start gt start,nnam)
        pp_type   = where(typ_start gt start,ntyp)
        pp_units  = where(uni_start gt start,nuni)
        pp_alias  = where(ali_start gt start,nali)
        pp_format = where(for_start gt start,nfor)
        ;;--------------------------------------
        ;;Make sure scalar has a name and format        
        if nnam gt 0 and nfor gt 0 then begin
           ;;Name
           str = head_str[nam_start[pp_name[0]]]
           temp = strtrim(strsplit(str,'=',/extract),2)
           name=temp[1]
           ;;Format
           str = head_str[for_start[pp_format[0]]]
           temp = strtrim(strsplit(str,'=',/extract),2)
           temp = strtrim(strsplit(temp[1],',',/extract),2)
           if n_elements(temp) gt 1 then format=strmid(temp[1],0,1) $
           else format=strmid(temp[0],0,1)
           if format eq 'I' then str_element, values, name, 0  , /add
           if format eq 'F' then str_element, values, name, 0.0, /add
        endif
     endif
     ;;---------------------------
     ;;Scalar within vector
     if nvec gt 0 then begin
        ;;--------------------------------------
        ;;Find Vector name
        vstart = vec_start[pp_vec[0]]
        pp1       = where(nam_start gt vstart)
        pp2       = head_str[nam_start[pp1[0]]]
        temp      = strtrim(strsplit(pp2,'=',/extract),2)
        vec_name  = temp[1]
        pp_name   = where(nam_start gt start,nnam)
        pp_type   = where(typ_start gt start,ntyp)
        pp_units  = where(uni_start gt start,nuni)
        pp_alias  = where(ali_start gt start,nali)
        pp_format = where(for_start gt start,nfor)
        ;;--------------------------------------
        ;;Make sure scalar has a name and format
        if nnam gt 0 and nfor gt 0 then begin
           ;;Name
           str = head_str[nam_start[pp_name[0]]]
           temp = strtrim(strsplit(str,'=',/extract),2)
           name=temp[1]
           ;;Format
           str = head_str[for_start[pp_format[0]]]
           temp = strtrim(strsplit(str,'=',/extract),2)
           temp = strtrim(strsplit(temp[1],',',/extract),2)
           if n_elements(temp) gt 1 then format=strmid(temp[1],0,1) $
           else format=strmid(temp[0],0,1)
           if format eq 'I' then str_element, $
              values, vec_name+'_'+name, 0  , /add
           if format eq 'F' then str_element, $
              values, vec_name+'_'+name, 0.0, /add
        endif
     endif
  endfor


  ;;-----------------------------------------
  ;; Read data
  ;; NOTE: If the end of the file contains an 
  ;;       empty line then adjust for it. 
  tmp=''
  temp=0
  while ~eof(file_unit) do begin
     readf, file_unit, tmp
     if strtrim(tmp,2) eq '' then temp++
  endwhile
  ;; Reload file
  free_lun, file_unit
  openr, file_unit, file, /get_lun
  data  = replicate(values,nrows-fil_stop[0]-1-temp)
  for i=0, fil_stop[0] do readf, file_unit, tmp
  readf, file_unit, data
  free_lun, file_unit


  ;;-----------------------------------------
  ;; Resize structure
  if n_elements(data.time_year) gt 0 then pp=where(data.time_year ne 0) $
  else stop,'No time variable present.'
  data=data[pp]


  ;;-----------------------------------
  ;; Find frame from filename
  sts_pos      = strpos(filename,'.sts')
  tn           = ['pl','ss','pc']
  spice_frames = ['MAVEN_SPACECRAFT','MAVEN_MSO','IAU_MARS']
  temp = [strpos(strmid(filename,0,sts_pos[0]),tn[0]),$
          strpos(strmid(filename,0,sts_pos[0]),tn[1]),$
          strpos(strmid(filename,0,sts_pos[0]),tn[2])]
  pp = where(temp ne -1,cc)
  if cc eq 0 or cc gt 1 then begin
     ;;------------------
     ;; Find from vector
     pos=strlowcase($
         strsplit($
         strsplit($
         strjoin($
         tag_names(values),$
         '_'),$
         /extract,escape='B'),$
         '_', /extract))
     pp=where(pos eq tn[0] or $
              pos eq tn[1] or $
              pos eq tn[2],cc)
     if cc eq 0 then begin
        print, "No Frame found (default='NA')"
        frame = 'NA'
        spice_frame = 'NA'
     endif else begin
        frame = pos[pp[0]]
        spice_frame = spice_frames[where(frame eq tn)]        
     endelse        
  endif else begin
     frame       = tn[pp[0]]
     spice_frame = spice_frames[pp[0]]
  endelse



  ;;-----------------------------------
  ;; Find level from filename
  sts_pos = strpos(file,'.sts')
  ilevel  = strsplit(strmid(filename,0,sts_pos[0]),'_',/extract)
  pp = where(ilevel eq 'l1' or ilevel eq 'l2',cc)
  if cc eq 0 or cc gt 1 then begin
     print, "ERROR: No level designation "+$
            "identified from filename (default='l1')."
     ilevel='l1'
  endif
  level =  ilevel[pp]


  ;;-----------------------------------
  ;; Convert time to unix time
  time_unix = replicate(time_struct(0D), n_elements(data.time_year))
  time_unix.year  = data.time_year
  time_unix.doy   = data.time_doy
  time_unix.hour  = data.time_hour
  time_unix.min   = data.time_min
  time_unix.sec   = data.time_sec
  time_unix.fsec  = double(data.time_msec)/1000D
  doy_to_month_date, data.time_year, data.time_doy, month, date
  time_unix.month = month
  time_unix.date  = date
  time_unix       = time_double(time_unix)
  
  ;;--------------------------------------------
  ;; Structure for  header information
  str_element, header_info, 'time_unix',     time_unix,    /add 
  str_element, header_info, 'frame',         frame,        /add
  str_element, header_info, 'header',        head_str,     /add
  str_element, header_info, 'spice_frame',   spice_frame,  /add      
  str_element, header_info, 'spice_kernels', kernel_files, /add    
  header = header_info

  ;;-------------------------------------
  ;; Add new time variables
  str_element, data, 'TIME',  time_unix, /add

  ;-----------------------------------------
  ;Create arrays according to Davin's e-mail
  ;B_structure = {time:0d, vector:[0.,0.,0.]}
  ;B = replicate(b_structure, n)
  nn    = n_elements(data)
  tags  = tag_names(data)
  ntags = n_elements(tags)
  pp    = where(strmid(tags,0,5) ne 'TIME_' and $
             tags ne 'DDAY',vnn)
  ;vtags  = ['TIME',tags[pp]]
  vtags  = tags[pp]
  nvtags = n_elements(vtags)
  tpp    = where(strmid(tags,0,5) eq 'TIME_' or $
             tags eq 'DDAY',tnn)
  tvtags  = tags[tpp]
  ntvtags = n_elements(tvtags)
  new_values = values

  ;;----------------------------------------
  ;; Remove time variables from 'values' 
  secc = data.time_sec
  minn = data.time_min
  for i=0, tnn-1 do $
     temp=execute("str_element, new_values, tvtags[i], '', /delete")  
  data2 = replicate(new_values, nn)

  ;;-------------------------------------
  ;; Add new time variables
  str_element, data2, 'TIME',  time_unix, /add

  for i=0, vnn-1 do $
     temp=execute("data2."+vtags[i]+" = data."+vtags[i])
  ;data = data2
  data = 0

  ;;--------------------------------------
  ;; SPECIAL CASE FOR L1 FILES
  ;; L1 files use a different structure than
  ;; L2 files because the mag team changed the 
  ;; sts file structure.
  pp = where(vtags eq 'OB_BPL_X',cc)
  if level eq 'l1' and cc ne 0 then begin          
     data = replicate({time:0.D,vec:[0.,0.,0.],range:0.},nn)
     data.range  = data2.ob_bpl_range
     data.vec[0] = data2.ob_bpl_x
     data.vec[1] = data2.ob_bpl_y
     data.vec[2] = data2.ob_bpl_z
     data.time   = data2.time
  endif else data = data2
  
  return, data

end


















  ;;;--------------
  ;;;--------------
  ;;;--------------
  ;;;FUTURE VERSION


  ;;###########################################################################
  ;; Write to CDF

  ;;dir_cdf =rootdir+'/maven/data/sci/mag/'+level+'/'+year+'/'+month+'/cdf/'

  ;;----------------------------------------------------
  ;; Create cdf 
  ;sts_pos=strpos(file,'.sts')
  ;;cdf_filename=dir_cdf+strmid(file,0,sts_pos[0])+'.cdf'
  ;cdf_filename=strmid(file,0,sts_pos[0])+'.cdf'
  ;fileid = cdf_create(cdf_filename,$
  ;                    /single_file,$
  ;                    /network_encoding,$
  ;                    /clobber)

  ;;----------------------------------------------------
  ;; Create cdf header and add information
  ;id0  = cdf_attcreate(fileid,'DATE',        /global_scope)
  ;id1  = cdf_attcreate(fileid,'HOST',        /global_scope)
  ;id2  = cdf_attcreate(fileid,'TITLE',       /global_scope)
  ;id3  = cdf_attcreate(fileid,'FRAME',       /global_scope)
  ;id4  = cdf_attcreate(fileid,'PROGRAM',     /global_scope)
  ;id5  = cdf_attcreate(fileid,'COMMENT',     /global_scope)
  ;id6  = cdf_attcreate(fileid,'CMD_LINE',    /global_scope)
  ;id7  = cdf_attcreate(fileid,'KERNEL_FILES',/global_scope)

  ;cdf_attput,fileid,'DATE',0,header_struc.date
  ;cdf_attput,fileid,'HOST',0,header_struc.host
  ;cdf_attput,fileid,'TITLE',0,header_struc.title
  ;cdf_attput,fileid,'FRAME',0,frame
  ;cdf_attput,fileid,'PROGRAM',0,header_struc.program
  ;cdf_attput,fileid,'COMMENT',0,header_struc.comment
  ;cdf_attput,fileid,'CMD_LINE',0,header_struc.cmd_line
  ;cdf_attput,fileid,'KERNEL_FILES',0,strjoin(kernel_files,',')

  ;--------------------
  ;Attributes
  ;dummy = cdf_attcreate(fileid,'OBJECT',/variable_scope)
  ;dummy = cdf_attcreate(fileid,'NAME',/variable_scope)
  ;dummy = cdf_attcreate(fileid,'ALIAS',/variable_scope)
  ;dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
  ;dummy = cdf_attcreate(fileid,'TYPE',/variable_scope)
  ;dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)

  ;--------------------
  ;Insert Variables
  ;nn=n_elements(sca_info)
  ;for i=0., nn-1 do begin
  ;   if fieldtype[i] eq 2 then $
  ;      varid = cdf_varcreate(fileid,sca_info[i].name, /CDF_INT2  ,/ZVARIABLE)
  ;   if fieldtype[i] eq 4 then $
  ;      varid = cdf_varcreate(fileid,sca_info[i].name, /CDF_DOUBLE,/ZVARIABLE)
  ;   cdf_attput,fileid,'OBJECT',varid,'SCALAR'          ,/ZVARIABLE
  ;   cdf_attput,fileid,'NAME'  ,varid,sca_info[i].name  ,/ZVARIABLE
  ;   cdf_attput,fileid,'ALIAS' ,varid,sca_info[i].alias ,/ZVARIABLE
  ;   cdf_attput,fileid,'FORMAT',varid,sca_info[i].format,/ZVARIABLE
  ;   cdf_attput,fileid,'TYPE'  ,varid,sca_info[i].type  ,/ZVARIABLE
  ;   cdf_attput,fileid,'UNITS' ,varid,sca_info[i].units ,/ZVARIABLE
  ;   tt=execute('cdf_varput,fileid,sca_info[i].name,data.'+$
  ;              sca_info[i].name)
  ;endfor
  ;cdf_close,fileid
  ;skip_cdf:

