PRO eva_data_load_mms_exb, sc=sc, vthres=vthres, ql=ql, hpca=hpca, fpi=fpi
  compile_opt idl2
  if undefined(vthres) then vthres = 500.
  
  ; B
  ;------------
  tn = tnames(sc+'_dfg_srvy_dmpa',ct)
  if ct ne 1 then begin
    mms_sitl_get_dfg, sc_id=sc
    eva_cap,sc+'_dfg_srvy_gsm_dmpa'
    options,sc+'_dfg_srvy_gsm_dmpa',$
      labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],ytitle=sc+'!CDFG!Cgsm',ysubtitle='[nT]',$
      colors=[2,4,6],labflag=-1,constant=0
    eva_cap,sc+'_dfg_srvy_dmpa'
    options,sc+'_dfg_srvy_dmpa',$
      labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],ytitle=sc+'!CDFG!Cgsm',ysubtitle='[nT]',$
      colors=[2,4,6],labflag=-1,constant=0
  endif
  
  ; E
  ;------------
  tn = tnames(sc+'_edp_fast_dce_sitl',ct)
  if ct ne 1 then begin
    mms_sitl_get_edp,sc=sc, level = 'sitl'
    options,sc+'_edp_fast_dce_sitl', $
      labels=['X','Y','Z'],ytitle=sc+'!CEDP!Cfast',ysubtitle='[mV/m]',$
      colors=[2,4,6],labflag=-1,yrange=[-20,20],constant=0
  endif
  
  ; ExB
  ;------------
  get_data,sc+'_dfg_srvy_dmpa',data=B
  get_data,sc+'_edp_fast_dce_sitl',data=E,dl=dl,lim=lim
  tnB = tnames(sc+'_dfg_srvy_dmpa',ctB)
  tnE = tnames(sc+'_edp_fast_dce_sitl',ctE)
  if ctB eq 1 and ctE eq 1 then begin
    ; E has a higher time resolution than B
    ; Here, we interpolate B so that its timestamps will match with those of E.
    Bip = fltarr(n_elements(E.x),3)
    wBx = interpol(B.y[*,0], B.x, E.x,/spline)
    wBy = interpol(B.y[*,1], B.x, E.x,/spline)
    wBz = interpol(B.y[*,2], B.x, E.x,/spline)
    iwB2 = 1000./(wBx^2 + wBy^2 + wBz^2)
    EXB = fltarr(n_elements(E.x),3)
    EXB[*,0] = ((E.y[*,1]*wBz - E.y[*,2]*wBy)*iwB2 > (-1)*vthres) < vthres
    EXB[*,1] = ((E.y[*,2]*wBx - E.y[*,0]*wBz)*iwB2 > (-1)*vthres) < vthres
    EXB[*,2] = ((E.y[*,0]*wBy - E.y[*,1]*wBx)*iwB2 > (-1)*vthres) < vthres
    str_element,/delete,'lim','yrange'
    store_data,sc+'_exb_dsl',data={x:E.x,y:EXB},dl=dl
    options,sc+'_exb_dsl',labels=['(ExB)x','(ExB)y','(ExB)z'],labflag=-1,colors=[2,4,6],$
      ytitle=sc+'!CExB',ysubtitle='[km/s]',constant=0,ystyle=1

    ; extract ExB to be compared with FPI
    comp = ['x','y','z']
    clrs = [2,4,6]
    cmax = n_elements(comp)
    for c=0,cmax-1 do begin
      store_data,sc+'_exb_dsl_'+comp[c],data={x:E.x,y:EXB[*,c]}
      options,sc+'_exb_dsl_'+comp[c],labels='(ExB)'+comp[c],labflag=-1,colors=clrs[c],$
        ytitle=sc+'!C(ExB)'+comp[c],ysubtitle='[km/s]',constant=0,ystyle=1
    endfor
  endif
  
  ; Compare with FPI/HPCA
  ;-------------------------
  
  if (not keyword_set(fpi)) and (not keyword_set(hpca) ) then return
  
;  tpv = keyword_set(ql) ? '_dis_bulk' : '_fpi_iBulkV_DSC' 
;  tpv2 = keyword_set(ql) ? '_dis_bulkVperp_' : '_fpi_iBulkVperp_'
;  tpv3 = keyword_set(ql) ? '_exbql_vperp_' : '_exb_vperp_'
  tpv = keyword_set(hpca) ? '_hpca_hplus_ion_bulk_velocity' : '_fpi_ion_vel_dbcs'
  tpv2 = keyword_set(hpca) ? '_hpca_ion_Vperp' : '_fpi_ion_Vperp'
  tpv3 = keyword_set(hpca) ? '_exb_hpca_vperp_' : '_exb_fpi_vperp_'

  ; extract Vperp
  tn = tnames(sc+tpv,ct)
  if ct ne 1 then begin
    if keyword_set(hpca) then begin
      prb = strmid(sc,3,1)
      eva_data_load_mms_hpca, prb=prb, level='sitl'
    endif else begin
      eva_data_load_mms_fpi_ql, sc=sc
    endelse
  endif
  tn = tnames(sc+tpv,ct)
  if ct eq 1 then begin
  
    ; V has a much lower time resolution than B
    ; Here, we keep the lower time resolution by interpolating B.
    get_data,sc+tpv,data=F
    wBx = interpol(B.y[*,0], B.x, F.x)
    wBy = interpol(B.y[*,1], B.x, F.x)
    wBz = interpol(B.y[*,2], B.x, F.x)
    iwB2 = 1./(wBx^2 + wBy^2 + wBz^2)
    BdotV = iwB2*(wBx*F.y[*,0]+wBy*F.y[*,1]+wBz*F.y[*,2])
    Vperp = fltarr(n_elements(F.x),3)
    Vperp[*,0] = F.y[*,0] - BdotV*wBx
    Vperp[*,1] = F.y[*,1] - BdotV*wBy
    Vperp[*,2] = F.y[*,2] - BdotV*wBz
    for c=0,cmax-1 do begin
      store_data,sc+tpv2+comp[c],data={x:F.x,y:Vperp[*,c]}
      options,sc+tpv2+comp[c],labels='Vperp,'+comp[c],labflag=-1,colors=clrs[c],$
        ytitle=sc+'!CVperp,'+comp[c],ysubtitle='[km/s]',constant=0,ystyle=1
    endfor
    
    ; combine
    for c=0,cmax-1 do begin
      store_data,sc+tpv3+comp[c],data=sc+['_exb_dsl_',tpv2]+comp[c]
      options,sc+tpv3+comp[c],colors=[clrs[c],0],labflag=-1,$
        labels=['(ExB)'+comp[c],'Vperp,'+comp[c]]
    endfor
    
  endif
END