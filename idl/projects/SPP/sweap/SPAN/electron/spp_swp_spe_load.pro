; $LastChangedBy: orlando $
; $LastChangedDate: 2025-03-14 14:23:43 -0700 (Fri, 14 Mar 2025) $
; $LastChangedRevision: 33179 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_load.pro $
; Created by Davin Larson 2018
; Major updates by Phyllis Whittlesey 2019

pro spp_swp_spe_load,spxs=spxs,types=types,varformat=varformat,trange=trange,no_load=no_load,verbose=verbose,esteps=esteps,psteps=psteps,$
  alltypes=alltypes,allvars=allvars,hkp=hkp,save=save,level=level,file_prefix=file_prefix,no_update=no_update,no_server=no_server

  if ~keyword_set(level) then level='L3'
  if ~keyword_set(types) then types='sf0'
  vars = orderedhash()
  if ~keyword_set(file_prefix) then file_prefix='psp/data/sci/sweap/'
  if ~keyword_set(esteps) then esteps = [4,8,12]
  if ~keyword_set(psteps) then psteps = [11,5,0]
  if level eq 'L3' then begin
    fileformat='spe/L3/SP?_TYP_pad/YYYY/MM/psp_swp_SP?_TYP_L3_pad_YYYYMMDD_v??.cdf'
    ;http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/spe/L3/spb_sf0_pad/2018/11/psp_swp_spb_sf0_L3_pad_20181107_v00.cdf
    if ~keyword_set(spxs) then spxs= ['spe']
    vars['pad'] = '*'
    normpad =1
  endif
  level=strupcase(level)
  if ~keyword_set(spxs) then spxs = ['spa','spb']
  if ~keyword_set(types) then types = ['sf1', 'sf0']  ;,'st1','st0']   ; add archive when available
  if keyword_set(alltypes) then types = 'all'
  if types[0] eq 'all' then begin
    types=['hkp','fhkp']
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1'] do types=[types,type0+type1+type2]
  endif

  dir='spe/'+level+'/SP?_TYP/YYYY/MM/'
  if types eq 'hkp' then dir = 'spe/'+level+'/SP?_TYP/YYYY/MM/'
  if ~keyword_set(fileformat) then fileformat=dir+'psp_swp_SP?_TYP_'+level+'*_YYYYMMDD_v??.cdf'

  vars['hkp'] = '*TEMP* *_BITS *_FLAG* *CMD* *PEAK* *CNT* *MCP*'
  if keyword_set(allvars) then varformat='*'

  tr = timerange(trange)
  foreach type,types do begin
    foreach spx, spxs do begin
      filespx = str_sub(fileformat,'SP?', spx)              ; instrument string substitution
      filetype = str_sub(filespx,'TYP',type)                 ; packet type substitution
      dprint,filetype,/phelp
      files = spp_file_retrieve(filetype,trange=tr,/last_version,/daily_names,/valid_only,prefix=file_prefix,verbose=verbose,no_update=no_update,no_server=no_server)
      if keyword_set(save) then begin
        vardata = !null
        novardata = !null
        loadcdfstr,filenames=files,vardata,novardata
        dummy = spp_data_product_hash(spx+'_'+type+'_'+level,vardata)
      endif
      if keyword_set(no_load) then continue
      prefix = 'psp_swp_'+spx+'_'+type+'_'+level+'_'
      if keyword_set(varformat) then vfm = varformat else if vars.haskey(type) then vfm=vars[type] else vfm=[]
      if level eq 'L3' then begin
        varformat = '*'
        if keyword_set(files) then begin
          cdf = cdf_tools(files)
          time = cdf.vars['TIME'].data.array
          eflux_vs_pa_e = cdf.vars['EFLUX_VS_PA_E'].data.array
          eflux_vs_energy = cdf.vars['EFLUX_VS_ENERGY'].data.array
          energy = cdf.vars['ENERGY_VALS'].data.array
          pitchangle = cdf.vars['PITCHANGLE'].data.array
          qf = cdf.vars['QUALITY_FLAG'].data.array
          ebins = bytarr(32)
          ebins[esteps] = 1
          avg_eflux = average(/nan,eflux_vs_pa_e,2)
          store_data,prefix+'AVG_EFLUX_VS_E',time,eflux_vs_energy,energy,dlim={ylog:1,bins:ebins,yrange:[1e4,1e10],labels:strtrim(round(energy[0,*]),2)+' eV'}
          store_data,prefix+'EFLUX_VS_ENERGY',time,eflux_vs_energy,energy,dlim={spec:1,ylog:1,zlog:1,yrange:[1,1e4],ztitle:'[eV/cm2-s-ster-eV]',ysubtitle:'[eV]',ytickunits:'scientific'}
          if spx eq 'spe' then begin
            store_data,prefix+'spa_QUALITY_FLAG',time,qf[*,0]
            store_data,prefix+'spb_QUALITY_FLAG',time,qf[*,1]
          endif else store_data,prefix+'QUALITY_FLAG',time,qf
          foreach e,esteps do begin
            enum = strtrim(e,2)
            eval = median(energy[*,e])
            ytitle = 'psp!cswp!c'+spx+'!c'+type+'!c'+level+'!cElectron!cPAD!c'+strtrim(round(eval),2)+' eV'
            eflux_e = eflux_vs_pa_e[*,*,e]
            store_data,prefix+'EFLUX_VS_PA_E'+enum,time,eflux_e,pitchangle,dlim={yrange:[0,180],spec:1,ystyle:3,zlog:1,ytitle:ytitle,ysubtitle:'[Degrees]',ztitle:'[eV/cm2-s-ster-eV]'}
            if spx eq 'spe' then begin
              SPX_VS_PA_E=cdf.vars['SPX_VS_PA_E'].data.array
              SPX_VS_PA = SPX_VS_PA_E[*,*,e]
              store_data,prefix+'SPX_VS_PA_E'+enum,time,SPX_VS_PA,pitchangle,dlim={yrange:[0,180],spec:1,ystyle:3,ztitle:'SPA=1 SPB=2'}
            endif
            if keyword_set(normpad) then begin
              npa = 12
              nflux_e = eflux_e / (avg_eflux[*,e] # replicate(1,npa) )
              store_data,prefix+'NFLUX_VS_PA_E'+enum,time,nflux_e,pitchangle,dlim={yrange:[0,180],spec:1,ystyle:3,zlog:1,ytitle:ytitle+'!cNormalized',zrange:[.1,10],ztitle:'Normalized',ysubtitle:'[Degrees]'}
            endif
          endforeach
          foreach pa,psteps do begin
            panum = strtrim(pa,2)
            paval = median(pitchangle[*,pa])
            ytitle = 'psp!cswp!c'+spx+'!c'+type+'!c'+level+'!cEFLUX!cVS!cENERGY!c'+strtrim(round(paval),2)+' Deg'
            eflux_pa = reform(eflux_vs_pa_e[*,pa,*])
            store_data,prefix+'EFLUX_VS_PA'+panum+'_E',time,eflux_pa,energy,dlim={spec:1,ystyle:3,ylog:1,zlog:1,ytitle:ytitle,ysubtitle:'[eV]',ztitle:'[eV/cm2-s-ster-eV]',ytickunits:'scientific'}
            if 0 && spx eq 'spe' then begin
              SPX_VS_E = reform(SPX_VS_PA_E[*,pa,*])
              store_data,prefix+'SPX_VS_PA'+panum+'_E',time,SPX_VS_E,energy,dlim={spec:1,ystyle:3,ylog:1,ztitle:'SPA=1 SPB=2'}
            endif
          endforeach
          mag_sc = cdf.vars['MAGF_SC'].data.array
          store_data,prefix+'MAGF_SC',time,mag_sc,dlim={colors:'bgr',labels:['Bx','By','Bz'],labflag:-1,ysubtitle:'[nT]'}
          xyz_to_polar ,prefix+'MAGF_SC'
          dprint,dlevel=3
        endif else begin
          get_support_data=1
          if not keyword_set(varformat) then var_type = 'data'
          if keyword_set(get_support_data) then var_type = ['data','support_data']
          cdfi = cdf_load_vars(files,varformat=varformat,var_type=var_type,/spdf_depend, $
            varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2, all=all)

          dprint,dlevel=4,verbose=verbose,'Starting load into tplot'
          ;  Insert into tplot format
          cdf_info_to_tplot,cdfi,varnames2,all=all,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname, $  ;bpif keyword_set(all) eq 0
            verbose=verbose,  tplotnames=tplotnames,load_labels=load_labels
        endelse

        if spx eq 'spa' || spx eq 'spb' then begin
          dprint,spx,dlevel=3
        endif

      endif else begin
        cdf2tplot,files,prefix=prefix,varformat=vfm,verbose=verbose
      endelse
      spp_swp_qf,prefix=prefix+'*'

      if level eq 'L2' and (type eq 'sf0' or type eq 'af0') then begin ;; will need to change this in the future if sf0 isn't 3d spectra.
        ;; make a line here to get data from tplot
        ;; Hard code bins for now, retain option to keep flexible later
        nrg_bins = 32
        def_bins = 8
        anode_bins = 16
        prod_str = '_SFN_'
        prod_type = str_sub(prod_str,'SFN',type)
        ; order of the below should be anode, deflector, energy bin
        get_data, 'psp_swp_' + spx + prod_type + level + '_EFLUX' , data = span_eflux
        get_data, 'psp_swp_' + spx + prod_type + level + '_ENERGY', data = span_energy
        get_data, 'psp_swp_' + spx + prod_type + level + '_PHI', data = span_phi
        get_data, 'psp_swp_' + spx + prod_type + level + '_THETA', data = span_theta
        ;;----------------------------------------------------------
        ;; Make an Nrg Sypec
        nTimePoints = size(span_eflux.v)
        xpandEflux_nrg = reform(span_eflux.y, nTimePoints[1],  anode_bins, def_bins, nrg_bins)
        xpandEbins = reform(span_eflux.v, nTimePoints[1], (def_bins * anode_bins), nrg_bins)
        flatEbins = reform(xpandEbins[*,0,*])
        totalEflux_nrg = total(total(xpandEflux_nrg, 2) , 2)
        sum_nrg_spec = {x: span_eflux.x,y: totalEflux_nrg,v: flatEbins }
        store_data, 'psp_swp_' + spx + prod_type + 'ENERGY_SPEC_ql', data = sum_nrg_spec
        ;;----------------------------------------------------------
        ;; Make an Anode Apec
        ;xpandEflux_anode = reform(span_eflux.y, nTimePoints[1], anode_bins, def_bins, nrg_bins)
        ;        xpandPhi = reform(span_phi.y, nTimePoints[1], anode_bins, (def_Bins*nrg_bins))
        ;        flatAnodeBins = xpandphi[*,*,0]
        ;totalEflux_anode = total(total(xpandEflux_anode, 3),3)
        ;sum_anode_spec = {x: span_eflux.x,y: totalEflux_anode,v: flatAnodeBins }
        ;store_data, 'psp_swp_' + spx + prod_type + 'ANODE_SPEC_ql', data = sum_anode_spec
        ;;----------------------------------------------------------
        ;; Gen Def Spec
        ;xpandEflux_def = reform(span_eflux.y, nTimePoints[1], anode_bins, def_bins, nrg_bins)
        ;xpandTheta = reform(span_theta.y, nTimePoints[1], anode_bins, def_bins, nrg_bins)
        ;flatDefBins = reform(xpandTheta[*,0,*,0])
        ;totalEflux_def = total(total(xpandEflux_def, 2),3)
        ;sum_def_spec = {x: span_eflux.x,y: totalEflux_def,v: flatDefBins }
        ;store_data, 'psp_swp_' + spx + prod_type + 'DEF_SPEC_ql', data = sum_def_spec

        ;; some lines here to put these back in tplot - done for NRG spec
        ;; be done?
        ylim,prefix+'EFLUX',1.,10000.,1,/default
        ylim,'*ENERGY*_ql',1,1e4,1,/default
        ylim,'*ANODE*_ql',0,0,0,/default
        ylim,'*DEF*_ql',0,0,0,/default
        Zlim,prefix+'*EFLUX',100.,2000.,1,/default
        Zlim,'*_ql',1,1,1,/default
        ylim, '*spb*ANODE*ql*', 50,310,0, /default
        ylim, '*spa*ANODE*ql*', 180,420,0, /default
        options, '*_ql', spec = 1
        ;        tplot_options, 'no_interp', 1
      endif

    endforeach
  endforeach

end
