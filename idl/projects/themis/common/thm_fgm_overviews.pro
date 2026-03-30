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
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-03-26 13:01:57 -0700 (Thu, 26 Mar 2026) $
; $LastChangedRevision: 34293 $
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
;Use L1 data
    thm_load_fgm, probe = sc, coord = 'gse', suff = '_gse', level = 'l1'
    thm_load_fit, probe = sc, coord = 'gse', suff = '_gse', level = 'l1' ;level 1 is default    
    
    if ~is_string(tnames('th'+sc+'_fgl_gse')) then begin
      store_data,'th'+sc+'_fgl_gse',data={x:time_double(date2)+findgen(2)*86400., y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif
    
    if ~is_string(tnames('th'+sc+'_fgs_gse')) then begin
      store_data,'th'+sc+'_fgs_gse',data={x:time_double(date2)+findgen(2)*86400., y:[!VALUES.D_NAN,!VALUES.D_NAN]}
    endif
    
    sc = probe_list[i]          ;load routines can change this to an array
    If(sc Eq 'e' And time_double(date) Ge time_double('2024-05-25')) Then Begin
      fgs_varname = 'th'+sc+'_fgs_dsl'
      fgl_varname = 'th'+sc+'_fgl_dsl'
      var_string1 += 'th'+sc+'_fgs_dsl '
      var_string2 += ' sample_rate_'+sc + ' th'+sc+'_fgl_dsl '
    endif else begin
      fgs_varname = 'th'+sc+'_fgs_gse'
      fgl_varname = 'th'+sc+'_fgl_gse'
      var_string1 += 'th'+sc+'_fgs_gse '
      var_string2 += ' sample_rate_'+sc + ' th'+sc+'_fgl_gse '
    endelse
;Adjust titles
    options, fgs_varname, 'ytitle', fgs_varname
    options, fgl_varname, 'ytitle', fgl_varname
;kill units in ytitles
    options, fgs_varname, 'ysubtitle', ''
    options, fgl_varname, 'ysubtitle', ''
;for recent THEMIS E FGS data, if there is an estimated Bz, put the Bz curve
;behind Bx and By. jmm, 2024-12-12
   If(sc Eq 'e' And time_double(date) Ge time_double('2024-05-25')) Then Begin
      thm_load_fgm, probe = sc, coord = 'dsl', suff = '_dsl', level = 'l1'
      thm_load_fit, probe = sc, coord = 'dsl', suff = '_dsl', level = 'l1' ;level 1 is default
      if ~is_string(tnames('th'+sc+'_fgl_dsl')) then begin
        store_data,'th'+sc+'_fgl_dsl',data={x:time_double(date2)+findgen(2)*86400., y:[!VALUES.D_NAN,!VALUES.D_NAN]}
      endif

      if ~is_string(tnames('th'+sc+'_fgs_dsl')) then begin
        store_data,'th'+sc+'_fgs_dsl',data={x:time_double(date2)+findgen(2)*86400., y:[!VALUES.D_NAN,!VALUES.D_NAN]}
      endif


      ;Adjust titles
      options, fgs_varname, 'ytitle', fgs_varname
      options, fgl_varname, 'ytitle', fgl_varname
      ;kill units in ytitles
      options, fgs_varname, 'ysubtitle', 'DSL'
      options, fgl_varname, 'ysubtitle', 'DSL'

      options, fgs_varname, 'indices', [2,0,1]
      options, fgl_varname, 'indices', [2,0,1]

;check for l1b data, if there is none yet, set Bz to NaN 
      If(~is_string(thm_l1b_check(date, sc))) Then Begin
         get_data, 'th'+sc+'_fgs_dsl', data = btmp
         btmp.y[*, 2] = !values.f_nan
         store_data, 'th'+sc+'_fgs_dsl', data = btmp
         get_data, 'th'+sc+'_fgl_dsl', data = btmp
         btmp.y[*, 2] = !values.f_nan
         store_data, 'th'+sc+'_fgl_dsl', data = btmp
      Endif
   Endif
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
tclip, '*_fg*', -100.0, 100.0, /overwrite

title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) FGS, FGL [nT]'
If(Not keyword_set(nopng)) Then Begin
  tplot, var_string, title = title
  thm_gen_multipngplot, 'thm_tohban_fgm', date2, directory = dir
Endif Else Begin
  tplot, var_string, title = title
Endelse  

end
