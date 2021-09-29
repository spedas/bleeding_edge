;+
;NAME:
; mvn_pfpl2_longplot
;PURPOSE:
; MAVEN PFP GEN Quicklook Plot, long-term 2 weeks
;CALLING SEQUENCE:
; mvn_pfpl2_longplot, date = date, ndays = nays, makepng=makepng, $
;                     device = device, directory = pdir
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; Plots, on the screen or in a png file
;KEYWORDS:
; date = If set, a plot for the input date and the previous ndays
; ndays = the number of days to plot
;              attempted.
; makepng = If set, make a png file, with filename
;           'mvn_gen_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; multipngplot = if set, then make multiple plots for each orbit
;HISTORY:
; Hacked from mvn_pfpl2_overplot, 2019-12-10, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: muser $
; $LastChangedDate: 2019-12-18 13:09:39 -0800 (Wed, 18 Dec 2019) $
; $LastChangedRevision: 28124 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_pfpl2_longplot.pro $
;-
Pro mvn_pfpl2_longplot, date = date, ndays = ndays, $
                        directory = directory, $
                        device = device, $
                        not_save = not_save, $
                        _extra=_extra

  mvn_qlook_init, device = device
;First load the data
  del_data, '*'
;how many days?
  If(keyword_set(ndays)) Then nnday = ndays Else nnday = 14
;the tplot_save program works with start and end dates, so calculate
;dates
  If(~keyword_set(date)) Then Begin ;today
     date0 = time_double(time_string(systime(/sec), precision = -3))
  Endif Else date0 = time_double(date)
  one_day = 24.0d0*3600.0d0
  days = date0-one_day*dindgen(nnday)
; No plots prior to 2014-10-14, as all of the data may not exist
  If(time_double(date0) Lt time_double('2014-10-14T00:00:00')) Then Begin
     dprint, 'Date too early: '+time_string(date0)
     Return
  Endif
;For today, create a tplot_save file, unless /not_save is set
  If(~keyword_set(not_save)) Then Begin
     mvn_ql_pfp_tplot_save, date0
  Endif
;For the rest of the dates in question, only create a file if
;there isn't already one
  opath = root_data_dir() + 'maven/anc/tohban/'
  prefix = 'mvn_ql_pfp_'
  For j = 1, nnday-1 Do Begin
     path = opath + time_string(days[j], tformat='YYYY/MM/')
     fnamej = path+prefix + time_string(days[j], tformat='YYYYMMDD')
     fnamej = fnamej+'.tplot'
     If(~is_string(file_search(fnamej))) Then Begin
        mvn_ql_pfp_tplot_save, days[j]
     Endif
  Endfor
;At this point, you presumably have all of the data thay you need to
;plot
  timespan, days[nnday-1], nnday ;to be sure that date0 is processed
  tdays = timerange()
;set the title
  title = 'MAVEN PFP L2: '+strjoin(time_string(tdays, precision=-3), ' to ')
  tplot_options, 'title', title
  mvn_ql_pfp_tplot, /restore, /tplot, /png

;Plots are in the current directory, move it out if needed
  If(keyword_set(directory)) Then Begin
     If(~is_string(file_search(directory))) Then $
        file_mkdir2, directory, mode = '0775'o
     filename = 'mvn_ql_pfp_tplot_' + $
                time_string(tdays[0], tformat='yyMMDD_') + $
                time_string(tdays[1], tformat='yyMMDD')+'.png'
; the filename is from the start of the data in the plot, to the end
; of the last day. Here keep the date of the last data processed in
; the filename, and keep to a consistent namimg convention
     new_filename = 'mvn_pfp_l2_long_' + $
                    time_string(days[0], tformat='YYYYMMDD_hhmmss')+'.png'
     file_move, filename, directory+new_filename, /overwrite
  Endif

  Return
End
