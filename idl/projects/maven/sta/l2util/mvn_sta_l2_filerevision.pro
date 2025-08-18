;+
;NAME:
; mvn_sta_l2_filerevision
;PURPOSE:
; tracks the revision number for a STATIC L2 file
;CALLING SEQUENCE:
; mvn_sta_l2_filerevision, fullfile, fullfile_rev, fullfile_del,$
;                          dont_delete = dont_delete
;INPUT:
; fullfile = the filename, without revision number, e.g.,
;'/disks/data/maven/pfp/sta/l2/2014/07/mvn_sta_l2_db-1024m_20140707_v00.cdf'
;OUTPUT:
; fullfile_rev = the filename, current revision, e.g., 
;'/disks/data/maven/pfp/sta/l2/2014/07/mvn_sta_l2_db-1024m_20140707_v00_r00.cdf'
; fullfile_del =  files to be deleted
;HISTORY:
; 22-jul-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-01-09 10:22:20 -0800 (Fri, 09 Jan 2015) $
; $LastChangedRevision: 16613 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_l2_filerevision.pro $
;-
Pro mvn_sta_l2_filerevision, fullfile, fullfile_rev, fullfile_del

  fullfile_rev = ''
  fullfile_del = ''
  If(~is_string(fullfile)) Then Return

;Need to split off directory to use file_basename to remove .cdf
  fdir = file_dirname(fullfile, /mark_dir)
  file = file_basename(fullfile, '.cdf')

  fullfile0 = fdir+file+'_r??.cdf'

  test4file = file_search(fullfile0)
  fullfile_del = test4file
  If(~is_string(test4file)) Then rv_str = 'r00' Else Begin
     nfiles = n_elements(test4file)
     test4file = test4file[nfiles-1] ;last version
     rss = strpos(test4file, '_r', /reverse_search)
     If(rss[0] Ne -1) Then Begin
        rno = fix(strmid(test4file, rss[0]+2, 2))+1
        rv_str = 'r'+string(rno, format='(i2.2)')
     Endif Else rv_str = 'r00'
  Endelse

  fullfile_rev = fdir+file+'_'+rv_str+'.cdf'
  Return
End


