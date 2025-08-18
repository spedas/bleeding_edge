;+
;PROCEDURE:	get_emom2
;PURPOSE:	
;  Gets eesa moment structure.
;INPUT:	
;	none, but "load_3dp_data" must be called 1st.
;KEYWORDS:
;   POLAR
;   VTHERMAL
;CREATED BY:	Davin Larson
;FILE:  get_emom2.pro
;VERSION:  1.3
;LAST MODIFICATION:  97/11/14
;-


pro get_emom2,data=data,polar=polar,vthermal=vthermal, $
    no_tplot=no_tplot,mag_name=mag_data

@wind_com.pro
if n_elements(wind_lib) eq 0 then begin
   print,'You must first load some data'
   return
endif

mom={momdata,charge:0,mass:0.d,dens:0.d,temp:0.d,vel:dblarr(3), $
   vv:dblarr(3,3),q:dblarr(3)}

moment={emoment_str,time:0.d,spin:0,gap:0,valid:0, $
   cmom:bytarr(14),dist:mom}

rec_len = long( n_tags(moment,/length) )

num = call_external(wind_lib,'emom_to_idl')
if num le 0 then begin
  message,/info,'No electron moment data during this time'
  return
endif

data = replicate(moment,num)
vv_uniq = [0,4,8,1,2,5]
vv_trace = [0,4,8]

sze = call_external(wind_lib,'emom_to_idl',num,rec_len,data)

if not keyword_set(no_tplot) then begin
time = ptr_new(data.time)

mass = 5.6856591e-6 


;corrections: 
data.dist.vv[0,0] = data.dist.vv[0,0] / 1.115
data.dist.vv[1,1] = data.dist.vv[1,1] / 1.115
data.dist.vv[2,2] = data.dist.vv[2,2] / 1.023
data.dist.vv[0,2] = -data.dist.vv[0,2]
data.dist.vv[1,2] = -data.dist.vv[1,2]

data.dist.vv[2,0] = data.dist.vv[0,2]
data.dist.vv[2,1] = data.dist.vv[1,2]

store_data,'Ne',data={x:time, y:data.dist.dens}
store_data,'Te',data={x:time, y:data.dist.temp}
store_data,'Ve',data={x:time, y:transpose(data.dist.vel)}
store_data,'VVe',data={x:time, y:transpose(data.dist.vv(vv_uniq))}
store_data,'Qe',data={x:time, y:transpose(data.dist.q)}
t3arr = replicate(!values.f_nan,num,3)
symmarr = replicate(!values.f_nan,num,3)
if n_elements(magdir) ne 3 then magdir=[-1.,1.,0.]
magfn = magdir/sqrt(total(magdir^2)) 
for i=0l,num-1 do begin
   dens = data[i].dist.dens
   vel = data[i].dist.vel
;   t3x3 = (data[i].dist.vv) * mass
   t3x3 = (data[i].dist.vv - (vel # vel)) * mass
   t3evec = t3x3
   t3 = replicate(!values.f_nan,3)
   if total(t3evec[[1,3,8]]) gt 0. then begin
      trired,t3evec,t3,dummy
      triql,t3,dummy,t3evec

      s = sort(t3)
      if t3[s[1]] lt .5*(t3[s[0]] + t3[s[2]]) then n=s[2] else n=s[0]

      shft = ([-1,1,0])[n] 
      t3 = shift(t3,shft)
      t3evec = shift(t3evec,0,shft)

      dot =  total( magfn * t3evec[*,2] )
      if dot lt 0 then t3evec = -t3evec
      symm = t3evec[*,2]
;     symm_ang = acos(abs(dot)) * !radeg
      magdir = symm
      t3arr[i,*]= t3
      symmarr[i,*] = symm
   endif
endfor
store_data,'T3e',data={x:time, y:t3arr}
store_data,'SDe',data={x:time, y:symmarr}
if keyword_set(mag_data) then begin
   magf = data_cut(mag_data,data.time)
   mt3e = replicate(!values.f_nan,num,3)

   for i=0l,num-1 do begin
      rot = rot_mat(reform(magf[i,*]))
      t3x3 = (data[i].dist.vv - (vel # vel)) * mass
      tp3x3 = transpose(rot) # (t3x3 # rot)
      mt3e[i,*] = tp3x3[[0,4,8]]
   endfor

   store_data,'MT3e',data={x:time,y:mt3e}
endif

if not keyword_set(polar) then xyz_to_polar,'Ve',/ph_0_360

if not keyword_set(vthermal) then begin
   vthe = sqrt(total(data.dist.vv(vv_trace),1))
   store_data,'VTHe',data={x:time, y:vthe}
endif

endif


return
end


