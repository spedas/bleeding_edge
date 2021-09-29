;+
;
;PROCEDURE:       MVN_QL_PFP_TPLOT_SAVE
;
;PURPOSE:         Creates a daily summary tplot save file of Tohban's MAVEN PFP data.
;
;INPUTS:          Time range as a string format of 'YYYY-MM-DD'.
;
;EXAMPLE:         IDL> mvn_ql_pfp_tplot_save, '2019-11-13', '2019-11-19'
;
;CREATED BY:      Takuya Hara on 2019-11-13.
;
;LAST MODIFICATION:
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-12-10 13:25:11 -0800 (Tue, 10 Dec 2019) $
; $LastChangedRevision: 28105 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_ql_pfp_tplot_save.pro $
;
;-
PRO mvn_ql_pfp_tplot_save, sdate, edate, verbose=verbose
  opath = root_data_dir() + 'maven/anc/tohban/'
  prefix = 'mvn_ql_pfp_'

  stime = sdate
  IF SIZE(edate, /type) EQ 0 THEN etime = stime ELSE etime = edate
  IF SIZE(stime, /type) EQ 7 THEN stime = time_double(stime)
  IF SIZE(etime, /type) EQ 7 THEN etime = time_double(etime)

  times = time_double(tformat='YYYY-MM-DD', time_intervals(trange=[stime, etime], /daily_res))
  ntime = N_ELEMENTS(times)
  FOR j=0, ntime-1 DO BEGIN
     timespan, times[j]
     store_data, '*', /delete

     path = opath + time_string(times[j], tformat='YYYY/MM/')
     file_mkdir2, path, mode = '0775'o

     fname = prefix + time_string(times[j], tformat='YYYYMMDD')

     mvn_ql_pfp_tplot, /burst, bcrust=0, pos=0
     
     tname = tnames()
     ntplot = N_ELEMENTS(tname)
     
     pfp = STRMATCH(tname, 'mvn_*')
     w = WHERE(tname EQ 'burst_flag', nw)
     IF nw EQ 1 THEN pfp[w] = 1
     
     FOR i=0, ntplot-1 DO BEGIN
        get_data, tname[i], alim=alim
        IF tag_exist(alim, 'dummy', /quiet) THEN append_array, dummy, 1 ELSE append_array, dummy, 0
        undefine, alim
     ENDFOR 

     w = WHERE((pfp EQ 1) AND (dummy EQ 0), nw)
     IF nw GT 0 THEN BEGIN
        file_delete, path + fname + '.tplot',/allow_nonexistent ;otherwise unable to change permissions
        tplot_save, tname[w], filename=path + fname
        SPAWN, 'chgrp maven ' + path + fname + '.tplot'
        file_chmod, path + fname + '.tplot', '664'o
     ENDIF 
     undefine, w, nw, tname, dummy
  ENDFOR 
  RETURN
END
