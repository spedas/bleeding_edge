 ;+
;NAME:
; mvn_sta_cmn_l2file_save
;PURPOSE:
; saves an STA L2 cdf, managing the revision number and md5 sum. The
; file will have the latest revision number, there will be a hard
; link to the revisioned file with no revision number, andan md5 sum
; for the uncompressed file. Also deletes old versions.
;CALLING SEQUENCE:
; mvn_sta_cmn_l2file_save, otp_struct, fullfile0, no_compression =
;                          no_compression, iv1_process=iv1_Process
;INPUT:
; otp_struct = the structure to output in CDF_LOAD_VARS format.
; fullfile0 = the full-path filename for the revisionless cdf file
;OUTPUT:
; No explicit output, the revisioned file is written, an md5 sum file
; is written in the same directory, and the revisionless file is
; linked to the revsioned file 
;KEYWORDS:
; no_compression = if set, skip the compression step
; temp_dir = if set, output files into subdirectories of this dir,
;            then move to final destination. The default is
;            '/mydisks/home/maven/', don't forget the slash
;HISTORY:
; 22-jul-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: muser $
; $LastChangedDate: 2026-01-14 11:05:30 -0800 (Wed, 14 Jan 2026) $
; $LastChangedRevision: 34002 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_cmn_l2file_save.pro $
;-
Pro mvn_sta_cmn_l2file_save, otp_struct, fullfile0, temp_dir = temp_dir, $
                             no_compression = no_compression, $
                             _extra = _extra

  If(~is_struct(otp_struct)) Then Begin
     dprint, 'Bad structure input '
     Return
  Endif

  If(~is_string(fullfile0)) Then Begin
     dprint, 'Bad filename input '
     Return
  Endif

;Ok, get the next revision, and any files to delete
  mvn_sta_l2_filerevision, fullfile0, fullfile, delfiles

  If(~is_string(fullfile)) Then Begin
     dprint, 'No filename for file: '+fullfile0
     Return
  Endif

  file = file_basename(fullfile)
  file_id = file_basename(file, '.cdf')
  otp_struct.filename = file
  ppp = strsplit(file_id, '_', /extract)
  app_id = strmid(ppp[3], 0, 2)
;only mvn_sta_l2_app_id_etc here, no date
  otp_struct.g_attributes.logical_source = strjoin(ppp[0:3], '_')
;File id has the date and sw version
  otp_struct.g_attributes.logical_file_id = strjoin(ppp[0:5], '_')

;Add compression, 2014-05-27, changed to touch all files with
;cdfconvert, 2014-06-10
;Creates an md5sum of the uncompressed file, and saves it in the same
;path, 2014-07-07
;Now do all of the work in /tmp, because
;cdfconvert over the network is killing my computer, 2014-11-07, jmm
;make a directory for the file
;Have a backup for bad temp directories, so that /tmp isn't deleted
  If(keyword_set(temp_dir)) Then tdir = temp_dir Else tdir = '/mydisks/home/maven/'
  If(n_elements(ppp) Eq 7 && strlen(ppp[4]) Eq 8) Then tdir_out =  tdir+ppp[4] $
  Else tdir_out = tdir+'YYYYMMDD'
  file_mkdir, tdir_out
  fullfilex = tdir_out+'/'+file

  dummy = cdf_save_vars2(otp_struct, fullfilex, /no_file_id_update)
  spawn, '/disks/socware/thmsoc_production_test/cdf_linux_latest/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:none -delete'
;  spawn, '/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:none -delete'
;COnvert is done here to be sure md5 file has consistent results when
;uncompressed elsewhere
;  spawn, '/usr/local/pkg/cdf-3.7.1/bin/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:none -delete'

  md5file = ssw_str_replace(fullfile, '.cdf', '.md5')
  md5filex = ssw_str_replace(fullfilex, '.cdf', '.md5')
  If(is_string(file_search(md5filex))) Then file_delete, md5filex
  spawn, 'md5sum '+fullfilex+' > '+md5filex

;Extract the md5 sum, and replace the filename in the file, because
;you do not want the path name, yuck
  md5str = strarr(1)
  openr, unit, md5filex, /get_lun 
  readf, unit, md5str
  free_lun, unit
  ppp = strsplit(md5str[0], /extract)
  openw, unit, md5filex, /get_lun
  printf, unit, ppp[0], '  ', file
  free_lun, unit

  If(~keyword_set(no_compression)) Then Begin
;     spawn, '/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert
;     '+fullfilex+' '+fullfilex+' -compression cdf:gzip.5 -delete'
          spawn, '/disks/socware/thmsoc_production_test/cdf_linux_latest/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:gzip.5 -delete'
  Endif

;move the files to the output directory
  dir = file_dirname(fullfile)
  print, 'Moving: '+fullfilex+' To: '+fullfile
  file_move, fullfilex, fullfile, /overwrite
  file_move, md5filex, md5file, /overwrite

;Delete files, fullfile0 is a link if it exists, but must be re-linked
  If(is_string(file_search(fullfile0))) Then file_delete, fullfile0

;md5 files need deleting too
  If(is_string(delfiles)) Then Begin
     ndel = n_elements(delfiles)
     For j = 0, ndel-1 Do Begin
        file_delete, delfiles[j]
        del_md5filej = ssw_str_replace(delfiles[j], '.cdf', '.md5')
        If(is_string(file_search(del_md5filej))) Then file_delete, del_md5filej
     Endfor
  Endif

;delete temporary directory
  file_delete, tdir_out, /recursive

;Link revisionless file:
  spawn, 'ln '+fullfile+' '+fullfile0

;chmod to g+w for the files
  spawn, 'chmod g+w '+fullfile
  spawn, 'chmod g+w '+fullfile0
  spawn, 'chmod g+w '+md5file
;And group maven
  spawn, 'chgrp maven '+fullfile
  spawn, 'chgrp maven '+fullfile0
  spawn, 'chgrp maven '+md5file

  Return
End
