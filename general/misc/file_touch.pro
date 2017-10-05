;+
; FILE_TOUCH
; Purpose:  Wrapper routine for the "touch" program that sets file modification and access times
; USAGE:
;    file_touch,'foo',systime(1)-300,/mtime   ; sets mod time to 5 minutes ago
; keywords:
;    MTIME    set only modification time(UTC)
;    ATIME    set only access time(UTC)
;    VERBOSE  sets VERBOSITY of messages (0: error messages only,  6: lots)
; Restrictions:
;   #1 
;   Shell executable "touch" must be in path on local operating system.  This is common on unix systems.
;   Windows executable available from: http://sourceforge.net/projects/unxutils/
;   If the touch executable is not found then no action is taken.
;   Test for executable occurs only once.
;
;   #2 Behavior on Windows is currently untested, and may not be
;   consistent with Linux.
;    
;   #3 This routine will not work with home directories(~/file_name will not work) on linux variants.  The /noshell option to spawn means that it won't expand home directories into full paths
;  
;   #4 Routine will not work for modification date 1970-01-01/00:00:00
; 
;   #5 Time should be a UTC time in seconds since 1970.
;   Example:  file_touch,'foo',systime(1),/mtime
;
;   #6 This routine primarily for file_http_copy routine.  It
;   is not considered stable for general purpose use and the interface
;   may change. 
;
;$LastChangedBy: davin-mac $
;$LastChangedDate: 2015-10-19 16:18:58 -0700 (Mon, 19 Oct 2015) $
;$LastChangedRevision: 19110 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_touch.pro $
;-

pro file_touch,file,time,mtime=mtime,atime=atime,no_create=no_create,exit_status=status,verbose=verbose,exists=exists ;   ,toffset=toffset

common file_touch_com, touch_init,touch_version


if ~keyword_set(touch_init)  then begin
    spawn,'touch --version',touch_version,touch_error
    if (strpos(strjoin(touch_error),'usage') ne -1 ) then touch_version=1
    touch_init = 1
endif

if arg_present(exists) then begin
  exists = keyword_set(touch_version)
  return
endif

if ~keyword_set(touch_version) then begin
    dprint,verbose=verbose,dlevel=touch_init-1 ,'Executable "touch" not found. Ignoring.'
    touch_init =4
    return
endif else dprint,verbose=verbose,dlevel=5,touch_version,/phelp

if size(/type,file) ne 7 then begin
    dprint,verbose=verbose,'filename required.'
    return
endif else begin
    finfo = file_info(file)
    filename = finfo.name
endelse

commands = 'touch'
if keyword_set(mtime) then commands = [commands,'-m']
if keyword_set(atime) then commands = [commands,'-a']
if keyword_set(no_create) then commands = [commands,'-c']

;if undefined(toffset) then toffset= '+0'
   
   
if !version.os_family eq 'unix' then begin
   ;;; if keyword_set(tstring) then commands = [commands,'-d',tstring +toffset]       ;;; previous version
   
   if keyword_set(time) then begin    

      ;orphaned code
      ;;;; tstring = time_string(time[0], tformat= 'YYYY-MM-DD hh:mm:ss')   ;+ toffset   ;;; previous version (for -d option)
;      tstring = time_string(double(time[0])+double(toffset)*60.*60., tformat='YYYYMMDDhhmm.ss') ;I believe that this version is in error.  It interprets toffset as seconds, when it should be hours(pcruce)

      tstring = time_string(time[0],/local, tformat ='YYYYMMDDhhmm.ss')
      commands = [commands,"-t",tstring]
   endif
 
   commands = [commands,filename]
   dprint,verbose=verbose,dlevel=4,commands
   spawn,commands ,/noshell,/stderr,output,exit_status=status
      
   
endif else if !version.os_family eq 'Windows' then begin
    dprint,dlevel=0,'Warning.  FILE_TOUCH is not currently working with Windows.'
    dprint,dlevel=0,'  '

    ;kludge to fix time daylightsaving time error in old version of touch
   ;;;if touch_version[0] eq 'touch (GNU fileutils) 3.16' then begin                  ;;;previous version
      ;;;if isdaylightsavingtime(time[0]) then toffset = ' -60'                      ;;; previous version
   if (strpos(strjoin(touch_version),'fileutils') ne -1 ) && isdaylightsavingtime(time[0]) then begin
     dst_offset = '-1' ;;; going back 1 hour
     dprint,dlevel=3,verbose=verbose,'Correcting for DST error in TOUCH program. offset:"'+dst_offset+'"'
   endif else begin
     dst_offset='+0'
   endelse
   
   ;;;if keyword_set(tstring) then tstring = '-t "' + tstring+toffset + '"' else tstring=''   ;;; previous version
   if keyword_set(time) then begin
     tstring = '-t "' + time_string(double(time[0])+double(toffset)*60.*60.+double(dst_offset)*60.*60., tformat='YYYYMMDDhhmm.ss') + '"' 
     dprint,dlevel=6,verbose=verbose,'tstring=' ,tstring
   endif else begin
     tstring=''
   endelse
   
   filestring = '"' + filename + '"'
   command = strjoin([commands,tstring,filestring],' ')
   dprint,verbose=verbose,dlevel=4,command
   spawn,command ,/noshell,/stderr, /hide,output ,exit_status=status
endif

;confirm_mtime =1
if keyword_set(confirm_mtime) && keyword_set(time) then begin   
   fi = file_info(file)  
   if fi.mtime ne long64(time) then begin
      dprint,'Change of file modification time failed'
   endif
   
endif



if keyword_set(output) then dprint,dlevel=1,verbose=verbose,output

end

