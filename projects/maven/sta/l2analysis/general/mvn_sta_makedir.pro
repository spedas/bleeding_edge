;+
;Routine for STATIC L3 data processing. Create a new directory if the requested one is not present. Directory will have the format
;
;basedir/year/month/
;
;Where baserdir is the base directory and must already be present. Year and month sub folders are then checked for, and created
;if not present. 
;
;Current setting is to use 
;
;file_mkdir, checkdir  
;file_chmod, '775'o, checkdir
;spawn, 'chgrp maven '+checkdir  ;via keyword /group
;
;To set permissions and group settings.
;
;
;INPUTS:
;basedir: string: baser directory that must already be present (you must include the final '/')
;
;year: string: eg '2015'
;month: string, eg '03' or '11'. Note, month must be two characters, so months < 10 must have 'zero' as the first character.
;
;KEYWORDS:
;set /group to also set the MAVEN group permission on any created folder. Default is to not do this.
;
;EXAMPLE:
;mvn_sta_makedir, '/users/user/data/', '2020', '01'   ;NOTE: you must include the final '/' in basedir.
;-
;


pro mvn_sta_makedir, basedir, year, month, success=success, group=group

proname = "mvn_sta_makedir"

if size(basedir,/type) ne 7 or size(year,/type) ne 7 or size(month,/type) ne 7 then begin
    print, proname, ": You must set basedir, year and month as strings."
    success = 0.
    return
endif

;Check for basedir - bail if not present:
dir0 = file_search(basedir, count=ndir0)
if ndir0 eq 0 then begin
    print, proname, ": basedir must be a valid directory that is already present."
    success=0
    return
endif

sl = path_sep()  ;/ for mac, \ for windows

;Set up year-month folder directory if not present:
checkdir1 = basedir+year+sl+month
dir1 = file_search(checkdir1, count=ndir1)
if ndir1 eq 0 then begin
    file_mkdir, checkdir1  ;make dir if not present
    file_chmod, checkdir1, '775'o  ;folder permissions
    if keyword_set(group) then spawn, 'chgrp maven '+checkdir1   ;change group to MAVEN, probably only works on SSL computers
    print, proname, ": directory created: ", checkdir1
endif

;Final check:
dir2 = file_search(checkdir1, count=ndir2)
if ndir2 eq 1 then begin
    print, proname, ": directory confirmed: ", checkdir1
    success=1
endif else begin
    print, proname, ": unable to create requested directory: ", checkdir1
    success=0
endelse


end

