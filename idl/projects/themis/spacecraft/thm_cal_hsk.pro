
;+
; Procedure: thm_cal_hsk
;
; Purpose:  Converts housekeeping data into physical units.
;           Generates data structure for performing conversion.
;           
; Inputs: 
;   in_names: The list of tplot names that should be converted into physical units,
;             tvars not on this list will not be modified
;             
; Outputs:
;   out_names: Set a named variable to this keyword to return the output variable names
;                    
; Notes:
;  1.  If calibrating use dprint,setdebug=5 to see detailed calibration information
;  2.  Some exceptions to the DBX style calibrations are hard-coded into the code,
;      If updating calibrations, be sure to check the arrays "naming_corrections" and "group_names"
;      to verify that they work correctly with modifications.
;  3.  Overall, the calibration is a two part process.  A. Tables are pre-generated using DBX records when thm_cal_hsk_make_tables is called.
;      These tables completely describe the conversions, with the exception of the exceptions named in #2.  The conversion tables 
;      are loaded and used to transform the data when thm_cal_hsk is called.  The end-user should never have to call
;      thm_cal_hsk_make_tables
;           
; $LastChangedBy: pcruce $
; $LastChangedDate: 2009-07-13 14:47:13 -0700 (Mon, 13 Jul 2009) $
; $LastChangedRevision: 6425 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/thm_cal_hsk.pro $
;- 

;helper function, properly converts dbx colors for discrete conversions into themis colors 
function thm_cal_hsk_conv_colors,in_colors

  compile_opt idl2,hidden
  
  colors = strlowcase(in_colors)

  out_colors = lonarr(n_elements(in_colors))

  col_names = ['black','red','green','yellow','blue','magenta','cyan','white']
  col_perm = [0,6,4,5,2,1,3,255]

  for i = 0,7 do begin
  
    idx = where(colors eq col_names[i] or colors eq strtrim(i,2),c)
    if c gt 0 then begin
      out_colors[idx] = col_perm[i]
    endif
  
  endfor

  return,out_colors
  
end

;helper function modularizes repeated record extraction code
pro thm_cal_hsk_get_records,file_strings,record_type,record_length,out_records

  compile_opt idl2,hidden

  ;split the file into records by type
  ;and split the records into individual fields
  record_types = strlowcase(strmid(file_strings,0,3))
  
  idx = where(record_types eq record_type,rec_num)
  if rec_num gt 0 then begin
    records = strarr(rec_num,record_length)      
    for i = 0,rec_num-1 do begin
      rec = strtrim(strsplit(file_strings[idx[i]],'|',/extract,/preserve_null),2)
      records[i,*] = rec[0:record_length-1]
    endfor
    
    if ~keyword_set(out_records) then begin
      out_records = records
    endif else begin
      out_records = [out_records,records]
    endelse
  endif
 
end

;helper function modularizes repeated file read code
pro thm_cal_hsk_read_file,path,lines

  compile_opt idl2,hidden
 
  s = ''

  line_num = file_lines(path)
  lines = strarr(line_num)
  
  ;read the file into an array
  openr,lun,path,/get_lun
  for i = 0,line_num-1 do begin
    readf,lun,s
    lines[i] = strtrim(s,2)
  endfor
  close,lun
  free_lun,lun
    
  ;remove all lines that are non-records
  first = strmid(lines,0,1)
  idx = where(first ne '#' and first ne '')
  lines = lines[idx]
  
end

;helper function swaps names of telemetry conversions, if appropriate
function thm_cal_hsk_correct_name,in_name

  compile_opt idl2,hidden
  
  ;some of the names used in the CDF differ from the DBX records, this associative array identifies the transformations
  naming_corrections = [['imon_p25vd','ivmon_p25vd','imon_efi_board','imon_efi_x','imon_efi_y','imon_efi_z','idcb3v','prmy_htri','scnd_htri'],$  ;Name in CDF
                      ['imon_p2_5vd','ivmon_p2_5vd','imon_efiboard','imon_efix','imon_efiy','imon_efiz','idcb_3v','iprmy_htri','iscnd_htri']] ;Name in DBX record
                      
  idx = where(in_name eq naming_corrections[*,1],c)
  
  if c eq 1 then begin
    return,naming_corrections[idx,0]
  endif else begin
    return,in_name
  endelse
   
end

;this helper routine constructs a data structure that describes the conversion for each 
;quantity that requires calibration. The structure is stored in an IDL sav, and distributed
;It is constructed from the THEMIS MOC dbx records 
pro thm_cal_hsk_make_tables,dbxpaths,outpath

  compile_opt idl2,hidden
    
  ;Read raw records from file
  for i = 0,n_elements(dbxpaths)-1 do begin
  
    thm_cal_hsk_read_file,dbxpaths[i],file_strings
    
    ;get tlm records
    thm_cal_hsk_get_records,file_strings,'tlm',15,tlm_records
    
    ;get alg records
    thm_cal_hsk_get_records,file_strings,'alg',12,alg_records
    
    ;get dsc records    
    thm_cal_hsk_get_records,file_strings,'dsc',9,dsc_records     
        
    ;get xpr records
    thm_cal_hsk_get_records,file_strings,'xpr',7,xpr_records 
    
  endfor
  
  ;turn records into conversions
  
  for i = 0,(dimen(tlm_records))[0]-1 do begin
  
    tlm_record = reform(tlm_records[i,*])
    
    tlm_name = thm_cal_hsk_correct_name(strlowcase(tlm_record[1]))
    tlm_conv = tlm_record[11]
    
    ;these 'if' statements look a little weird because it takes a bit of finangling to do assignments inside conditional in idl
    if n_elements((idx = where(tlm_conv eq alg_records[*,1],c))) ne 1 || c gt 0 then begin
      alg_record = reform(alg_records[idx,*])    
      coefs = alg_record[3:10]
      cf_idx = where(~is_numeric(coefs),cf_num)
            
      if cf_num ne 0 then begin
        coefs[cf_idx] = '0'
      endif
      
      conversions = csvector({type:'alg',name:tlm_name,conversion:coefs},conversions)
    
    endif else if n_elements((idx = where(tlm_conv eq dsc_records[*,1],c))) ne 1 || c gt 0 then begin
    
      dsc_labels = dsc_records[idx,2]
      dsc_mins = float(dsc_records[idx,4])
      dsc_maxs = float(dsc_records[idx,5])
      dsc_colors = thm_cal_hsk_conv_colors(dsc_records[idx,6])
      
      conversions = csvector({type:'dsc',name:tlm_name,labels:dsc_labels,mins:dsc_mins,maxs:dsc_maxs,colors:dsc_colors},conversions)
      
      if c gt 64 then begin
        dprint,'Warning! Cannot do discrete conversion with more than 64 bits'
      endif
   
    endif else if n_elements((idx = where(tlm_conv eq xpr_records[*,1],c))) ne 1 || c gt 0 then begin
    
      xpr_record = reform(xpr_records[idx,*])
      conversions = csvector({type:'xpr',name:tlm_name,conversion:xpr_record[3]},conversions)
    
    endif
    
;     else begin  ;no conversion
;    
;      conversions = csvector({type:'none',name:tlm_name},conversions)
;      
;    endelse
     
  endfor

  save,conversions,filename=outpath

end

;platform independent mechanism to find file where conversions are stored
pro thm_cal_hsk_path,cpath

  compile_opt idl2,hidden

  rt_info = routine_info('thm_cal_hsk_path',/source) 
  cpath = file_dirname(rt_info.path) + '/thm_hsk_conversions.sav'

end

;this routine substitutes '_conv' in place of '_raw' in a name
function thm_cal_hsk_sub_name,name

  compile_opt idl2,hidden
  
  if strmatch(name,'*_raw') then begin
    return,strmid(name,0,strlen(name)-strlen('_raw')) + '_cal'
  endif else begin
    return,name+'_cal'
  endelse
  
end

;this routine works like strput, but it
;can insert into multiple strings, with multiple
;substrings, and multiple positions.  
function thm_cal_hsk_strput_vec,str,sub,pos

  compile_opt idl2,hidden
  
  front = strmid(str,0,pos)
  back = strmid(str,pos+strlen(sub),strlen(str))
  
  if ndimen(front) ne 1 then begin
    fdim = min(dimen(front))
    front = front[lindgen(fdim),lindgen(fdim)]
  endif
  
  if ndimen(back) ne 1 then begin
    bdim = min(dimen(back))
    back = back[lindgen(bdim),lindgen(bdim)]
  endif
  
  return,front+sub+back
  
end

;converts the string representation of
;a coeficient into a double precision representation
;It does this by either replacing the 'e' with a 'd'
;in exponential notation 1e2 -> 1d2
;or appending a 'd', 1.0 -> 1.0d
function thm_cal_hsk_alg_double,coefs

  compile_opt idl2,hidden

  out = coefs
  pos = stregex(coefs,'e',/fold_case)
  
  idx = where(pos ne -1,c,complement=cidx,ncomplement=nc)
  
  if c ne 0 then begin
    out[idx] = thm_cal_hsk_strput_vec(coefs[idx],'d',pos[idx])
  endif
  
  if nc ne 0 then begin
    out[cidx] += 'd'
  endif
  
  return,out 

end

;code handles a special case where names were grouped during raw preprocessing, and thus,
;don't match conversion names.  Unfortunately, we can't use split_vec because it doesn't
;produce the correct output names
;WARNING: mutates t_names
pro thm_cal_hsk_split_groups,t_names,groups,splits=splits

  compile_opt idl2,hidden
  
  for i = 0,n_elements(groups)-1 do begin
  
    split_name = strfilter(t_names,'*'+groups[i]+'_raw')
    
    if ~keyword_set(split_name) then continue
      
    for j = 0,n_elements(split_name)-1 do begin
    
      get_data,split_name[j],data=d,dlimit=dl,limit=l
      dim = dimen(d.y)
      
      if ndimen(d.y) ne 2 then continue 
      
      dprint,dlevel=5,'Splitting variable "' + split_name[j] + '" into components' 
      
      stem = strmid(split_name[j],0,strlen(split_name[j])-(strlen('_raw')+strlen(groups[i]))) 
      comp_names = stem+groups[i]+strtrim(lindgen(dim[1])+1,2)+'_raw'
      if n_elements(t_names) eq 1 then begin
        t_names = [comp_names]
      endif else begin
        t_names = [ssl_set_complement([split_name[j]],t_names),comp_names]
      endelse
      
      splits = csvector({in_name:split_name[j],out_name:comp_names},splits)
      
      for k = 0,dim[1]-1 do begin
                       
        store_data,comp_names[k],data={x:d.x,y:d.y[*,k]},dlimit=dl,limit=l
    
      endfor
  
    endfor
    
  
  endfor
  

end

;reforms the variables split by thm_cal_hsk_split_groups, into
;their calibrated output
pro thm_cal_hsk_unsplit_groups,splits

  compile_opt idl2

  if ~keyword_set(splits) then return
  
  len = csvector(splits,/length)
  
  for i =0,len-1 do begin
  
    split = csvector(i,splits,/read)
    
    out_name = thm_cal_hsk_sub_name(split.in_name)
    
    in_name = strarr(n_elements(split.out_name))
    for j = 0,n_elements(in_name)-1 do begin
      in_name[j] = thm_cal_hsk_sub_name(split.out_name[j])
    endfor
    
    if ~keyword_set(tnames(in_name[0])) then begin
      dprint,dlevel=5,'Problem unsplitting "' + split.in_name + "'
    endif else begin
      dprint,dlevel=5,'Unsplitting "' + split.in_name + '" into "' + out_name + '"'
    endelse
    
    get_data,in_name[0],data=d,dlimit=dl,limit=l
    
    outd = {x:d.x,y:make_array(n_elements(d.y),n_elements(in_name),type=size(d.y,/type))}
    
    for j = 0,n_elements(in_name)-1 do begin
      get_data,in_name[j],data=d
      outd.y[*,j] = d.y
    endfor
    
    store_data,out_name,data=outd,dlimit=dl,limit=l
  
  endfor

end

;this routine actually does the conversion on each specific variable
pro thm_cal_hsk_do_cal,in_name,conv

  compile_opt idl2,hidden

  out_name = thm_cal_hsk_sub_name(in_name)

  if conv.type eq 'alg' then begin
  
    str_name = '"' + in_name + '"'
  
    coefs = thm_cal_hsk_alg_double(conv.conversion)
  
;JWL recommends using polynomial of different form (a + x*(b+x*(c)))
;to prevent computational error during subtractions
;    conv_str = '"'+out_name+'"='
;    
;    conv_str += conv.conversion[0]
;    
;    for i = 1,7 do begin
;        conv_str += '+' + conv.conversion[i] + '*"' + in_name + '"^' + strtrim(i,2)
;    endfor

    ;This polynomial string is easier to construct working right to left

     conv_str = '(' + coefs[7] + ')'

    for i = 6,0,-1 do begin
      conv_str = '(' + coefs[i] + '+' + str_name + '*' + conv_str + ')' 
    endfor
    
    conv_str = '"'+out_name+'"=' + conv_str

    ;print,conv_str
    dprint,dlevel=5,'ALG Conversion: ' + conv_str
    
    calc,conv_str,err=err
    
    if is_struct(err) then begin
      dprint,"Error in polynomial conversion for: " + in_name  
    endif
  
  endif else if conv.type eq 'dsc' then begin
  
    get_data,in_name,data=d,limit=l,dlimit=dl
    dim = dimen(d.y)
    outd = {x:d.x,y:ulon64arr(dim)}
    
    ;discrete data is often not a bit packed encoding, but a range-based encoding
    ;this converts between the two, as bitplot is the most effective way of
    ;view hsk discrete data from within tplot
    for i = 0,n_elements(conv.mins)-1 do begin
    
      idx = where(d.y ge conv.mins[i] and d.y le conv.maxs[i],c)
      if c gt 0 then begin
        outd.y[idx] = ishft(1ULL,i) 
      endif
      
    endfor
     
    dprint,dlevel=5,'DSC Conversion: "' + out_name + '" <-- "' + in_name + '"(No closed form for discrete conversion)'  
    
    store_data,out_name,data=outd,limit=l,dlimit=dl
    options,out_name,/def,labels=conv.labels,colors=conv.colors,tplot_routine='bitplot',numbits=n_elements(conv.mins),psyms=6,symsize=.3
    
  endif else if conv.type eq 'xpr' then begin
  
    conv_str = '"' + out_name + '"='
    conv_str += strjoin(strsplit(conv.conversion,'x',/extract),'"'+in_name+'"')
    
   ; print,conv_str
   
    dprint,dlevel=5,'XPR Conversion: ' + conv_str
    
    calc,conv_str,err=err
    
    if is_struct(err) then begin
      dprint,"Error in expression conversion for: " + in_name  
   ;   stop
    endif
  
  endif else begin
 
     dprint,"Error, Could not apply conversion for: " + in_name
   ;  stop
  endelse

end

pro thm_cal_hsk,in_names,out_names=out_names

  compile_opt idl2
  
  t_names = in_names
  
  dprint,'Beginning housekeeping conversion for ' + strtrim(n_elements(in_names),2) + ' values' 
  
  ;names of variables that need to be split into components to perform uniform conversions
  group_names = ['iefi_ibias','iefi_usher','iefi_guard']
  
  thm_cal_hsk_split_groups,t_names,group_names,splits=splits

  ;itm_fifostate 2x?
  ;iatt_state,idhsk_state
  ;prmy
  

  ;load conversion data from IDL save file
  thm_cal_hsk_path,convpath
  restore,convpath
  
  conv_num = csvector(conversions,/length)
  
  ;runs though the full list of conversions
  for i = 0,conv_num-1 do begin
  
    conversion = csvector(i,conversions,/read)
    
   ; print,conversion.name
    
    ;get the names that match this conversion
    idx = where(strmatch(t_names,'*'+conversion.name+'_raw',/fold_case),c,complement=cidx,ncomplement=nc)
    if c eq 0 then begin
      continue
    endif
    c_names = t_names[idx]
    
    for j = 0,n_elements(c_names)-1 do begin
     
      thm_cal_hsk_do_cal,c_names[j],conversion 
    
    endfor
    
    ;if no variables are left, then we're done
    if nc eq 0 then begin
      t_names =''
      break
    endif
    
    ;otherwise remove converted variables from the list
    t_names = t_names[cidx]
  
  endfor
  
  if keyword_set(t_names) then begin
    for i = 0,n_elements(t_names)-1 do begin
      out_name = thm_cal_hsk_sub_name(t_names[i])
      dprint,dlevel=5,'Identity Conversion: "' + out_name + '" = "' + t_names[i] + '"'
      copy_data,t_names[i],out_name
    endfor
  endif
  
  thm_cal_hsk_unsplit_groups,splits
  
  out_names = in_names
  
  for i = 0,n_elements(in_names)-1 do begin
    out_names[i] = thm_cal_hsk_sub_name(in_names[i])
  endfor
  
  dprint,'Housekeeping conversion completed' 

end