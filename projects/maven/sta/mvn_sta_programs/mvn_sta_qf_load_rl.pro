
;;Quality Flag Legend
;;
;;Location   Definition                                            - Determined from                                                             
;;---------------------------------------------------------------------------------------------------------------------------------                       
;;bit 0      Test pulser on                                        - testpulser header bit set
;;bit 1      Diagnostic mode                                       - diagnostic header bit set                                                  
;;bit 2      Dead time correction > factor of 2                    - deadtime correction > 2                                                    
;;bit 3      MCP detector gain droop flag- deadtime and beam width - tbd algorithm                                    
;;bit 4      Dead time correction not at event time                - missing data quantity for deadtime                                         
;;bit 5      Electrostatic attenuator failing at <2 eV             - attE on and eprom_ver<2                                                    
;;bit 6      Attenuator change during accumulation                 - att 1->2 or 2->1 transition (one measurement)                              
;;bit 7      Mode change during accumulation                       - only needed for packets that average data during mode transition           
;;bit 8      LPW sweeps interfering with data                      - LPW mode not dust mode                                                     
;;bit 9      High background                                       - minimum value in DA > 1000                                                 
;;bit 10     Missing background                                    - dat.bkg = 0           - may not be needed                                  
;;bit 11     Missing spacecraft potential                          - dat.sc_pot = 0        - may not be needed                                  
;;bit 12     Extra                                                 - may not be needed                                    



;;Bit Value Definition
;;----------------------------------------------------------
;;bit = 0 -> No Flag.
;;bit = 1 -> Flag set (see legend above). 
;;
;;Example:
;;
;;     IDL> print, format='(B)',quality_flag
;;     IDL> 0000100101100
;;
;;     Flags are set for:
;;     bit 2 = 1
;;     bit 3 = 1
;;     bit 5 = 1
;;     bit 8 = 1




pro mvn_sta_qf_load_rl,verbose=verbose



  ;;--------------------------------------------------------
  ;;Declare all the common block arrays
  common mvn_2a,mvn_2a_ind,mvn_2a_dat
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c2,mvn_c2_ind,mvn_c2_dat
  common mvn_c4,mvn_c4_ind,mvn_c4_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d2,mvn_d2_ind,mvn_d2_dat
  common mvn_d3,mvn_d3_ind,mvn_d3_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat
  common mvn_d6,mvn_d6_ind,mvn_d6_dat
  common mvn_d7,mvn_d7_ind,mvn_d7_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_da,mvn_da_ind,mvn_da_dat
  common mvn_db,mvn_db_ind,mvn_db_dat



  ;;----------------------------------------------------
  ;;Make sure APID da is loaded to obtain quality flags
  ;;for the the background (bit 9).
  temp=execute("temp1=mvn_da_dat")
  if size(temp1,/type) ne 8 then mvn_sta_l2_load, sta_apid=['da']
  temp=execute("temp1=mvn_da_dat")
  if size(temp1,/type) ne 8 then stop, 'mvn_da_dat needs to be loaded for.'



  ;;-----------------------------------------------------
  ;;Find orbits and altitudes
  tt=timerange()
  orb_time = tt[0]+360*indgen(240)*(tt[1]-tt[0])/(24*3600)
  orb_num = mvn_orbit_num(time=orb_time)-0.3
  maven_orbit_tplot,result=result,/loadonly
  R_m = 3389.9D
  npts=n_elements(result.x)
  ss = dblarr(npts, 4)
  ss[*,0] = result.x
  ss[*,1] = result.y
  ss[*,2] = result.z
  ss[*,3] = result.r
  alt = (ss[*,3] - 1D)*R_m




  ;;;********************************************************
  ;;;Get APID c6
  ;;;
  ;;
  ;;NOTE:
  ;;
  ;;     APID c6 is used as the base time. All other APIDs
  ;;     will be prodcued based on the c6 time intervals.
  ;;

  ;;Load c6 - Change structure name to dat
  print, 'Generate Quality Flags for APID c6...'
  dat      = mvn_c6_dat  
  qf       = dat.quality_flag
  qf_time  = dat.time
  npts     = dimen1(dat.data)
  time     = dat.time
  time_end = dat.end_time
  mode     = dat.mode
  att      = dat.att_ind
  header   = dat.header
  eprom    = dat.eprom_ver



  ;;--------------------------------------------------------
  ;;Clear the following bits: 0,1,5,6,7,8,9,10,11,12
  bitclear=2^0  + 2^1  + 2^5 + 2^6  + $
           2^7  + 2^8  + 2^9 + 2^10 + $
           2^11 + 2^12
  qf=qf and (not bitclear)
  


  ;;***************************************************************
  ;;Bit 0 - Test pulser
  ;;QF bit 0    test pulser on   (header and 128)        
  bit0mask=2^0
  head=(header and 128L)/128L
  pp=where(head eq 1L,cc)
  if cc ne 0 then qf[pp] = qf[pp] or bit0mask
  if keyword_set(verbose) then print, 'Bit 0 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************
  ;;Bit 1 - Diagnostic Mode
  ;;QF bit 1    diagnostic mode  (header and 64)        
  bit1mask=2^1
  head=(header and 64L)/64L
  pp=where(head eq 1L,cc)
  if cc ne 0 then qf[pp] = qf[pp] or bit1mask
  if keyword_set(verbose) then $
     print, 'Bit 1 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************
  ;;Bit 2 - Dead time correction
  bit2mask=2^2
  if keyword_set(verbose) then $
     print, 'Bit 2 flags - Total:  '+string(0L)+'/'+string(npts)  

  
  
  ;;***************************************************************
  ;;Bit 3 - MCP Gain Droop
  bit3mask=2^3
  if keyword_set(verbose) then $
     print, 'Bit 3 flags - Total:  '+string(0L)+'/'+string(npts)  

  
  
  ;;***************************************************************
  ;;Bit 4 - Dead time correction
  bit4mask=2^4
  if keyword_set(verbose) then $
     print, 'Bit 4 flags - Total:  '+string(0L)+'/'+string(npts)  
  
  
  ;;***************************************************************
  ;;Bit 5 - Electrostatic Attenuator Irregularity
  ;;
  ;;NOTES:
  ;;      Electrostatic attenuator flag should be set if
  ;;      ((att_ind eq 1) or (att_ind eq 3)) and
  ;;      (((eprom eq 2) and (c1 gt 10.)) or ((eprom eq 1) and 
  ;;      (c2 gt 10.))) 
  ;;      where c1 is the total counts in apid c0 less than .75 eV
  ;;      where c2 is the total counts in apid c0 less than 2.5 eV 
  
  ;;Jim's Method
  bit5mask=2^5
  npts=n_elements(dat.time)
  bit5=intarr(npts)
  eprom = dat.eprom_ver
  att = dat.att_ind
  swp = dat.swp_ind
  energy = dat.energy
  ccc = 0L
  ind = where(eprom eq 1 or eprom eq 2 ,cnt)
  if cnt gt 0 then begin
     for i=0,npts-1 do begin
        if (att[i] eq 1 or att[i] eq 3) then begin   
           if eprom[i] eq 1 then ind = where(energy[swp[i],*,0] lt 2.5,count)
           if eprom[i] eq 2 then ind = where(energy[swp[i],*,0] lt 0.75,count)
           if count ge 1 then begin
              datt = total(dat.data[i,ind,*])
              ;if datt gt 10. then bit5[i]=2^5
              if datt gt 10. then qf[i] = qf[i] or bit5mask
              if datt gt 10. then ccc++
           endif
        endif
   endfor
  endif 

  if keyword_set(verbose) and n_elements(ccc) then $
     print, 'Bit 5 flags - Total:  '+string(ccc)+'/'+string(npts) $
  else print, 'Bit 5 flags - Total:  '+string(0L)+'/'+string(npts)
  


  ;;***************************************************************
  ;;Bit 6 - Attenuator Change During Accumulation
  ;;NOTE
  ;;
  ;; 1. Bit6 is allowed to land on boundaries only for electrostatic
  ;; attenuator.
  ;; 2. For APIDs with 4  second cadence we only want to include
  ;; transitions to and from mechanical. e.g. 1->2 or 2->1. For APIDs
  ;; that have a larger cadence we include all changes.
  bit6mask=2^6
  pp1=[0,findgen(n_elements(att)-1)]        
  temp=att[pp1]-att
  ind=where(temp ne 0,cc)
  if cc ne 0 then qf[ind] = qf[ind] or bit6mask
  if keyword_set(verbose) then $
     print, 'Bit 6 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************  
  ;;Bit 7  - Mode Change During Accumulation
  ;;NOTE
  ;;
  ;; Is allowed to land on boundaries   
  bit7mask=2^7
  pp=[0,findgen(n_elements(mode)-1)]        
  temp=mode-mode[pp]
  ind=where(temp ne 0,cc)
  if cc ne 0 then qf[ind] = qf[ind] or bit7mask
  if keyword_set(verbose) then $
     print, 'Bit 7 flags - Total:  '+string(cc)+'/'+string(npts)
  
  

  ;;***************************************************************  
  ;;Bit 8  - LPW Sweep Interference
  ;;
  ;;NOTES:
  ;;    - LPW sweeps interfering with data:
  ;;      - Date lt 2014-11-20 for all orbits
  ;;      - Date gt 2014-11-20 and date lt 2015-01-07 for odd orbits
  ;;    - The LPW interference should only apply to 'conic' (2)
  ;;      and 'ram' (1) modes on the identified orbits,
  ;;      i.e. mode less than 3 
  bit8mask=2^8
  orb_num_new=fix(interpol(orb_num,orb_time,time))
  date1=time_double('2014-11-20')
  date2=time_double('2015-01-07')
  pp1=where(time lt date1 and mode lt 3,cc1)
  if cc1 ne 0 then qf[pp1] = qf[pp1] or bit8mask
  pp2=where(time ge date1 and $
            time lt date2 and $
            (orb_num_new mod 2) eq 1 and $ ;odd orbits 
            mode lt 3,cc2)
  if cc2 ne 0 then qf[pp2] = qf[pp2] or bit8mask
  if keyword_set(verbose) then $
     print, 'Bit 8 flags - Total:  '+string(cc1)+'/'+string(npts)+' (c1)'
  if keyword_set(verbose) then $
     print, 'Bit 8 flags - Total:  '+string(cc1)+'/'+string(npts)+' (c2)'



  ;;***************************************************************
  ;;Bit 9  - High Background
  bit9mask=2^9
  pp=where(min(mvn_da_dat.rates,dim=2) ge 1000.D,cc)
  if cc ne 0 then begin
     ind=mvn_da_dat.time*0.D
     ind[pp]=1.
     time_da=mvn_da_dat.time[pp]
     ;;Interpolate for time (apid c6)  
     ind2=ceil(interpol(ind,mvn_da_dat.time,time))
     pp=where(ind2 gt 0)
     qf[pp] = qf[pp] or bit9mask
  endif
  if keyword_set(verbose) then $
     print, 'Bit 9 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************
  ;;Bit 10 - Missing Background
  ;;
  ;; !!! Default is set to 1 until these values are calculated !!!
  bit10mask=2^10
  qf = qf or bit10mask
  if keyword_set(verbose) then $
     print, 'Bit 10 flags - Total: '+string(npts)+'/'+string(npts)
  


  ;;***************************************************************  
  ;;Bit 11 - Missing Spacecraft Potential
  ;;
  ;; !!! Default is set to 1 until these values are calculated !!!
  bit11mask=2^11
  qf = qf or bit11mask
  if keyword_set(verbose) then $
     print, 'Bit 11 flags - Total: '+string(npts)+'/'+string(npts)
  
  

  ;;***************************************************************
  ;;Bit 12 - Extra
  ;;
  ;; !!! Default is set to 1 until these values are calculated !!!
  bit12mask=2^12
  qf = qf or bit12mask
  if keyword_set(verbose) then $
     print, 'Bit 12 flags - Total: '+string(npts)+'/'+string(npts)
  


  ;;-----------------------------------------------
  ;;Apply quality flag to all APIDs and  
  ;;define QF and APIDs
  apid=['2a','c0','c2','c4','c8','c6',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4','d6','d7',$
        'd8','d9','da','db']
  cade=[   4,  32,   4,   4,   4,   4,$
           4,  32,   4,  32,   4, 128,$
          16,  16,   4,   4, 148,   4,$
           4, 128,   4,   4]
  nn_apid=n_elements(apid)
  for api=0, nn_apid-1 do begin     
     temp=execute('nn1=size(mvn_'+apid[api]+'_dat,/type)')
     if nn1 eq 8 then begin

        temp=execute('qf_new=mvn_'+apid[api]+'_dat.quality_flag')        
        temp=execute('time_new=mvn_'+apid[api]+'_dat.time')        
        
        ;;---------------------------------------------------------
        ;;Time interval
        temp1=execute('nn1=n_elements(mvn_'+apid[api]+'_dat.time)')
        temp2=execute('nn2=n_elements(mvn_'+apid[api]+'_dat.end_time)')
        ;start time -----
        if temp1 then temp=execute('t_start=mvn_'+apid[api]+'_dat.time') $
        else stop, 'No time instances.'
        ;stop time ------
        if temp2 then temp=execute('t_stop=mvn_'+apid[api]+'_dat.end_time') $
        else temp=execute('t_stop=mvn_'+apid[api]+'_dat.time')       
        for itime=0., nn1-1 do begin
           t1=t_start[itime]
           t2=t_stop[itime]
           pp=where( time ge t1-0.1 and time_end le t2+0.1,cc)
           if cc ne 0 then for i=0., cc-1 do qf_new[itime]=qf_new[itime] or qf[itime[pp[[i]]]]           
        endfor


        ;;---------------------------------------------------------------------------
        ;;EXCEPTION
        ;;---------------------------------------------------------------------------
        ;;Bit 6 (attenuator change) only applies
        ;;to summed APIDs. Any flag set for not-summed APIDs (cadence
        ;;of 4 seconds or less) is removed
        if cade[api] le 4 then begin
           ;;1. Make sure to 0 out all bit 6 for this APID
           qf_new=qf_new and (not 2^6)
           ;;2. interpolate current APID attenuator with c6 attenuator           
           att_int=ceil(interpol(att,time,time_new))
           ;;3. find instances when att goes from 1->2 and 2->1
           pp1=[0,findgen(n_elements(att_int)-1)]        
           temp5=att_int-att_int[pp1]
           ind=where(temp5 ne 0,cc)
           att_ind_12=where((att_int[ind] eq 2) or $
                            ((att_int[ind] eq 1) and $
                             temp5[ind] eq -1),cc)
           final_ind=ind[att_ind_12]
           ;;4. insert flags back into APID
           qf_new[final_ind]=qf_new[final_ind] or 2^6
        endif
        ;;---------------------------------------------------------------------------
        ;;Insert new 
        temp=execute('mvn_'+apid[api]+'_dat.quality_flag=qf_new')

        
     endif
  endfor


end
