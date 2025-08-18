;+
;PROCEDURE:   mvn_swe_addlpw
;PURPOSE:
;  Loads LPW data and creates tplot variables using LPW code.
;
;USAGE:
;  mvn_swe_addlpw
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    PANS:          Named variable to hold the tplot variable(s) created.
;
;    MINCUR:        Minimum peak current in IV sweep for accepting LPW
;                   density.  Default = 1e-7.  Quality filter for high-
;                   altitude LPW densities suggested by Chris Fowler.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-01-19 14:47:21 -0800 (Fri, 19 Jan 2018) $
; $LastChangedRevision: 24551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addlpw.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addlpw, pans=pans, mincur=mincur

  if not keyword_set(mincur) then mincur = 1.e-7

  mvn_lpw_load_l2, ['lpiv','lpnt'], tplotvars=lpw_pan, /notplot
  
  indx = where(lpw_pan ne '', count)
  if (count gt 0) then pans = lpw_pan[indx] else pans = ''

  get_data,'mvn_lpw_lp_iv_l2',data=iv,index=i
  if (i gt 0) then imax = max(iv.y, dim=2, /nan)

  get_data,'mvn_lpw_lp_ne_l2',data=n_e,index=j
  if (j gt 0) then begin
    if (i gt 0) then begin
      qmax = interpol(imax, iv.x, n_e.x)
      indx = where(qmax lt mincur, count)
      if (count gt 0L) then n_e.y[indx] = !values.f_nan  ; mask data below threshold
      store_data,'mvn_lpw_lp_ne_l2',data=n_e
    endif
    options,'mvn_lpw_lp_ne_l2','psym',0
    options,'mvn_lpw_lp_ne_l2','colors',[1]
  endif

  get_data,'mvn_lpw_lp_te_l2',data=t_e,index=j
  if (j gt 0) then begin
    if (i gt 0) then begin
      qmax = interpol(imax, iv.x, t_e.x)
      indx = where(qmax lt mincur, count)
      if (count gt 0L) then t_e.y[indx] = !values.f_nan  ; mask data below threshold
      store_data,'mvn_lpw_lp_te_l2',data=t_e
    endif
    options,'mvn_lpw_lp_te_l2','psym',0
    options,'mvn_lpw_lp_te_l2','colors',[1]
  endif

  get_data,'mvn_lpw_lp_vsc_l2',data=v_e,index=j
  if (j gt 0) then begin
    if (i gt 0) then begin
      qmax = interpol(imax, iv.x, v_e.x)
      indx = where(qmax lt mincur, count)
      if (count gt 0L) then v_e.y[indx] = !values.f_nan  ; mask data below threshold
    endif
    indx = where((v_e.y gt 15.) or (v_e.y lt -20.), count)
    if (count gt 0L) then v_e.y[indx] = !values.f_nan

    store_data,'mvn_lpw_lp_vsc_l2',data=v_e
    options,'mvn_lpw_lp_vsc_l2','psym',0
    options,'mvn_lpw_lp_vsc_l2','colors',[1]
  endif

  return
  
end
