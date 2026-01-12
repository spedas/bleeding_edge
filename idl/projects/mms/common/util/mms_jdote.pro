;+
; Procedure:
;  mms_jdote
;
; Purpose:
;  Create tplot variables for MMS J dot E'
;
;
; Keywords:
;
;     trange:     time range of interest [starttime, endtime]
;                 if empty, the default time will be ['2022-03-06/05:42:00', '2022-03-06/06:12:00']
;                 if you want to use an already defined timespan then you can use:  trange = timerange()
;
;     probes:     list of probes, only the first in the list will be used
;                 default is ['3']
;
;     data_rate:  the data rate
;                 default is 'brst'
;
;     werror:     returns 1 if there was an error, 0 if no errors
;
; Example use:
;      To run using the default values, simply use:
;      mms_jdote
;
;      To specify some keywords, use:
;      timespan,'2022-03-06/05:42', 30, /min
;      trange = timerange()
;      probes = ['3']
;      data_rate = 'brst'
;      mms_jdote, probes=probes, trange=trange, data_rate=data_rate
;
;
; Notes:
;      Code provided by Marit Oieroset and Victoria Coffey.
;      Please note that this code requires a good measurement of the electric field parallel to the magnetic field,
;      which is very rare. It should be used for specific time intervals only.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-01-07 13:03:20 -0800 (Wed, 07 Jan 2026) $
;$LastChangedRevision: 33976 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_jdote.pro $
;-

function mms_crossn3,a,b
  ; modified version of the mms function crossn3
  COMPILE_OPT idl2

  sa = size(a)

  ok = (sa[0] eq 2) and (sa[2] eq 3)

  if not ok then begin
    dprint, 'not an N x 3 vector...'
    return,!values.f_nan
  endif

  sb = size(b)

  ok = (sb[0] eq 2) and (sb[2] eq 3)

  if not ok then begin
    dprint, 'not an N x 3 vector...'
    return,!values.f_nan
  endif

  c = a-a

  c[*,0] = a[*,1]*b[*,2] - b[*,1]*a[*,2]
  c[*,1] = a[*,2]*b[*,0] - b[*,2]*a[*,0]
  c[*,2] = a[*,0]*b[*,1] - b[*,0]*a[*,1]

  return,c
end

FUNCTION mms_dotp,v,w
  ; modified version of the mms function dotp

  COMPILE_OPT idl2

  vv = reform(v)
  ww = reform(w)
  sv = size(vv)
  sw = size(ww)
  IF (sv[0] NE 1 AND sv[0] NE 2) OR (sw[0] NE 1 AND sw[0] NE 2) THEN $
    GOTO,size_error

  IF sv[0] NE sw[0] THEN BEGIN
    m = 2
    IF sw[0] EQ 1 THEN BEGIN
      IF sw[1] NE sv[2] THEN GOTO,size_error
      ww = ww ## make_array(sv[1],value=ww[0]-ww[0]+1)
    ENDIF ELSE BEGIN                ;sv[0] eq 1
      IF sv[1] NE sw[2] THEN GOTO,size_error
      vv = vv ## make_array(sw[1],value=vv[0]-vv[0]+1)
    ENDELSE
  ENDIF ELSE BEGIN
    m = sv[0]                       ;m = 1 or 2
    FOR i=1,m DO IF sv[i] NE sw[i] THEN GOTO,size_error
  ENDELSE

  return,total(vv*ww,m)

  size_error:
  dprint, string('dotp: ')+'inputs have incompatible sizes'
  return,!values.f_nan

END

pro mms_vperppara_xyz, velvar, magf, vperp_mag=vperp_mag, vpara=vpara, vperp_xyz=vperp_xyz
  ; modified version of the mms function vperppara_xyz

  COMPILE_OPT idl2

  tinterpol, magf, velvar, newname='b1_interp'

  get_data, velvar, data=vec1
  get_data, 'b1_interp', data=vec2

  vpara_t= total(vec1.y*vec2.y,2)/sqrt(total(vec2.y^2,2))

  vperp_t= sqrt(total(vec1.y^2,2) - vpara_t^2)

  if keyword_set(vperp_mag) then store_data,vperp_mag,data={xtitle:'Time',x:vec1.x,y:vperp_t}

  if keyword_set(vpara) then store_data,vpara,data={xtitle:'Time',x:vec1.x,y:vpara_t}

  get_data,velvar,data = v

  get_data,'b1_interp',data = b

  vperpx = v.y[*,0] - mms_dotp(v.y,b.y) * b.y[*,0] / (b.y[*,0]^2 + b.y[*,1]^2 + b.y[*,2]^2)
  vperpy = v.y[*,1] - mms_dotp(v.y,b.y) * b.y[*,1] / (b.y[*,0]^2 + b.y[*,1]^2 + b.y[*,2]^2)
  vperpz = v.y[*,2] - mms_dotp(v.y,b.y) * b.y[*,2] / (b.y[*,0]^2 + b.y[*,1]^2 + b.y[*,2]^2)


  vperp = fltarr(n_elements(vperpx), 3)

  vperp[*,0] = vperpx
  vperp[*,1] = vperpy
  vperp[*,2] = vperpz

  if keyword_set(vperp_xyz) then store_data,vperp_xyz,data = {x:v.x, y:vperp}

end

pro mms_jdote, probes=probes, trange=trange, data_rate=data_rate, werror=werror

  COMPILE_OPT idl2

  mms_init

  msg = "Disclaimer: Please note that the procedure mms_jdote requires " + $
          "a good measurement of the electric field parallel to the magnetic field, " + $
          "which is very rare. It should only be used for specific time intervals."
  dprint, msg

  ; Error handling
  werror=0
  catch, Error_status
  if Error_status ne 0 then begin
    werror=1
    dprint, 'Error message: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  ; Default keywords
  if ~keyword_set(trange) then begin
    timespan,'2022-03-06/05:42', 30, /min ; Victoria Coffey event
    tr = timerange()
  endif else tr = trange
  if ~keyword_set(probes) then probes=['3'] else probes=[probes[0]]
  sc_id = 'mms' + string(probes[0])
  if ~keyword_set(data_rate) then data_rate='brst'

  ; Load data
  mms_load_fgm, trange=tr, probes=probes, data_rate=data_rate
  mms_load_edp, trange=tr, probes=probes, data_rate=data_rate
  mms_load_fpi, trange=tr, probes=probes, data_rate=data_rate

  ; Find _current_ve_vi_gse
  copy_data,sc_id+'_dis_bulkv_gse_brst',sc_id+'_Vi'
  copy_data,sc_id+'_des_bulkv_gse_brst',sc_id+'_Ve'

  tinterpol,sc_id+'_Vi', sc_id+'_Ve',newname='vi_des'

  get_data,'vi_des',data=vii
  get_data,sc_id+'_Ve',data=vee
  get_data,sc_id+'_des_numberdensity_brst',data=nee

  current_e=(nee.y#[1.,1.,1.])*(vii.y-vee.y)*1.6e-10*1e6 ; in micro A
  store_data,sc_id+'_current_ve_vi_gse',data={x:vee.x,y:current_e}


  ;*** jdotE ***
  get_data,sc_id+'_current_ve_vi_gse',data=d
  store_data,sc_id+'_jmag',data={x:d.x,y:sqrt(d.y[*,0]^2+d.y[*,1]^2+d.y[*,2]^2)}

  copy_data,sc_id+'_fgm_b_gse_'+data_rate+'_l2_bvec',sc_id+'_B'
  tinterpol,sc_id+'_B',sc_id+'_Vi',newname='B_dis'

  tinterpol,sc_id+'_B',sc_id+'_edp_dce_gse_brst_l2',newname='B_interp'

  get_data,sc_id+'_edp_dce_gse_brst_l2',data=ee
  get_data,'B_interp',data=b

  mms_vperppara_xyz, sc_id+'_edp_dce_gse_brst_l2', 'B_interp', vpara=sc_id+'_E_para', vperp_xyz=sc_id+'_E_perp_xyz'

  store_data,'Bmag',data={x:b.x,y:sqrt(b.y[*,0]^2+b.y[*,1]^2+b.y[*,2]^2)}
  get_data,'Bmag',data=bmag

  cross_prod=mms_crossn3(ee.y, b.y)
  num=float(n_elements(b.x))
  e_cross_b=fltarr(num,3)

  for i=0,num-1 do begin
    e_cross_b[i,0]=1e3*cross_prod[i,0]/bmag.y[i]^2 ; in km/s
    e_cross_b[i,1]=1e3*cross_prod[i,1]/bmag.y[i]^2
    e_cross_b[i,2]=1e3*cross_prod[i,2]/bmag.y[i]^2
  endfor

  store_data,sc_id+'_ExB',data={x:b.x,y:e_cross_b}

  tinterpol,sc_id+'_B',sc_id+'_Ve',newname='B_ave_ve'
  tinterpol,sc_id+'_edp_dce_gse_brst_l2',sc_id+'_Ve',newname='E_ave_ve'

  get_data,sc_id+'_Ve',data=v
  get_data,'B_ave_ve',data=b

  cross_prod=-mms_crossn3(v.y, b.y)
  num=float(n_elements(b.x))
  v_cross_b=fltarr(num,3)

  for i=0.,num-1 do begin
    v_cross_b[i,0]=1e-3*cross_prod[i,0]
    v_cross_b[i,1]=1e-3*cross_prod[i,1]
    v_cross_b[i,2]=1e-3*cross_prod[i,2]
  endfor

  store_data,sc_id+'_vexB_efield',data={x:v.x,y:v_cross_b}

  get_data,'E_ave_ve',data=e_des
  get_data,sc_id+'_vexB_efield',data=vexb

  get_data,sc_id+'_current_ve_vi_gse',data=c_ve_vi

  e_frozen=e_des.y-vexb.y ; vexb is actually -vex

  jdoteprime=dotp(c_ve_vi.y,e_frozen)*1e-9*1e9 ; in nW

  jdote=dotp(c_ve_vi.y,e_des.y)*1e-9*1e9 ; in nW

  store_data,sc_id+'_e_frozen',data={x:e_des.x,y:e_frozen}
  store_data,sc_id+'_jdoteprime',data={x:e_des.x,y:jdoteprime}

  store_data,sc_id+'_jdote',data={x:e_des.x,y:jdote}

  mms_vperppara_xyz, sc_id+'_current_ve_vi_gse', 'B_ave_ve', vpara=sc_id+'_current_fpi_para', vperp_xyz=sc_id+'_current_fpi_perp_xyz'
  mms_vperppara_xyz, sc_id+'_e_frozen', 'B_ave_ve', vpara=sc_id+'_e_frozen_para', vperp_xyz=sc_id+'_e_frozen_perp_xyz'

  get_data,sc_id+'_current_fpi_perp_xyz',data=current_fpi_perp_xyz
  get_data,sc_id+'_e_frozen_perp_xyz',data=e_frozen_perp_xyz

  jdoteprime_perp=dotp(current_fpi_perp_xyz.y,e_frozen_perp_xyz.y)*1e-9*1e9 ; in nW

  get_data,sc_id+'_current_fpi_para',data=current_fpi_para
  get_data,sc_id+'_e_frozen_para',data=e_frozen_para

  jdoteprime_para=current_fpi_para.y*e_frozen_para.y*1e-9*1e9 ; in nW

  store_data,sc_id+'_jdoteprime_perp',data={x:e_des.x,y:jdoteprime_perp}
  store_data,sc_id+'_jdoteprime_para',data={x:e_des.x,y:jdoteprime_para}

  options,sc_id+'_jdoteprime_perp','colors',2
  options,sc_id+'_jdoteprime_para','colors',6

  store_data,sc_id+'_jdoteprime_comp',data=[sc_id+'_jdoteprime',sc_id+'_jdoteprime_perp',sc_id+'_jdoteprime_para']

  mms_vperppara_xyz, sc_id+'_current_ve_vi_gse', 'B_ave_ve', vpara=sc_id+'_current_fpi_para', vperp_xyz=sc_id+'_current_fpi_perp_xyz'
  mms_vperppara_xyz, 'E_ave_ve', 'B_ave_ve', vpara='E_ave_ve_para', vperp_xyz='E_ave_ve_perp_xyz'

  get_data,sc_id+'_current_fpi_perp_xyz',data=current_fpi_perp_xyz
  get_data,'E_ave_ve_perp_xyz',data=e_ave_ve_perp_xyz

  jdote_perp=dotp(current_fpi_perp_xyz.y,e_ave_ve_perp_xyz.y)*1e-9*1e9 ; in nW

  get_data,sc_id+'_current_fpi_para',data=current_fpi_para
  get_data,'E_ave_ve_para',data=e_ave_ve_para

  jdote_para=current_fpi_para.y*e_ave_ve_para.y*1e-9*1e9 ; in nW

  store_data,sc_id+'_jdote_perp',data={x:e_des.x,y:jdote_perp}
  store_data,sc_id+'_jdote_para',data={x:e_des.x,y:jdote_para}

  options,sc_id+'_jdote_perp','colors',2
  options,sc_id+'_jdote_para','colors',6

  store_data,sc_id+'_jdote_comp',data=[sc_id+'_jdote',sc_id+'_jdote_perp',sc_id+'_jdote_para']

  copy_data,sc_id+'_jdote',sc_id+'_jdote2'
  copy_data,sc_id+'_jdoteprime',sc_id+'_jdoteprime2'

  options,sc_id+'_jdote2','colors',6

  store_data,sc_id+'_jdote_and_eprime',data=[sc_id+'_jdoteprime2',sc_id+'_jdote2']

  ; tplot, sc_id+'_jdote_and_eprime'

end