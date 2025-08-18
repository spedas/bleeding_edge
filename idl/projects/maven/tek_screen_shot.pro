
pro tek_screen_shot,url,file_format,verbose=verbose,prefix=prefix,filename=filename,window=window
if not keyword_set(url) then url = 'http://128.32.13.161/image.png'
if not keyword_set(file_format) then file_format= 'TEK_YYYYMMDD_hhmmss.png'
filename = time_string(systime(1),tformat=file_format)
if keyword_set(prefix) then filename = prefix+filename
file_http_copy , url, filename,verbose=2
if n_elements(window) eq 1 then begin
        w=!d.window
        wi,window,wsize=[800,480]
        tv,/true, read_png(filename)
        wi,w
endif
;dprint,verbose=verbose,dlevel=2,'Saved TEK file ',filename
end

