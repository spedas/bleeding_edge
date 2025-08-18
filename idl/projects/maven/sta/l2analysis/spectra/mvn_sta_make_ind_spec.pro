;+
;Make STATIC energy spectra for individual ion species, based on AMU mass range. 
;Can be used with any sta_apid that resolves mass, but the default is c6.
;
;If sta_apid=ce, cf, d0 or d1, the routine will also produce the anode and deflector spectra with the mass dependence.
;
;INPUTS:
;trange: [a,b]: a and b are double precision UNIX times, and are the start and stop times for the time range to look at. If not 
;               set, the routine will run over the entire time range loaded, for the requested apid.
;
;sta_apid: string: STATIC apid to load, default is 'c6' if not set.
;       
;        
;KEYWORDS:       
;units: 'Eflux' or 'Counts'. Default is 'Eflux' if not set 
;
;mrange: [a,b] : AMU mass range to make spectrogram over, between values of a and b. Default is [0.5, 50.] if not set.
;
;m_int: AMU mass value to assume when calculating energies etc. Default if not set is the mean of mrange.
;
;success: 1: routine ran successfully; 0: routine did not run successfully.
;
;tpname: string: the tplot name given to the resulting spectrogram. The additions '_E', '_D' and '_A' will be added
;                for energy, deflector and anode products. If not set, the default name will be given, which includes the
;                mrange values used. If tpname is not set, the default name used will be output in this variable.
;  
;species: string (upper or lower case): set to one of the following to use pre-determined mass ranges:
;         'H', 'He', 'O', 'O2', 'CO2' [NOTE: do not include the '+']
;         Note: if you set the species keyword, the species name will be added to the ytitle of the relevant tplot.                
;
;EXAMPLES:
;
;Users must first load STATIC data:
;timespan, '2018-01-01', 1.
;mvn_sta_l2_load, sta_apid='c6'   ;load data into IDL
;mvn_sta_l2_tplot   ;put data into tplot
;
;mvn_sta_make_ind_spec, mrange=[14.,20.], m_int=16., sta_apid='c6', tpname=tpname  ;calculate c6 spectrum for O+, for all data loaded. The output
;                                                                                  ;tpname will contain the default tplot name for this spectrum.
;
;ctime, tr
;mvn_sta_make_ind_spec, species='O2', sta_apid='c6' , trange=tr, tpname='c6var'  ;calculate c6 spectrum for O2+, over the time range tr,
;                                                                                ;and save the output as tplot variable 'c6var'.
;
;NOTES:
;At some point, CMF will add in keywords to only include ions that lie within/outside specific pitch angles wrt the local B field. I haven't
;gotten around to this yet...
;
;CREATED: 2020-03-23
;BY: Chris Fowler (cmfowler@berkeley.edu)
;
;For testing:
;.r /Users/cmfowler/IDL/STATIC_routines/Spectra/mvn_sta_make_ind_spec.pro
;-
;

;===================
;---SUB ROUTINES---:
;===================

;+
;Sub routine that does the actual summing etc. Based on get_en_spec_4d.
;
;INPUTS:
;trange, sta_apid, mrange, m_int and tpname are set by the main routine and input here.
;
;-

pro mvn_sta_make_ind_spec_core, trange=trange, sta_apid=sta_apid, mrange=mrange, m_int=m_int, tpname=tpname, success=success, units=units, $
                    species=species, erange=erange

res1 = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)
res2 = execute("dat0=all_dat_"+sta_apid)  ;get data structure for all times

;Find time indices requested:
time_all = dat0.time + ((dat0.end_time-dat0.time)/2d)  ;mid times
iFI = where(time_all ge trange[0] and time_all le trange[1], niFI)

if sta_apid eq 'ce' or sta_apid eq 'cf' or sta_apid eq 'd0' or sta_apid eq 'd1' then fourdim = 1 else fourdim = 0  ;do we have energy, anode, def, mass?

if size(species,/type) ne 0 then spec_str = species+'!C' else spec_str = '' ;title for y axis

if niFI gt 0 then begin
      ;=======
      ;ARRAYS:
      ;=======
      ;ARRAYS:
      timearr = time_all[iFI]  ;add times
      eflux_sum = fltarr(niFI, dat0.nenergy)  ;data for energy spec
      energy_arr = fltarr(niFI, dat0.nenergy)  ;energy table
      eflux_theta = fltarr(niFI, dat0.ndef)   ;for deflectors and anodes - only added to if there are these dimensions available
      eflux_phi = fltarr(niFI, dat0.nanode)
      theta_arr = fltarr(niFI, dat0.ndef)
      phi_arr = fltarr(niFI, dat0.nanode)

            
      for tt = 0l, niFI-1l do begin
          
          indexSTR = strtrim(iFI[tt])  ;indice in data structure
          
          resTMP = execute("datTMP = mvn_sta_get_"+sta_apid+'(index='+indexSTR+')')  ;dat structure for this timestep
          
          datTMP2 = datTMP
          mvn_sta_convert_units, datTMP2, units  ;this subtracts bkg, replace datTMP2 with new units
          
          datTMP3 = sum4m(datTMP2, mass=mrange, m_int=m_int)
          
          energy_arr[tt, *] = transpose(datTMP3.energy[*,0])  ;energy is same for all anode-defl values.
          
          
          ;Numbers for deflector and anode breakdown:
          nanode = datTMP3.nanode
          ndef = datTMP3.ndef
          nenergy = datTMP3.nenergy
          nbins = datTMP3.nbins
          nmass = datTMP3.nmass
          npts=1l  ;number of timesteps in dat array - do in for loop for now, as sum4m only takes one timestep at a time
          data = datTMP3.data  ;bkg is subtracted during convert units above
          dat_energy = datTMP3.energy
          
          ;Zero out energies outside of requested range:
          if keyword_set(erange) then begin
              ekeep = where(dat_energy ge erange[0] and dat_energy le erange[1], nekeep, complement=ezero, ncomplement=nezero)
              if nezero gt 0 then data[ezero] = 0.
          endif
          
          thetaTMP = total(reform(datTMP3.theta[nenergy-1,*],npts,ndef,nanode),3)/nanode  ;check all of this works properly
          phiTMP = total(reform(datTMP3.phi[nenergy-1,*],npts,ndef,nanode),2)/ndef
          
          ;Store in arrays:
          energy_arr[tt, *] = transpose(datTMP3.energy[*,0])  ;energy is same for all anode-defl values.
          theta_arr[tt,*] = thetaTMP
          phi_arr[tt,*] = phiTMP
          if fourdim eq 0 then eflux_sum[tt, *] = (data)  ;just energy data to sum over
          
          ;Products that are specific to ce, cf, d0 and d1:
          if fourdim eq 1 then begin
              data1=total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2)  ;check all of this works properly
              data2=total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2)
                          
              ;Store in arrays:
              eflux_sum[tt, *] = total(data, 2)  ;sum over second dimension, anode-def dimension.
              eflux_theta[tt,*] = data1
              eflux_phi[tt,*] = data2
          endif
              
      endfor ;tt
      
      ;TPLOT VARIABLES:
      massSTR = strtrim(string(mrange[0], format='(f12.1)'),2)+','+strtrim(string(mrange[1], format='(f12.1)'),2)
      if keyword_set(erange) then energySTR = strtrim(string(erange[0], format='(f12.1)'),2)+','+strtrim(string(erange[1], format='(f12.1)'),2) else energySTR='full'
      if not keyword_set(tpname) then tpname = 'mvn_sta_'+sta_apid+'_mr('+massSTR+')_er('+energySTR+')_energy_spectrogram'

      tname1 = tpname[0]+'_E'
      store_data, tname1, data={x: timearr, y: eflux_sum, v: energy_arr}
        options, tname1, ytitle=spec_str+'Energy [eV]', spec=1, ylog=1, zlog=1, no_interp=1, ztitle=units
        ylim, tname1, 0.1, 4E4
        zlim, tname1, 1E3, 1E9
      
      ;For apids with deflector and anode information as well (ce, cf, d0, d1), produce mass dependent spectra for anode and deflector plots:
      if fourdim eq 1 then begin
          tname2 = tpname[0]+'_D'
          store_data, tname2, data={x: timearr, y: eflux_theta, v: theta_arr}
            options, tname2, ytitle=spec_str+'Theta', spec=1, zlog=1, no_interp=1, ztitle=units
            ylim, tname2, -45, 45
            zlim, tname2, 1E3, 1E9
          
          tname2 = tpname[0]+'_A'
          store_data, tname2, data={x: timearr, y: eflux_phi, v: phi_arr}
            options, tname2, ytitle=spec_str+'Phi', spec=1, zlog=1, no_interp=1, ztitle=units
            ylim, tname2, -180, 180
            zlim, tname2, 1E3, 1E9          
      endif
      
      success=1
endif else begin
      success=0
endelse

end

;===================
;---MAIN ROUTINE---:
;===================

pro mvn_sta_make_ind_spec, trange=trange, units=units, sta_apid=sta_apid, mrange=mrange, m_int=m_int, success=success, tpname=tpname, $
          species=species, erange=erange

if keyword_set(species) then begin
    species = strupcase(species)
    mranges=mvn_sta_get_mrange()
    case species of
      'H' : begin
                mrange = mranges.H
                m_int=1.
            end
      'HE' : begin
                mrange = mranges.He
                m_int=2.
             end
      'O' : begin
                mrange = mranges.O
                m_int=16.
            end
      'O2' : begin
                mrange = mranges.O2
                m_int=32.
             end
      'CO2' : begin
                mrange = mranges.CO2
                m_int=44.
              end
      else: tmp=0  ;leave undedefined, and either the mrange keyword is already set, or the default is used below    
    endcase
  
endif  

if ~keyword_set(units) then units = 'Eflux'
if not keyword_set(mrange) then mrange=[0., 50.]
if not keyword_set(m_int) then m_int = mean(mrange,/nan)

if size(trange,/type) ne 0 then begin
  if size(trange,/type) ne 5 then begin
      print, ""
      print, "mvn_sta_make_ind_spec: trange must be a two element double UNIX time array of start and stop times."
      success=0
      return
  endif
  if n_elements(trange) eq 1 then begin
      print, ""
      print, "mvn_sta_make_ind_spec: trange must be a two element double UNIX time array of start and stop times."
      success=0
      return
  endif
endif

if keyword_set(sta_apid) then begin
    ;INSERT A CHECK THAT THE REQUESTED APID HAS MASS INFO.
    if sta_apid ne 'd0' and sta_apid ne 'd1' and sta_apid ne 'ce' and sta_apid ne 'cf' and sta_apid ne 'c6' and sta_apid ne 'cc' $
            and sta_apid ne 'cd' then begin  
                print, ""
                print, "mvn_sta_make_ind_spec: sta_apid must be a product that has mass resolution: c6, cc, cd, ce, cf, d0, d1."
                success=0
                return          
             endif
    ;If apid ok then:
    apSTR = sta_apid
endif else apSTR='c6'  ;default

;Check the requested apid is in memory:
case apSTR of
  'cc' : begin
            common mvn_cc, get_ind_cc, all_dat_cc
            if size(all_dat_cc,/type) eq 0 then flag=1 else flag=0
            if flag eq 0 then trange2 = [min(all_dat_cc.time,/nan), max(all_dat_cc.time,/nan)]
         end
         
  'cd' : begin
           common mvn_cd, get_ind_cd, all_dat_cd
           if size(all_dat_cd,/type) eq 0 then flag=1 else flag=0
           if flag eq 0 then trange2 = [min(all_dat_cd.time,/nan), max(all_dat_cd.time,/nan)]
         end
     
   'c6' : begin
           common mvn_c6, get_ind_c6, all_dat_c6
           if size(all_dat_c6,/type) eq 0 then flag=1 else flag=0
           if flag eq 0 then trange2 = [min(all_dat_c6.time,/nan), max(all_dat_c6.time,/nan)]
         end
   
   'ce' : begin
           common mvn_ce, get_ind_ce, all_dat_ce
           if size(all_dat_ce,/type) eq 0 then flag=1 else flag=0
           if flag eq 0 then trange2 = [min(all_dat_ce.time,/nan), max(all_dat_ce.time,/nan)]
         end    
   
   'cf' : begin
           common mvn_cf, get_ind_cf, all_dat_cf
           if size(all_dat_cf,/type) eq 0 then flag=1 else flag=0
           if flag eq 0 then trange2 = [min(all_dat_cf.time,/nan), max(all_dat_cf.time,/nan)]
         end    
     
   'd0' : begin
           common mvn_d0, get_ind_d0, all_dat_d0
           if size(all_dat_d0,/type) eq 0 then flag=1 else flag=0
           if flag eq 0 then trange2 = [min(all_dat_d0.time,/nan), max(all_dat_d0.time,/nan)]
         end 
    
    'd1' : begin
           common mvn_d1, get_ind_d1, all_dat_d1
           if size(all_dat_d1,/type) eq 0 then flag=1 else flag=0
           if flag eq 0 then trange2 = [min(all_dat_d1.time,/nan), max(all_dat_d1.time,/nan)]
         end   
endcase

if flag eq 1 then begin
  print, ""
  print, "mvn_sta_make_ind_spec: requested apid is not loaded. Use mvn_sta_l2_load, sta_apid='"+apSTR+"'."
  success=0
  return
endif

;Check if time range requested; use full range loaded if not set:
if ~keyword_set(trange) then trange=trange2  ;this will only run if the correct apid is loaded

mstr = '('+strtrim(string(mrange[0], format='(f12.1)'),2)+','+strtrim(string(mrange[1], format='(f12.1)'),2)+')'

;Routine used to use get_en_spec_4d, but CMF found that it did not work properly for d0/d1 data, so now use the sub-routine above.
;get_en_spec_4d,'mvn_sta_get_'+apSTR,t1=trange[0],t2=trange[1],mass=mrange,m_int=m_int,name=tpname, units=units
;    options, tpname, ytitle='Energy'
;    options, tpname, labels=strtrim(string(m_int, format='(F5.1)'),2)+' AMU'
;    options, tpname, labflag=1
;    options, tpname, ysubtitle='['+mstr+', eV]'
;    get_data, tpname, data=dd1
;    yrange=[1., max(dd1.v,/nan)*1.1]
;    ylim, tpname, yrange
;    options, tpname, no_interp=1

mvn_sta_make_ind_spec_core, trange=trange, sta_apid=sta_apid, mrange=mrange, m_int=m_int, tpname=tpname, success=core_success, units=units, $
              erange=erange, species=species

success=core_success

end



