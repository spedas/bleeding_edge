;+
;
;PROCEDURE:       MVN_QL_PFP_TPLOT_RESTORE
;
;PURPOSE:         Restores a daily summary tplot save file of Tohban's MAVEN PFP data.
;
;INPUTS:          Time range to be restored.
;
;CREATED BY:      Takuya Hara on 2019-11-19.
;
;LAST MODIFICATION:
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-10-09 15:39:51 -0700 (Mon, 09 Oct 2023) $
; $LastChangedRevision: 32181 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_ql_pfp_tplot_restore.pro $
;
;-
PRO mvn_ql_pfp_tplot_restore, trange, verbose=verbose, no_download=no_download, tplot=tplot
  oneday = 24.d0 * 3600.d0
  path = 'maven/anc/tohban/YYYY/MM/'
  fname = 'mvn_ql_pfp_YYYYMMDD.tplot'

  store_data, '*', /delete
  IF SIZE(trange, /type) EQ 0 THEN get_timespan, trange $
  ELSE timespan, trange

  files = mvn_pfp_file_retrieve(path + fname, trange=trange, /last_version, /valid_only, $
                                /daily_names, no_download=no_download, verbose=verbose)

  w = WHERE(files NE '', nw)
  IF nw GT 0 THEN BEGIN
     info = FILE_INFO(files[w])
     mtime = info.mtime
     text = files[w] + '  not modified since  ' + time_string(mtime, tformat='DOW, DD MTH YYYY hh:mm:ss GMT')
     tplot_restore, filename=files[w], /append
     dprint, dlevel=2, verbose=verbose, 'Restoring file: ', text
  ENDIF 

; Ephemeris, current and timecrop keywords are now obsolete, but
; trange is needed for input, jmm, 2023-10-09
  maven_orbit_tplot, trange = trange, /load
;  maven_orbit_tplot, /current, /load, timecrop=[-2.d0, 2.d0]*oneday + trange ; +/- 2 day is buffer.
  options, 'alt2', panel_size=2./3., ytitle='ALT [km]'
  tplot_options, 'var_label'
  
  IF KEYWORD_SET(tplot) THEN BEGIN
     tname = ['mvn_sep1f_ion_eflux', 'mvn_sep1r_ion_eflux', 'mvn_sep1f_elec_eflux', 'mvn_sep1r_elec_eflux', $
              'mvn_sta_c0_e', 'mvn_sta_c6_m', 'mvn_swis_en_eflux', 'mvn_swe_etspec', 'mvn_lpw_iv', $
              'mvn_mag_bamp', 'mvn_mag_bang_1sec', 'alt2', 'burst_flag']
     
     tplot, tname
  ENDIF 
  RETURN
END
