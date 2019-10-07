;+
;NAME:
; mvn_l2file_compress
;PURPOSE:
; compresses an output L2 file and creates an md5 file 
;CALLING SEQUENCE:
; mvn_l2file_compress, fullfile0
;INPUT:
; fullfile0 = the full-path filename for the revisionless cdf file
;OUTPUT:
; No explicit output, the revisioned file is written, an md5 sum file
; is written in the same directory, and the revisionless file is
; linked to the revsioned file 
;KEYWORDS:
;None, so far
;HISTORY:
; 26-nov-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimmpc1 $
; $LastChangedDate: 2019-10-06 14:57:53 -0700 (Sun, 06 Oct 2019) $
; $LastChangedRevision: 27823 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_l2file_compress.pro $
;-
Pro mvn_l2file_compress, fullfile0, _extra = _extra

  If(~is_string(fullfile0)) Then Begin
     dprint, 'Bad filename input '
     Return
  Endif

  fullfile = file_search(fullfile0)
  If(~is_string(fullfile)) Then Begin
     dprint, 'No file: '+fullfile0
     Return
  Endif


;Move the file to the local working directory; cdf convert will kill
;the network in some cases, so this should be run in a local working
;directory on the machine that is running the program, so that
;cdfconvert does not have to operate over the network, jmm, 2015-01-12
  fullfile_init = fullfile
  file = file_basename(fullfile)
  file_path = file_dirname(fullfile)

  fullfile = './'+file
  file_move, fullfile_init, fullfile, /overwrite

  file_id = file_basename(file, '.cdf')

  spawn, '/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert '+fullfile+' '+$
         fullfile+' -compression cdf:none -delete'

  md5file = ssw_str_replace(fullfile, '.cdf', '.md5')
  If(is_string(file_search(md5file))) Then file_delete, md5file
  spawn, 'md5sum '+fullfile+' > '+md5file

;Extract the md5 sum, and replace the filename in the file, because
;you do not want the path name, yuck
  md5str = strarr(1)
  openr, unit, md5file, /get_lun 
  readf, unit, md5str
  free_lun, unit
  ppp = strsplit(md5str[0], /extract)
  openw, unit, md5file, /get_lun
  md5outstr = strtrim(ppp[0],2) + '  ' + strtrim(file[0],2) ; make sure no extra spaces
  printf, unit, md5outstr
  free_lun, unit

  spawn, '/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert '+fullfile+' '+fullfile+' -compression cdf:gzip.5 -delete'

;chmod to g+w for the files
  spawn, 'chmod g+w '+fullfile
  spawn, 'chmod g+w '+md5file

;move the fullfile and md5file to the data directory
  file_move, fullfile, fullfile_init, /overwrite
  file_move, md5file, file_path[0]+'/'+file_basename(md5file), /overwrite


  Return
End
