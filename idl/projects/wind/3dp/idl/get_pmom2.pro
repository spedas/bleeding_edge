


;+
;PROCEDURE:	get_pmom2
;PURPOSE:	
;  Gets pesa moment structure.
;INPUT:	
;	none, but "load_3dp_data" must be called 1st.
;KEYWORDS:
;   POLAR
;   VTHERMAL
;CREATED BY:	Davin Larson
;FILE:  get_pmom2.pro
;VERSION:  1.4
;LAST MODIFICATION:  02/11/01
;-


pro get_pmom2,protons=protons,alphas=alphas,polar=polar,prefix=prefix,magf=magf, $
    no_tplot=no_tplot,magname=magname,nofixtime=nofixtime, $
    nofixwidth=nofixwidth,nofixmcp=nofixmcp,time_shift=time_shift

@wind_com.pro
if n_elements(wind_lib) eq 0 then begin
   print,'You must first load some data'
   return
endif

if n_elements(polar) eq 0 then polar =1

mom={pmomdata,charge:0,mass:0.d,dens:0.d,temp:0.d,vel:dblarr(3), $
   vv:dblarr(3,3),q:dblarr(3)}

moment={moment_str,time:0.d,spin:0,gap:0,valid:0,e_s:0b,ps:0b, $
   cmom:bytarr(10),Vc:0,e_ran:fltarr(2),dist:mom}

rec_len = long( n_tags(moment,/length) )

num = call_external(wind_lib,'pmom_to_idl')

if num le 0 then begin
  message,/info,'No pmom data available'
  return
endif

protons = replicate(moment,num)
alphas  = replicate(moment,num)
vv_uniq = [0,4,8,1,2,5]
vv_trace = [0,4,8]

num = call_external(wind_lib,'pmom_to_idl',num,rec_len,protons,alphas)

if not keyword_set(nofixtime) then begin
  protons= fix_pmom_spin_time(protons)  
  alphas = fix_pmom_spin_time(alphas)
endif

time = protons.time
if keyword_set(time_shift) then time = time + time_shift

;kluge,  remove when fixed in C - code.
protons.dist.vv[1*3+2] = -protons.dist.vv[1*3+2]
protons.dist.vv[2*3+1] = -protons.dist.vv[2*3+1]
protons.dist.vv[0*3+2] = -protons.dist.vv[0*3+2]
protons.dist.vv[2*3+0] = -protons.dist.vv[2*3+0]
;end of kludge

Vpmag = sqrt(total(protons.dist.vel^2,1))

;temp = protons.dist.temp - .074^2 * .00522*vpmag^2

;vtherm = sqrt(temp/.00522)

if not keyword_set(nofixwidth) then begin

; subtract instrument response here....

; ctime,t
; wid = average(tsample('VVp',t),1)
; vp2 = average(tsample('Vp_mag',t))^2
; vth2 = average(tsample('wi_swe_VTHp',t))^2
; inst_width2 = float((wid - vth2*[1,1,1,0,0,0]/2) / vp2)
; printdat,/val,wid=300,inst_width2,'instwidth2'
;inst_width2 = [0.00307388, 0.00240956, 0.00274486, 0.00172333, 0,0]
inst_width2 = [0.00238550, 0.00305542, 0.00185387, 0.00173632, 0, 0]

vv_map = [[0,3,4],[3,1,5],[4,5,2]]
ii = inst_width2[vv_map]
for i=0l,n_elements(time)-1 do $
   protons[i].dist.vv = protons[i].dist.vv - ii * vpmag[i]^2
for i=0l,n_elements(time)-1 do $
   alphas[i].dist.vv = alphas[i].dist.vv - ii * vpmag[i]^2

; rotate matrix

dphi = (protons.ps - 4 )/64.*2*!pi
s2 = sin(dphi)
c2 = cos(dphi)
sc = s2*c2
s2 = s2^2
c2 = c2^2
xx  = protons.dist.vv[0]
xy  = protons.dist.vv[1]
yy  = protons.dist.vv[4]

protons.dist.vv[0] =  c2 * xx  + 2*sc   * xy + s2 * yy
protons.dist.vv[1] = -sc * xx  + (c2-s2)* xy + sc * yy
protons.dist.vv[3] = protons.dist.vv[1]
protons.dist.vv[4] = s2  * xx  - 2*sc   * xy + c2 * yy

endif

vthp = sqrt(total(protons.dist.vv(vv_trace),1)*2/3)
vtha = sqrt(total(alphas.dist.vv(vv_trace),1)*2/3)

protons.dist.temp = .00522 * vthp^2
alphas.dist.temp = 4* .00522 * vtha^2


;vt3 = replicate(!values.f_nan,n_elements(time))
;for i=0l,n_elements(time)-1 do begin
;      vv = reform(protons[i].dist.vv)
;      if finite(total(vv)) then  vt3[i]=sqrt(determ(reform(vv),/check,/double))
;endfor

if not keyword_set(nofixmcp) then begin
   file= file_source_dirname(/mark)+'pl_mcp_eff_3dp.dat'
   dprint,dlevel=2,'PL efficiency file: ',file
   mcp=read_asc(file,/tags,/conv_time)
   t = protons.time
   dummy = interp(mcp.eff,mcp.time,t,index=i)
   eff = (mcp.eff)[i]
   dt  = (mcp.dt)[i]
   rmax = protons.dist.dens * vpmag^4 / vthp^3 /1e6
   corr = (1+rmax*dt) /eff
   protons.dist.dens = protons.dist.dens *  corr
endif

if not keyword_set(no_tplot) then begin

if size(/type,prefix) ne 7 then prefix=''

;store_data,prefix+'Vc',data={x:time,   y:protons.Vc}
store_data,prefix+'Np',data={x:time,   y:float(protons.dist.dens)}
if keyword_set(corr) then store_data,prefix+'Eff',data={x:time,   y:float(1/corr)}
store_data,prefix+'Tp',data={x:time,   y:float(protons.dist.temp)}
store_data,prefix+'Vp',data={x:time,   y:float(transpose(protons.dist.vel))}
if  keyword_set(polar) then xyz_to_polar,prefix+'Vp',/ph_0_360
store_data,prefix+'VVp',data={x:time,   y:float(transpose(protons.dist.vv(vv_uniq)))}
store_data,prefix+'VTHp',data={x:time, y:float(vthp)}
store_data,prefix+'VTHp/Vp',data={x:time, y:float(vthp/vpmag)}
store_data,prefix+'Na/Np',data={x:time,   y:float(alphas.dist.dens/protons.dist.dens)}
store_data,prefix+'Na',data={x:time,   y:float(alphas.dist.dens)}
store_data,prefix+'Ta',data={x:time,   y:float(alphas.dist.temp)}
store_data,prefix+'Va',data={x:time,   y:float(transpose(alphas.dist.vel))}
if  keyword_set(polar) then xyz_to_polar,prefix+'Va',/ph_0_360
store_data,prefix+'VVa',data={x:time,   y:float(transpose(alphas.dist.vv(vv_uniq)))}
store_data,prefix+'VTHa',data={x:time,  y:float(vtha)}

;store_data,prefix+'VTHp^3',data={x:time,   y:float(vt3)}
;store_data,prefix+'spin',data={x:time, y:long(uint(protons.spin))}

magf=0
mass = protons[0].dist.mass

if keyword_set(magname) then begin
    P3 = fltarr(n_elements(time),6)
    vt3 = fltarr(n_elements(time))
    magf = data_cut(magname,time)
    for i=0l,n_elements(time)-1 do begin
      rmat = rot_mat(reform(magf[i,*]))
      vv = reform(protons[i].dist.vv)
;      vv = transpose(rmat) ## (vv ## rmat)
      vv = rotate_tensor(vv,rmat)
      P3[i,*] = vv[vv_uniq]
    endfor
    store_data,prefix+'RVVp',data={x:time,   y:float(P3)}
    T3 =P3[*,0:2]*mass
    help,T3,mass,P3
    assym = 2*P3[*,2]/(p3[*,1]+p3[*,0])
    store_data,prefix+'T3p',data={x:time,y:float(T3)}
    store_data,prefix+'Tp_rat',data={x:time,y:float(assym)}
    store_data,prefix+'magf',data={x:time,y:float(magf)}
endif


endif


return
end

