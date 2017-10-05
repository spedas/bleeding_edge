;+
;NAME:
; mvn_swe_kpgen
;PURPOSE:
; Loads L0 data, creates L2 files for 1 day
;CALLING SEQUENCE:
; mvn_swe_kpgen, date = date
;INPUT:
; date keyword
;KEYWORDS:
; date = If set, the input date. The default is today
; directory = If set, output into this directory, for testing
;             purposes, don't forget a slash '/'  at the end.
;HISTORY:
; Hacked from mvn_swe_l2gen, 2015-01-25, jmm, jimm@ssl.berkeley.edu
; jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-02-24 18:45:38 -0800 (Tue, 24 Feb 2015) $
; $LastChangedRevision: 17037 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_swe_kpgen.pro $
;- 
Pro mvn_swe_kpgen, date = date, directory = directory, _extra = _extra
; crib for loading l0 data, creating L2 CDF files, and populating structures
; only works for one day at a time -- that's how we make L2 CDFs

@ mvn_swe_com

;Root data directory, sometimes isn't defined
  setenv, 'ROOT_DATA_DIR=/disks/data/'

; pick a day
  If(keyword_set(date)) Then time = time_string(date[0], /date_only) $
  Else time = time_string(systime(/sec), /date_only)

;time = '2014-03-26'
;time = '2014-10-22'
  t_start = time_double(time)
  t_end = time_double(time) + 86400.D ; a full day
  trange = [t_start, t_end]
  trange_str = time_string(trange)
;You need a timespan, so that the clock drift doesn't prompt for one
  timespan, t_start, 1
; get SPICE kernels
  mvn_swe_spice_init, trange = trange, /force

; Make kp save file:
  del_data, '*'                 ;delete all tplot variables so files 
                                ;aren't made from the previous day's data
  mvn_swe_kp, trange

Return
End

