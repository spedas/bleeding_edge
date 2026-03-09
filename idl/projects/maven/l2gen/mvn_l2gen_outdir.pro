;+
;NAME: mvn_l2gen_outdir 
;PURPOSE: helper function to create output directories,
;group-writeable, with group set to 'maven'. 
;CALLING SEQUENCE:
;mvn_l2gen_outdir, directory, year = year, month = month
;KEYWORDS:
; year = 'yyyy' will create directory+year+'/'
; month = 'mm' will create directory+year+'/'+month+'/'
;HISTORY:
; $LastChangedBy: ghanley $
; $LastChangedDate: 2026-03-02 13:37:42 -0800 (Mon, 02 Mar 2026) $
; $LastChangedRevision: 34212 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_l2gen_outdir.pro $
;-
Pro mvn_l2gen_outdir, directory, year = year, month = month

  If(~is_string(file_search(directory, /test_dir))) Then Begin
     file_mkdir, directory
     spawn, 'chmod 775 ' + directory
     If(!version.os Eq 'linux') Then spawn, 'chgrp maven '+directory
  Endif
  If(keyword_set(year) && is_string(year)) Then Begin
     diryr = directory+year+'/'
     If(~is_string(file_search(diryr, /test_dir))) Then Begin
        file_mkdir, diryr
        spawn, 'chmod 775 ' + diryr
        If(!version.os Eq 'linux') Then spawn, 'chgrp maven '+diryr
     Endif
     If(keyword_set(month) && is_string(month)) Then Begin
        dirmo = diryr+month+'/'
        If(~is_string(file_search(dirmo, /test_dir))) Then Begin
           file_mkdir, dirmo
           spawn, 'chmod 775 ' + dirmo
           If(!version.os Eq 'linux') Then spawn, 'chgrp maven '+dirmo
        Endif
     Endif
  Endif

  Return
End

     

