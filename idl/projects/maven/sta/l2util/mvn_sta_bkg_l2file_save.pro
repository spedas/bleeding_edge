;+
;NAME:
; mvn_sta_bkg_l2file_save
;PURPOSE:
; saves an STA L2 background cdf, overwrites old versions, no revisions
; or md5 sums or links, just the file
;CALLING SEQUENCE:
; mvn_sta_bkg_l2file_save, otp_struct, fullfile0, no_compression =
;                          no_compression, iv_level=iv_level
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
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-09-26 17:09:08 -0700 (Tue, 26 Sep 2023) $
; $LastChangedRevision: 32136 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_bkg_l2file_save.pro $
;-
Pro mvn_sta_bkg_l2file_save, otp_struct, fullfile0, temp_dir = temp_dir, $
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

  fullfile = fullfile0
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
  spawn, '/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:none -delete'
;Convert is done here to be sure md5 file has consistent results when
;uncompressed elsewhere
;  spawn, '/usr/local/pkg/cdf-3.7.1/bin/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:none -delete'

  If(~keyword_set(no_compression)) Then Begin
     spawn, '/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert '+fullfilex+' '+fullfilex+' -compression cdf:gzip.5 -delete'
  Endif

;move the files to the output directory
  dir = file_dirname(fullfile)
;check for previous existence of files to allow for chmod or chgrp commands
  If(is_string(file_search(fullfile))) Then fullfile_chmod = 0B Else fullfile_chmod = 1B
  print, 'Moving: '+fullfilex+' To: '+fullfile
  file_move, fullfilex, fullfile, /overwrite
;delete temporary directory
  file_delete, tdir_out, /recursive
  If(fullfile_chmod) Then Begin
;chmod to g+w for the files
     spawn, 'chmod g+w '+fullfile
;And group maven
     spawn, 'chgrp maven '+fullfile
  Endif

  Return
End
