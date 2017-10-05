function fa_pathnames,filename,prefix=prefix,suffix=suffix,directory=directory

fa_init

if filename EQ '.fast_master' then begin
   print,'PLEASE do not copy .fast_master.'
   print,'Quitting...'
   return,'INVALID PATHNAME'
endif

if NOT keyword_set(prefix) then prefix=''
if NOT keyword_set(suffix) then suffix=''
if NOT keyword_set(directory) then directory='' else directory+='/'
pathname=prefix+directory+filename+suffix

filename=file_retrieve(pathname,_extra=!fast)
if NOT file_test(!fast.local_data_dir+pathname) then $
print,'Error: File '+strupcase(filename)+' not present in local_data_dir.'
return,filename

end