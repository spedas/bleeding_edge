pro tekscope_rename_files

files = file_search('e:/temp/scope/tek00*.png')
finfo = file_info(files)
dirname = file_dirname(files)
for i=0,n_elements(files)-1 do file_move,files[i],dirname[i]+'/'+time_string(tformat='TEK_YYYYMMDD_hhmmss.png',finfo[i].mtime)

end







function tekscope_load_all,load=load,files=files

source = mav_file_source()
pathname = 'maven/sep/prelaunch_tests/EM1/scope/TEK_*.png'
if keyword_set(load) then begin
  files = file_retrieve(pathname,_extra=source)
  load=0
endif else files = file_search(source.local_data_dir + pathname)
bname = file_basename(files)
times = str2time(bname,tformat='TEK_YYYYMMDD_hhmmss.png')
return,times
end







