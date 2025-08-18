;+
;NAME:
; thm_memeory_plots
;PURPOSE:
; the plots show the number of raw data packets in satellite memory
;CALLING SEQUENCE:
; thm_memory_plots,date=date,dur=dur
;KEYWORDS:
; date = the start date for the plots
; dur = duration for the plots
; nopng = if set, do not create a png file
; directory = if set, put the answer in this directory, otherwise put
;             it in the local working directory
; mode = 'survey' or 'burst', only can be used for /nopng, the default
;        is to plot both
;HISTORY:
; 19-dec-2007, from Andreas Kieling
; 9-jan-2008, jmm, Added directory keyword
;$LastChangedBy: jimm $
;$LastChangedDate: 2019-08-05 13:41:02 -0700 (Mon, 05 Aug 2019) $
;$LastChangedRevision: 27542 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_memory_plots.pro $
;
Pro thm_memory_plots, date = date, dur = dur, nopng = nopng, $
                      directory = directory, mode = mode, _extra = _extra

  del_data, '*'

  If(keyword_set(directory)) Then Begin
    dir = directory             ;slash check
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Ne '/' And ll Ne '\') Then dir = dir+'/'
  Endif Else dir = './'

  If(Not keyword_set(date)) Then date = time_string(systime(/sec), /date_only)
  If(not keyword_set(dur)) Then dur = 1 ; day

  timespan, date, dur, /day

  tplot_options, 'xmargin', [ 18, 10]
  tplot_options, 'ymargin', [ 5, 5]

  thm_load_hsk, probe = 'a'
  thm_load_hsk, probe = 'b'
  thm_load_hsk, probe = 'c'
  thm_load_hsk, probe = 'd'
  thm_load_hsk, probe = 'e'
  
  probe_list = ['a','b','c','d','e']
  
  for i = 0,n_elements(probe_list)-1 do begin
    if ~keyword_set(tnames('th'+probe_list[i]+'_hsk_issr_survey_raw')) then begin
      store_data,'th'+probe_list[i]+'_hsk_issr_survey_raw',data={x:timerange(),y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif 
    if ~keyword_set(tnames('th'+probe_list[i]+'_hsk_issr_burst_raw')) then begin
      store_data,'th'+probe_list[i]+'_hsk_issr_burst_raw',data={x:timerange(),y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif 
    if ~keyword_set(tnames('th'+probe_list[i]+'_hsk_issr_eng_raw')) then begin
      store_data,'th'+probe_list[i]+'_hsk_issr_eng_raw',data={x:timerange(),y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif 
  endfor

  tnames_outer_survey = 'th'+['b','c']+'_hsk_issr_survey_raw'
  tnames_inner_survey = 'th'+['a','d','e']+'_hsk_issr_survey_raw'
  tnames_survey = 'th'+['a','b','c','d','e']+'_hsk_issr_survey_raw'
  tnames_burst = 'th'+['a','b','c','d','e']+'_hsk_issr_burst_raw'
  tnames_eng =  'th'+['a','b','c','d','e']+'_hsk_issr_eng_raw'

  ylim, tnames_inner_survey, 0, 30000, 0
  ylim, tnames_outer_survey, 0, 40000, 0
  ylim, tnames_burst, 0, 25000, 0
  ylim, tnames_eng, 0, 1000, 0

  title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E)'
  If(not keyword_set(nopng)) Then Begin
    dur_str = strcompress(/remove_all, string(dur))
    date_str = time_string(time_double(date), /date_only)
    tplot,tnames_survey, title = title
    makepng, dir+date_str+'-'+dur_str+'days-memory-survey'
    tplot, tnames_burst, title = title
    makepng, dir+date_str+'-'+dur_str+'days-memory-burst'
    tplot, tnames_eng, title = title
    makepng, dir+date_str+'-'+dur_str+'days-memory-eng'
  Endif Else Begin
    If(keyword_set(mode)) Then Begin
      xmode = strcompress(strlowcase(mode), /remove_all)
      case xmode of
        'burst': tplot, tnames_burst, title = title
        'survey':tplot,tnames_survey, title = title
        'eng':tplot,tnames_eng, title = title
        else:tplot,tnames_survey, title = title
      endcase
  Endif Else Begin
      window, 0, xs = 560, ys = 660
      tplot,tnames_survey, title = title, window = 0
      window, 1, xs = 560, ys = 660
      tplot,tnames_burst, title = title, window = 1
      window, 2, xs = 560, ys = 660
      tplot,tnames_eng, title = title, window = 2
    Endelse
  Endelse

  Return

end
