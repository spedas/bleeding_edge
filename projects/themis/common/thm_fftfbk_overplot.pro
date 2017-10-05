;+
;NAME:
; thm_fftfbk_overplot
;PURPOSE:
; Creates overview plots of FBK and FFT (in fast-survey FFF mode) for
; all probes. Two plots are created, one for the "inner probes" (a, d,
; e) and one for the "outer probes" (b, c). There are four quantities
; for each probe, two FBK and two FFF.
;CALLING SEQUENCE:
; thm_fftfbk_overplot, date=date,device = device, $
;                      directory = directory, makepng = makepng
;INPUT:
; date = the date for the plots, e.g., '2012-12-21' in any tplottable
;        format
;OUTPUT:
; none explicit, plots are generated
;KEYWORDS:
;          DEVICE: sets the device (x or z) (default is x)
;          MAKEPNG: keyword to generate 5 png files
;          DIRECTORY: sets the directory where the above pngs are
;          placed (default is './')
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-26 16:41:44 -0800 (Thu, 26 Jan 2012) $
; $LastChangedRevision: 9622 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_fftfbk_overplot.pro $
;-
Pro thm_fftfbk_overplot, date, device = device, dont_delete_data = dont_delete_data, $
                         directory = directory, makepng = makepng
;Input FFT, FBK data for all probes
  probe_list = ['a', 'b', 'c', 'd', 'e']
  inner_probes = ['a', 'd', 'e']
  outer_probes = ['b', 'c']
;clean slate
  If(~keyword_set(dont_delete_data)) Then del_data, '*'
  If(~keyword_set(date)) Then Begin
    dprint, 'Date must be set to generate fft-fbk overview plots'
    Return
  Endif
  If(keyword_set(directory)) Then dir = directory Else dir = './'
  If(keyword_set(device)) Then set_plot, device
;
  date2 = time_string(date)
  timespan, date2, 1
  year = string(strmid(date2, 0, 4))
  month = string(strmid(date2, 5, 2))
  day = string(strmid(date2, 8, 2))
;Load data for all probes
  thm_load_state, /get_support_data
  thm_load_fbk
  thm_load_fft
;For each probe there should be 4 variables filled, 2 fbk and 2 fff,
;if those aren't there, the fill with dummy variables.
  inner_probe_tvars = ''
  outer_probe_tvars = ''
  For ip = 0, 4 Do Begin
    sc = probe_list[ip]
    thx = 'th'+sc
    del_data, thx+'_fb_h*' ; del thx_fb_hff as it is not used and gets in the way later
    fbk_tvars = tnames(thx+'_fb_*') ; this should give us two tplot variables (but sometimes more)
    If(n_elements(fbk_tvars) eq 1) Then fbk_tvars = [fbk_tvars, 'filler']
    For i = 0, 1 Do Begin       ;only two variables
;kluge to prevent missing data from crashing things
      get_data, fbk_tvars[i], data = dd
      If(size(dd, /type) Ne 8) Then Begin
        filler = fltarr(2, 6)
        filler[*, *] = float('NaN')
        name = thx+'_fb_'+strcompress(string(i+1), /remove_all)
        store_data, name, data = {x:time_double(date)+findgen(2), y:filler, v:findgen(6)}
        options, name, 'spec', 1
        ylim, name, 1, 1000, 1
        zlim, name, 0, 0, 1
        fbk_tvars[i] = name
      Endif Else Begin
        store_data, fbk_tvars[i], data = {x:dd.x, y:dd.y, v:[2048., 512., 128., 32., 8., 2.]}
        options, fbk_tvars[i], 'spec', 1
        options, fbk_tvars[i], 'zlog', 1
        ylim, fbk_tvars[i], 2.0, 2048.0, 1
        thm_spec_lim4overplot, fbk_tvars[i], ylog = 1, zlog = 1, /overwrite
        lbl = thx+'_fbk_'+strmid(fbk_tvars[i], 7)
        options, fbk_tvars[i], 'ytitle',  strjoin(strsplit(lbl, '_', /extract), '!c')
;for ztitle, we need to figure out which type of data is there
;      for V channels, <|V|>.
;      for E channels, <|mV/m|>.
;      for SCM channels, <|nT|>.
        x1 = strpos(fbk_tvars[i], 'scm')
        If(x1[0] Ne -1) Then Begin
          options, fbk_tvars[i], 'ztitle', '<|nT|>'
;reset the upper value of zlimit to 2.0, jmm, 30-nov-2007
          get_data, fbk_tvars[i], data = d
          If(is_struct(d)) Then zlim,  fbk_tvars[i], min(d.y), 2.0, 1
        Endif
        xv = strpos(fbk_tvars[i], 'v')
        If(xv[0] Ne -1) Then options, fbk_tvars[i], 'ztitle', '<|V|>'
        xe = strpos(fbk_tvars[i], 'e')
        If(xe[0] Ne -1) Then Begin
          options, fbk_tvars[i], 'ztitle', '<|mV/m|>'
;reset the upper value of zlimit to 2.0, jmm, 30-nov-2007
          get_data, fbk_tvars[i], data = d
          If(is_struct(d)) Then zlim,  fbk_tvars[i], min(d.y), 2.0, 1
        Endif
      Endelse
    Endfor
;load the FFF data

;here try to create composite FFF, FBK variables one for EFI and one
;for SCM
    fft_tvars_eac = tnames(thx+'_fff_??_e?c34')
    fft_tvars_scm = tnames(thx+'_fff_??_scm3')
    fft_tvars = [fft_tvars_eac, fft_tvars_scm]
    For i = 0, 1 Do Begin
;kluge to prevent missing data from crashing things
      get_data, fft_tvars[i], data = dd
      If(size(dd, /type) Ne 8) Then Begin
        filler = fltarr(2, 6)
        filler[*, *] = float('NaN')
        name = thx+'_fff_'+strcompress(string(i+1), /remove_all)
        store_data, name, data = {x:time_double(date)+findgen(2), y:filler, v:findgen(6)}
        options, name, 'spec', 1
        ylim, name, 1, 1000, 1
        zlim, name, 0, 0, 1
        fft_tvars[i] = name
      Endif Else Begin
        options, fft_tvars[i], 'spec', 1
        options, fft_tvars[i], 'zlog', 1
        lbl = thx+'_fff_'+strmid(fft_tvars[i], 7)
        options, fft_tvars[i], 'ytitle', strjoin(strsplit(lbl, '_', /extract), '!c')
;replace zero values with NaN -- may remove the black from the 2 and 6
;                                hour plots
        zv = where(dd.y Eq 0, nzv)
        If(nzv Gt 0) Then dd.y[zv] = !values.f_nan
;only bother with this if necessary, but sometimes dd.v is zero,
;probably there will be limits set.
        yv = where(dd.v Eq 0, nyv)
        If(nyv Gt 0) Then Begin
          yv1 = where(dd.v Gt 0, nyv1)
          If(nyv1 Gt 0) Then Begin
            minyv1 = min(dd.v[yv1])
            dd.v[yv] = minyv1 > 1.0
          Endif
        Endif
        store_data, fft_tvars[i], data = temporary(dd)
;degap the data:
        tdegap, fft_tvars[i], /overwrite, dt = 600.0
        thm_spec_lim4overplot, fft_tvars[i], ylog = 1, zlog = 1, /overwrite
;Units? seem to be ok
      Endelse
    Endfor
;fill inner or outer probe vars
    Case ip of
      0:inner_probe_vars = [fft_tvars, fbk_tvars]
      1:outer_probe_vars = [fft_tvars, fbk_tvars]
      2:outer_probe_vars = [outer_probe_vars, fft_tvars, fbk_tvars]
      3:inner_probe_vars = [inner_probe_vars, fft_tvars, fbk_tvars]
      4:inner_probe_vars = [inner_probe_vars, fft_tvars, fbk_tvars]
    Endcase
  Endfor
;At this point i have all of my variables, plot the inner and outer
;probes:
  ititle = 'Inner Probes: P5, P3, P4 (TH-A,D,E) FFT, FBK'
  otitle = 'Outer Probes: P1, P2 (TH-B,C) FFT, FBK'
  tplot_options, 'lazy_ytitle', 1

  !p.charsize = 0.6
  If(keyword_set(makepng)) Then Begin
    dprint, 'PLot_dir: '+dir
    tplot, inner_probe_vars, title = ititle
    thm_gen_multipngplot, 'thm_tohban_fftfbkinner', date2, directory = dir
    tplot, outer_probe_vars, title = otitle
    thm_gen_multipngplot, 'thm_tohban_fftfbkouter', date2, directory = dir
  Endif Else Begin
    If(!d.name NE 'Z') Then window, 0, xs = 640, ys = 720
    tplot, inner_probe_vars, title = ititle
    If(!d.name NE 'Z') Then window, 2, xs = 640, ys = 480
    tplot, outer_probe_vars, title = otitle, window = 2
  Endelse
  Return
End


