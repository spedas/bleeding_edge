;+
; NAME:
;    thm_scpot_density
;
; PURPOSE:
;    Convert the spacecraft potential to the electron density
;
; CATEGORY:
;    EFI, ESA
;
; CALLING SEQUENCE:
;    thm_scpot_density,probe=probe,datatype_esa=datatype_esa,datatype_efi=datatype_efi,merge=merge,noplot=noplot,scpot_esa=scpot_esa
;
; EXAMPLE:
;    thm_scpot_density,probe='d';default run
;    thm_scpot_density,probe='d',datatype_esa='peer',datatype_efi='vaf' ; scpot from vaf and vthermal from peer
;    thm_scpot_density,probe='d',datatype_esa='peer',datatype_efi='vaf',/merge ; merge scpot data from ESA and EFI packets
;
; PRE-REQUIREMENTS:
;    IDL save file (th'+probe+'_scpot_density_coefficients.sav'), which contains a conversion table.
;    Timespan for the calculation	like timespan,'2009-01-01/00:00:00',1,/day
;
; KEYWORD PARAMETERS:
;    probe              spacecraft name: 'a', 'b', 'c', 'd' or 'e'. Default is 'a'.
;    datatype_esa       ESA datatype: 'peef', 'peer', 'peem' or 'peeb'. Default is 'peef'.
;    datatype_efi       EFI datatype: 'vaf', 'vap' or 'vaw'. If
;                       omitted, spin-resolution 'PXXM' scpot is used.
;                       Otherwise, use scpot data stored in the EFI packet
;                       instead of 'datatype_esa', while the thermal
;                       velocity data are given by 'datatype_esa' and
;                       interpolated. The time resolution is higher.
;    suffix             If set, then this suffix is appended to the
;                       output variables
; OUTPUTS:
;    'th'+probe+'_'+datatype_efi+'_density' Electron density in cm-3
;    'th'+probe+'_*_density_comparison' Densities from ESA, scpot and Sheeley et al. model
;
; RESTRICTIONS:
;    The calculated electron density may include uncertainties. Uncertainties are larger where the thermal velocity of electrons is not accurately estimated: in the plasmasphere, plasmatrough and lobe. Error data in the electron thermal speed or spacecraft potential give unreliable denisities. The scpot data are not available in the inner L-shells during the early period of the mission.
;    Generally a factor of 2 uncertainty exists. scpot is sometimes inaccurate, particularly during large injection events, in shadows, in the magnetosheath and solar wind after 2013.  The plasmasphere density is only calibrated with the Sheeley et al. model. Long-term variations there aren't reliable.
;
;
; MODIFICATIONS:
;    Written by: Toshi Nishimura, 05/02/2009, modified 12/27/2017 (toshi16 at bu.edu)
;
;    Collaborators: Vassilis Angelopoulos and John Bonnell
;    It is recommended to contact them before presentations or publications using the data created by this code. Contact Toshi if you have technical questions or want him to check data quality.
;    Update in 2017: (1) Use time-dependent calibration parameters. The old code uses a fixed set of coefficients calibrated in 2009, and those parameters weren't updated since then, giving inaccurate density particularly in recent years. The old code should not be used after 2013. The new code considers time variation of the conversion coefficients calibrated by referring to the ESA density where reliable. (2) Improved plasmasphere and plume density estimates. The old code had issues of artificial offsets and wiggles, sometimes reaching by an order of magnitude, due to inaccurately determined scpot and thermal velocity. The new code produces the density that follows more closely with scpot and the Sheeley statistical model.
;
;

function sigmoid,x,height,xshift,stiffness
  return,height/(1.+exp(-stiffness*(x-xshift)))
end


pro thm_scpot_density,probe=probe,datatype_esa=datatype_esa,datatype_efi=datatype_efi,noload=noload,$
                      merge=merge,noplot=noplot,scpot_esa=scpot_esa,scpot_in=scpot_in,$
                      vthermal_in=vthermal_in,suffix=suffix

  compile_opt idl2

  if not (keyword_set(probe)) then probe='a'
  if not (keyword_set(datatype_esa)) then datatype_esa='peef'
  if (keyword_set(datatype_efi)) then datatype_efi_init=datatype_efi

  get_timespan,t

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SM position
  if not(keyword_set(noload)) then thm_load_state, probe = probe, datatype='pos',coord = 'sm'

  get_data,strjoin('th'+probe+'_state_pos'),data=tmp
  store_data, 'th'+probe+'_R', data={x:tmp.x, y:sqrt(tmp.y[*,0]^2+tmp.y[*,1]^2+tmp.y[*,2]^2)/6371.},dlim={colors:[0],labels:['R'],ysubtitle:'[km]',labflag:1,constant:0,ytitle:'th'+probe+'_R'}
  MLT=atan(tmp.y[*,1]/tmp.y[*,0])*180/!pi/15.+12
  if(n_elements(where(tmp.y[*,0] lt 0)) gt 1) then MLT[where(tmp.y[*,0] lt 0)]=(atan(tmp.y[where(tmp.y[*,0] lt 0),1]/tmp.y[where(tmp.y[*,0] lt 0),0])+!pi)*180/!pi/15.+12
  if(n_elements(where(MLT[*] gt 24)) gt 1) then MLT[where(MLT[*] ge 24)]=MLT[where(MLT[*] ge 24)]-24
  store_data, 'th'+probe+'_MLT', data={x:tmp.x, y:MLT},dlim={colors:[0],labels:['R'],ysubtitle:'[km]',labflag:1,constant:0,ytitle:'th'+probe+'_MLT'}
  MLAT=atan(tmp.y[*,2]/sqrt(tmp.y[*,0]^2+tmp.y[*,1]^2))*180/!pi
  store_data, 'th'+probe+'_MLAT', data={x:tmp.x, y:MLAT},dlim={colors:[0],labels:['MLAT'],ysubtitle:'[deg]',labflag:1,constant:0,ytitle:'th'+probe+'_MLAT'}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load data
  if(datatype_esa eq 'peef' or datatype_esa eq 'peer' or datatype_esa eq 'peeb' or datatype_esa eq 'peem') then begin
     if not(keyword_set(noload)) then begin
    ;load esa
        thm_load_esa, probe = probe, level = 2, datatype = [datatype_esa+'_density',datatype_esa+'_vthermal',datatype_esa+'_en_eflux',datatype_esa+'_sc_pot'],trange=t
        thm_load_esa, probe = probe, level = 2, datatype = ['peer_sc_pot'],trange=t
    ;load esa+efi
    ;thm_load_esa_pkt,probe=probe,datatype=datatype_esa,trange=t
        if not keyword_set(scpot_esa) then thm_pxxm_pot_to_scpot,probe=probe,datatype_efi=datatype_efi,merge=merge,trange=t
     endif
  endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load data
  if not(keyword_set(datatype_efi_init)) then begin
  ;Vsc
     if keyword_set(scpot_in) then scpot_var = scpot_in $
     else if keyword_set(scpot_esa) then scpot_var = 'th'+probe+'_'+datatype_esa+'_sc_pot' $
     else scpot_var = 'th'+probe+'_pxxm_scpot'
     get_data, scpot_var, data=Vdata, index=index
     if(index eq 0) then begin
        print,'NO scpot data'
        return
     endif
  ;scpot
     if not keyword_set(scpot_esa) and not keyword_set(scpot_in) then begin
        tinterpol_mxn,'th'+probe+'_peer_sc_pot','th'+probe+'_pxxm_scpot', newname='th'+probe+'_peer_sc_pot_int'
        get_data,'th'+probe+'_peer_sc_pot_int',data=Vdata_peer
        scpot_offset=median(Vdata.y-Vdata_peer.y)
        Vdata.y=Vdata.y-scpot_offset
     endif
     Vdata.y[*]=-Vdata.y[*]
     store_data,'th'+probe+'_pxxm_-scpot',data=Vdata
  ;Ne
     tinterpol_mxn,'th'+probe+'_'+datatype_esa+'_density','th'+probe+'_pxxm_-scpot', newname='th'+probe+'_'+datatype_esa+'_density_int'
     get_data,'th'+probe+'_'+datatype_esa+'_density_int',data=Nedata,index=index
     if(index eq 0) then begin
        print,'th'+probe+'_'+datatype_esa+'_density_int'
        return
     endif
  ;Vth
     if keyword_set(vthermal_in) then vthermal_var = vthermal_in $
     else vthermal_var = 'th'+probe+'_'+datatype_esa+'_vthermal'
     tinterpol_mxn,vthermal_var,'th'+probe+'_pxxm_-scpot', newname='th'+probe+'_'+datatype_esa+'_vthermal_int'
     get_data,'th'+probe+'_'+datatype_esa+'_vthermal_int',data=Vthdata,index=index
     if(index eq 0) then begin
        print,'th'+probe+'_'+datatype_esa+'_vthermal_int'
        return
     endif
  ;R,MLT
     tinterpol_mxn,'th'+probe+'_R','th'+probe+'_pxxm_-scpot', newname='th'+probe+'_R_int'
     tinterpol_mxn,'th'+probe+'_MLT','th'+probe+'_pxxm_-scpot', newname='th'+probe+'_MLT_int'
     get_data,'th'+probe+'_R_int',data=R,index=index1
     get_data,'th'+probe+'_MLT_int',data=MLT,index=index2
     if(index1 eq 0 or index2 eq 0) then begin
        print,'th'+probe+'_R_int',index1,index2
        return
     endif
  ;;;;;;;;;;;;;;;;;;;;;;;
  endif else begin
  ;Vsc
     if keyword_set(scpot_in) then scpot_var = scpot_in $
     else scpot_var = 'th'+probe+'_esa_pot'
     get_data,scpot_var,data=Vdata,index=index
     if(index eq 0) then begin
        print,scpot_var
        return
     endif
     Vdata.y[*]=-Vdata.y[*]
     store_data,'th'+probe+'_esa_-pot',data=Vdata
  ;Ne
     tinterpol_mxn,'th'+probe+'_'+datatype_esa+'_density' ,'th'+probe+'_esa_pot', newname='th'+probe+'_'+datatype_esa+'_density_int'
     get_data,'th'+probe+'_'+datatype_esa+'_density_int',data=Nedata,index=index
     if(index eq 0) then begin
        print,'th'+probe+'_'+datatype_esa+'_density_int'
        return
     endif
  ;Vth
     if keyword_set(vthermal_in) then vthermal_var = vthermal_in $
     else vthermal_var = 'th'+probe+'_'+datatype_esa+'_vthermal' 
     tinterpol_mxn,vthermal_var,'th'+probe+'_esa_-pot', newname='th'+probe+'_'+datatype_esa+'_vthermal_int'
     get_data,'th'+probe+'_'+datatype_esa+'_vthermal_int',data=Vthdata,index=index
     if(index eq 0) then begin
        print,'th'+probe+'_'+datatype_esa+'_vthermal_int'
        return
     endif
                                ;R,MLT
     tinterpol_mxn,'th'+probe+'_R','th'+probe+'_esa_-pot', newname='th'+probe+'_R_int'
     tinterpol_mxn,'th'+probe+'_MLT','th'+probe+'_esa_-pot', newname='th'+probe+'_MLT_int'
     get_data,'th'+probe+'_R_int',data=R,index=index1
     get_data,'th'+probe+'_MLT_int',data=MLT,index=index2
     if(index1 eq 0 or index2 eq 0) then begin
        print,'th'+probe+'_R_int',index1,index2
        return
     endif
  endelse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Vth correction
  Vthdata.y=Vthdata.y*(1-(-1/(1+exp(-1*(R.y-6)))+1))+1.0*10^2*(-1/(1+exp(-1*(R.y-6)))+1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load coefficients
  fpath = file_dirname(routine_filepath('thm_scpot_density'), /mark)+'thm_scpot_density_coefficients/'
  fname = file_search(fpath+'th'+probe+'_scpot_density_coefficients.sav')
  if fname eq '' then begin     ; original paths
     fname=file_search('./save/th'+probe+'_scpot_density_coefficients.sav')
     if fname eq '' then fname=file_search('th'+probe+'_scpot_density_coefficients.sav')
     if fname eq '' then begin
        print,'th'+probe+'_scpot_density_coefficients.sav is missing'
        return
     endif
  endif
  restore,filename=fname
  psp0=interpol(float(scpot_density_coefficients[*,1]),time_double(scpot_density_coefficients[*,0]),Vdata.x)
  psp1=interpol(float(scpot_density_coefficients[*,2]),time_double(scpot_density_coefficients[*,0]),Vdata.x)
  psp2=interpol(float(scpot_density_coefficients[*,3]),time_double(scpot_density_coefficients[*,0]),Vdata.x)
  p10=interpol(float(scpot_density_coefficients[*,7]),time_double(scpot_density_coefficients[*,0]),Vdata.x)
  p11=interpol(float(scpot_density_coefficients[*,8]),time_double(scpot_density_coefficients[*,0]),Vdata.x)
  p20=interpol(float(scpot_density_coefficients[*,12]),time_double(scpot_density_coefficients[*,0]),Vdata.x)
  p21=interpol(float(scpot_density_coefficients[*,13]),time_double(scpot_density_coefficients[*,0]),Vdata.x)

  psp=fltarr(n_elements(psp0),6)
  p1=fltarr(n_elements(psp0),5)
  p2=fltarr(n_elements(psp0),5)
  psp[*,0:2]=[[psp0],[psp1],[psp2]]
  psp[*,3]=scpot_density_coefficients[0,4]
  psp[*,4]=scpot_density_coefficients[0,5]
  psp[*,5]=scpot_density_coefficients[0,6]
  p1[*,0:1]=[[p10],[p11]]
  p1[*,2]=scpot_density_coefficients[0,9]
  p1[*,3]=scpot_density_coefficients[0,10]
  p1[*,4]=scpot_density_coefficients[0,11]
  p2[*,0:1]=[[p20],[p21]]
  p2[*,2]=scpot_density_coefficients[0,14]
  p2[*,3]=scpot_density_coefficients[0,15]
  p2[*,4]=scpot_density_coefficients[0,16]
;print,median(psp0),median(psp1),median(psp2),median(p10),median(p11),median(p20),median(p21)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;scpot-density conversion
  Ne_scpot=10^(psp[*,0]*exp(-(vdata.y+1.0)^2/psp[*,1])+psp[*,2])*sigmoid(vdata.y,psp[*,3],psp[*,4],psp[*,5])+(10^(p1[*,0]+(vdata.y/p1[*,1]))*sigmoid(vdata.y,p1[*,2],p1[*,3],p1[*,4])+10^(p2[*,0]+(vdata.y/p2[*,1]))*(-sigmoid(vdata.y,p2[*,2],p2[*,3],p2[*,4])+1))/vthdata.y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  options,'th'+probe+'_'+datatype_esa+'_sc_pot',colors=2
  store_data,'th'+probe+'_'+datatype_esa+'_en_eflux_pot',data=['th'+probe+'_'+datatype_esa+'_en_eflux','th'+probe+'_pxxm_scpot','th'+probe+'_'+datatype_esa+'_sc_pot']
  ylim,'th'+probe+'_'+datatype_esa+'_en_eflux_pot',5e0,2.3e4,style=1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;plasmasphere model (just for comparison) [Sheeley et al.]
  Ne_Sheeley_PSph=1390*(3/R.y)^4.8
  Ne_Sheeley_PSsh=124*(3/R.y)^4.0+36*(3/R.y)^3.5*cos((MLT.y-(7.7*(3/R.y)^2+12))*!pi/12)
  Ne_Sheeley_PSph[where(R.y[*] lt 2 or R.y[*] gt 7)]='NaN'
  Ne_Sheeley_PSsh[where(R.y[*] lt 2 or R.y[*] gt 7)]='NaN'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;store data
  if keyword_set(suffix) then sfx = suffix[0] else sfx = ''
  if not(keyword_set(datatype_efi_init)) then begin
     store_data,'th'+probe+'_pxxm_density'+sfx,data={x:Vdata.x,y:[Ne_scpot]},dlim={colors:[0],labels:['Ne_scpot'],ysubtitle:'[cm-3]',labflag:1,constant:0,ylog:1}
     store_data,'th'+probe+'_'+datatype_esa+'_density_Sheeley'+sfx,data={x:Vdata.x,y:[Ne_Sheeley_PSph]},dlim={colors:[0],labels:['Ne_Sheeley_PSph'],ysubtitle:'[cm-3]',labflag:1,constant:0,ylog:1}
     store_data,'th'+probe+'_'+datatype_esa+'_density_comparison'+sfx,data={x:Vdata.x,y:[[Nedata.y],[Ne_scpot],[Ne_Sheeley_PSph]]},dlim={colors:[0,2,6],labels:['Ne_peer','Ne_scpot','Ne_Sheeley_PSph'],ysubtitle:'[cm-3]',labflag:-1,constant:0,ylog:1}
;options,'th'+probe+'_'+datatype_esa+'_density_comparison';,ytickformat='logticks_exp'
;tplot,['th'+probe+'_pxxm_-scpot','th'+probe+'_'+datatype_esa+'_density','th'+probe+'_vthermal2','th'+probe+'_'+datatype_esa+'_density_comparison','th'+probe+'_'+datatype_esa+'_en_eflux_pot'],var_label=['th'+probe+'_R']
     tplot,['th'+probe+'_pxxm_density'+sfx,'th'+probe+'_'+datatype_esa+'_density_comparison'+sfx,'th'+probe+'_'+datatype_esa+'_en_eflux_pot'],var_label=['th'+probe+'_R']

;;;;;;;;;;;;;;;;;;;;;;;
  endif else begin
     store_data,'th'+probe+'_'+datatype_efi_init+'_density'+sfx,data={x:Vdata.x,y:[Ne_scpot]},dlim={colors:[0],labels:['Ne_scpot'],ysubtitle:'[cm-3]',labflag:1,constant:0,ylog:1}
     store_data,'th'+probe+'_'+datatype_efi_init+'_density_Sheeley'+sfx,data={x:Vdata.x,y:[Ne_Sheeley_PSph]},dlim={colors:[0],labels:['Ne_Sheeley_PSph'],ysubtitle:'[cm-3]',labflag:1,constant:0,ylog:1}

     store_data,'th'+probe+'_'+datatype_efi_init+'_density_comparison'+sfx,data={x:Vdata.x,y:[[Nedata.y],[Ne_scpot],[Ne_Sheeley_PSph]]},dlim={colors:[0,2,6],labels:['Ne_'+datatype_esa,'Ne_scpot','Ne_Sheeley_PSph'],ysubtitle:'[cm-3]',labflag:-1,constant:0,ylog:1}
     options,'th'+probe+'_'+datatype_efi_init+'_density_comparison' ;,ytickformat='logticks_exp'
;tplot,['th'+probe+'_esa_pot','th'+probe+'_'+datatype_esa+'_density','th'+probe+'_vthermal2','th'+probe+'_'+datatype_efi_init+'_density_comparison','th'+probe+'_'+datatype_esa+'_en_eflux_pot']
     if not keyword_set(noplot) then tplot,['th'+probe+'_'+datatype_efi_init+'_density'+sfx,'th'+probe+'_'+datatype_efi_init+'_density_comparison'+sfx,'th'+probe+'_'+datatype_esa+'_en_eflux_pot']
  endelse


end
