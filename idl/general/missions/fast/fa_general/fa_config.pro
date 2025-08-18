function fa_config,category,field,valid=valid,all=all

fa_init

if keyword_set(all) then begin
	
	openr,unit,fa_pathnames('fastconfig',directory='information'),/get_lun
	
	while ~eof(unit) do begin
	
		line=''
		readf,unit,line
		line=strupcase(line)
		
		if (strpos(line,' ') EQ 0) OR (strpos(line,'	') EQ 0) then continue
		if (strpos(line,'#') EQ 0) OR (strlen(line) EQ 0) then continue
		rec=strsplit(line,'	',/extract)
		
		if strpos(line,'-') EQ 0 then begin
			rec=strsplit(line,' ',/extract)
			categ=rec[1]
			continue
		endif
		
		str_element,field_struct,categ+'.'+rec[0],rec[1],/add
		
	endwhile
	
	return,field_struct
	
endif

common fa_information,info_struct
str_element,info_struct,'configuration.'+category+'.'+field,value
if keyword_set(value) then valid=1
return,value

end