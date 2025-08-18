;+
;NAME:
; thm_ffffbk_composite
;PURPOSE:
; Creates a composite FFF and FBK tplot variable for overview plots
;CALLING SEQUENCE:
; var = thm_ffffbk_composite(fffvar, fbkvar, scale = scale, $
;                            min_gap = min_gap)
;INPUT:
; fffvar = the name of the FFF variable
; fbkvar = the name of the FBS variable
;OUTPUT:
; var = the name of the composite variable, will be fbkvar+'_mix'
;KEYWORDS:
; scale = scale factor to multiply the FFF data, the default is 1.0
; min_gap = the minimum gap size for FFF data, FBK data will not be
;           inserted into gaps smaller than this. The default is 300.0
;           seconds
;HISTORY:
; 11-Aug-2010, jmm, jimm@ssl.berkeley.edu
;Version:
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-04-03 12:41:12 -0700 (Thu, 03 Apr 2025) $
; $LastChangedRevision: 33222 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_ffffbk_composite.pro $
;-
Function thm_ffffbk_composite, fffvar, fbkvar, scale = scale, $
                               min_gap = min_gap, _extra = _extra

  otp = fbkvar+'_mix'      ;default to return fbkvar if there's no fff
  get_data, fffvar, data = dfff
  get_data, fbkvar, data = dfbk, dlimits = dl ;use the dlimits for the FBK variable
  If(is_struct(dfff) Eq 0) Then Begin
    store_data, otp, data = dfbk, dlimits = dl
    Return, otp
  Endif
;Is this an efield or Bfield?
  fbk_inst = strmid(fbkvar, 0, 3) ;'edc' or 'scm'
  If(keyword_set(scale)) Then scx = scale[0] Else scale = 1.0
  If(keyword_set(min_gap)) Then mngp = min_gap Else mngp = 300.0
;first get the data, in principle this can be done for any variable
;with a v
  If(tag_exist(dfff, 'v')) Then Begin
    f = dfff.v
  Endif Else Return, otp
;now you have a v, get dv, you will eventually need a 2d v
  sf = size(f, /n_dim)
  tfff = dfff.x
  ntimes = n_elements(tfff)
  If(sf Eq 1) Then Begin
    nf = n_elements(f)
    f = rebin(f, nf, ntimes)
  Endif Else If(sf Eq 2) Then Begin
    f = transpose(f) 
  Endif Else Begin
    message, 'No way to get here, bad v dimension'
  Endelse
;now f is a nf, ntimes array
  nf = n_elements(f[*, 0])
  df1 = (f[1, *]-f[0, *])
  df2 = (f[nf-1, *]-f[nf-2, *])
  dfx = [f[0, *]-df1/2, (f[1:*, *]+f[0:nf-2, *])/2, f[nf-1, *]+df2/2]
  df = dfx[1:*,*]-dfx[0:nf-1,*]
  df = transpose(df)
  f = transpose(f)              ;back to ntimes, nf
;????? should df be in the sqrt?
  If(fbk_inst Eq 'edc' Or fbk_inst Eq 'eac') Then Begin
;changes units of output from (V/m)^2/Hz to mV/m
     yfff = scale*sqrt(1000.0*df*dfff.y)
  Endif Else Begin
;changes units of output from (nT)^2/Hz to nT
     yfff = scale*sqrt(df*dfff.y)
  Endelse
;yfff is now the normalized FFF data
;The next step is to work with the FBK data the new variable will have
;FFF data where FFF data exists, and FBK data in the other parts
;get time limits for fff data:  
  dtfff = tfff[1:*]-tfff
  x1 = where(dtfff Gt mngp, nx1)
  trfff = minmax(tfff)
  If(nx1 Gt 0) Then Begin
    trfff_gap = dblarr(2, nx1)
    For j = 0, nx1-1 Do trfff_gap[*, j] = [tfff[x1[j]], tfff[x1[j]+1]]
  Endif
;Now replace any FBK data in the appropriate time ranges with fff
;data. First rotate so that v increases 
  vfbk = rotate(dfbk.v, 2)
  tfbk = dfbk.x 
  yfbk = rotate(dfbk.y, 7)      ;rotate flips the frequency dependence
  nvfbk = n_elements(vfbk) & ntfbk = n_elements(dfbk.x)
  vfbk = rebin(vfbk, nvfbk, ntfbk)
  vfbk = transpose(vfbk)
;embed into an array with the same number of frequencies as the fff
;data
  yfbk1 = fltarr(ntfbk, nf) & yfbk1[*, 0:nvfbk-1] = yfbk
  vfbk1 = fltarr(ntfbk, nf) & vfbk1[*, 0:nvfbk-1] = vfbk
;use fbk data where there is not FFF data
  k0 = where(tfbk Lt trfff[0] Or tfbk Gt trfff[1]) ;before or after
;Are there gaps? Get gap subscripts
  If(nx1 Gt 0) Then Begin
    For j = 0, nx1-1 Do Begin
      kj = where(tfbk Gt trfff_gap[0, j] And $
                 tfbk Lt trfff_gap[1, j], nkj)
      If(nkj Gt 0) Then Begin
        If(k0[0] Ne -1) Then k0 = [k0, kj] Else k0 = kj
      Endif
    Endfor
  Endif
  If(k0[0] Eq -1) Then Begin
    t = tfff
    y = yfff
    v = f
  Endif Else Begin
    tfbk = tfbk[k0]
    vfbk1 = vfbk1[k0, *]
    yfbk1 = yfbk1[k0, *]
;now, concatenate and sort
    t = [tfff, tfbk]
    y = [yfff, yfbk1]
    v = [f, vfbk1]
    sst = bsort(t)
    t = t[sst]
    y = y[sst, *]
    v = v[sst, *]
  Endelse
  store_data, otp, data = {X:t, y:y, v:v}, dlimits = dl
;set some options
  vm = minmax(v[where(v Gt 0)])
  ylim, otp, vm[0], vm[1], 1
  zlim, otp, 0, 0, 1
  options, otp, 'spec', 1
  options, otp, 'zlog', 1
  Return, otp
End

  
  
  

  
