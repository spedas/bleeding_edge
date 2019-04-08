;+
; :DESCRIPTION:
;    Divide tplot variables including all beams into that for each beam.
;
; :EXAMPLE:
;    splitbeam, 'sd_hok_vlos_0'
;
; :Author:
;    Tomoaki Hori (E-mail: horit@isee.nagoya-u.ac.jp)
; :HISTORY:
;    2010/03/02: Created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
PRO splitbeam, tvars

  tvars = tnames(tvars)
  if strlen(tvars[0]) lt 6 then return
  
  FOR n = 0, N_ELEMENTS(tvars)-1 DO BEGIN
  
    ;Does tvar exist?
    tvar = tvars[n]
    IF SIZE(tvar,/type) EQ 2 OR SIZE(tvar,/type) EQ 3 THEN tvar=tnames(tvar)
    IF STRLEN(tnames(tvar)) LT 2 THEN CONTINUE ;Skip if tplot var not found
    IF STRLOWCASE(STRMID(tvar, 0,3)) NE 'sd_' THEN CONTINUE ;Skip if given non-SD data
    
    ;Generate the tplot var. name for the beam_dir
    stn = STRMID(tvar, 3,3)
    suf = STRMID(tvar, 0,1, /reverse )
    beamdir_tvar_name = 'sd_'+stn+'_azim_no_'+suf
    
    IF STRLEN(tnames(beamdir_tvar_name)) LT 2 THEN CONTINUE
    
    get_data, beamdir_tvar_name, data=d
    bmidx = uniq( d.y, SORT(d.y) )
    
    get_data, tvar, data=data, dl=dl, lim=lim
    
    FOR i=0L, N_ELEMENTS(bmidx)-1 DO BEGIN
    
      azim_suf = '_azim' + STRING(d.y[bmidx[i]], '(I2.2)')
      vn = tvar + azim_suf
      ;print, vn
      idx = WHERE( d.y EQ d.y[bmidx[i]] )
      ;print, n_elements(idx)
      IF idx[0] EQ -1 THEN CONTINUE
      ;help, dd.x, dd.y
      if is_struct(data) then begin
        dd = data
        store_data, vn, data={x:dd.x[idx], y:dd.y[idx,*], v:dd.v }, dl=dl, lim=lim
      endif else begin ;Cases of multi-tplot var containing both iono. and ground scatter data 
        vn_iono = data[ ( where( strpos(data,'iscat') ge 0 ) )[0] ] ;& help, vn_iono
        vn_gscat= data[ ( where( strpos(data,'gscat') ge 0 ) )[0] ] ;& help, vn_gscat
        get_data, vn_iono, data=dd, dl=dl, lim=lim
        get_data, vn_gscat, data=ddg, dl=dlg, lim=limg
        store_data, vn_iono+azim_suf, data={x:dd.x[idx], y:dd.y[idx,*], v:dd.v}, dl=dl,lim=lim
        store_data, vn_gscat+azim_suf,data={x:ddg.x[idx],y:ddg.y[idx,*],v:ddg.v},dl=dlg,lim=limg
        options, vn_iono+azim_suf, 'ytitle', STRUPCASE(stn)+'!Cbm'+STRING(d.y[bmidx[i]], '(I2.2)')
        options, vn_iono+azim_suf, 'ysubtitle', '[range gate]'
        store_data, vn, data=[ vn_iono+azim_suf,vn_gscat+azim_suf ]
      endelse
      
      options, vn, 'ytitle', STRUPCASE(stn)+'!Cbm'+STRING(d.y[bmidx[i]], '(I2.2)')
      options, vn, 'ysubtitle', '[range gate]'
      maxrg = max(dd.v,/nan)+1
      ylim, vn, [0,maxrg]
      
    ENDFOR
    
  ENDFOR
  
  
END

