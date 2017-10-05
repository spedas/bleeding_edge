;+
;Purpose:
;Generates sst overview plots for a given date
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
; thm_sst_overviews,'2007-03-23',dir='~/out',device='z'
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-01-24 16:34:47 -0800 (Fri, 24 Jan 2014) $
; $LastChangedRevision: 14018 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_sst_overviews.pro $
;-

pro thm_sst_overviews, date, directory = directory, $
                       device = device, nopng = nopng, $
                       mode = mode ;only plot the given mode, 'reduced','full'
                                   ;only valid for the /nopng case

probe_list = ['a','b','c','d','e']

;clean slate
del_data,'*'
common data_cache_com, dcache
;really do this
dcache = ''

thm_init

if not keyword_set(date) then begin
    dprint,'Date must be set to generate sst overview plots'
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

var_string_f1 = ''
var_string_f2 = ''
var_string_r1 = ''
var_string_r2 = ''

;Load data first for all probes since thm_load_sst resets limits for
;all variables, as far as I can see, jmm, 26-nov-2007

for i = 0L,n_elements(probe_list)-1L do begin
    sc = probe_list[i]
    thx = 'th'+sc
    sample_rate_var = thm_sample_rate_bar(date, 1, sc, /outline)

;Load L2 data, and only use L1 data if L2 is not present
    thm_load_sst, probe = sc, level = 'l2'
;Full mode first -- If Level 2 data didn't show up, use L1
    index_sst_e = where(thx+'_psef_en_eflux' eq tnames())
    index_sst_i = where(thx+'_psif_en_eflux' eq tnames())
    If(index_sst_e[0] eq -1 Or index_sst_i[0] Eq -1) Then Begin
        thm_load_sst2, probe = sc, level = 'l1'
        instr_do = ['psif', 'psef']
        ss_do = bytarr(n_elements(instr_do))
        For j = 0, n_elements(instr_do)-1 Do Begin
            index_sst = where(strjoin('th'+sc+'_'+instr_do[j]+'_data') eq tnames(), nokj)
            If(nokj Gt 0) Then ss_do[j] = 1b
        Endfor
        ok_instr = where(ss_do Eq 1, nok_instr)
        If(nok_instr Eq 0) Then Begin
            dprint, 'NO SST FULL Data for Probe: '+sc
        Endif Else Begin
            instr_do = instr_do[ok_instr]
            thm_part_moments, probe = sc, instrument = instr_do, $
              moments = ['density', 'velocity', 't3'],method_clean='automatic'
        Endelse
    Endif

;You need L1 data for reduced mode
    thm_load_sst, probe = sc, level = 'l1'
    instr_do = ['psir', 'pser']
    ss_do = bytarr(n_elements(instr_do))
    For j = 0, n_elements(instr_do)-1 Do Begin
      index_sst = where(strjoin('th'+sc+'_'+instr_do[j]+'_tot') eq tnames(), nokj)
      If(nokj Gt 0) Then ss_do[j] = 1b
    Endfor
    ok_instr = where(ss_do Eq 1, nok_instr)
    If(nok_instr Eq 0) Then Begin
      dprint, 'NO SST REDUCED Data for Probe: '+sc
    Endif Else Begin
      instr_do = instr_do[ok_instr]
      thm_part_moments_old, probe = sc, instrument = instr_do, $
        moments = ['density', 'velocity', 't3'],method_clean='automatic'
    Endelse
endfor

;now with all data loaded, test for missing data, and reset limits,
;labels, etc...
for i = 0L,n_elements(probe_list)-1L do begin
    sc = probe_list[i]
;kluge to prevent missing data from crashing things 
    index_sst=where(strjoin('th'+sc+'_psef_en_eflux') eq tnames())
    if index_sst eq -1 then begin
        filler=fltarr(2,16)
        filler(*,*)=float('NaN')
        store_data,strjoin('th'+sc+'_psef_en_eflux'),data={x:time_double(date)+findgen(2),y:filler,v:findgen(16)}
        name=strjoin('th'+sc+'_psef_en_eflux')
        options,name,'spec',1
        ylim,name,1,1000,1
        zlim,name,1,1000,1
        options,name,'ytitle','th'+sc+'!Celec'
        options,name,'ztitle','Eflux'
    endif else begin 
        name='th'+sc+'_psef_en_eflux'
        tdegap, name, /overwrite, dt = 600.0 ;jmm, 9-dec-2009
        options,name,'spec',1
        options,name,'ytitle','th'+sc+'!Celec'
        options,name,'ztitle','Eflux'
        options,name,'y_no_interp',1
        options,name,'x_no_interp',1
        thm_spec_lim4overplot, name, zlog = 1, ylog = 1, /overwrite
    endelse
;kluge to prevent missing data from crashing things 
    index_sst=where(strjoin('th'+sc+'_psif_en_eflux') eq tnames())
    if index_sst eq -1 then begin
        filler=fltarr(2,16)
        filler(*,*)=float('NaN')
        store_data,strjoin('th'+sc+'_psif_en_eflux'),data={x:time_double(date)+findgen(2)*86400.,y:filler,v:findgen(16)}
        name=strjoin('th'+sc+'_psif_en_eflux')
        options,name,'spec',1
        ylim,name,1,1000,1
        zlim,name,1,1000,1
        options,name,'ytitle','th'+sc+'!Cions'
        options,name,'ztitle','Eflux'
    endif else begin
;SST ion panel
        name='th'+sc+'_psif_en_eflux'
        tdegap, name, /overwrite, dt = 600.0 ;jmm, 9-dec-2009
        options,name,'spec',1
        options,name,'ytitle','th'+sc+'!Cions'
        options,name,'ztitle','Eflux'
        options,name,'y_no_interp',1
        options,name,'x_no_interp',1
        thm_spec_lim4overplot, name, zlog = 1, ylog = 1, /overwrite
    endelse
;kluge to prevent missing data from crashing things 
    index_sst=where(strjoin('th'+sc+'_psir_en_eflux') eq tnames())
    if index_sst eq -1 then begin
        filler=fltarr(2,16)
        filler(*,*)=float('NaN')
        store_data,strjoin('th'+sc+'_psir_en_eflux'),data={x:time_double(date)+findgen(2),y:filler,v:findgen(16)}
        name=strjoin('th'+sc+'_psir_en_eflux')
        options,name,'spec',1
        ylim,name,1,1000,1
        zlim,name,1,1000,1
        options,name,'ytitle','th'+sc+'!Cions'
        options,name,'ztitle','Eflux'
    endif else begin 
        name='th'+sc+'_psir_en_eflux'
        tdegap, name, /overwrite, dt = 600.0 ;jmm, 9-dec-2009
        options,name,'spec',1
        options,name,'ytitle','th'+sc+'!Cions'
        options,name,'ztitle','Eflux'
        options,name,'y_no_interp',1
        options,name,'x_no_interp',1
        thm_spec_lim4overplot, name, zlog = 1, ylog = 1, /overwrite
;reset sst ylimit maxima to 3.0e6
        get_data, name, data = d
        If(is_struct(d)) Then ylim, name, min(d.v), 3.0e6, 1
    endelse
;kluge to prevent missing data from crashing things 
    index_sst=where(strjoin('th'+sc+'_pser_en_eflux') eq tnames())
    if index_sst eq -1 then begin
        filler=fltarr(2,16)
        filler(*,*)=float('NaN')
        store_data,strjoin('th'+sc+'_pser_en_eflux'),data={x:time_double(date)+findgen(2),y:filler,v:findgen(16)}
        name=strjoin('th'+sc+'_pser_en_eflux')
        options,name,'spec',1
        ylim,name,1,1000,1
        zlim,name,1,1000,1
        options,name,'ytitle','th'+sc+'!Celec'
        options,name,'ztitle','Eflux'
    endif else begin 
        name='th'+sc+'_pser_en_eflux'
        tdegap, name, /overwrite, dt = 600.0 ;jmm, 9-dec-2009
        options,name,'spec',1
        options,name,'ytitle','th'+sc+'!Celec'
        options,name,'ztitle','Eflux'
        options,name,'y_no_interp',1
        options,name,'x_no_interp',1
        thm_spec_lim4overplot, name, zlog = 1, ylog = 1, /overwrite
;reset sst ylimit maxima to 3.0e6
        get_data, name, data = d
        If(is_struct(d)) Then ylim, name, min(d.v), 3.0e6, 1
    endelse
    var_string_f1 += 'th'+sc+'_psef_en_eflux '
    var_string_f2 += ' sample_rate_'+sc+ ' th'+sc+'_psif_en_eflux '
    var_string_r1 += 'th'+sc+'_pser_en_eflux '
    var_string_r2 += ' sample_rate_'+sc+ ' th'+sc+'_psir_en_eflux '
endfor
var_string_f = var_string_f1 + ' ' + var_string_f2
var_string_r = var_string_r1 + ' ' + var_string_r2

;set colors
!p.background=255.
!p.color=0.
time_stamp,/off
loadct2,43
!p.charsize=0.8
;kill units in ytitles
options, '*', 'ysubtitle', ''
If(not keyword_set(nopng)) Then Begin
  title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIF,PSEF EFlux eV/(eV*cm!U2!N*sec*sr)'
  tplot, var_string_f, title = title
  thm_gen_multipngplot, 'thm_tohban_sstfull', date2, directory = dir
  title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIR,PSER EFlux eV/(eV*cm!U2!N*sec*sr)'
  tplot, var_string_r, title = title, trange = [time_double(date2), time_double(date2)+3600.*24.]
  thm_gen_multipngplot, 'thm_tohban_sstreduced', date2, directory = dir
Endif Else Begin
  If(keyword_set(mode)) Then Begin
    xmode = strcompress(strlowcase(mode), /remove_all)
    case xmode of
      'reduced':Begin
        var = var_string_r
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIR,PSER EFlux eV/(eV*cm!U2!N*sec*sr)'
      End
      'full':Begin
        var = var_string_f
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIF,PSEF EFlux eV/(eV*cm!U2!N*sec*sr)'
      End
      else:Begin
        var = var_string_f
        title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIF,PSEF EFlux eV/(eV*cm!U2!N*sec*sr)'
      End
    endcase
    tplot, var, title = title
  Endif Else Begin
    window, 1, xs = 560, ys = 660
    title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIF,PSEF EFlux eV/(eV*cm!U2!N*sec*sr)'  
    tplot, var_string_f, title = title, window = 1
    window, 2, xs = 560, ys = 660
    title = 'P5, P1, P2, P3, P4 (TH-A,B,C,D,E) PSIR,PSER EFlux eV/(eV*cm!U2!N*sec*sr)'
    tplot, var_string_r, title = title, window = 2
  Endelse
Endelse
end

