pro cdf_default_attributes,global_att_names=global_att_names,global_struct=global_struct, $
    variable_struct=variable_struct, variable_att_names=variable_att_names, $
    inq = inq,  $
    vars_template=vars_template
    
  
global_att_names = ['Project','Discipline','Data_type','Descriptor','Data_version','Instrument_type' $
  ,'Logical_file_id','Logical_source','Logical_source_description','Mission_group','PI_name','PI_affiliation' $
  ,'Source_name','TEXT'   $      
  ,'Generated_by', 'Generation_date'           $  ; optional
  ,'HTTP_LINK','LINK_TEXT','LINK_TITLE'        $   ;optional
  ,'Mods'                   $   
  ,'Parents'                $  ; 
  ,'Software_version'       $  ;
  ,'TITLE'                  $
  ]
  

for i=0,n_elements(global_att_names)-1 do begin
   if i eq 0 then global_struct = create_struct(global_att_names[i],'')  $
   else global_struct=create_struct(global_struct,global_att_names[i],'')
endfor
  
variable_struct = { $
   CATDESC:  'Catalog Description', $
   FIELDNAM: 'Variable Name', $
;   FORMAT: '5f', $
   VALIDMIN: -!values.f_infinity, $
   VALIDMAX:  !values.f_infinity, $
   FILLVAL:  !values.f_nan, $
   MONOTON:  'FALSE',   $   ; only required for NRV
   SCALEMIN:  0.,  $
   SCALEMAX:  100. }
   

inq = {NDIMS:0,decoding:'HOST_DECODING',encoding:'NETWORK_ENCODING',majority:'ROW_MAJOR' $
       ,maxrec:-1,nvars:0,nzvars:0,natts:0,dim:[0] }
       
vars_template = {name:'',Num:0,is_zvar:1,datatype:'',type:0,numattr:-1,numelem:0,recvary:1B, $
       numrec:0,ndimen:0,d:lonarr(6),dataptr:ptr_new(),attrptr:ptr_new()  }



return

end

