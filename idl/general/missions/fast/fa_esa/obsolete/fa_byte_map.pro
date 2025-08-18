;Converts compressed bytes to 14 or 16 bit integers the slow way.

function fa_byte_map,input,totalbits,suppress=suppress

if totalbits EQ 14 then begin
	if keyword_set(suppress) then begin
		fa_init
		if file_test(!fast.local_data_dir+'information/byteto14_map') then begin
			file=!fast.local_data_dir+'information/byteto14_map'
		endif else begin
			file=fa_pathnames('byteto14_map',dir='information')
		endelse
	endif else begin
		file=fa_pathnames('byteto14_map',dir='information') 
	endelse
endif
if totalbits EQ 16 then begin
	if keyword_set(suppress) then begin
		fa_init
		if file_test(!fast.local_data_dir+'information/byteto16_map') then begin
			file=!fast.local_data_dir+'information/byteto16_map'
		endif else begin
			file=fa_pathnames('byteto16_map',dir='information')
		endelse
	endif else begin
		file=fa_pathnames('byteto16_map',dir='information')
	endelse
endif

openr,unit,file,/get_lun
convert_array=lonarr(10,26)
readf,unit,convert_array
close,unit
free_lun,unit

one_pl=input mod 10
ten_pl=(input-one_pl)/10

return,convert_array[one_pl,ten_pl]
end