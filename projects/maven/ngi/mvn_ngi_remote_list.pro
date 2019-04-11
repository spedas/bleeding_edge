;+
; FUNCTION:
;       mvn_ngi_remote_list
; PURPOSE:
;       returns lists of NGIMS L2 files in the server without downloading them
; CALLING SEQUENCE:
;       f = mvn_ngi_remote_list(filetype='csn',latestv=v,latestr=r)
; INPUTS:
;       None
; KEYWORDS:
;       trange: time range (if not present then timerange() is called)  
;       filetype: 'csn', 'cso', 'ion', etc. (Def: '*') 
;       latestversion: returns the latest version number in string
;       latestrevision: returns the latest revision number in string
;       level: 'l2' or 'l1b' (Def: 'l2')
; CREATED BY:
;       Yuki Harada on 2015-07-13
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-04-10 10:43:30 -0700 (Wed, 10 Apr 2019) $
; $LastChangedRevision: 26991 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/ngi/mvn_ngi_remote_list.pro $
;-

function mvn_ngi_remote_list, trange=trange, filetype=filetype, verbose=verbose, _extra=_extra, latestversion=version, latestrevision=revision, level=level

  if ~keyword_set(filetype) then filetype = '*'
  if ~keyword_set(level) then level = 'l2'
  dprint,verbose=verbose,'checking ngi '+level+' file list: '+filetype

  ;;; set pathnames to search
  pformat = 'maven/data/sci/ngi/'+level+'/YYYY/MM/mvn_ngi_'+level+'_'+filetype+'-*_YYYYMMDD?hh????_v??_r??.csv'
  res = 3600L & sres = 0L       ;- hourly check
  tr = timerange(trange)
  str = (tr-sres)/res
  dtr = (ceil(str[1]) - floor(str[0]) )  > 1
  times = res * (floor(str[0]) + lindgen(dtr))+sres
  pathnames = time_string(times,tformat=pformat)
  pathnames = pathnames[uniq(pathnames)]

  ;;; extract directory & file names to search
  pfiles = pathnames
  for ipn=0,n_elements(pathnames)-1 do begin
     slashpos1 = strpos(pathnames[ipn],'/',/reverse_search)
     pfiles[ipn] = strmid(pathnames[ipn],slashpos1+1)
     if ipn eq 0 then dpathnames = strmid(pathnames[ipn],0,slashpos1+1) $
     else dpathnames = [dpathnames,strmid(pathnames[ipn],0,slashpos1+1)]
  endfor
  dpathnames = dpathnames[uniq(dpathnames)]

  s = mvn_file_source(no_download=0,last_version=0,_extra=_extra)

  f = ''
  if s.no_server eq 0 then begin
     for idpn=0,n_elements(dpathnames)-1 do begin
        ;;; download directory and extract links from .remote-index.html
        dum = file_retrieve(dpathnames[idpn],links=links,source=s)
;        file_http_copy,dpathnames[idpn],serverdir=s.remote_data_dir,localdir=s.local_data_dir,url_info=url_info,verbose=verbose,_extra=s,links=links,file_mode='666'o,dir_mode='777'o ;- obsolete
        for ipf=0,n_elements(pfiles)-1 do begin
           w = where( strmatch(links,pfiles[ipf]) , nw )
           if nw gt 0 then f = [f,links[w]]
        endfor
     endfor
  endif else f = file_retrieve(pathnames,_extra=s,/valid_only)
  w = where( strlen(f) gt 0 , nw )
  if nw eq 0 then files = '' else files = f[w]

  vidx = strpos(f,'_v')
  w = where( vidx ne -1 , nw )
  if nw gt 0 then version = string(max(fix(strmid(f[w],vidx[w]+2,2))),f='(i2.2)') else version='' ;- latest version
  w = where( strmatch(f,'*_v'+version+'*') , nw )
  if nw gt 0 then f = f[w]      ;- only latest version files
  ridx = strpos(f,'_r')
  w = where( ridx ne -1 , nw )
  if nw gt 0 then revision = string(max(fix(strmid(f[w],ridx[w]+2,2))),f='(i2.2)') else revision='' ;- latest revision

  return,files

end
