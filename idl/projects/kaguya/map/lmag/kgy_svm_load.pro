;+
; PROCEDURE:
;       kgy_svm_load
; PURPOSE:
;       Downloads and reads in SVM data files
; CREATED BY:
;       Yuki Harada on 2018-05-02
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-15 00:54:22 -0700 (Tue, 15 May 2018) $
; $LastChangedRevision: 25223 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/lmag/kgy_svm_load.pro $
;-

pro kgy_svm_load, svm30only=svm30only

@kgy_svm_com

url = 'http://www.geo.titech.ac.jp/lab/tsunakawa/Kaguya_LMAG.dir/globalSVM20150511.zip'

ld = root_data_dir()+'kaguya/mod/svm/'
datfile = ld + 'LunarSVM_000_02_v01.dat'
if ~file_test(datfile) then begin ;- download files
   f = spd_download(remote_file=url,local_path=ld)
   file_unzip,f
endif

if ~keyword_set(svm30only) then begin
   dprint,'Reading in '+datfile
   d = read_ascii(datfile,data_start=12,count=Ndat)
;;;     Lon     Lat      Be      Bn      Br      Bt
;;; 6 x 1621800
   svm_dat = d.(0)
endif


datfile = ld + 'LunarSVM_030_05_v01.dat'
if file_test(datfile) then begin
   dprint,'Reading in '+datfile
   d = read_ascii(datfile,data_start=12,count=Ndat)
;;;     Lon     Lat      Be      Bn      Br      Bt
;;; 6 x 258480
   svm30_dat = d.(0)
endif


end
