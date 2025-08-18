; $LastChangedBy: moka $
; $LastChangedDate: 2024-07-30 09:30:12 -0700 (Tue, 30 Jul 2024) $
; $LastChangedRevision: 32773 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_data/eva_data_load_mms_fgm.pro $
PRO eva_data_load_mms_fgm, sc=sc, sfx=sfx
  
  if undefined(sfx) then sfx = 'dfg'
  
  if sfx eq 'afg' then begin 
    mms_sitl_get_afg, sc=sc
  endif else begin
    mms_sitl_get_dfg, sc=sc
  endelse
  
  tng = sc+'_'+sfx+'_srvy_gsm_dmpa'
  eva_cap,tng,max=150.
  options,tng,$
    labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],ytitle=sc+'!C'+strupcase(sfx)+'!Cgsm',ysubtitle='[nT]',$
    colors=[2,4,6],labflag=-1,constant=0
  
  tnd = sc+'_'+sfx+'_srvy_dmpa'
  eva_cap,tnd,max=150.
  options,tnd,$
    labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],ytitle=sc+'!C'+strupcase(sfx)+'!Cdmpa',ysubtitle='[nT]',$
    colors=[2,4,6],labflag=-1,constant=0
    
  eva_cap,sc+'_'+sfx+'_srvy_gsm_dmpa_btot',max=150; |B|
  options,sc+'_'+sfx+'_srvy_gsm_dmpa_btot',$
    labels='|B|',ytitle=sc+'!C'+strupcase(sfx)+'!C|B|',ysubtitle='[nT]',$
    colors=0,labflag=-1,constant=0,ynozero=0
    
  tn = tnames(sc+'*')
  idg = where(strmatch(tn,tng),ctg)
  idd = where(strmatch(tn,tnd),ctd)
  if (ctg eq 1) and (ctd eq 1) then begin
    get_data,tng,data=Dg
    get_data,tnd,data=Dd
    nmax = n_elements(Dg.x)
    mmax = n_elements(Dd.x)
    if (nmax eq mmax) then begin 
      Dnewx = fltarr(nmax,2)
      Dnewy = fltarr(nmax,2)
      Dnewz = fltarr(nmax,2)
      Dnewx[*,0] = Dg.y[*,0]
      Dnewx[*,1] = Dd.y[*,0]
      Dnewy[*,0] = Dg.y[*,1]
      Dnewy[*,1] = Dd.y[*,1]
      Dnewz[*,0] = Dg.y[*,2]
      Dnewz[*,1] = Dd.y[*,2]
      tt = sc+'_'+sfx+'_srvy_gsmdmpa'
      store_data,tt+'_x',data={x:Dg.x, y:Dnewx}
      store_data,tt+'_y',data={x:Dg.x, y:Dnewy}
      store_data,tt+'_z',data={x:Dg.x, y:Dnewz}
      options, tt+'_*',colors=[2,6],labflag=-1,labels=['GSM-DMPA','DMPA'],constant=0
      options, tt+'_x',ytitle=sc+'!C'+strupcase(sfx)+'!Csrvy!Cx'
      options, tt+'_y',ytitle=sc+'!C'+strupcase(sfx)+'!Csrvy!Cy'
      options, tt+'_z',ytitle=sc+'!C'+strupcase(sfx)+'!Csrvy!Cz'
    endif
  endif

END
