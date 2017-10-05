function file_search_filter,filenames,trange=trange,verbose=verbose,count=count
   if keyword_set(trange) then begin
      tr = minmax(time_double(trange))  
      ftimes = file_extract_time_from_name(filenames,/fullpath)
      s= sort(ftimes)
      ftimes= ftimes[s]
      filenames = filenames[s]
      if tr[0] eq tr[1] then w = max( where(ftimes le tr[0],nw) )  else  w = where( ftimes lt tr[1]  and ftimes ge tr[0],nw)
      if nw ne 0 then    files = filenames[w] else files=''
   endif else files=filenames
   count = n_elements(files) * keyword_set(files)
return,files
end


function file_date_filter,filenames,parameter=par
if not keyword_set(par) then par={func:'file_date_filter',trange:[0d,systime(1)]}
if n_params() eq 0 then return,par
      tr = minmax(time_double(par.trange))  
      ftimes = file_extract_time_from_name(filenames,/fullpath)
      s= sort(ftimes)
      ftimes= ftimes[s]
      filenames = filenames[s]
      if tr[0] eq tr[1] then w = max( where(ftimes le tr[0],nw) )  else  w = where( ftimes lt tr[1]  and ftimes ge tr[0],nw)
      if nw ne 0 then    files = filenames[w] else files=''
return,files
end



function file_search_plus,localdir,pathformat,trange=trange,serverdir=serverdir,verbose=verbose,min_age_limit=min_age_limit,no_download=no_download
if not keyword_set(pathformat) then pathformat='*.dat'
if  keyword_set(serverdir)   then begin
   if not keyword_set(min_age_limit) then min_age_limit = 3600 * 24 * 7  ; 1 week
   file_http_copy,pathformat,verbose=verbose,serverdir=serverdir,localdir=localdir,no_download=2,url_info=url_info,min_age_limit=min_age_limit,dir_mod='777'o,file_mode='666'o   ;get remote listings
   urls = url_info.url
   pathnames = strmid(urls,strlen(serverdir))
   nf = n_elements(pathnames)
   dprint,verbose=verbose,dlevel=3,'Found '+strtrim(nf,2)+' files on "'+serverdir+'" that match "'+pathformat+'"'
   pathnames = file_search_filter(pathnames,trange=trange,verbose=verbose,count=nf)
   dprint,verbose=verbose,dlevel=3,'Found '+strtrim(nf,2)+' files on "'+serverdir+'" within time range '+strjoin(time_string(trange),' - ')
;   dprint,verbose=verbose,dlevel=3,pathnames
   if not keyword_set(no_download) then $
     file_http_copy,pathnames,verbose=verbose,serverdir=serverdir,localdir=localdir,no_download=no_download,min_age_limit=min_age_limit, $
             url_info=url_info,dir_mod='777'o,file_mode='666'o,archive_ext='.arc'   ;get remote files
endif
filepath = file_search(localdir,pathformat,count=nf)
dprint,verbose=verbose,dlevel=3,'Found '+strtrim(nf,2)+' files on "'+localdir+'" that match "'+pathformat+'"'
dprint,verbose=verbose,dlevel=4,filepath
if not keyword_set(filepath) then return, ''          ; no files found
filepath = file_search_filter(filepath,trange=trange,verbose=verbose,count=count)
if keyword_set(trange) then dprint,verbose=verbose,dlevel=3,'Found '+strtrim(count,2)+' files on "'+localdir+'" within time range '+strjoin(time_string(trange),' - ')
dprint,verbose=verbose,dlevel=4,filepath
return,filepath
end



