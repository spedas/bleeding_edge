;+
;Purpose:
;Generates a set of field and moment plots.
;Only ground processed moments will be used.
;
;The plots include:
;
;
;Arguments:
;       date: the date for which the plots will be generated
;
;       probe: the probe for which the plots will be generated
;
;       directory(optional): an optional output directory
; 
;       device(optional):switch to 'z' device for cron plotting
;
;       makepng(optional):set this keyword to direct script to make a png
;
;Example:
; thm_fitgmom_overviews,'2007-03-23','b',dir='~/out',device='z'
;
; $LastChangedBy$
; $LastChangedDate$
; $LastChangedRevision$
; $URL$
;-

;Moved to separate file
;this procedure will set the maximum and minimum for a given mnemonic
;within a specific time range
;pro set_lim,mnem,start,stop,min,max,log
;
;COMPILE_OPT idl2,hidden
;
;if tnames(mnem) then begin 
;
;   get_data,mnem,data=d
;
;   if(n_elements(d) eq 1) then begin
;
;      t_idx = where(d.x ge start and d.x le stop)
;
;      n = size(d.y,/n_dim)
;
;   
;      if(t_idx[0] eq -1) then begin
;         ylim,mnem,min,max,log
;         return
;      endif
;
;
;      if(n eq 1) then dy = d.y[t_idx] $
;      else if(n eq 2) then dy = d.y[t_idx,*] $
;      else if(n eq 3) then dy = d.y[t_idx,*,*] $
;      else message,'cannot handle n_dim'
;
;      i_idx = where(finite(dy))
;
;      if(i_idx[0] ne -1) then dy = dy[i_idx]
;
;      min2 = min(dy)
;      max2 = max(dy)
;
;      if(min2 lt min) then minf = min else minf=min2
;      if(max2 gt max) then maxf = max else minf=max2
;
;   endif else begin
;      
;      min2 = -1*!VALUES.D_INFINITY
;      max2 = !VALUES.D_INFINITY
;   
;      for i=0,n_elements(d)-1 do begin 
;
;         get_data,d[i],data=d2
;
;         If(is_struct(d2) Eq 0) Then continue ;jmm, 3-jan-2009
;
;         t_idx = where(d2.x ge start and d2.x le stop)
;
;         n = size(d2.y,/n_dim)
;
;         if(t_idx[0] eq -1) then continue
;
;         if(n eq 1) then dy = d2.y[t_idx] $
;         else if(n eq 2) then dy = d2.y[t_idx,*] $
;         else if(n eq 3) then dy = d2.y[t_idx,*,*] $
;         else message,'cannot handle n_dim'
;
;         i_idx = where(finite(dy))
;
;         if(i_idx[0] ne -1) then dy = dy[i_idx]
;
;; The following two lines are syntax errors, jmm, 12-jun-2008
;;         min2 = min(dy,min2)
;;         max2 = max(dy,max2)
;         min2i = min(dy)
;         max2i = max(dy)
;         If(i Eq 0) Then Begin
;           min2 = min2i & max2 = max2i
;         Endif Else Begin
;           If(min2i Lt min2) Then min2 = min2i
;           If(max2i Gt max2) Then max2 = max2i
;         Endelse
;      endfor
;   
;      if(min2 lt min) then minf = min else minf=min2
;      if(max2 gt max) then maxf = max else minf=max2
;
;;      minf = max(min2,min)
;;      maxf = min(max2,max)
;   
;;      if(max2 gt maxf) then maxf = max else minf=max2
;   endelse
;
;   ylim,mnem,minf,maxf,log
;
;endif else begin
;   dprint,'Mnemonic does not exist: ' + mnem
;endelse
;
;end

;makes a blank panel if proper data quantities are not present
;pro blank_panel,mnem,ytitle,labels=labels
;
;dcolors = [2,4,6,0]
;
;x = timerange(/current)
;
;y = [!VALUES.F_NAN,!VALUES.F_NAN]
;
;if keyword_set(labels) then begin
;
;   
;   d = {x:x,y:rebin(y,2,n_elements(labels))}
;
;   cols = dcolors[0:(n_elements(labels)-1)]
;
;   dl = {ytitle:ytitle,labels:labels,colors:cols,labflag:1}
;
;endif else begin
;   
;   d = {x:x,y:y}
;
;   dl = {ytitle:ytitle}
;
;endelse
;
;store_data,mnem,data=d,dlimits=dl
;
;end

pro thm_fitgmom_overviews,date,probe,directory=directory,device=device,makepng=makepng

;I always use this compiler option
;it makes integer values 32 bit by default and
;prevents the indexing of arrays using '()'
;thus fixing a couple of idl's quirks
compile_opt idl2

probe_list = ['a','b','c','d','e']

;clean slate
del_data,'*'

thm_init

if not keyword_set(date) then begin
    dprint,'Date must be set to generate fields and moments overview plots'
    return
endif

date2 = time_string(date)

if not keyword_set(probe) then begin
    dprint,'probe must be set to generate fields and moments overview plots'
    return
endif

probe = strlowcase(probe)

if(strfilter(probe_list,probe) eq '') then begin
   dprint,'probe must be valid to generate fields and moments overview plots'
    return
endif

if keyword_set(directory) then dir=directory else dir='./'

if keyword_set(device) then set_plot,device

timespan,date2,1,/day

times = timerange(/current)

;increase the x margin so that you can see the labels on the left
tplot_options, 'xmargin', [20, 10]

var_string = ''

;-----------------------
;fgm with total
;thm_load_fgm,probe=probe,coord='gsm', level = 'l2'
;Use L1 data
thm_load_fit,probe=probe,coord='gsm',suffix='_gsm'

fgs_name = 'th'+probe+'_fgs_gsm'

if tnames(fgs_name) then begin

   tvectot,fgs_name,newname=fgs_name+'+t'

   options,fgs_name+'+t',ytitle='th'+probe+'!Cfgs!Cgsm',ysubtitle='[nT]'

   thm_set_lim,fgs_name+'+t',times[0],times[1],-100D,100D,0

   get_data,fgs_name+'+t',dlimit=dl

   dl.labels[3] = 'Bt'

   store_data,fgs_name+'+t',dlimit=dl

;for recent FGS data, if there is an estimated Bz, put the Bz curve
;behind Bx and By. jmm, 2024-12-12
;Set Bz to zero if L1B data is not used, jmm, 2025-06-02
   If(probe Eq 'e' And time_double(date) Ge time_double('2024-06-01')) Then Begin
      options, fgs_name+'+t', 'indices', [2,0,1,3]
      get_data, 'th'+probe+'_fgl_l1b_bz', data = temp_bz
      If(~is_struct(temp_bz)) Then Begin ;reset Bz to zero
         get_data, fgs_name+'+t', data = dbz
         dbz.y[*, 2] = 0
         dbz.y[*, 3] = sqrt(dbz.y[*, 0]^2+dbz.y[*, 1]^2)
         store_data, fgs_name+'+t', data = dbz
      Endif
   Endif

endif else begin 

   thm_blank_panel,fgs_name+'+t','th'+probe+'!Cfgs!Cgsm!C[nT]',labels=['Bx','By','Bz','Bt']

endelse

var_string += ' ' + fgs_name+'+t'

thm_load_state,probe=probe,coord='gsm',/get_support

;---------------------------------------
;fgm with t89 model field subtracted

if tnames(fgs_name) && tnames('th'+probe+'_state_pos') then begin

   tinterpol_mxn,'th'+probe+'_state_pos',fgs_name,newname='pos_interp', /QUADRATIC
   
   tt89,'pos_interp', period=3.049

;now subtract
   dif_data,fgs_name,'pos_interp_bt89',newname=fgs_name+'-t89'

   get_data,fgs_name,dlimit=dl

   store_data,fgs_name+'-t89',dlimit=dl

;ensure that the y scale is bounded at +- 100 nT

   thm_set_lim,fgs_name+'-t89',times[0],times[1],-100D,100D,0

   options,fgs_name+'-t89',ytitle='th'+probe+'!Cfgs!Cgsm!C-t89',ysubtitle='[nT]',labels=['Bx','By','Bz']

   If(probe Eq 'e' And time_double(date) Ge time_double('2024-06-01')) Then Begin
      options, fgs_name+'-t89', 'indices', [2,0,1]
      get_data, 'th'+probe+'_fgl_l1b_bz', data = temp_bz
      If(~is_struct(temp_bz)) Then Begin ;reset Bz to zero
         get_data, fgs_name+'-t89', data = dbz
         dbz.y[*, 2] = 0
         store_data, fgs_name+'-t89', data = dbz
      Endif
   Endif

endif else begin
  
   thm_blank_panel,fgs_name+'-t89','th'+probe+'!Cfgs!Cgsm!C-t89!C[nT]',labels=['Bx','By','Bz']

endelse

var_string += ' ' + fgs_name+'-t89'

thm_load_esa, probe = probe, level = 'l2'
;If Level 2 data didn't show up, check for L1
thx = 'th'+probe[0]
index_esa_e = where(thx+'_peef_en_eflux' eq tnames())
index_esa_i = where(thx+'_peif_en_eflux' eq tnames())

if(index_esa_e[0] eq -1 Or index_esa_i[0] Eq -1) then begin
  thm_load_esa_pkt, probe = probe[0]
  instr_all = ['peif', 'peef', 'peir', 'peer', 'peib', 'peeb']
  for j = 0, n_elements(instr_all)-1 do begin
    test_index = where(thx+'_'+instr_all[j]+'_en_counts' eq tnames())
    If(test_index[0] Ne -1) Then $
      thm_part_moments, probe = probe[0], instrument = instr_all[j]
  endfor
endif

thm_load_efi,probe=probe,datatype='vaf',level=1,coord='spg'

;-----------------------------------------------------
;here we do the sample rate bar
sample_rate_var = ' ' + thm_sample_rate_bar(date,1,probe,/outline)

var_string += sample_rate_var


;----------------------------------------------
;- Npot, Ni, Ne [1/cc] (b,g,r)
;Npot is the spacecraft potential-derived density, Nishimura calculation
;color and label needs to be reset
thm_scpot2dens_opt_n, probe = probe, /no_data_load, datatype_esa = 'peer'
copy_data, 'th'+probe+'_peer_density_npot', 'Npot'
;check for data, If the variable exists, but with no data, then delete it
If(tnames('Npot')) Then Begin
  get_data, 'Npot', data = dtest
  If(is_struct(dtest) Eq 0) Then del_data, 'Npot' Else Begin
    options, 'Npot', colors = 2
    options, 'Npot', labels = ''
  Endelse
Endif


if tnames('Npot') && tnames('th'+probe+'_peer_density') then begin

   get_data,'th'+probe+'_peer_density',data=d

   d2 = {x:d.x,y:rebin(d.y,n_elements(d.y),3)}

   store_data,'dlab_kluge',data=d2

   options,'dlab_kluge',colors=[2,0,6],labels=['Npot','Ni','Ne'],labflag=1

   store_data,'den_mom',data=['Npot','th'+probe+'_peir_density','dlab_kluge']
   
endif else if tnames('th'+probe+'_peer_density') then begin 

   get_data,'th'+probe+'_peer_density',data=d

   d2 = {x:d.x,y:rebin(d.y,n_elements(d.y),2)}

   store_data,'dlab_kluge',data=d2

   options,'dlab_kluge',colors=[0,6],labels=['Ni','Ne'],labflag=1

   store_data,'den_mom',data=['th'+probe+'_peir_density','dlab_kluge']

endif

options,'th'+probe+'_peir_density',colors=0

if tnames('den_mom') then begin

   options,'den_mom','ytitle','Density!C[1/cc]'

   thm_set_lim,'den_mom',times[0],times[1],1.0e-3, 100.0,1

endif else begin

   thm_blank_panel,'den_mom','Density!C[1/cc]',labels=['Npot','Ni','Ne']

endelse

var_string += ' den_mom'

;-------------------------------------------------------
;- Ti_para, Ti_perp, Te_para, Te_perp [green, blue, black, red]

 ;     These are constructed from the magt3 as:
 ;     Ti_perp = (Ti_x+Ti_y)/2 [average perp] 
 ;     That makes no sense at all
 ;     switched to sqrt(Ti_x^2+Ti_y^2), jmm, 2009-12-09
 ;     Ti_para = Ti_z
 ;     etc.

if tnames('th'+probe+'_peir_magt3') && $
   tnames('th' + probe + '_peer_magt3') then begin

   get_data,'th' + probe + '_peir_magt3',data=d

   ti_perp = sqrt(d.y[*,0]^2+d.y[*,1]^2)

   ti_para = d.y[*,2]

   store_data,'ti_para',data={x:d.x,y:ti_para}

   store_data,'ti_perp',data={x:d.x,y:ti_perp}

   get_data,'th' + probe + '_peer_magt3',data=d

   te_perp = sqrt(d.y[*,0]^2+d.y[*,1]^2)

   te_para = d.y[*,2]

   store_data,'te_para',data={x:d.x,y:te_para}

   store_data,'tlab_kluge',data={x:d.x,y:rebin(te_perp,n_elements(te_perp),4)}

   options,'ti_para',colors=4

   options,'ti_perp',colors=2

   options,'te_para',colors=0

   options,'te_perp',colors=6

   options,'tlab_kluge',colors=[4,2,0,6],labels=['Ti!9'+string(35B)+'!X', 'Ti!9'+string(120B)+'!X',$
                                                 'Te!9'+string(35B)+'!X', 'Te!9'+string(120B)+'!X'], labflag = 1

   store_data,'Tieperpara',data=['ti_para','ti_perp','te_para','tlab_kluge']

   options,'Tieperpara',ytitle='magt3!C[eV]'

   thm_set_lim,'Tieperpara',times[0],times[1],-1*!VALUES.D_INFINITY,!VALUES.D_INFINITY,1

endif else begin

   thm_blank_panel,'Tieperpara','magt3!C[eV]',labels=['Ti!9'+string(35B)+'!X', 'Ti!9'+string(120B)+'!X',$
                                                 'Te!9'+string(35B)+'!X', 'Te!9'+string(120B)+'!X']
endelse

var_string += ' Tieperpara'


;--------------------------------------------------------
;- thx_peir_velocity [km/s] (x y z t = blue, green, red, black)
;  For on board moments, when possible, replace with:
;  thx_peim_velocity

;      Autoscale this with max velocity of +/-1500km/s.

pei_vel_name = 'th'+probe+'_peir_velocity_gsm'

if tnames(pei_vel_name) then begin

   options,pei_vel_name,'labels',['Vx','Vy','Vz'],def=1

   options,pei_vel_name,'labflag',1,def=1

   tvectot,pei_vel_name,newname=pei_vel_name+'+t'
   
   options,pei_vel_name+'+t',ytitle='th'+probe+'!Cpeir!Cvelocity!Cgsm'

   get_data,pei_vel_name+'+t',dlimit=dl

   dl.labels[3] = 'Vt'

   store_data,pei_vel_name+'+t',dlimit=dl

   thm_set_lim,pei_vel_name+'+t',times[0],times[1],-1500D,1500D,0
   
endif else begin

   thm_blank_panel,pei_vel_name+'+t','th'+probe+'!Cpeim!Cvelocity!C[km/s]',labels=['Vx','Vy','Vz','Vt']

endelse

var_string += ' ' + pei_vel_name+'+t'

;------------------------------------------------------
;- thm_peer_velocity [km/s] (x y z t = blue, green, red, black)
;  For on board moments, when possible, replace with:
;  thx_peem_velocity

;      Autoscale, max velocity of +/-1500km/s.


pee_vel_name = 'th'+probe+'_peer_velocity_gsm'

if tnames(pee_vel_name) then begin

   options,pee_vel_name,'labels',['Vx','Vy','Vz'],def=1

   options,pee_vel_name,'labflag',1,def=1

   tvectot,pee_vel_name,newname=pee_vel_name+'+t'
   
   options,pee_vel_name+'+t',ytitle='th'+probe+'!Cpeer!Cvelocity!Cgsm'

   get_data,pee_vel_name+'+t',dlimit=dl

   dl.labels[3] = 'Vt'

   store_data,pee_vel_name+'+t',dlimit=dl

   thm_set_lim,pee_vel_name+'+t',times[0],times[1],-1500D,1500D,0
   
endif else begin

   thm_blank_panel,pee_vel_name+'+t','th'+probe+'!Cpeer!Cvelocity!C[km/s]',labels=['Vx','Vy','Vz','Vt']

endelse

var_string += ' ' + pee_vel_name+'+t'


;-------------------------------------------------------------
;- Exyz (mV/m): this is the E cross B velocity of the plasma.
;     Computed as: E = - VxB
;     * Take the negative of the cross-product of Vi and B.
;     * Use the conversion that 1mV/m = 1000km/s in 1nT.
;       So to convert from nT*km/s to mV/m divide by 1000.
;     * Note: You must interpolate the B data on the V times before
;       multiplying, even though they are at the same cadence.

if tnames('th'+probe+'_peir_velocity_gsm') && $
   tnames('th'+probe+'_fgs_gsm') then begin

   
   ;this clipping fixes an artifact where interpolation sometimes causes
   ;unreasonably large or small values if the velocity times preceed or
   ;exceed the fgm times.
   time_clip,'th'+probe+'_peir_velocity_gsm','th'+probe+'_fgs_gsm','th'+probe+'_fgs_gsm',/tvar,newname='vel_clip'

   tinterpol_mxn,'th'+probe+'_fgs_gsm','vel_clip',newname='bvinterpol'

   tcrossp, 'vel_clip', 'bvinterpol',newname='vxb';jmm,3-mar-2008, removed 'th'+probe

   get_data,'vxb',data=d

   if(size(d, /type) eq 8) then begin ;jmm, protect against missing data, 28-apr-2008

     d.y = d.y*(-1D/1000D)

     store_data, 'e_eq_nvxb', data = d

     options, 'e_eq_nvxb', 'ytitle', 'E=-VxB'

     options, 'e_eq_nvxb', 'ysubtitle', '[mV/m]'

     options, 'e_eq_nvxb', 'labels', ['Ex', 'Ey', 'Ez']

     options, 'e_eq_nvxb', 'colors', [2, 4, 6]

     options, 'e_eq_nvxb', 'labflag', 1

   endif else  thm_blank_panel,'e_eq_nvxb','E=-VxB!C[mV/m]',labels=['Ex','Ey','Ez']

endif else begin 

   thm_blank_panel,'e_eq_nvxb','E=-VxB!C[mV/m]',labels=['Ex','Ey','Ez']

endelse

   var_string += ' e_eq_nvxb'


;- Pi, Pe, Pb, Pt [nPa] (blue, green, red, black)

;      Pb is the magnetic pressure, proportional to Btotal ^ 2.
;      Pt is the total (magnetic + particle) pressure = Pi+Pe+Pb
;      Pi, Pe are the fourth component of the 4-vector pressure
;      or the fourth component of the 4-vector temperature (the average)
;      multiplied by N. Multiply Pi, Pe [eV/cm^3] by 1.6x 10^-4 to get nPa
;      Multiply nT^2 by 1./2513.2741 to get nPa (magnetic pressure).
;     * Note: You must interpolate the B data on the Pi times before
;       multiplying, even though they are on the same cadence.

if tnames('th'+probe+'_fgs_gsm') && $
   tnames('th'+probe+'_peir_ptens') && $
   tnames('th'+probe+'_peer_ptens') then begin

   get_data,'th'+probe+'_fgs_gsm',data=d_fgs

   get_data,'th'+probe+'_peir_ptens',data=d_peir

   get_data,'th'+probe+'_peer_ptens',data=d_peer

   Pb = total(d_fgs.y^2,2) * (1D/2513.2741D)

   Pi = (d_peir.y[*,0]+d_peir.y[*,1]+d_peir.y[*,2])/3D * 1.6e-4

   Pe = (d_peer.y[*,0]+d_peer.y[*,1]+d_peer.y[*,2])/3D * 1.6e-4

   Pb_i = interpol(pb,d_fgs.x,d_peir.x)

   Pe_i = interpol(pe,d_peer.x,d_peir.x)

   Pt = Pi + Pb_i + Pe_i

   d = {x:d_peir.x,y:[[Pi],[Pe_i],[Pb_i],[Pt]]}

   store_data,'pressure_vars',data=d

   options,'pressure_vars',colors=[2,4,6,0],labels=['Pi','Pe','Pb','Pt'],labflag=1
   
   options,'pressure_vars',ysubtitle='[nPa]',ytitle='Pressure'

endif else begin

   thm_blank_panel,'pressure_vars','Pressure!C[nPa]',labels=['Pi','Pe','Pb','Pt']

endelse

var_string += ' pressure_vars'


;- Omnidirectional spectrum thx_peir_en_spec for ions at 3sec
;  resolution (standard L2 product)

if tnames('th'+probe+'_peir_en_eflux') then begin

   get_data, 'th'+probe+'_peir_en_eflux', data = d

;change d.v for cases with 0 energy
   xxx = where(d.v lt 1.0, nxxx)
   If(nxxx Gt 0) Then Begin
      d.v[xxx] = 0.01
      store_data, 'th'+probe+'_peir_en_eflux', data = d
   Endif
   yminv = min(d.v) > 0.1

   thm_spec_lim4overplot,'th'+probe+'_peir_en_eflux',zlog=1,ylog=1,/overwrite,ymin=yminv

   options,'th' + probe + '_peir_en_eflux','ysubtitle','eV/!C(cm^2-s-!Csr-eV)'
   
   options,'th' + probe + '_peir_en_eflux','ytitle','th'+probe+'!Cpeir!Cen!Ceflux'

endif else begin

   thm_blank_panel,'th'+probe+'_peir_en_eflux','thb!Cpeir!Cen_eflux!CeV/!C(cm^2-s-!Csr-eV)'

endelse

var_string += ' th' + probe + '_peir_en_eflux'

;- Omnidirectional spectrum thx_peer_en_spec for ions at 3sec
;  resolution (standard L2 product)

if tnames('th'+probe+'_peer_en_eflux') then begin

   get_data, 'th'+probe+'_peer_en_eflux', data = d

;change d.v for cases with 0 energy
   xxx = where(d.v lt 1.0, nxxx)
   If(nxxx Gt 0) Then Begin
      d.v[xxx] = 0.01
      store_data, 'th'+probe+'_peer_en_eflux', data = d
   Endif
   yminv = min(d.v) > 0.1

   thm_spec_lim4overplot,'th'+probe+'_peer_en_eflux',zlog=1,ylog=1,/overwrite,ymin=yminv

   options,'th' + probe + '_peer_en_eflux','ysubtitle','eV/!C(cm^2-s-!Csr-eV)'
   
   options,'th' + probe + '_peer_en_eflux','ytitle','th'+probe+'!Cpeer!Cen!Ceflux'

endif else begin

   thm_blank_panel,'th'+probe+'_peer_en_eflux','thb!Cpeer!Cen_eflux!CeV/!C(cm^2-s-!Csr-eV)'

endelse 

var_string += ' th' + probe + '_peer_en_eflux'

;options copied from thm_gen_overplot

!p.background=255.
!p.color=0.
time_stamp,/off
loadct2,43
!p.charsize=0.8

;eliminate space between plots

tplot_options,'ygap',0.0D

;set limits
thm_set_lim,fgs_name+'+t',times[0],times[1],-100D,100D,0

thm_set_lim,fgs_name+'-t89',times[0],times[1],-100D,100D,0

thm_set_lim,'den_mom',times[0],times[1],1.0e-3, 100.0,1

thm_set_lim,'Tieperpara',times[0],times[1], 0.1, 9999.0,1

thm_set_lim,pei_vel_name+'+t',times[0],times[1],-1500D,1500D,0

thm_set_lim,pee_vel_name+'+t',times[0],times[1],-1500D,1500D,0

thm_set_lim,'pressure_vars',times[0],times[1],0D,50D,1

if tnames('th'+probe+'_state_pos') then begin

   get_data,strjoin('th'+probe+'_state_pos'),data=tmp
   store_data,strjoin('th'+probe+'_state_pos_gsm_x'),data={x:tmp.x,y:tmp.y[*,0]/6371.2}
   options,strjoin('th'+probe+'_state_pos_gsm_x'),'ytitle','th'+probe+'_X-GSM'
   store_data,strjoin('th'+probe+'_state_pos_gsm_y'),data={x:tmp.x,y:tmp.y[*,1]/6371.2}
   options,strjoin('th'+probe+'_state_pos_gsm_y'),'ytitle','th'+probe+'_Y-GSM'
   store_data,strjoin('th'+probe+'_state_pos_gsm_z'),data={x:tmp.x,y:tmp.y[*,2]/6371.2}
   options,strjoin('th'+probe+'_state_pos_gsm_z'),'ytitle','th'+probe+'_Z-GSM'

endif

probes_title = ['P5',  'P1',  'P2',  'P3', 'P4'] ;jmm, 3-mar-2008, 
scv = strcompress(strlowcase(probe[0]),/remove_all)
pindex = where(probe_list Eq scv) ;this is always true for one probe by the time we are here
title =  probes_title[pindex[0]]+' (TH-'+strupcase(scv)+') fields and ground moments overview'
tplot,var_string,title=title, var_label = ['th'+probe+'_state_pos_gsm_z', 'th'+probe+'_state_pos_gsm_y', 'th'+probe+'_state_pos_gsm_x']

if keyword_set(makepng) then begin
  year = strmid(date, 0, 4)
  month = strmid(date, 5, 2)
  day = strmid(date, 8, 2)
  ymd = year+month+day
  if keyword_set(directory) then dir=directory else dir='./'
  makepng,dir+'th'+probe+'_l2_gmoms_'+year+month+day+'_0024',/no_expose
;six-hour plots
  For j = 0, 3 Do Begin
    hrs0 = 6*j
    hrs1 = 6*j+6
    tr0 = time_double(date)+3600.0d0*[hrs0, hrs1]
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
;Set limits for this time period
    thm_set_lim, fgs_name+'+t', tr0[0], tr0[1], -100D, 100D, 0
    thm_set_lim, fgs_name+'-t89', tr0[0], tr0[1], -100D, 100D, 0
    thm_set_lim, 'den_mom', tr0[0], tr0[1], 1.0e-3, 100.0, 1
    thm_set_lim, 'Tieperpara', tr0[0], tr0[1], 0.1, 9999.0, 1
    thm_set_lim, pei_vel_name+'+t', tr0[0], tr0[1], -1500D, 1500D,0
    thm_set_lim, pee_vel_name+'+t', tr0[0], tr0[1], -1500D, 1500D,0
    thm_set_lim, 'pressure_vars', tr0[0], tr0[1], 0D, 50D, 1
    tplot, trange = tr0
    makepng, dir+'th'+probe+'_l2_gmoms_'+ymd+'_'+hshf, /no_expose
  Endfor
;two-hour plots
  For j = 0, 11 Do Begin
    hrs0 = 2*j
    hrs1 = 2*j+2
    tr0 = time_double(date)+3600.0d0*[hrs0, hrs1]
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
;Set limits for this time period
    thm_set_lim, fgs_name+'+t', tr0[0], tr0[1], -100D, 100D, 0
    thm_set_lim, fgs_name+'-t89', tr0[0], tr0[1], -100D, 100D, 0
    thm_set_lim, 'den_mom', tr0[0], tr0[1], 1.0e-3, 100.0, 1
    thm_set_lim, 'Tieperpara', tr0[0], tr0[1], 0.1, 9999.0, 1
    thm_set_lim, pei_vel_name+'+t', tr0[0], tr0[1], -1500D, 1500D, 0
    thm_set_lim, pee_vel_name+'+t', tr0[0], tr0[1], -1500D, 1500D, 0
    thm_set_lim, 'pressure_vars', tr0[0], tr0[1], 0D, 50D, 1
    tplot, trange = tr0
    makepng, dir+'th'+probe+'_l2_gmoms_'+ymd+'_'+hshf, /no_expose
  Endfor
;reset the time range
  tlimit, 0, 0
Endif
End
