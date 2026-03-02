;+
;NAME:
; mvn_sta_l2gen_addbck
;PURPOSE:
; Inputs MAVEN STATIC L2 data from current files, calculates
; background, levels iv1 through iv4, and outputas a new L2 file, with
; incremented version number.
;CALLING SEQUENCE:
; mvn_sta_l2gen_addbck, date = date, directory = directory
;INPUT:
; None, input is via keyword
;OUTPUT:
; L2 Files are created
;KEYWORDS:
; date = the date for the file
; end_date = the end_data for this process. If set, then do not
; process data for this date and afterwards.
; alt_data_path = the output directory path, the default is
;                 'maven/'. The path must end in 'maven/'
;                 UPDATED 2026-02 no longer prepends /disks/data/
; init = if set, then starts the process by doing the iv1 data 3 days
;        in advance, and backfilling to this date, iv2 two days in
;        advance, iv3 one day in advance, then today. The defaut is to
;        assume that the iv1, 2, 3 data are there. Should only need to
;        do this once.
;HISTORY:
; 8-oct-2025, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro mvn_sta_l2gen_addbck, date = date, alt_data_path = alt_data_path, $
                          init = init, end_date = end_date, _extra = _extra

;Define the common blocks
  common mvn_2a, mvn_2a_ind, mvn_2a_dat & mvn_2a_dat = -1
  common mvn_c0, mvn_c0_ind, mvn_c0_dat & mvn_c0_dat = -1
  common mvn_c2, mvn_c2_ind, mvn_c2_dat & mvn_c2_dat = -1
  common mvn_c4, mvn_c4_ind, mvn_c4_dat & mvn_c4_dat = -1
  common mvn_c6, mvn_c6_ind, mvn_c6_dat & mvn_c6_dat = -1
  common mvn_c8, mvn_c8_ind, mvn_c8_dat & mvn_c8_dat = -1
  common mvn_ca, mvn_ca_ind, mvn_ca_dat & mvn_ca_dat = -1
  common mvn_cc, mvn_cc_ind, mvn_cc_dat & mvn_cc_dat = -1
  common mvn_cd, mvn_cd_ind, mvn_cd_dat & mvn_cd_dat = -1
  common mvn_ce, mvn_ce_ind, mvn_ce_dat & mvn_ce_dat = -1
  common mvn_cf, mvn_cf_ind, mvn_cf_dat & mvn_cf_dat = -1
  common mvn_d0, mvn_d0_ind, mvn_d0_dat & mvn_d0_dat = -1
  common mvn_d1, mvn_d1_ind, mvn_d1_dat & mvn_d1_dat = -1
  common mvn_d2, mvn_d2_ind, mvn_d2_dat & mvn_d2_dat = -1
  common mvn_d3, mvn_d3_ind, mvn_d3_dat & mvn_d3_dat = -1
  common mvn_d4, mvn_d4_ind, mvn_d4_dat & mvn_d4_dat = -1
  common mvn_d6, mvn_d6_ind, mvn_d6_dat & mvn_d6_dat = -1
  common mvn_d7, mvn_d7_ind, mvn_d7_dat & mvn_d7_dat = -1
  common mvn_d8, mvn_d8_ind, mvn_d8_dat & mvn_d8_dat = -1
  common mvn_d9, mvn_d9_ind, mvn_d9_dat & mvn_d9_dat = -1
  common mvn_da, mvn_da_ind, mvn_da_dat & mvn_da_dat = -1
  common mvn_db, mvn_db_ind, mvn_db_dat & mvn_db_dat = -1

;You need to be sure that the bkg functions can find the data, all
;version 3 here
  v3 = mvn_sta_current_sw_version(value = 3, /reset)
  If(keyword_set(alt_data_path)) Then Begin
     l = strlen(alt_data_path)
     mvn_test = strmid(alt_data_path, l-6, l-1)
     If(mvn_test Ne 'maven/') Then Begin
        message, /info, 'Bad alt_data_path'
        Return
     Endif
   ;  local_data_dir = '/disks/data/'+strmid(alt_data_path, 0, l-6)
      local_data_dir = strmid(alt_data_path, 0, l-6)
     ppp = mvn_file_source(local_data_dir = local_data_dir, /set)
  Endif

  one_day = 86400.0d0
  If(keyword_set(init)) Then Begin
     For j = 0, 3 Do Begin
        dj = time_string(time_double(date)+j*one_day)
        mvn_sta_l2gen, date = dj, temp_dir = './', iv_level = 1, $
                       alt_data_path = alt_data_path
     Endfor
     For j = 0, 2 Do Begin
        dj = time_string(time_double(date)+j*one_day)
        mvn_sta_l2gen, date = dj, temp_dir = './', iv_level = 2, $
                       alt_data_path = alt_data_path
     Endfor
     For j = 0, 1 Do Begin
        dj = time_string(time_double(date)+j*one_day)
        mvn_sta_l2gen, date = dj, temp_dir = './', iv_level = 3, $
                       alt_data_path = alt_data_path
     Endfor
  Endif Else Begin     
;generate all background levels, starting with today plus 3 days for
;iv2, then today plus 2 days for iv2 then today plus one day for iv3
;then today for iv4, unless end_date is set, then no processing for
;that date and after.
     If(keyword_set(end_date)) Then Begin
        tend = time_double(end_date)
     Endif Else tend = time_double('2145-01-01/00:00:00')
     d1 = time_string(time_double(date)+3*one_day)
     If(d1 Lt tend) Then Begin
        mvn_sta_l2gen, date = d1, temp_dir = './', iv_level = 1, $
                       alt_data_path = alt_data_path
     Endif
     d2 = time_string(time_double(date)+2*one_day)
     If(d2 Lt tend) Then Begin
        mvn_sta_l2gen, date = d2, temp_dir = './', iv_level = 2, $
                       alt_data_path = alt_data_path
     Endif
     d3 = time_string(time_double(date)+one_day)
     If(d3 Lt tend) Then Begin
        mvn_sta_l2gen, date = d3, temp_dir = './', iv_level = 3, $
                       alt_data_path = alt_data_path
     Endif
  Endelse
  mvn_sta_l2gen, date = date, temp_dir = './', iv_level = 4, $
                 alt_data_path = alt_data_path
;Add background to data and output
  timespan, date
;clear out all common block structures
  mvn_sta_l2_clearcommon
  mvn_sta_l2_load, iv_level = 4, alt_data_path = alt_data_path
;the directory output is full-path
  If(keyword_set(alt_data_path)) Then Begin
     ;dir00 = '/disks/data/'+alt_data_path+'data/sci/sta/'
     dir00 = alt_data_path+'data/sci/sta/'
  Endif Else dir00 = '/disks/data/maven/data/sci/sta/'
  datein = time_string(date)
  yyyy = strmid(datein, 0, 4)
  mmmm = strmid(datein, 5, 2)
  dddd = strmid(datein, 8, 2)
  dir_out0 = dir00+'l2/'
  dir_out = dir_out0+yyyy+'/'+mmmm+'/'
  mvn_l2gen_outdir, dir_out0, year = yyyy, month = mmmm
  mvn_sta_cmn_2a_l2gen, mvn_2a_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_d6_l2gen, mvn_d6_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_d7_l2gen, mvn_d7_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_d89a_l2gen, mvn_d8_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_d89a_l2gen, mvn_d9_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_d89a_l2gen, mvn_da_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_db_l2gen, mvn_db_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_c0_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_c2_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_c4_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_c6_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_c8_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_ca_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_cc_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_cd_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_ce_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_cf_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_d0_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_d1_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_d2_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_d3_dat, directory = dir_out, _extra = _extra
  mvn_sta_cmn_l2gen, mvn_d4_dat, directory = dir_out, _extra = _extra

End

