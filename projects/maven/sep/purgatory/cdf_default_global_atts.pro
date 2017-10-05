function cdf_default_global_atts, attribute_names
    
attribute_names = ['Title','Project','Discipline','Source_name','Descriptor','Data_type','Data_version','TEXT','Mods', $
  'Logical_source','Logical_source_description','PI_name','PI_affiliation','Instrument_type','Mission_group',$
  'HTTP_LINK','LINK_TEXT','LINK_TITLE' ]
  
for i=0,n_elements(attribute_names)-1 do begin
   if i eq 0 then str = create_struct(attribute_names[i],'') else str=create_struct(str,attribute_names[i],'')
endfor
return,str

end

