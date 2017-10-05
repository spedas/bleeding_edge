;+
;NAME:
; mvn_l0_db2file
;PURPOSE:
; Given a date and/or a time range, find the appropriate l0 file
;CALLING SEQUENCE:
; filex = mvn_l0_db2file(date)
;INPUT:
; date = the date
;OUTPUT:
; filex = the filename
;KEYWORDS:
; l0_file_type = ['all', 'arc', 'svy'], the default is 'all'
; l0_file_path = if set, use this for the full-path to the l0 file, 
;                which seems to be in flux. Don't forget the trailing '/'
;HISTORY:
; 12-mar-2014, jmm, jimm@ssl.berkeley.edu
; 22-apr-2014, jmm, Added l0_file_type, changed default path
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-08-29 12:54:08 -0700 (Fri, 29 Aug 2014) $
; $LastChangedRevision: 15727 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_l0_db2file.pro $
;-
Function mvn_l0_db2file, date, l0_file_path = l0_file_path, $
                         l0_file_type = l0_file_type, _extra=_extra

  mvn_qlook_init
  date0 = strmid(time_string(date, format=6), 0, 8)
  yyyy = strmid(date0, 0, 4)
  mmmm = strmid(date0, 4, 2)
  ppp = mvn_file_source()

  If(keyword_set(l0_file_path)) Then fpath = l0_file_path $
;  Else fpath = ppp.local_data_dir+'maven/pfp/l0/'+yyyy+'/'+mmmm+'/'
  Else fpath = ppp.local_data_dir+'maven/data/sci/pfp/l0/'
  If(keyword_set(l0_file_type)) Then Begin
     ftyp = strcompress(/remove_all, l0_file_type[0])
  Endif Else ftyp = 'all'
  ftmp = fpath+'mvn_pfp_'+ftyp+'_l0_'+date0+'_v*.dat'
  files = file_search(ftmp)
  If(is_string(files)) Then Begin
     filex = files[n_elements(files)-1]
  Endif Else filex = ''
  Return, filex

End

     
  
