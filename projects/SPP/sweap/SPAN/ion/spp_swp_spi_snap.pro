;+
; Ali 20190601
; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:39:00 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 30005 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_snap.pro $
;-
;
;useful keywords:
;load: loads the data, only needed once at the beginning
;spectra: creates tplot variables for spectra
;rate: uses 'rates' instead of counts (recommended)
;snap: shows a snapshot of particle distributions
;alfven: calculates the Alfven speed from FIELDS QTN
;energybin: plots data in energy bin number instead of actual energies
;plots: creates tplot variables for diagnostic purposes
;e12: encounters 1 and 2

pro spp_swp_spi_snap,level=level,types=types,trange=trange,load=load,alltypes=alltypes,maxcalc=maxcalc,nmaxcalc=nmaxcalc,rate=rate,accum=accum,snap=snap,$
  spectra=spectra,mode=mode,mass_explode=mass_explode,pixel_explode=pixel_explode,pixel_image=pixel_image,plots=plots,merge=merge,alfven=alfven,total=total,energybin=energybin,e12=e12,status_bits=status_bits

  if ~keyword_set(types) then types=['tof','sf00','sf01','sf10','sf11','sf12','sf20','sf21','sf22','sf23']
  if keyword_set(alltypes) then begin
    types=['tof']
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1','2'] do foreach type3,['0','1','2','3'] do types=[types,type0+type1+type2+type3]
  endif
  if ~keyword_set(level) then level='L1'
  if keyword_set(plots) then begin
    maxcalc=1
    ;nmaxcalc=1
    rate=1
    accum=1
    spectra=1
    mode=1
    status_bits=1
    ;merge=1
    total=1
  endif

  if level eq 'L1' then begin
    dir='spi/'+level+'/spi_TYP/YYYY/MM/'
    fileformat=dir+'psp_swp_spi_TYP_'+level+'*_YYYYMMDD_v??.cdf'
    fileprefix='psp/data/sci/sweap/'
    tr=timerange(trange)

    if keyword_set(energybin) then begin
      yrange=[32,0]
      ylog=0
      ytickunits=''
      en=findgen(32)
    endif else begin
      yrange=[100,20e3]
      ylog=1
      ytickunits='scientific'
      en=exp(9.825-findgen(32)/6.25) ;energy bins for encounter 2
      ve=velocity(en,/proton) ;speeds corresponding to energy bins
    endelse

    if ~keyword_set(e12) then anoderange=[-1,16] else anoderange=[-1,8]

    axis_style=2
    min=0
    max=4
    countrate='Counts'
    if keyword_set(rate) then begin
      min-=2
      max-=1
      countrate='Rate'
    endif

    while 1 do begin

      if keyword_set(snap) then begin
        ctime,t,np=1,/silent
        if ~keyword_set(t) then return

        windowname='spp_swp_spi_snap'
        p=getwindows(windowname)
        if keyword_set(p) then p.setcurrent else p=window(name=windowname,dimensions=[800,800])
        p.erase
      endif

      foreach type,types do begin

        prefix='psp_swp_spi_'+type+'_'+level+'_' ;tplot_prefix
        if keyword_set(load) then begin
          filetype=str_sub(fileformat,'TYP',type)
          files=spp_file_retrieve(filetype,trange=tr,/daily_names,/valid_only,/last_version,prefix=fileprefix,verbose=verbose)
          vardata = !null
          novardata = !null
          loadcdfstr,filenames=files,vardata,novardata
          obj=spp_data_product_hash('spi_'+type+'_'+level,vardata)
        endif else begin
          vardata=!null
          obj=spp_data_product_hash('spi_'+type+'_'+level)
          if keyword_set(obj) then vardata=obj.data
        endelse

        if ~keyword_set(vardata) then continue

        if type eq 'tof' then begin
          if keyword_set(spectra) then store_data,prefix+'TOF',vardata.time,transpose(vardata.tof),dlim={zlog:1,spec:1,ystyle:3,ztitle:'Counts'}
          continue
        endif

        data=vardata.data
        times=vardata.time
        dt=times-shift(times,1)
        totaccum=vardata.time_accum
        dim=size(/dimen,data)
        nt=dim[1]
        maxcounts=max(data,dim=1)
        if keyword_set(accum) then store_data,prefix+'tot_accum_period',times,totaccum,dlim={ylog:1,ystyle:3}
        if keyword_set(maxcalc) then store_data,prefix+'maxcounts',times,maxcounts,dlim={ylog:1,yrange:[1,1e5],ystyle:3,constant:[1,2.^16]}
        if keyword_set(nmaxcalc) then begin
          maxcounts[where(maxcounts eq 0,/null)]=-1
          nmax=total(transpose(data) eq rebin(maxcounts,[nt,dim[0]]),2)
          store_data,prefix+'maxbins',times,nmax,dlim={ylog:1,ystyle:3}
        endif
        if keyword_set(mode) then begin
          ;Mode2: bbbb bbbb bbbb bbbb
          ;       MMPP PPEE EEEE TTTT
          mode2=vardata.mode2
          tmode=mode2 and 0xf
          tmode=mode2 and 'f'x
          emode=(mode2 and 'f0'x)/16 ;wrong
          emode=ishft(mode2,-4) and '3f'x
          pmode=(mode2 and 'f00'x)/16^2 ;wrong
          pmode=ishft(mode2,-10) and 'f'x
          mmode=(mode2 and 'f000'x)/16^3
          mmode=ishft(mode2,-12) and '3'x

          store_data,prefix+'mode',times,[[tmode],[emode],[pmode],[mmode]],dlim={ystyle:3,colors:'rbgk',labels:['t','e','p','m'],labflag:-1}
        endif
        if keyword_set(status_bits) then store_data,prefix+'status_bits',times,vardata.status_bits,dlim={ystyle:3}
        if 0 and type.charat(2) eq '0' and type.charat(3) eq '0' then begin
          nt/=2
          data=2*rebin(data,[dim[0],nt]) ;summing over neighboring bins to go from 16 accum periods to 32, similar to other products
          times=rebin(times,nt)
        endif
        if keyword_set(snap) then begin
          tmin=min(abs(times-t),tminsub,/nan)
          data=data[*,tminsub]
          times=times[tminsub]
          dt=dt[tminsub]
          totaccum=totaccum[tminsub]
          nt=1
        endif
        ;prefix=prefix+countrate+'_'

        pbin=where(type.charat(2) eq ['0','1','2'])
        mbin=where(type.charat(3) eq ['0','1','2','3'])
        case dim[0] of
          2048:datdimen=[8,32,8];sf0x: DxExA: deflection(theta),energy,anode(phi)
          256 :datdimen=[8,32]  ;sf1x: DxE: deflection,energy (only encounters 1 and 2)
          512 :datdimen=[32,16] ;sf2x: ExM: energy,mass
        endcase
        if type.charat(1) eq 't' then begin
          min+=1
          max+=1
        endif
        if keyword_set(rate) then data/=transpose(rebin([totaccum],[nt,dim[0]]))
        data=reform(reform(data,[datdimen,nt],/overwrite),/overwrite)

        case dim[0] of
          2048:begin
            if keyword_set(snap) and ~(pbin eq 1 and mbin eq 0) then begin
              data_theta=total(data,1)
              data_energy=total(data,2)
              data_phi=total(data,3,/nan)
              p=image(transpose(alog10(data_theta)),8.*pbin[0]-.5+findgen(8),-.5+findgen(32),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                title='',xtitle='Anode #',ytitle='Energy bin',xrange=anoderange,yrange=[32,-1],/current,layout=[5,2,6-5*(mbin-pbin)])
              p=text(/relative,target=p,0,-.01-pbin/2.7,[type,time_string(times,tformat='YYYY-MM-DD'),time_string(times,tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum,2),'dt='+strtrim(dt,2)+'s'])
              p=image(alog10(data_phi),-.5+findgen(8),-.5+findgen(32),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                title='',xtitle='Deflection bin',ytitle='Energy bin',xrange=[-1,8],yrange=[32,-1],/current,layout=[5,2,pbin+7-5*(mbin-pbin)])
              p=text(/relative,target=p,0,-.01,[type,time_string(times,tformat='YYYY-MM-DD'),time_string(times,tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum,2),'dt='+strtrim(dt,2)+'s'])
              p=image(transpose(alog10(data_energy)),8.*pbin[0]-.5+findgen(8),-.5+findgen(8),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                ytitle='Deflection bin',xtitle='Anode #',yrange=[-1,8],xrange=anoderange,/current,layout=[5,6,9-5*(mbin-pbin)])
              p=text(/relative,target=p,1.1,-1*(~keyword_set(e12))+1.4*pbin,[type,time_string(times,tformat='YYYY-MM-DD'),time_string(times,tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum,2),'dt='+strtrim(dt,2)+'s'])
            endif
            if keyword_set(spectra) then begin
              data_vs_theta=total(total(data,2),2,/nan)
              data_vs_energy=total(total(data,1),2,/nan)
              data_vs_phi=total(total(data,1),1)
              store_data,prefix+'deflection',times,transpose(data_vs_theta),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              store_data,prefix+'energy',times,transpose(data_vs_energy),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              store_data,prefix+'anode',times,transpose(data_vs_phi),dlim={zlog:1,spec:1,yrange:[7,0],ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              if mbin eq 0 then begin
                data00_phi=total(data,3,/nan)
                times00=times
                nt00=nt
              endif
            endif
            if keyword_set(pixel_explode) then for itheta=0,7 do for iphi=0,7 do store_data,prefix+'energy_A'+strtrim(iphi,2)+'D'+strtrim(itheta,2),times,transpose(reform(data[itheta,*,iphi,*])),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
            if keyword_set(pixel_image) then for itheta=0,7 do for iphi=0,7 do p=image(alog10(transpose(reform(data[itheta,*,iphi,pixel_image]))),layout=[8,9,9+iphi+itheta*8],/current,margin=.01,rgb_table=33,aspect=0,min=0,max=1,axis_style=2,/order,xmajor=0,ymajor=0,xminor=0,yminor=0)
          end
          256:begin
            data[*,2*lindgen(16),*]=reverse(data[*,2*lindgen(16),*],1) ;sf1x has the "snake pattern" deflection
            if keyword_set(snap) then begin
              p=image(alog10(data),-.5+findgen(8),-.5+findgen(32),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                title='',xtitle='Deflection bin',ytitle='Energy bin',xrange=[-1,8],yrange=[32,-1],/current,layout=[5,2,8-5*mbin])
              p=text(/relative,target=p,0,-.01,[type,time_string(times,tformat='YYYY-MM-DD'),time_string(times,tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum,2),'dt='+strtrim(dt,2)+'s'])
            endif
            if keyword_set(spectra) then begin
              data_vs_theta=total(data,2)
              data_vs_energy=total(data,1)
              store_data,prefix+'deflection',times,transpose(data_vs_theta),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              store_data,prefix+'energy',times,transpose(data_vs_energy),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              if keyword_set(merge) and mbin eq 0 then begin
                indmerge=replicate(0l,nt00)
                it10=0l
                for it00=0l,nt00-2 do begin
                  if times00[it00] eq times[it10] then begin
                    indmerge[it00:it00+1]=[it00,it00+1]
                    it00++
                    it10++
                  endif
                endfor
                indmerge2=where(indmerge ne 0,ntmerge)
                if keyword_set(rate) then rebincoeff=1. else rebincoeff=2.
                data00merge=rebincoeff*rebin(data00_phi[*,*,indmerge2],[datdimen,ntmerge/2]) ;summing over neighboring bins to go from 16 accum periods to 32, similar to other products
                data00phi0=data-data00merge
                data_vs_theta_nophi0=total(data00merge,2)
                data_vs_energy_nophi0=total(data00merge,1)
                datatot_nophi0=total(data_vs_energy_nophi0,1)
                data_vs_theta_phi0=total(data00phi0,2)
                data_vs_energy_phi0=total(data00phi0,1)
                datatot_phi0=total(data_vs_energy_phi0,1)
                phi0torest=datatot_phi0/datatot_nophi0 ;if this is high, most of protons are out of the fov
                corrfac=1.7/(1.7-phi0torest)
                wfov=where(phi0torest lt .5)
                store_data,prefix+'sf00merge_deflection',times[0:-2],transpose(data_vs_theta_nophi0),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'sf00anode0_deflection',times[0:-2],transpose(data_vs_theta_phi0),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                ;store_data,prefix+'-sf00anode0_deflection',times[0:-2],-transpose(data_vs_theta_phi0),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'sf00merge_energy',times[0:-2],transpose(data_vs_energy_nophi0),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'sf00anode0_energy',times[0:-2],transpose(data_vs_energy_phi0),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                ;store_data,prefix+'-sf00anode0_energy',times[0:-2],-transpose(data_vs_energy_phi0),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                ;store_data,prefix+'sf00anode0',times[0:-2],transpose(reform(data00phi0,[256,nt-1])),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                ;store_data,prefix+'-sf00anode0',times[0:-2],-transpose(reform(data00phi0,[256,nt-1])),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'sf00merge_total',times[0:-2],datatot_nophi0,dlim={ylog:1,ystyle:2,labels:countrate,labflag:1}
                store_data,prefix+'sf00mergefov_total',times[wfov],datatot_nophi0[wfov],dlim={ylog:1,ystyle:2,labels:countrate,labflag:1}
                store_data,prefix+'sf00anode0_total',times[0:-2],datatot_phi0,dlim={ylog:1,ystyle:2,labels:countrate,labflag:1}
                store_data,prefix+'sf00anode0/rest',times[0:-2],phi0torest,dlim={ylog:1,ystyle:2,labels:countrate,labflag:1}
                store_data,prefix+'sf00corrfac',times[0:-2],corrfac,dlim={ylog:1,ystyle:2,labels:countrate,labflag:1}
                ;store_data,prefix+'-sf00anode0_total',times[0:-2],-datatot_phi0,dlim={ylog:1,ystyle:2,labels:countrate,labflag:1} ;just one point for encounter 2!
                store_data,prefix+'sf00merge_total_ovl',data=prefix+['sf00merge_total','sf00anode0_total'],dlim={yrange:[10.^(min+3),10.^(max+1)],labels:['no0','anode0'],labflag:-1,colors:'rb'}
              endif
            endif
          end
          512:begin
            if keyword_set(snap) then begin
              p=image(alog10(data),-.5+findgen(32),-.5+findgen(16),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                xtitle='Energy bin',ytitle='Mass bin',xrange=[32,-1],yrange=[-1,16],/current,layout=[2,6,12-2*mbin])
              p=text(/relative,target=p,-.1,0,[type,time_string(times,tformat='YYYY-MM-DD'),time_string(times,tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum,2),'dt='+strtrim(dt,2)+'s'])
            endif
            if keyword_set(spectra) then begin
              data[0,*,*]=0. ;highest energy bin contains noise
              data_vs_energy=total(data,2)
              data_vs_mass=total(data,1)
              store_data,prefix+'energy',times,transpose(data_vs_energy),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              store_data,prefix+'mass',times,transpose(data_vs_mass),dlim={zlog:1,spec:1,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
              if keyword_set(merge) and mbin eq 0 then begin
                data_vs_energy20=data_vs_energy
                times20=times
                datatot20=total(data_vs_energy20,1) ;total rate (0th moment)
                den20=total(data_vs_energy20/rebin(ve,[32,nt]),1) ;proportional to density
                if keyword_set(data00merge) then den10=corrfac*total((data_vs_energy_phi0+data_vs_energy_nophi0)/rebin(ve,[32,nt]),1) ;proportional to density
                datatoten0=total(data_vs_energy20*rebin(en,[32,nt]),1)/datatot20 ;mean energy (1st moment)
                datatotte0=sqrt(total(data_vs_energy20*(rebin(en,[32,nt]))^2,1)/datatot20-datatoten0^2) ;temperature
                speed0=velocity(datatoten0,/proton)
                vther0=velocity(datatotte0,/proton)
                store_data,prefix+'energy_mean_(eV)',times,datatoten0,dlim={ylog:ylog,yrange:yrange,ystyle:3,colors:'b'}
                store_data,prefix+'proton_energy_ovl',data=prefix+'energy'+['','_mean_(eV)'],dlim={ylog:ylog,yrange:yrange,ystyle:3,zrange:[10.^(min+1),10.^max]}
              endif
              if keyword_set(merge) and mbin eq 1 then begin
                if total(times20 eq times) ne nt then message,'Different time cadence b/w sf20 and sf21, consider only loading data from 19-3-31 to 19-4-11 for encounter 2 or from 19-8-22 to 19-9-14 for encounter 3'
                data_vs_energy1=total(data[*,1:2,*],2) ;alpha mass bin peak
                data_vs_energy2=data_vs_energy1-.005*data_vs_energy20
                data_vs_energy3=data_vs_energy2*(data_vs_energy2 ge 0.)
                datatot1=total(data_vs_energy3,1)
                den21=total(data_vs_energy3/rebin(ve/sqrt(2.),[32,nt]),1)
                datatoten1=total(data_vs_energy3*rebin(en,[32,nt]),1)/datatot1
                datatotte1=sqrt(total(data_vs_energy3*(rebin(en,[32,nt]))^2,1)/datatot1-(datatoten1)^2)
                speed1=velocity(datatoten1/2.,/proton)
                vther1=velocity(datatotte1/2.,/proton)
                store_data,prefix+'alpha_energy',times,transpose(data_vs_energy1),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'alpha-proton_energy',times,transpose(data_vs_energy2),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'-alpha+proton_energy',times,transpose(-data_vs_energy2),en,dlim={ylog:ylog,zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
                store_data,prefix+'alpha-proton_energy_mean_(eV)',times,datatoten1,dlim={ylog:ylog,yrange:yrange,ystyle:3,colors:'r'}
                store_data,prefix+'alpha_energy_ovl',data=prefix+'alpha-proton_energy'+['','_mean_(eV)'],dlim={ylog:ylog,yrange:yrange,ystyle:3,zrange:[10.^min,10.^(max-2)]}
                store_data,prefix+'total_0.1scaled',times,.1*[[datatot20],[datatot1]],dlim={ylog:1,ystyle:3,colors:'br',labels:['proton','alpha'],labflag:-1,constant:10.^(findgen(10)-5)}
                store_data,prefix+'density_(cm-3)',times,50.*[[den20],[den21]],dlim={ylog:1,ystyle:3,colors:'br',labels:['proton','alpha'],labflag:-1,constant:10.^(findgen(10)-5)}
                if keyword_set(den10) then store_data,prefix+'corrdensity_(cm-3)',times[0:-2],50.*den10,dlim={ylog:1,ystyle:3,colors:'g',constant:10.^(findgen(10)-5)}
                store_data,prefix+'energy_mean_(eV)',times,[[datatoten0],[datatoten1]],dlim={ylog:ylog,yrange:yrange,ystyle:3,colors:'br',labels:['proton','alpha'],labflag:1}
                store_data,prefix+'bulk_speed_(km/s)',times,[[speed1],[speed0]],dlim={ystyle:3,colors:'rb',labels:['alpha','proton'],labflag:-1,constant:findgen(10)*100.}
                store_data,prefix+'thermal_speed_(km/s)',times,[[vther1],[vther0]],dlim={ystyle:3,colors:'rb',labels:['alpha','proton'],labflag:-1,constant:findgen(10)*100.}
                store_data,prefix+'temperaure_(eV)',times,[[datatotte0],[datatotte1]],dlim={ystyle:3,colors:'br',labels:['proton','alpha'],labflag:1,ylog:1}
                store_data,prefix+'dE/E',times,[[datatotte1/datatoten1],[datatotte0/datatoten0]],dlim={ystyle:3,colors:'rb',labels:['alpha','proton'],labflag:-1,ylog:1}
                store_data,prefix+'speed_difference_(km/s)',times,speed1-speed0,dlim={ystyle:3,constant:0}
                store_data,prefix+'speed_ratio',times,speed1/speed0,dlim={ystyle:3,constant:1}
                store_data,prefix+'alpha2proton_flux_ratio',times,datatot1/datatot20,dlim={ylog:1,ystyle:3,constant:10.^(findgen(10)-5)}
                store_data,prefix+'alpha2proton_density_ratio',times,den21/den20,dlim={ylog:1,ystyle:3,constant:10.^(findgen(10)-5)}
                store_data,prefix+'_mbin12_energy_ovl',data=prefix+['alpha_energy','energy_mean_(eV)'],dlim={ylog:ylog,yrange:yrange,ystyle:3,zrange:[10.^min,10.^(max-2)]}
              endif
            endif
            if keyword_set(mass_explode) then for mmbin=0,15 do store_data,prefix+'_energy_mass'+strtrim(mmbin,2),times,transpose(total(data[*,mmbin,*],2)),en,dlim={zlog:1,spec:1,yrange:yrange,ystyle:3,zrange:[10.^min,10.^max],ztitle:countrate}
          end
        endcase
        if keyword_set(spectra) and keyword_set(total) then begin
          datatot=total(data_vs_energy,1)
          store_data,prefix+'total',times,datatot,dlim={ylog:1,ystyle:2,labels:countrate,labflag:1}
        endif
        if type.charat(1) eq 't' then begin
          min-=1
          max-=1
        endif
      endforeach
      if keyword_set(spectra) and keyword_set(total) then begin
        store_data,'psp_swp_spi_sfx0_L1_total_ovl',data='psp_swp_spi_sf?0_L1_total',dlim={yrange:[10.^(min+3),10.^(max+1)],colors:'bgr'}
        store_data,'psp_swp_spi_sfx1_L1_total_ovl',data='psp_swp_spi_sf?1_L1_total',dlim={yrange:[10.^(min+2),10.^(max-1)],colors:'bgr'}
      endif
      if keyword_set(alfven) then begin
        get_data,'psp_swp_spi_sf01_L3_MAGF_SC',data=mag
        get_data,'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2_fp',data=fp
        if ~keyword_set(mag) then spp_swp_load,/spi,type='sf01'
        if ~keyword_set(fp) then spp_swp_load,/fld,type='rfs_lfr
        psp_fld_rfs_convol_peak
        get_data,'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2_fp',data=fp
        nfp=(fp.y/9e3)^2 ;cm-3
        store_data,'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2_nfp_(cm-3)',fp.x,nfp,dlim={ylog:1,ystyle:3,labels:'QTN',labflag:1}
        store_data,'psp_swp_spi_nfp_den_(cm-3)_ovl',data='psp_swp_spi_sf21_L1_density_(cm-3) psp_swp_spi_sf21_L1_corrdensity_(cm-3) psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2_nfp_(cm-3)',dlim={yrange:[1,1000]}

        xyz_to_polar,'psp_swp_spi_sf01_L3_MAGF_SC'
        get_data,'psp_swp_spi_sf01_L3_MAGF_SC_mag',data=mag
        if keyword_set(mag) then begin
          mp_kg = 1.6726231e-27 ;proton mass
          mu0 = 1.2566370614e-6
          np=interp(nfp,fp.x,mag.x)
          valf = (mag.y*(1e-9)/sqrt(mp_kg * np * 1e6 * mu0))/1e3
          store_data,'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2_nfp_interp_(cm-3)',mag.x,np,dlim={ylog:1,ystyle:3}
          store_data,'psp_swp_spi_alfven_speed_(km/s)',mag.x,valf,dlim={ystyle:3,constant:0}
          store_data,'psp_swp_spi_alfven_speed_(km/s)_ovl',data='psp_swp_spi_'+['sf21_L1_speed_difference_(km/s)','alfven_speed_(km/s)'],dlim={colors:'br',labels:['a-p diff','alfven'],labflag:1}
        endif
      endif
      options,/default,'psp_swp_spi_*energy',ytickunits=ytickunits,ztickunits='scientific'
      options,/default,'psp_swp_spi_*deflection',ztickunits='scientific'
      options,/default,'psp_swp_spi_*anode',ztickunits='scientific'
      options,/default,'psp_swp_spi_*mass',ztickunits='scientific'
      if keyword_set(snap) then p=colorbar(title='Log10 '+countrate,/orientation,position=[.95,.7,.98,.95]) else return
    endwhile
  endif

  if level eq 'L2' then begin
    if keyword_set(load) then begin
      spp_swp_spi_load ;loads L3 files and creates tplot variables
      spp_swp_spi_load,/save,types=types,level=level,/no_load
    endif

    obj=spp_data_product_hash('spi_'+types+'_'+level)
    dat=obj.data

    if ~tag_exist(dat,'EFLUX') then message,'EFLUX not loaded'
    eflux=dat.eflux
    energy=dat.energy
    theta=dat.theta
    phi=dat.phi
    times=dat.time

    dim=size(/dimen,eflux)
    nt=dim[1]
    datdimen=[8,32,8] ;theta,energy,phi
    newdim=[datdimen,nt]

    eflux=reform(eflux,newdim,/overwrite)
    theta=reform(theta,newdim,/overwrite)
    phi=reform(phi,newdim,/overwrite)
    energy=reform(energy,newdim,/overwrite)

    if types eq 'sf00' then minmax=[7,11]
    if types eq 'sf01' then minmax=[6,10]

    axis_style=2

    while 1 do begin
      ctime,t,np=1,/silent
      if ~keyword_set(t) then return
      tmin=min(abs(times-t),tminsub,/nan)

      eflux2=eflux[*,*,*,tminsub]
      theta2=theta[*,*,*,tminsub]
      phi2=phi[*,*,*,tminsub]
      energy2=energy[*,*,*,tminsub]

      eflux_theta=total(eflux2,1) ;sum over theta (deflection angle)
      eflux_energy=total(eflux2,2) ;sum over energy
      eflux_phi=total(eflux2,3,/nan) ;sum over phi (anode)

      theta_vals=mean(mean(theta2,dim=2),dim=2,/nan)
      energy_vals=mean(mean(energy2,dim=1),dim=2,/nan)
      phi_vals=mean(mean(phi2,dim=1),dim=1)

      wphi=where(finite(phi_vals),/null)

      windowname='spp_swp_spi_snap'
      p=getwindows(windowname)
      if keyword_set(p) then p.setcurrent else p=window(name=windowname,dimensions=[500,500])
      p.erase

      p=text(.35,.97,time_string(times[tminsub]))
      p=image(transpose(alog10(eflux_theta[*,wphi])),.5+findgen(7),.5+findgen(32),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
        xtitle='anode #',ytitle='energy bin',xrange=[0,8],yrange=[33,0],position=[.1,.1,.4,.9])
      p=image(alog10(eflux_phi),.5+findgen(8),.5+findgen(32),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
        xtitle='deflection bin',ytitle='energy bin',xrange=[0,9],yrange=[33,0],position=[.4,.1,.7,.9])
      p=image(transpose(alog10(eflux_energy[*,wphi])),0.5+findgen(7),0.5+findgen(8),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
        ytitle='deflection bin',xtitle='anode #',yrange=[0,9],xrange=[0,8],position=[.75,.1,.95,.3])
      p=colorbar(title='Log10 (Eflux)',/orientation,position=[.85,.5,.9,.9])

    endwhile

  endif

end