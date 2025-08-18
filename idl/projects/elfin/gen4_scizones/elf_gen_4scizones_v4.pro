pro elf_gen_4scizones_v4,tstats_start_str,tstats_end_str,outdir
    ;
    ; This program generates prec/perp/back eflux results for each science zone on ELFIN
    ; including activity indices, and stores them in IDL .sav files at uniform resolution
    ; for later use in statistical averaging. 
    ; 
    elf_init
    ;
    ;cwd,'C:\Users\Vassilis\Desktop\code2run4VAbyVA'
    ;
    pival=!PI
    Ree=6378.1 ; Earth equatorial radius in km
    Rem=6371.0 ; Earth mean radius in km
    keV2ergs = 1.602*1.e-9 ; multiply by to get ergs
    
    tplot_restore,filenames='/home/elfin/idl-runner/idl/ELF_activity_indices.tplot' ; this has indices for the entire ELFIN mission
  
    ;make a list of all valid events, where field7=0 (quality of the EPDE phase delays is good)
    ela_szs=read_csv('/home/elfin/data/elfin/ela/calibration_files/ela_epde_phase_delays.csv')
    elb_szs=read_csv('/home/elfin/data/elfin/elb/calibration_files/elb_epde_phase_delays.csv')
   
    ela_szs_starts=time_double(strmid(ela_szs.field1[1:*],1,19))
    ela_szs_ends=time_double(strmid(ela_szs.field2[1:*],1,19))
    elb_szs_starts=time_double(strmid(elb_szs.field1[1:*],1,19))
    elb_szs_ends=time_double(strmid(elb_szs.field2[1:*],1,19))
    ela_szs_flag=float(ela_szs.field7[1:*])
    elb_szs_flag=float(elb_szs.field7[1:*])
    ;
    ; select which events to read in the ELFIN mission
    ;
    ; used to test Jan 01, 2021 files on 20230709
    ; tstats_start=time_double('2021-01-01/00:00:00')
    ; tstats_end=time_double('2021-01-02/00:00:00')
    ; used to create files on 20230709
    tstats_start=time_double(tstats_start_str) ; subinterval start for stats
    tstats_end=time_double(tstats_end_str) ; subinterval end for stats
    ;tstats_start=time_double('2021-07-01/00:00:00')
    ;tstats_end=time_double('2022-09-15/00:00:00')
    iany_ela=where(ela_szs_starts ge tstats_start and ela_szs_starts lt tstats_end and abs(ela_szs_flag) lt 0.5, jany_ela)
    iany_elb=where(elb_szs_starts ge tstats_start and elb_szs_starts lt tstats_end and abs(elb_szs_flag) lt 0.5, jany_elb)
    ;
    if jany_ela lt 1 or jany_elb lt 1 then begin ; either ELA or ELB do not exist in the specified interval
      if jany_ela gt 0.5 and jany_elb lt 1 then begin ; only ELB does not exist but ELA does
        probenamea=make_array(jany_ela,/string) & probenamea[*]='a'
        elx_szs_starts=ela_szs_starts[iany_ela]
        elx_szs_ends=ela_szs_ends[iany_ela]
        probename=probenamea
        numevents=jany_ela
      endif
      if jany_elb gt 0.5 and jany_ela lt 1 then begin ; only ELA does not exist but ELB does
        probenameb=make_array(jany_elb,/string) & probenamea[*]='b'
        elx_szs_starts=elb_szs_starts[iany_elb]
        elx_szs_ends=elb_szs_ends[iany_elb]
        probename=probenameb
        numevents=jany_elb
      endif
      if jany_ela lt 1 and jany_elb lt 1 then begin ; neither ELA nor ELB exist
        print,'neither ELA nor ELB have science zones in the specified interval'
        goto, EXIT_THIS_IDL_SESSION
      endif
    endif else begin ; both ELA and ELB exist
      probenamea=make_array(jany_ela,/string) & probenamea[*]='a'
      probenameb=make_array(jany_elb,/string) & probenameb[*]='b'
      elx_szs_starts=[ela_szs_starts[iany_ela],elb_szs_starts[iany_elb]]
      elx_szs_ends=[ela_szs_ends[iany_ela],elb_szs_ends[iany_elb]]
      probename=[probenamea,probenameb]
      numevents=jany_ela+jany_elb
    endelse   

    mytype='eflux'
    ; for SEPs use 0.7, and jSEPs nonzero; for non-SEP events can use 0.75 or 0.7 (better) and jSEPs=0
    errmax4specs=0.70 ; this means % max error, for color spectrograms (cnt>=4.0 is dQ/Q<=0.5; cnt>2.04 is dQ/Q<0.70; cnt>1. is dQ/Q=1.)
    errmax4lines=0.70 ; this means % max error, for line spectra or other uses (not used here)
    errmax4SEPs=0.33 ; his means % max error, for color spectrograms (cnt>=6.2 is dQ/Q<=0.4)
    SEPbacktopreclt = 0.25 ; back flux less than prec flux
    SEPprectoperpgt = 0.60 ; down flux gt perp flux
    SEPLshellgt=6.
    SEPenergygt=400. ; greater than energy, in keV, deposited by SEP protons in EPDE front det.
    SEPhienergygt=2500. ; greater than energy, in keV, deposited by very energetic SEP protons in EPDE front det.
    myjSEPs=0 ; implement SEP decontamination (1) or not (0)
    ;
    myfulspn = 1 ; 1: fulspn... ; 0: not fulspn
    myregnoreg = 0 ; 1: regularized... ; 0: not regularized (for plotting ratios only)
    if myfulspn eq 1 then fulnoful='fulspn_' else fulnoful='' ; for filenames
    if myregnoreg eq 1 then regnoreg='reg_' else regnoreg='' ; for filenames
    ;
    for jthevent=0,numevents-1 do begin
    ;  stop
      sclet=probename[jthevent]
      tstart=time_string(elx_szs_starts[jthevent])
      tend=time_string(elx_szs_ends[jthevent])
      timeduration=time_double(tend)-time_double(tstart)
      timespan,tstart,timeduration,/seconds
      ;
      ;this is for generating save files for each track, same as for ovation
      year=long(strmid(tstart,0,4)) & month=long(strmid(tstart,5,2)) & day=long(strmid(tstart,8,2))
      hour=long(strmid(tstart,11,2)) & minute=long(strmid(tstart,14,2)) & sec=long(strmid(tstart,17,2))
      date_str = string(year, format='(i4)')+string(month, format='(i02)') $
        + string(day, format='(i02)')+'_' + string(hour, format='(i02)') $
        + string(minute, format='(i02)')

  
 
      ;output file consist of one text file for each aurora type
      ;integrated energy flux in unit of ergs/(cm^2s) as a function of MLAT and MLT
      ;
      ;obtain ELFIN position
      ;
      elf_load_state, probe = sclet
      ;
      cotrans, 'el'+sclet+'_pos_gei','elx_pos_gse',/GEI2GSE ; these are 1s resolution data !!
      cotrans, 'elx_pos_gse','elx_pos_gsm',/GSE2GSM
      tt89,'elx_pos_gsm',/igrf_only,newname='elx_bt89_gsm',period=1. ; gets IGRF field at ELF location
      ttrace2equator,'elx_pos_gsm',external_model='none',internal_model='igrf',/km,in_coord='gsm',out_coord='gsm',rlim=100.*Rem ; native is gsm
      cotrans,'elx_pos_gsm_foot','elx_pos_sm_foot',/GSM2SM ; now in SM
      get_data,'elx_pos_sm_foot',data=elx_pos_sm_foot
      xyz_to_polar,'elx_pos_sm_foot',/co_latitude ; get position in rthphi (polar) coords
      calc," 'Ligrf'=('elx_pos_sm_foot_mag'/Rem)/(sin('elx_pos_sm_foot_th'*pival/180.))^2 " ; uses 1Rem (mean E-radius, the units of L) NOT 1Rem+100km!
      tdotp,'elx_bt89_gsm','elx_pos_gsm',newname='elx_br_tmp'
      get_data,'elx_br_tmp',data=Br_tmp
      hemisphere=sign(-Br_tmp.y)
      r_ift_dip = (1.+100./Rem)
      calc," 'MLATigrf' = (180./pival)*arccos(sqrt(Rem*r_ift_dip/'elx_pos_sm_foot_mag')*sin('elx_pos_sm_foot_th'*pival/180.))*hemisphere " ; at ionofootpoint
      calc," 'MLTigrf' = ('elx_pos_sm_foot_phi' + 180. mod 360. ) / 15. " ; done with MLT
      ;
      ;ELFIN MLT and MLAT
      get_data,'MLATigrf',data=MLATigrf
      MLAT_elf = abs(MLATigrf.y)
      get_data,'MLTigrf',data=MLTigrf
      MLT_elf = MLTigrf.y
      get_data,'Ligrf',data=Ligrf
      L_elf = Ligrf.y
      ;
      ; determine if EPD quantities to be used will be declared "up" or "down" from the get-go,
      ; one sci. zone at a time, based on the average location in each sci. zone (SM north or south)
      ;
      calc," elx_pos_mlat_med = median('MLATigrf') "
      if sign(elx_pos_mlat_med) ge 0 then begin ; hemisphere is 'north'
        dnval='para' ; means down or precipitating ("prec")
        upval='anti' ; means up or backscattered ("back")
      endif else begin ; hemisphere is 'south'
        dnval='anti'
        upval='para'
      endelse
      ;
      ;read ELFIN data and create elf_eflux_gterr for down, perp, up
      ; do the minimum processing to save time!
      ; have: cotrans, 'el'+sclet+'_pos_gei','elx_pos_gse',/GEI2GSE 
      ; 
      ; load raw data (counts) to obtain the error estimates
      elf_load_epd,probe=sclet,datatype='pef',type = 'raw'
      if myfulspn then elf_getspec,probe=sclet,datatype='pef',type = 'raw',enerbins=[[0,6],[7,14]],/fullspin,/get3Dspec,/nodegaps $
      else elf_getspec,probe=sclet,datatype='pef',type = 'raw',enerbins=[[0,6],[7,14]],/get3Dspec,/nodegaps
      ;
      ; now convert all quantities to be used into probe='x'
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_'+upval,'elx_pef_en_fulspn_spec2plot_back' ; back(scattered) means up-going
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_'+dnval,'elx_pef_en_fulspn_spec2plot_prec' ; prec(ipitating) means down-going
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_perp','elx_pef_en_fulspn_spec2plot_perp' ; perp not used by carry for completeness
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_omni','elx_pef_en_fulspn_spec2plot_omni' ; not used but carry for completeness
      ;
      ; compute the errors for params to use below (this is the only chance to do it, so do more now if you may need later)
      ; Use these raw counts to produce the df/f error estimate = 1/sqrt(counts) for all quantities you need to. Use calc with globing:
      calc," 'elx_pef_en_fulspn_spec2plot_????_err' = 1/sqrt('elx_pef_en_fulspn_spec2plot_????') " ; <-- what I will use later, err means df/f
      ;
      ; reload data in eflux units now (two calls: first reload data, then recompute spectra)
      elf_load_epd,probe=sclet,datatype='pef',type = mytype, trange = [tstart, tend]
      if myfulspn then elf_getspec,probe=sclet,datatype='pef',type = mytype,/fullspin,/get3Dspec,energies=[[50.,430.],[430.,6000.]],/nodegaps $
      else elf_getspec,probe=sclet,datatype='pef',type = mytype,/get3Dspec,energies=[[50.,430.],[430.,6000.]],/nodegaps
      ;
      myphasedelay = elf_find_phase_delay(probe=sclet, instrument='epde', trange=[tstart,tend]) ; for reference only
      mysect2add=myphasedelay.DSECT2ADD ; record on plot for reference
      mydSpinPh2add=myphasedelay.DPHANG2ADD ; record on plot for reference
      ;
      ; now again convert all quantities to be used into probe='x' and back/prec rather than para/anti
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_'+upval,'elx_pef_en_fulspn_spec2plot_back' ; back(scattered) means up-going
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_'+dnval,'elx_pef_en_fulspn_spec2plot_prec' ; prec(ipitating) means down-going
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_perp','elx_pef_en_fulspn_spec2plot_perp' ; 
      copy_data,'el'+sclet+'_pef_en_'+fulnoful+'spec2plot_omni','elx_pef_en_fulspn_spec2plot_omni' ; not used but carry for completeness
      copy_data,'el'+sclet+'_pef_pa_'+fulnoful+'spec2plot_ch0','elx_pef_pa_fulspn_spec2plot_ch0' ; exist, w/info on LC (can plot if needed); not gterr-cleaned
      copy_data,'el'+sclet+'_pef_pa_'+fulnoful+'spec2plot_ch1','elx_pef_pa_fulspn_spec2plot_ch1' ; exist, w/info on LC (can plot if needed); not gterr-cleaned
      ;
      ; plot the non-regularized data
      zlim,'el?_p?f_en*spec*',1e4,1e9,1
      zlim,'el?_pef_pa_*spec2plot_ch0*',5.e4,1.e9,1
      zlim,'el?_pef_pa_*spec2plot_ch1*',1.e4,5.e8,1
      ylim,'*en*spec2plot*',5e1,5.e3,1
      ylim,'*pa*spec2plot*',0.,180.,0
      ;
      options,'el?_pef_'+['en_fulspn_spec2plot_????','pa_fulspn_spec2plot_ch?LC'],'ysubtitle',''
      ;
      ; to eliminate SEPs, here calculate errmax4specs table (rather than single value) to use
      ;
      get_data,'elx_pef_en_fulspn_spec2plot_prec',data=elx_pef_en_fulspn_spec2plot_prec
      ntimes=n_elements(elx_pef_en_fulspn_spec2plot_prec.x)
      Emids=elx_pef_en_fulspn_spec2plot_prec.v
      nenergies = n_elements(elx_pef_en_fulspn_spec2plot_prec.v) ; this is 16 (nominally)
      EskeV2D=make_array(ntimes,/float,value=1.)#elx_pef_en_fulspn_spec2plot_prec.v
      ;
      tinterpol_mxn,'Ligrf','elx_pef_en_fulspn_spec2plot_prec',newname='Ligrf_int'
      get_data,'Ligrf_int',data=Ligrf_int
      Ligrf1D=reform(Ligrf_int.y#make_array(nenergies,/float,value=1.),ntimes*nenergies)
      errmax4specs2Dra=elx_pef_en_fulspn_spec2plot_prec.y
      errmax4specs2Dra[*,*]=errmax4specs ; define array
      errmax4specs1D=reform(errmax4specs2Dra,ntimes*nenergies)
      get_data,'elx_pef_en_fulspn_spec2plot_perp',data=elx_pef_en_fulspn_spec2plot_perp
      get_data,'elx_pef_en_fulspn_spec2plot_back',data=elx_pef_en_fulspn_spec2plot_back
      get_data,'elx_pef_en_fulspn_spec2plot_back_err',data=elx_pef_en_fulspn_spec2plot_back_err
      get_data,'elx_pef_en_fulspn_spec2plot_perp_err',data=elx_pef_en_fulspn_spec2plot_perp_err
      get_data,'elx_pef_en_fulspn_spec2plot_prec_err',data=elx_pef_en_fulspn_spec2plot_prec_err
      ctperp2D=1./elx_pef_en_fulspn_spec2plot_perp_err.y^2 ; counts in bin
      ctprec2D=1./elx_pef_en_fulspn_spec2plot_prec_err.y^2 ; counts in bin
      ctback2D=1./elx_pef_en_fulspn_spec2plot_back_err.y^2 ; counts in bin
      ctperp1D=reform(ctperp2D,ntimes*nenergies) ; counts in bin, 3x3 smoothed
      ctprec1D=reform(ctprec2D,ntimes*nenergies) ; counts in bin, 3x3 smoothed
      ctback1D=reform(ctback2D,ntimes*nenergies) ; counts in bin, 3x3 smoothed
      ;
      EskeV1D=reform(EskeV2D,ntimes*nenergies)
      hiscale=2.0 ; reject all look dirs as rogue if you have at least hiscale*counts in the other directions PLUS hinoise (this e
      hinoise=1./errmax4specs^2 ; this is high energy noise to be rejected
      iSEPs=where(((ctprec1D gt ctperp1D*SEPprectoperpgt and ctback1D lt ctprec1D*SEPbacktopreclt and EskeV1D gt SEPenergygt) or $ ; prec > ~ perp & back<<prec
        (ctback1D gt hiscale*(hinoise/hiscale+(ctprec1D)) and EskeV1D gt SEPhienergygt)) and $    ; back cnts >> prec+perp cnts + noise
        Ligrf1D gt SEPLshellgt, jSEPs)
      ;iSEPs=where((ctprec1D gt ctperp1D*SEPprectoperpgt and ctback1D lt ctprec1D*SEPbacktopreclt and EskeV1D gt SEPenergygt and $ ; prec > ~ perp & back<<prec
      ;            Ligrf1D gt SEPLshellgt),jSEPs)
      jSEPs=myjSEPs*jSEPs ; use myjSEPs to control whether you implement SEP decontamination or not (0: not; 1: yes)
      if jSEPs gt 0 then errmax4specs1D[iSEPs]=errmax4SEPs
      errmax4specs2Dra = reform(errmax4specs1D,ntimes,nenergies)
      ;
      quants2clean='elx_pef_en_fulspn_spec2plot_'+ $ ; will append 'gterr' to avoid over-writing
        ['prec','back','perp','omni']
      foreach element, quants2clean do begin
        error2use=element+'_err'
        copy_data,element,'quant2clean'
        copy_data,error2use,'error2use'
        get_data,'quant2clean',data=mydata_quant2clean,dlim=mydlim_quant2clean,lim=mylim_quant2clean
        ntimes=n_elements(mydata_quant2clean.y[*,0])
        nvalues=n_elements(mydata_quant2clean.y[0,*])
        mydata_quant2clean_temp=reform(mydata_quant2clean.y,ntimes*nvalues)
        get_data,'error2use',data=mydata_error2use
        mydata_error2use_temp=reform(mydata_error2use.y,ntimes*nvalues)
        if nvalues eq 1 then errmax4specs2use=errmax4lines else errmax4specs2use=errmax4specs1D
        ielim=where(abs(mydata_error2use_temp) gt errmax4specs2use, jelim) ; this takes care of NaNs and +/-Inf's as well!
        if jelim gt 0 then mydata_quant2clean_temp[ielim] = !VALUES.F_NaN ; make them NaNs, not even zeros
        mydata_quant2clean.y = reform(mydata_quant2clean_temp,ntimes,nvalues) ; back to the original array
        store_data,'quant2clean',data=mydata_quant2clean,dlim=mydlim_quant2clean,lim=mylim_quant2clean
        copy_data,'quant2clean',element+'gterr' ; doesn't overwrite the previous data in the tplot variable, creates new one!
      endforeach
      ;
      get_data,'elx_pef_en_fulspn_spec2plot_precgterr',data=elx_pef_en_fulspn_spec2plot_precgterr
      get_data,'elx_pef_en_fulspn_spec2plot_backgterr',data=elx_pef_en_fulspn_spec2plot_backgterr
      get_data,'elx_pef_en_fulspn_spec2plot_perpgterr',data=elx_pef_en_fulspn_spec2plot_perpgterr
      get_data,'elx_pef_en_fulspn_spec2plot_omnigterr',data=elx_pef_en_fulspn_spec2plot_omnigterr
      get_data,'elx_pef_pa_fulspn_spec2plot_ch0',data=elx_pef_pa_fulspn_spec2plot_ch0
      get_data,'elx_pef_pa_fulspn_spec2plot_ch1',data=elx_pef_pa_fulspn_spec2plot_ch1

      ;
      tinterpol_mxn,'proxy_ae',elx_pef_en_fulspn_spec2plot_precgterr.x,out=proxy_ae_int
      tinterpol_mxn,'proxy_ae_blkavg',elx_pef_en_fulspn_spec2plot_precgterr.x,out=proxy_ae_blkavg_int
      tinterpol_mxn,'elf_kp',elx_pef_en_fulspn_spec2plot_precgterr.x,out=elf_kp_int
      tinterpol_mxn,'dst',elx_pef_en_fulspn_spec2plot_precgterr.x,out=dst_int
      tinterpol_mxn,'Ligrf',elx_pef_en_fulspn_spec2plot_precgterr.x,out=Ligrf_int
      tinterpol_mxn,'MLATigrf',elx_pef_en_fulspn_spec2plot_precgterr.x,out=MLATigrf_int
      tinterpol_mxn,'MLTigrf',elx_pef_en_fulspn_spec2plot_precgterr.x,out=MLTigrf_int,/NEAREST_NEIGHBOR ; avoids 0/24 transition averaging
      tinterpol_mxn,'lossconedeg',elx_pef_en_fulspn_spec2plot_precgterr.x,out=lossconedeg_int
      ;
      sav_filename=outdir+'el'+sclet+'_eflux_'+ date_str +'.sav'
      dprint, 'Saving file: ' + sav_filename
      save,Ligrf_int,MLATigrf_int,MLTigrf_int,proxy_ae_int,proxy_ae_blkavg_int,elf_kp_int,dst_int,lossconedeg_int, $
           elx_pef_en_fulspn_spec2plot_precgterr,elx_pef_en_fulspn_spec2plot_backgterr, $
           elx_pef_en_fulspn_spec2plot_perpgterr,elx_pef_en_fulspn_spec2plot_omnigterr, $
           elx_pef_pa_fulspn_spec2plot_ch0,elx_pef_pa_fulspn_spec2plot_ch1, $
           filename=sav_filename
      ;
;    stop
 
    endfor
EXIT_THIS_IDL_SESSION:
;stop    
end    
      
