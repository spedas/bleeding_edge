; This version only works on Windows (so far)

pro ssl_wget,cmd,serverdir=serverdir,localdir=localdir,pathnames=pathnames,nowait=nowait, $
  outputfile=outputfile, $
  exit_status=exit_status, $
  verbose=verbose, $
  ncutdirs=ncutdirs



dprint,dlevel=4,verbose=verbose,'Start:  %Id %'

if 1 then timestamp = time_string(systime(1),tformat='_YYYYMMDD_hhmmss',/local) $
else timestamp = ''


if  keyword_set(pathnames) then begin
   if not keyword_set(listfile) then begin
      tempfile = 'wget-list'+timestamp+'.txt'
      tempfile = filepath(/tmp,tempfile)
      openw,unit,tempfile,/get_lun,/append
      for i=0,n_elements(pathnames)-1 do printf,unit,pathnames[i]
      flush,unit
      free_lun,unit
      listfile=tempfile
   endif
endif

dprint,dlevel=2,'Checking remote server ',serverdir,' for the following ',n_elements(pathnames),' files:'
for i=0,n_elements(pathnames)-1 do dprint,dlevel=2,verbose=verbose,pathnames[i]
dprint,dlevel=3,verbose=verbose,'Download list file: "',listfile,'"'

;wget_exe = 'wget'
;scope=scope_traceback(/struct)
;dir = file_dirname(scope[n_elements(scope)-1].filename)
;prog ='"'+dir+'/wget" '

if not keyword_set(opts) then opts = ' --timestamp -x -nH'   ; Use timestamps, retain directory structure, ignore host directories
;opts = '--help '
if keyword_set(localdir) then opts=opts+ ' -P'+localdir          ; Quoting localdir seems to fail on windows, Using environment variable
if keyword_set(pathnames) then opts=opts+ ' -i "'+listfile+'"'
if keyword_set(serverdir) then begin
    opts = opts+' -B '+serverdir
    if n_elements(ncutdirs) eq 0 then begin   ; determine number of directories to cut
       pos = 0
       n = -1
       while pos ge 0 do begin
          pos = strpos(serverdir,'/',pos+1)
          n=n+1
       endwhile
    endif
    ncutdirs = n-3 > 0
endif
if keyword_set(ncutdirs) then opts = opts+' --cut-dirs='+strtrim(ncutdirs,2)
if keyword_set(outputfile) then begin
  opts=opts+' -o '+outputfile
  hide = 1
endif
;if not keyword_set(nowait) then opts = opts+'-o wget.log '
wgetcmd = 'wget '+opts + ( keyword_set(cmd) ? cmd : '')

;printdat,prog,opts,cmd,wgetcmd

for i=0,n_elements(pathnames)-1 do dprint,dlevel=4,pathnames[i]
dprint,dlevel=3,verbose=verbose,wgetcmd

if !version.os_family eq 'Windows' then begin    ; Windows only:
   hide=1
   setenv,'wgetcmd='+wgetcmd   ;This is needed to get around quote problems in MS Windows
   if listfile eq '-' then begin   ; pipes
      spawn,'%wgetcmd%',exit_status=exit_status,nowait=nowait,hide=hide,pid=pid,unit=lunit ;,result,stderr ;,count=count
      dprint,dlevel=2,verbose=verbose,'unit=',lunit
      dprint,dlevel=2,verbose=verbose,/phelp,exit_status
      dprint,dlevel=2,verbose=verbose,/phelp,pathnames
      for i=0,n_elements(pathnames)-1 do printf,unit,pathnames[i]
      flush,lunit
      wait,.2
      if keyword_set(lunit) then free_lun,lunit
   endif else begin
      spawn,'%wgetcmd%',exit_status=exit_status,hide=hide ;,result,stderr ;,count=count
   endelse
endif else begin   ; all other (UNIX)
   spawn,wgetcmd,exit_status=exit_status,unit=unit
endelse


;printdat,result,stderr,count,exit_status

nstderr = n_elements(stderr)
for i=0,n_elements(result)-1 do dprint,dlevel=3,verbose=verbose,result[i]
for i=0,nstderr-2 do dprint,dlevel=3,verbose=verbose,stderr[i]

if nstderr gt 0 then dprint,dlevel=1,verbose=verbose,stderr[nstderr-1]

;dprint,localname,file_valid(localname)

dprint,dlevel=4,verbose=verbose,/phelp,pid

end
