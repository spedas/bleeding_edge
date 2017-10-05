;+
; NAME:
;       thm_plot_gmag_by_source
; PURPOSE:
;       Plots all GMAG data, arranged by the data source (e.g., THEMIS
;       EPO, GBO, u of alaska, etc...) for quick viewing
; CALLING SEQUENCE:
;       thm_mult_gmag_plot, date, duration
; INPUTS:
;       date: The start of the time interval to be plotted. (Format:
;       'YYYY-MM-DD/hh:mm:ss')
;	duration: The length of the interval being plotted. (Floating
;	point number of days -> 12hr=0.5), default=1
;	no_data_load:  This keyword prevents new data from being
;	loaded; the routine will try to plot existing data if it
;	exists.
;       source_in: Any or all of 'EPO/UCLA', 'GBO/UCalgary',
;       'GBO/Ualberta', 'Ualaska', 'MACCS', 'Misc'. The default is to
;       use all. Can be an array or string with spaces.
; OUTPUTS:
;       Plots...
; MODIFICATION HISTORY:
;       jmm, 4-Jan-2010, jimm@ssl.berkeley.edu
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17458 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_plot_gmag_by_source.pro $
;-

Pro thm_plot_gmag_by_source, date, duration, no_data_load = no_data_load, $
                             source_in = source_in, winsize = winsize, $
                             _extra = _extra
;________________________________________________________________________________________________
;find all gmag CDF files on given date and put data into tplot variables
;________________________________________________________________________________________________
  if not keyword_set(date) then begin
    dprint,  'You must specify a date.  (Format : YYYY-MM-DD/HH:MM:SS)'
    return
  endif

  if not keyword_set(duration) then duration = 1.

  vsource = ['epo/ucla', 'gbo/ucalgary', 'gbo/ualberta', 'ualaska', 'maccs', 'misc']
  If(is_string(source_in)) Then Begin
    If(n_elements(source_in) Eq 1) Then Begin
      sources = strlowcase(strsplit(source_in, ' ', /extract))
    Endif Else sources = strlowcase(strcompress(source_in, /remove_all))
    sources = ssl_check_valid_name(sources, vsource, /include_all)
    If(is_string(sources) Eq 0) Then Begin
      dprint, 'No valid sources input'
      Return
    Endif
  Endif Else sources = vsource

  start_time = time_double(date)
  end_time = start_time+86400.*duration

  timespan, date, duration

  nsource = n_elements(sources)

;start with no data
  if not keyword_set(no_data_load) then begin
    del_data, 'thg_mag_*'
  endif

;set window here
  osf = strupcase(!version.os_family)
  If(osf Eq 'WINDOWS') Then set_plot, 'win' Else set_plot, 'x'
  If(n_elements(winsize) Eq 2) Then Begin
    window, 0, xsize = winsize[0], ysize = winsize[1]
  Endif Else Begin
    screen_size = get_screen_size()
    xss = screen_size/3.0
    xss = 100.0*fix(xss[0]/100)
    window, 0, xsize = xss, ysize = screen_size(1)*0.9
  Endelse
  !p.color = 0
  !p.background = 255
  !p.charsize = 1.0
  date_compress = strcompress(strmid(date, 0, 4)+strmid(date, 5, 2)+strmid(date, 8, 2), /remove_all)

;plot each source
  For j = 0, nsource-1 Do Begin
    thetitle = 'SOURCE: '+sources[j]
    dprint, 'PROCESSING '+strupcase(thetitle)
    Case sources[j] Of
      'epo/ucla':sitesj = ['bmls', 'ccnv', 'drby', 'fyts', 'hots', $
                          'loys', 'ptrs', 'pine', 'rmus', 'swno', 'ukia']
      'gbo/ucalgary':sitesj = ['chbg', 'ekat', 'gbay', 'inuv', 'kapu', $
                               'kian', 'kuuj', 'mcgr', 'pgeo', 'snap', $
                               'tpas', 'whit', 'yknf']
      'gbo/ualberta':sitesj = ['fsim', 'fsmi', 'gill', 'pina', 'rank', 'snkq']

      'ualaska':sitesj = ['arct', 'bett', 'cigo', 'eagl', 'fykn', 'gako', $
                          'hlms', 'homr', 'kako', 'pokr', 'trap']
      'maccs':sitesj = ['cdrt', 'crvr', 'gjoa', 'iglo', 'nain', 'pang', 'rbay']
      'misc':sitesj = ['atha', 'nrsq']
    Endcase
    if not keyword_set(no_data_load) then begin
      thm_load_gmag, site = sitesj, /subtract_median
    endif
;________________________________________________________________________________________________
;check that there is some valid data
;________________________________________________________________________________________________
    nj = n_elements(sitesj)
    test_vars = 'thg_mag_'+sitesj
    tplotvars = tnames(test_vars)
    If(is_string(tplotvars) Eq 0) Then Begin
      dprint, 'Ok sites:'
      dprint,  'None'
      dprint, 'Missing sites:'
      for k = 0, nj-1 do dprint,  sitesj[k]
      ss_ok = -1
    Endif Else Begin
      ss_ok = sswhere_arr(test_vars, tplotvars)
      dprint, 'Ok sites:'
      for k = 0, n_elements(ss_ok)-1 do dprint,  sitesj[ss_ok[k]]
      ss_miss = sswhere_arr(test_vars, tplotvars, /notequal)
      dprint, 'Missing sites:'
      If(ss_miss[0] Ne -1) Then Begin
        for k = 0, n_elements(ss_miss)-1 do dprint,  sitesj[ss_miss[k]]
      Endif Else dprint,  'None'
    Endelse

    If(ss_ok[0] Ne -1) Then Begin
;sort stations by longitude
      stations = tplotvars
      lats = fltarr(n_elements(stations))
      lons = fltarr(n_elements(stations))
      nstations = n_elements(stations)
      for i = 0, nstations-1 do begin
        get_data, stations[i], dlimits = dl
        lats[i] = float(dl.cdf.vatt.station_latitude)
        lons[i] = float(dl.cdf.vatt.station_longitude)
      endfor
      lat_index = reverse(sort(lats))
      stations = stations[lat_index]
      
      tplot_options, 'region', [0.00, 0.00, 0.95, 1.]
      time_stamp, /off
      timespan, date, duration
;--------------------------
;plot away
      thetitle = 'SOURCE: '+sources[j]
      tplot, stations,  window = 0, title = thetitle
      wshow, 0
      dprint,  'Hit Enter to Continue:'
      xxx = strarr(1)
      read, xxx
    Endif
  Endfor                        ;j


end

