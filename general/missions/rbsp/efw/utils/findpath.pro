;+
; NAME: findpath.pro 
; SYNTAX: 
; PURPOSE: Finds the path to a particular file in current IDL paths
; ARGUMENTS: 
;    FILENAME  -> Name of the file to find   - STRING
;    PATH      <- Path to file (without "/") - STRING
;
; RETURNS:  Status of find
;            0 - Failure
;            1 - Success (exact match)
;            2 - Success (after adding ".pro")
;        
; KEYWORDS:
;    EXACT    /  Find exact match only (Don't try to add '.pro')
;    VERBOSE  /  Print out search pathes
;
; CALLING SEQUENCE: found=findpath('filename',pathname) 
;                  case found of
;                    0 : ERROR
;                    1 : fullpath=pathname+'/'+filename
;                    2 : fullpath=pathname+'/'+filename+'.pro'
;                  endcase
;              or
;                  if not findpath('filename',path,/exact) then ERROR
;
; NOTES:  By default, FINDPATH searches for exact match.  If not found
;        looks for 'filename' with ".pro" appended (unless /EXACT keyword
;        is set).
;
; CREATED BY: John P. Dombeck 7/03/2001
;
; MODIFICATION HISTORY:
;
;  07/03/01- J. Dombeck    Original writing
;  06/25/04- J. Dombeck    Added VERBOSE keyword
;                          Changed close -> free_lun
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-09-10 07:48:14 -0700 (Wed, 10 Sep 2014) $
;   $LastChangedRevision: 15750 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/findpath.pro $
;-


function findpath,filename,path,exact=exact,verbose=verbose


; Initialize path in case of error

  path=''


; Check filename

  n_elem=n_elements(filename)
  if n_elem ne 1 then begin
    message,"File name required as scalar string",/cont
    return,0
  endif

  if data_type(filename) ne 7 then begin
    message,"FILENAME requires string",/cont
    return,0
  endif
    
  if filename eq '' then begin
    message,"FILENAME requires non-null string",/cont
    return,0
  endif
    

; Get IDL system pathes and add './' to the beginning

  pathes=strsplit(!PATH,":",/extract)
  n_pathes=n_elements(pathes)+1
  pathes=['.',pathes]


; Look for exact file in pathes

  pathcount=0
  err=-1
  while (pathcount lt n_pathes) and (err ne 0) do begin
    if keyword_set(verbose) then $
      print,'Checking '+pathes(pathcount)
    fullfile=pathes(pathcount)+'/'+filename
    openr,unit,fullfile,error=err,/get_lun
    pathcount=pathcount+1
  endwhile


; Not found

  if err ne 0 then begin


  ; Finally not found, Return 0

    if keyword_set(exact) $
       or strmid(filename,strlen(filename)-4,3) eq ".pro" then begin
      return,0
 

  ; Search with '.pro' extention

    endif else begin
      found=findpath(filename+'.pro',path,/exact)
      if found eq 0 then return,0 $
                    else return,2
    endelse


; Found

  endif else begin
    path=pathes(pathcount-1)
    free_lun,unit
    return,1
  endelse

end        ;*** MAIN *** : * FINDPATH *
