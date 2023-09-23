;+
;NAME:
; mvn_spaceweather_overplot
;PURPOSE:
; MAVEN Spaceweather plots
;CALLING SEQUENCE:
; mvn_spaceweather_overplot, date = date, time_range = time_range, $
;               makepng=makepng, device = device, directory = pdir
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; Plots, on the screen or in 3 png files
;KEYWORDS:
; date = If set, a plot for the input date. If /makepng is set, then 3 plots
; time_range = If set, plot this time range, note that this supercedes
;              the date keyword, if both are set, the time range is
;              attempted, and this will plot a single plot, not for 3
;              different date ranges
; makepng = If set, make png files, with filenames:
;           mvn_spaceweather_date_1d.png, for a single day starting at
;           the input date
;           mvn_spaceweather_date_3d.png, for 3 days starting at
;           the input date
;           mvn_spaceweather_date_7d.png, for 7 days starting at
;           the input date
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a pngs are created, this is the output directory, the
;             default is the current working directory. The plots are
;             created in subdirectories /1day, /3day, /7day
;HISTORY:
; 2023-09-05, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-09-19 10:23:42 -0700 (Tue, 19 Sep 2023) $
; $LastChangedRevision: 32105 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_spaceweather_overplot.pro $
;-
Pro mvn_spaceweather_overplot, date = date, time_range = time_range, $
                               makepng = makepng, device = device, $
                               directory = directory, $
                               _extra=_extra

  mvn_qlook_init, device = device

;Delete all data
  del_data, '*'
;Options
  tplot_options, 'charsize', 1.0
  tplot_options, 'ygap', 0.5
  tplot_options, 'title', ''
  time_stamp, /off
  initct, 1074, /reverse

;Time ranges and plots
  one_day = 86400.0d0
  If(keyword_set(time_range)) Then Begin
     tr0 = time_double(time_range)
; No plots prior to 2014-10-14, as all of the data may not exist
     If(time_double(tr0[0]) Lt time_double('2014-10-12T12:00:00')) Then Begin
        dprint, 'Date too early: '+time_string(tr0[0])
        Return
     Endif
     timespan, tr0[0], tr0[1]-tr0[0], /seconds
     mvn_spaceweather, /tplot, /rtn, /overplot, tavg=300.d0
  Endif Else If(keyword_set(date)) Then Begin
     If(keyword_set(makepng)) Then Begin
        tr0 = time_double(date)+[0.0d0, 7*one_day]
        If(time_double(tr0[0]) Lt time_double('2014-10-12T12:00:00')) Then Begin
           dprint, 'Date too early: '+time_string(tr0[0])
           Return
        Endif
        tr3 = time_double(date)+[0.0d0, 3*one_day]
        tr1 = time_double(date)+[0.0d0, one_day]
;do 7 day plot
        timespan, tr0[0], 7, /days
        mvn_spaceweather, /tplot, /rtn, /overplot, tavg=300.d0
        If(keyword_set(directory)) Then pdir = directory Else pdir = './'
        pdir7 = pdir+'7day/'+time_string(tr0[0], tformat='YYYY/MM/')
        If(is_string(file_search(pdir7)) Eq 0) Then Begin
           message, /info, 'Creating: '+pdir7
           file_mkdir, pdir7
        Endif
        suffix7 = time_string(tr0[0], tformat='_YYYYMMDD_') + '7d'
        fullfile7 = pdir7+'mvn_spaceweather'+suffix7
        makepng, fullfile7
;do 3 day plot
        tlimit, tr3[0], tr3[1]
        makepng, fullfile3
        pdir3 = pdir+'3day/'+time_string(tr0[0], tformat='YYYY/MM/')
        If(is_string(file_search(pdir3)) Eq 0) Then Begin
           message, /info, 'Creating: '+pdir3
           file_mkdir, pdir3
        Endif
        suffix3 = time_string(tr0[0], tformat='_YYYYMMDD_') + '3d'
        fullfile3 = pdir3+'mvn_spaceweather'+suffix3
        makepng, fullfile3
;do 1 day plot
        tlimit, tr1[0], tr1[1]
        makepng, fullfile1
        pdir1 = pdir+'1day/'+time_string(tr0[0], tformat='YYYY/MM/')
        If(is_string(file_search(pdir1)) Eq 0) Then Begin
           message, /info, 'Creating: '+pdir1
           file_mkdir, pdir1
        Endif
        suffix1 = time_string(tr0[0], tformat='_YYYYMMDD_') + '1d'
        fullfile1 = pdir1+'mvn_spaceweather'+suffix1
        makepng, fullfile1
     Endif Else Begin
        tr0 = time_double(date)+[0.0d0, one_day]
        If(time_double(tr0[0]) Lt time_double('2014-10-12T12:00:00')) Then Begin
           dprint, 'Date too early: '+time_string(tr0[0])
           Return
        Endif
        timespan, date, 1
        mvn_spaceweather, /tplot, /rtn, /overplot, tavg=300.d0
     Endelse
  Endif Else Begin
     dprint, 'Need time_range or date input keywords set'
     Return
  Endelse
     
End
