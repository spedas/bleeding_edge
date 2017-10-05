;+
;Purpose:
;Generates fgm overview plots for a given date
;this includes one day long plot and 4 1/4 day plots
;It stores these plots in the current directory
;
;Arguments:
;       date: the date for which the plots will be generated
;
;       directory(optional): an optional output directory
; 
;       device(optional):switch to 'z' device for cron plotting
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-24 11:22:53 -0800 (Tue, 24 Jan 2012) $
; $LastChangedRevision: 9600 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_fgm_overviews.pro $
;-

pro thm_fgm_overviews,date,directory=directory,device=device,nopng=nopng,dont_delete_data=dont_delete_data

probe_list = ['a','b','c','d','e']

;clean slate
If(not keyword_set(dont_delete_data)) Then del_data,'*'

if not keyword_set(date) then begin
    dprint,'Date must be set to generate fgm overview plots'
    return
endif

date2 = time_string(date)

if keyword_set(directory) then dir=directory else dir='./'

if keyword_set(device) then set_plot,device

;tplot_options,'lazy_ytitle',0  ; prevent auto formatting on ytitle (namely having carrage returns at underscores)

timespan,date2,1,/day

year=string(strmid(date2,0,4))
month=string(strmid(date2,5,2))
day=string(strmid(date2,8,2))

thm_load_state,/get_sup

var_string1 = ''
var_string2 = ''

;Load all of the data, create sample rate bar
for i = 0L,n_elements(probe_list)-1L do begin
    sc = probe_list[i]
    sample_rate_var = thm_sample_rate_bar(date, 1, sc, /outline)
    thm_load_fgm, probe = sc, coord = 'gse', level = 'l2' ;level 2 data has a suffix
;check for existence of data, if it is not there, try L1
    If ~is_string(tnames('th'+sc+'_fgl_gse')) Then begin
      thm_load_fgm, probe = sc, coord = 'gse', suff = '_gse', level = 'l1'
    endif
     
    ;fallback if fgs data not present from level2 file
    if ~is_string(tnames('th'+sc+'_fgs_gse')) then begin
      thm_load_fit, probe = sc, coord = 'gse', suff = '_gse';level 1 is default
    endif
    
    if ~is_string(tnames('th'+sc+'_fgl_gse')) then begin
      store_data,'th'+sc+'_fgl_gse',data={x:time_double(date2)+findgen(2)*86400., y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif
    
    if ~is_string(tnames('th'+sc+'_fgs_gse')) then begin
      store_data,'th'+sc+'_fgs_gse',data={x:time_double(date2)+findgen(2)*86400., y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif
    
    sc = probe_list[i]          ;load routines can change this to an array
    var_string1 += 'th'+sc+'_fgs_gse '
    var_string2 += ' sample_rate_'+sc + ' th'+sc+'_fgl_gse '
;Adjust titles
    options, 'th'+sc+'_fgs_gse', 'ytitle', 'th'+sc+'_fgs_gse'
    options, 'th'+sc+'_fgl_gse', 'ytitle', 'th'+sc+'_fgl_gse'
;kill units in ytitles
    options, 'th'+sc+'_fgs_gse', 'ysubtitle', ''
    options, 'th'+sc+'_fgl_gse', 'ysubtitle', ''
endfor

var_string = var_string1 + ' ' + var_string2

;set colors
!p.background=255.
!p.color=0.
time_stamp,/off
loadct2,43
!p.charsize=0.8

tplot_options,'xmargin',[16,8]
;tclip instead of ylim, jmm, 13-jun-2008
;ylim,'*',-100.,100.
tclip, -100.0, 100.0, /overwrite

title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) FGS, FGL [nT]'
If(Not keyword_set(nopng)) Then Begin
  tplot, var_string, title = title
  thm_gen_multipngplot, 'thm_tohban_fgm', date2, directory = dir
Endif Else Begin
  tplot, var_string, title = title
Endelse  

end
