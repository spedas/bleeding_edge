;+
;Purpose:
;Generates esa overview plots for a given date
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
;Example:
; thm_esa_overviews,'2007-03-23',dir='~/out',device='z'
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-03-31 15:28:47 -0700 (Mon, 31 Mar 2025) $
; $LastChangedRevision: 33219 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_esa_overviews.pro $
;-

Pro thm_esa_overviews, date, directory = directory, $
                       device = device, nopng = nopng, $
                       mode = mode ;only plot the given mode, 'burst','reduced','full'
                                   ;only valid for the /nopng case

probe_list = ['a','b','c','d','e']

;clean slate
del_data,'*'
clear_esa_common_blocks

thm_init

if not keyword_set(date) then begin
    dprint,'Date must be set to generate esa overview plots'
    return
endif

date2 = time_string(date)
trange = time_double(date)+[0.0d0, 24.0d0*3600.0d0]

if keyword_set(directory) then dir=directory else dir='./'

if keyword_set(device) then set_plot,device

;tplot_options,'lazy_ytitle',0  ; prevent auto formatting on ytitle (namely having carrage returns at underscores)

timespan,date2,1,/day

year=string(strmid(date2,0,4))
month=string(strmid(date2,5,2))
day=string(strmid(date2,8,2))

var_string_b1 = ''
var_string_b2 = ''
var_string_r1 = ''
var_string_r2 = ''
var_string_f1 = ''
var_string_f2 = ''

for i = 0L,n_elements(probe_list)-1L do begin
    sc = probe_list[i]
    sample_rate_var = thm_sample_rate_bar(date, 1, sc, /outline)
    thm_load_esa, level = 'l2', probe = sc, $
      datatype = ['peeb', 'peer', 'peef', 'peib', 'peir', 'peif']+'_en_eflux'
    thm_load_esa, level = 'l2', probe = sc, $
      datatype = ['peeb', 'peer', 'peef', 'peib', 'peir', 'peif']+'_sc_pot'
;If Level 2 data didn't show up, check for L1
    index_esa_e = where('th'+sc+'_peef_en_eflux' eq tnames())
    index_esa_i = where('th'+sc+'_peif_en_eflux' eq tnames())
    if(index_esa_e[0] eq -1 Or index_esa_i[0] Eq -1) then begin
      thm_load_esa_pkt, probe = sc
      thm_load_esa_pot, probe = sc
      instr_all = ['peif', 'peir', 'peib', 'peef', 'peer', 'peeb']
      for j = 0, 5 do begin
        test_index = where('th'+sc+'_'+instr_all[j]+'_en_counts' eq tnames())
        If(test_index[0] Ne -1) Then thm_part_moments_old, probe = sc, instrument = instr_all[j]
      endfor
    endif   
endfor
;For missing data
filler = fltarr(2, 32)
filler[*, *] = float('NaN')
xfiller = time_double(date)+findgen(2)
vfiller = findgen(32)
for i = 0L,n_elements(probe_list)-1L do begin
;check for data availability - degap all data, with 10 minute time
;resolution, jmm, 2009-12-09. Add SCPOT to the data, if it exists,
;otherwise just rename the dummy variable
    sc = probe_list[i]
    name = 'th'+sc+'_peeb_en_eflux'
    get_data, name, data = d
    If(is_struct(d)) Then Begin
      thm_esa_lim4overplot, name, trange, zlog = 1, ylog = 1, /overwrite
      tdegap, name, /overwrite, dt = 600.0
      tdegap, 'th'+sc+'_peeb_sc_pot', /overwrite, dt = 600.0
      options, name, 'ytitle', 'th'+sc+'!Cpeeb'
      options,name,'ztitle','Eflux'
      svar = scpot_overlay('th'+sc+'_peeb_sc_pot', name, sc_line_thick = 2.0)
      name = svar               ;name is the variable to plot
    Endif Else Begin
      name = name+'_SCPOT'
      store_data, name, data = {x:xfiller, y:filler, v:vfiller}
      options, name, 'spec', 1
      ylim, name, 1, 1000, 1
      zlim, name, 1, 1000, 1
      options, name, 'ytitle', 'th'+sc+'!Cpeeb'
      options,name,'ztitle','Eflux'
    Endelse
    var_string_b1 += ' '+name
    name = 'th'+sc+'_peib_en_eflux'
    get_data, name, data = d
    If(is_struct(d)) Then Begin
      thm_esa_lim4overplot, name, trange, zlog = 1, ylog = 1, /overwrite
      tdegap, name, /overwrite, dt = 600.0
      options, name, 'ytitle', 'th'+sc+'!Cpeib'
      options,name,'ztitle','Eflux'
    Endif Else Begin
      store_data, name, data = {x:xfiller, y:filler, v:vfiller}
      options, name, 'spec', 1
      ylim, name, 1, 1000, 1
      zlim, name, 1, 1000, 1
      options, name, 'ytitle', 'th'+sc+'!Cpeib'
      options,name,'ztitle','Eflux'
    Endelse
    var_string_b2 += ' sample_rate_'+sc+ ' '+name
    name = 'th'+sc+'_peer_en_eflux'
    get_data, name, data = d
    If(is_struct(d)) Then Begin
      thm_esa_lim4overplot, name, trange, zlog = 1, ylog = 1, /overwrite
      tdegap, name, /overwrite, dt = 600.0
      tdegap, 'th'+sc+'_peer_sc_pot', /overwrite, dt = 600.0
      options, name, 'ytitle', 'th'+sc+'!Cpeer'
      options,name,'ztitle','Eflux'
      svar = scpot_overlay('th'+sc+'_peer_sc_pot', name, sc_line_thick = 2.0)
      name = svar               ;name is the variable to plot
    Endif Else Begin
      name = name+'_SCPOT'
      store_data, name, data = {x:xfiller, y:filler, v:vfiller}
      options, name, 'spec', 1
      ylim, name, 1, 1000, 1
      zlim, name, 1, 1000, 1
      options, name, 'ytitle', 'th'+sc+'!Cpeer'
      options,name,'ztitle','Eflux'
    Endelse
    var_string_r1 += ' '+name
    name = 'th'+sc+'_peir_en_eflux'
    get_data, name, data = d
    If(is_struct(d)) Then Begin
      thm_esa_lim4overplot, name, trange, zlog = 1, ylog = 1, /overwrite
      tdegap, name, /overwrite, dt = 600.0
      options, name, 'ytitle', 'th'+sc+'!Cpeir'
      options,name,'ztitle','Eflux'
    Endif Else Begin
      store_data, name, data = {x:xfiller, y:filler, v:vfiller}
      options, name, 'spec', 1
      ylim, name, 1, 1000, 1
      zlim, name, 1, 1000, 1
      options, name, 'ytitle', 'th'+sc+'!Cpeir'
      options,name,'ztitle','Eflux'
    Endelse
    var_string_r2 += ' sample_rate_'+sc+ ' '+name
    name = 'th'+sc+'_peef_en_eflux'
    get_data, name, data = d
    If(is_struct(d)) Then Begin
      thm_esa_lim4overplot, name, trange, zlog = 1, ylog = 1, /overwrite
      tdegap, name, /overwrite, dt = 600.0
      tdegap, 'th'+sc+'_peef_sc_pot', /overwrite, dt = 600.0
      options, name, 'ytitle', 'th'+sc+'!Cpeef'
      options,name,'ztitle','Eflux'
      svar = scpot_overlay('th'+sc+'_peef_sc_pot', name, sc_line_thick = 2.0)
      name = svar               ;name is the variable to plot
    Endif Else Begin
      name = name+'_SCPOT'
      store_data, name, data = {x:xfiller, y:filler, v:vfiller}
      options, name, 'spec', 1
      ylim, name, 1, 1000, 1
      zlim, name, 1, 1000, 1
      options, name, 'ytitle', 'th'+sc+'!Cpeef'
      options,name,'ztitle','Eflux'
    Endelse
    var_string_f1 += ' '+name
    name = 'th'+sc+'_peif_en_eflux'
    get_data, name, data = d
    If(is_struct(d)) Then Begin
      thm_esa_lim4overplot, name, trange, zlog = 1, ylog = 1, /overwrite
      tdegap, name, /overwrite, dt = 600.0
      options, name, 'ytitle', 'th'+sc+'!Cpeif'
      options,name,'ztitle','Eflux'
    Endif Else Begin
      store_data, name, data = {x:xfiller, y:filler, v:vfiller}
      options, name, 'spec', 1
      ylim, name, 1, 1000, 1
      zlim, name, 1, 1000, 1
      options, name, 'ytitle', 'th'+sc+'!Cpeif'
      options,name,'ztitle','Eflux'
    Endelse
    var_string_f2 += ' sample_rate_'+sc+ ' '+name
endfor

var_string_b = var_string_b1 + ' ' + var_string_b2
var_string_r = var_string_r1 + ' ' + var_string_r2
var_string_f = var_string_f1 + ' ' + var_string_f2

;set colors
!p.background=255.
!p.color=0.
time_stamp,/off
loadct2,43
!p.charsize=0.8
;kill units in ytitles
options, '*', 'ysubtitle', ''
If(Not keyword_set(nopng)) Then Begin
  title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIB,PEEB EFlux eV/(eV*cm!U2!N*sec*sr)'
  tplot, var_string_b, title = title
  thm_gen_multipngplot, 'thm_tohban_esaburst', date2, directory = dir
  title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIR,PEER EFlux eV/(eV*cm!U2!N*sec*sr)'  
  tplot, var_string_r, title = title, trange = [time_double(date2), time_double(date2)+3600.*24.]
  thm_gen_multipngplot, 'thm_tohban_esareduced', date2, directory = dir
  title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIF,PEEF EFlux eV/(eV*cm!U2!N*sec*sr)'
  tplot, var_string_f, title = title, trange = [time_double(date2), time_double(date2)+3600.*24.]
  thm_gen_multipngplot, 'thm_tohban_esafull', date2, directory = dir
Endif Else Begin
  If(keyword_set(mode)) Then Begin
    xmode = strcompress(strlowcase(mode), /remove_all)
    case xmode of
      'burst':Begin
        var = var_string_b
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIB,PEEB EFlux eV/(eV*cm!U2!N*sec*sr)'
      end
      'reduced':Begin
        var = var_string_r
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIR,PEER EFlux eV/(eV*cm!U2!N*sec*sr)'
      End
      'full':Begin
        var = var_string_f
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIF,PEEF EFlux eV/(eV*cm!U2!N*sec*sr)'
      End
      else:Begin
        var = var_string_f
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIF,PEEF EFlux eV/(eV*cm!U2!N*sec*sr)'
      End
    endcase
    tplot, var, title = title
  Endif Else Begin
    window, 1, xs = 560, ys = 660
    title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIB,PEEB EFlux eV/(eV*cm!U2!N*sec*sr)'
    tplot, var_string_b, title = title, window = 1
    window, 2, xs = 560, ys = 660
    title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIR,PEER EFlux eV/(eV*cm!U2!N*sec*sr)'
    tplot, var_string_r, title = title, window = 2
    window, 3, xs = 560, ys = 660
    title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PEIF,PEEF EFlux eV/(eV*cm!U2!N*sec*sr)'
    tplot, var_string_f, title = title, window = 3
  Endelse
Endelse
end

