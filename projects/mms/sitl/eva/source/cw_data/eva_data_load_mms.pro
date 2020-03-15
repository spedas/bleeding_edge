FUNCTION eva_data_load_mms, state, no_gui=no_gui, force=force
  compile_opt idl2

  ;-------------
  ; INITIALIZE
  ;-------------
  paramlist = strlowcase(state.paramlist_mms); list of parameters read from parameterSet file
  imax = n_elements(paramlist)
  sc_id = state.probelist_mms
  if (size(sc_id[0],/type) ne 7) then return, 'No'; STRING=7
  pmax = n_elements(sc_id)
  if pmax eq 1 then sc = sc_id[0] else sc = sc_id
  ts = str2time(state.start_time)
  te = str2time(state.end_time)
  timespan,state.start_time, te-ts, /seconds
  LOADED_4FGM = 0L
  
  ;----------------------
  ; NUMBER OF PARAMETERS
  ;----------------------
  cparam = imax*pmax
  if not keyword_set(no_gui) then begin
    if cparam ge 17 then begin
      rst = dialog_message('Total of '+strtrim(string(cparam),2)+' MMS parameters. Still plot?',/question,/center)
    endif else rst = 'Yes'
    if rst eq 'No' then return, 'No'
  endif
  
  ;-------------
  ; CATCH ERROR
  ;-------------
  perror = -1
  pcode = -1
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    ;catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will igonore this error.']
    if ~keyword_set(no_gui) then begin 
      ;ok = dialog_message(msg,/center,/error)
      print, 'EVA: '+msg
      progressbar -> Destroy
    endif
    message, /reset; Clear !ERROR_STATE
    perror = [perror,pcode]
    ;return, answer; 'answer' will be 'Yes', if at least some of the data were succesfully loaded.
  endif

  ;-------------
  ; LOAD
  ;-------------
  if ~keyword_set(no_gui) then begin
    progressbar = Obj_New('progressbar', background='white', Text='Loading MMS data ..... 0 %')
    progressbar -> Start
  endif
  
  ;... BentPipe should always be loaded ---
  a = tag_names(state)
  idx = where(a eq 'PREF',ct)
  if ct gt 0 then begin
    if state.PREF.EVA_TRIGGER then begin
      for p=0,pmax-1 do begin
        sc = sc_id[p]
        eva_data_load_mms_fpi_pseudomom, sc=sc_id
      endfor
    endif
  endif
  
  c = 0
  answer = 'No'
  for p=0,pmax-1 do begin; for each requested probe
    sc = sc_id[p]
    prb = strmid(sc,3,1)
    for i=0,imax-1 do begin; for each requested parameter
      
      
      if ~keyword_set(no_gui) then begin
        if progressbar->CheckCancel() then begin
          ok = Dialog_Message('User cancelled operation.',/center) ; Other cleanup, etc. here.
          break
        endif
      endif
      
      prg = 100.0*float(c)/float(cparam)
      sprg = 'Loading MMS data ....... '+string(prg,format='(I2)')+' %'
      if ~keyword_set(no_gui) then progressbar -> Update, prg, Text=sprg
      
      ; Check pre-loaded tplot variables. 
      ; Avoid reloading if already exists.
      tn=strlowcase(tnames('*',jmax))
      if strmatch(paramlist[i],'mms_s*') then begin
        param = paramlist[i]
      endif else begin
        param = strlowcase(sc+strmid(paramlist[i],4,1000))
      endelse
      if jmax eq 0 then begin; if no pre-loaded variable
        ct = 0
      endif else begin; if pre-loaded variable exists...
        idx = where(strmatch(tn,param),ct); check if param is one of the preloaded variables.
      endelse

      if keyword_set(force) then ct = 0
      
      if ct eq 0 then begin; if not loaded
        ;-----------
        ; ASPOCis
        ;-----------
        pcode=10
        ip=where(perror eq pcode,cp)
        if(strmatch(paramlist[i],'*_asp1_*') and (cp eq 0))then begin
          mms_load_aspoc,datatype='asp1',level='sitl',probe=prb
          answer = 'Yes'
        endif
        pcode=11
        ip=where(perror eq pcode,cp)
        if(strmatch(paramlist[i],'*_asp2_*') and (cp eq 0))then begin
          mms_load_aspoc,datatype='asp2',level='sitl',probe=prb
          answer = 'Yes'
        endif
        
        ;-----------
        ; EPD FEEPS
        ;-----------
        pcode=21
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_feeps_*') and (cp eq 0)) then begin
          mms_sitl_get_feeps, probes=prb
          feeps_e_omni = sc+ '_epd_feeps_srvy_sitl_electron_intensity_omni'
          feeps_i_omni = sc+ '_epd_feeps_srvy_sitl_ion_intensity_omni'
          tn=tnames(sc+'_epd_feeps_srvy_sitl_*_intensity_omni', jmax)
          if (strlen(tn[0]) gt 0) and (jmax ge 1) then begin
            options, [feeps_e_omni, feeps_i_omni], 'spec', 1
            options, [feeps_e_omni, feeps_i_omni], 'ylog', 1
            options, [feeps_e_omni, feeps_i_omni], 'zlog', 1
            options, feeps_e_omni, ytitle=sc+'!CFEEPS!Celectrons',ysubtitle='[keV]'
            options, feeps_i_omni, ytitle=sc+'!CFEEPS!Cions',ysubtitle='[keV]'
            ylim, [feeps_e_omni], 50, 530; 35, 500
            ylim, [feeps_i_omni], 55, 500
          endif
;          ; delete most of the variables
;          tn = tnames(sc+'*feeps*top*',jmax)
;          idx = where(~strmatch(tn,'*clean_sun_removed'),ct)
;          if jmax gt 0 then store_data, tn[idx],/delete
;          ; options
;          tnf = sc+'_epd_feeps_srvy_sitl_electron*intensity*'
;          tn=tnames(tnf,jmax)
;          if (strlen(tn[0]) gt 0) and (jmax ge 1) then begin
;            options, tnf, ytitle=sc+'!CFEEPS!Cintnsty',ysubtitle='[keV]'
;            ylim, tnf, 50, 530
;          endif
          answer = 'Yes'
        endif
        
        ;-----------
        ; EPD EIS
        ;-----------
        pcode=22
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_epd_eis_*') and (cp eq 0)) then begin
          varformat = sc + ['_epd_eis_*_spin', '_epd_eis_*_pitch_angle_t*', '_epd_eis_*_*_flux_t*']
          ;mms_load_eis, probes=prb, datatype='extof', level='l1b', data_units = 'flux', varformat=varformat
          mms_sitl_get_eis, probes=prb, datatype='extof', level='l1b', data_units = 'flux', varformat=varformat
          tn=tnames(sc+'_epd_eis_*',jmax)
          if (strlen(tn[0]) gt 0) and (jmax ge 1) then begin
            idx = where(strmatch(tn,'*flux_omni_spin'),c,complement=cidx, ncomp=nc)
            store_data, tn[cidx], /delete; delete most of the variables
            tn = tnames(sc+'_epd_eis_*_flux_omni_spin',kmax)
            for k=0,kmax-1 do begin
              tarr = strsplit(tn[k],'_',/extract)
              options, tn[k],ytitle=sc+'!CEIS!C'+tarr[4],ysubtitle='[keV]'
              case tarr[4] of
                'proton': yrange = [50, 530];1000]
                'alpha': yrange = [70, 530];700]
                'oxygen': yrange = [130,530];1000]
              endcase
              ylim, tn[k], yrange
            endfor
          endif
        endif
        
        ;-----------
        ; FIELDS/AFG
        ;-----------
        pcode=30
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_afg*') and (cp eq 0)) then begin
          eva_data_load_mms_fgm,sc=sc,sfx='afg'
;          mms_sitl_get_afg, sc_id=sc
;          eva_cap,sc+'_afg_srvy_gsm_dmpa'
;          options,sc+'_afg_srvy_gsm_dmpa',$
;            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='GSM [nT]',$
;            colors=[2,4,6],labflag=-1,constant=0
;          eva_cap,sc+'_afg_srvy_dmpa'
;          options,sc+'_afg_srvy_dmpa',$
;            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='DMPA [nT]',$
;            colors=[2,4,6],labflag=-1,constant=0
          answer = 'Yes'
        endif
        pcode=31
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_omb*') and (cp eq 0)) then begin
          mms_sitl_get_afg, sc_id=sc, level='l1b'
          tn=tnames(sc+'*_afg_srvy_omb*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            eva_cap,sc+'_afg_srvy_omb'
            options,sc+'_afg_srvy_omb',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='OMB [nT]',$
              colors=[2,4,6],labflag=-1,constant=0
            answer = 'Yes'
          endif
          tn=tnames(sc+'*_afg_srvy_bcs*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            eva_cap,sc+'_afg_srvy_bcs'
            options,sc+'_afg_srvy_bcs',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='BCS [nT]',$
              colors=[2,4,6],labflag=-1,constant=0
            answer = 'Yes'
          endif
        endif
        
        ;-----------
        ; FIELDS/DFG
        ;-----------
        pcode=32
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dfg*') and (cp eq 0)) then begin
          eva_data_load_mms_fgm, sc=sc, sfx='dfg'
          answer = 'Yes'
        endif
        pcode=33
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_omb*') and (cp eq 0)) then begin
          mms_sitl_get_dfg, sc_id=sc, level='l1b'
          tn=tnames(sc+'*_dfg_srvy_omb*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            eva_cap,sc+'_dfg_srvy_omb'
            options,sc+'_dfg_srvy_omb',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='OMB [nT]',$
              colors=[2,4,6],labflag=-1,constant=0
            answer = 'Yes'
          endif
          tn=tnames(sc+'*_dfg_srvy_bcs*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            eva_cap,sc+'_dfg_srvy_bcs'
            options,sc+'_dfg_srvy_bcs',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='BCS [nT]',$
              colors=[2,4,6],labflag=-1,constant=0
            answer = 'Yes'
          endif
        endif

        ;-----------
        ; FIELDS/DSP
        ;-----------
        pcode=40
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dsp_*e_*') and (cp eq 0)) then begin
          ;mms_sitl_get_dsp, sc=sc, datatype='bpsd'
          mms_load_dsp,probe=prb,datatype='epsd',data_rate='srvy',level='l1b'
          mms_load_dsp,probe=prb,datatype='epsd',data_rate='fast',level='l2'
          tn=tnames(sc+'*dsp_lfe*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            ylim,tn,30,6000,1
            zlim,tn,5e-10,1e-6,1
            options,tn,ysubtitle=''
            answer = 'Yes'
          endif
          tn=tnames(sc+'*dsp_mfe*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            ylim,tn,500,1e+5,1
            zlim,tn,1e-10,1e-7,1
            options,tn,ysubtitle=''
            answer = 'Yes'
          endif
        endif
        
;        pcode=41
;        ip=where(perror eq pcode,cp)
;        if (strmatch(paramlist[i],'*_dsp_*b_*') and (cp eq 0)) then begin
;          ;mms_sitl_get_dsp, sc=sc, datatype='bpsd'
;          mms_load_dsp,probe=prb,datatype='bpsd',data_rate='srvy',level='l1b'
;          mms_load_dsp,probe=prb,datatype='bpsd',data_rate='fast',level='l2'
;          tn=tnames(sc+'*dsp_lfb*',cnt)
;          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
;            ylim,tn,30,6000,1
;            zlim,tn,5e-10,1e-6,1
;            options,tn,ysubtitle=''
;            answer = 'Yes'
;          endif
;          tn=tnames(sc+'*dsp_mf*',cnt)
;          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
;            ylim,tn,500,1e+5,1
;            zlim,tn,1e-10,1e-7,1
;            options,tn,ysubtitle=''
;            answer = 'Yes'
;          endif
;        endif
        
;        pcode=41
;        ip=where(perror eq pcode,cp)
;        if (strmatch(paramlist[i],'*_dsp_mfe*') and (cp eq 0)) then begin
;          mms_sitl_get_dsp, sc=sc, datatype='epsd'
;          tn=tnames(sc+'*dsp_mfe*',cnt)
;          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
;            ylim,tn,500,1e+5,1
;            zlim,tn,1e-10,1e-7,1
;            answer = 'Yes'
;          endif
;        endif
;        
        pcode=42
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dsp_bpsd_*') and (cp eq 0)) then begin
          mms_sitl_get_dsp, sc = sc, datatype = 'bpsd', level = 'l2', data_rate='fast'
          tn = tnames(sc+'_dsp_bpsd_*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 1) then begin
            options,sc+'_dsp_bpsd_omni_fast_l2', spec=1,zlog=1,ytitle=sc+'!CDSP!Cbpsd',ysubtitle='[Hz]',ztitle='[(nT)!U2!N/Hz]'
            ylim, tn, 32, 4000, 1
            for m=1,3 do begin
              strm = strtrim(string(m),2)
              options,sc+'_dsp_bpsd_scm'+strm+'_fast_l2',spec=1,zlog=1,ytitle=sc+'!CDSP!Cfast!Cbpsd_scm'+strm,$
                ysubtitle='[Hz]',ztitle='[(nT)!U2!N/Hz]'
              ylim, sc+'_dsp_bpsd_scm'+strm+'_fast_l2', 32, 4000, 1
            endfor
            answer = 'Yes'
          endif
        endif
        
        ;-------------
        ; FIELDS EDI
        ;-------------
        pcode=35
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edi_amb_*') and (cp eq 0)) then begin
          mms_sitl_get_edi_amb,sc=sc
;          eva_data_proc_edi, sc
          options,sc+'_edi_counts1_0',ytitle=sc+'!CEDI!Cpa0',ysubtitle='[cts]'
          options,sc+'_edi_counts1_180',ytitle=sc+'!CEDI!Cpa180',ysubtitle='[cts]'
          answer = 'Yes'
        endif
        
        ;------------
        ; FIELDS EDP
        ;------------
        pcode=36
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_fast_dce_*') and (cp eq 0)) then begin
          mms_sitl_get_edp,sc=sc, level = 'sitl'
          
          tn = tnames(sc+'_edp_fast_dce_sitl',cnt)
          if (strlen(tn[0]) gt 0) and (cnt eq 1) then begin
            options,tn,labels=['X','Y','Z'],ytitle=sc+'!CEDP!Cfast',ysubtitle='[mV/m]',$
              colors=[2,4,6],labflag=-1,yrange=[-20,20],constant=0
          
            get_data,tn,data=D,dl=dl,lim=lim
            str_element,/add,'lim','labels',['X','Y']
            str_element,/add,'lim','colors',[2,4]
            store_data,sc+'_edp_fast_dce_sitl_xy',data={x:D.x,y:D.y[*,0:1]},dl=dl,lim=lim
            
          endif
          answer = 'Yes'
        endif
        
        pcode=37
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_scpot_fast*') and (cp eq 0)) then begin
          mms_sitl_get_edp, sc=sc, data_rate = 'fast', level='sitl', datatype='scpot'
          tn = tnames(sc+'_edp_scpot_fast_sitl',cnt)
          if (strlen(tn[0]) gt 0) and (cnt eq 1) then begin
            get_data,tn,data=D,dl=dl,lim=lim
            ynew = (-1)*alog10(D.y > 0)
            store_data,tn,data={x:D.x,y:ynew},dl=dl,lim=lim
            options,tn,ytitle=sc+'!CEDP!C-log(p)',labels='pot'
          endif
          answer = 'Yes'
        endif
        
        pcode=38
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_hfesp_srvy_*') and (cp eq 0)) then begin
          mms_sitl_get_edp, sc = sc, datatype='hfesp', level = 'l2', data_rate='srvy'
          tn = tnames(sc+'_edp_hfesp_srvy_l2',cnt)
          if (strlen(tn[0]) gt 0) and (cnt eq 1) then begin
            options,tn,ytitle=sc+'!CEDP!Chfesp',ysubtitle='[Hz]',ztitle='[(V/m)!U2!N/Hz]'
            options,tn,spec=1,zlog=1
            ylim,tn,600,65536,1 
            tplot_force_monotonic,tn,/forward
          endif
          answer = 'Yes'
        endif
        
        ;------------------
        ; FPI PSEUDO MOM
        ;------------------
        pcode=50
        ip=where(perror eq pcode,cp)
        PSEUDOMOM = (strmatch(paramlist[i],'*pseudo*') or strmatch(paramlist[i],'*bentpipe*')) 
        if PSEUDOMOM and (cp eq 0) then begin
          ;eva_data_load_mms_fpi, sc=sc
          eva_data_load_mms_fpi_pseudomom, sc=sc
          answer = 'Yes'
        endif

        ;-------------
        ; FPI QL OLD
        ;-------------
        pcode=51
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_des_*') and (cp eq 0)) then begin
          eva_data_load_mms_fpi_ql_old, prb=prb, datatype='des'
          answer = 'Yes'
        endif
        pcode=52
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dis_*') and (cp eq 0)) then begin
          eva_data_load_mms_fpi_ql_old, prb=prb, datatype='dis'
          answer = 'Yes'
        endif
        
        ;-------------
        ; FPI QL NEW
        ;-------------
        pcode=53
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_fpi_*') and ~PSEUDOMOM and (cp eq 0)) then begin
          eva_data_load_mms_fpi_ql, sc=sc
          answer = 'Yes'
        endif
        
        ;---------------
        ; FPI COMBINED
        ;---------------
        pcode=54
        ip=where(perror eq pcode,cp)
        if strmatch(paramlist[i],'*_fpi_com*') then begin
          eva_data_load_mms_fpi_com, sc=sc
          answer = 'Yes'
        endif
        
        
        ;-----------
        ; HPCA
        ;-----------
        pcode=60
        ip=where(perror eq pcode,cp)
        level = 'sitl'
        if (strmatch(paramlist[i],'*_hpca_*_omni_flux') and (cp eq 0)) then begin
          sh='H!U+!N'
          sa='He!U++!N'
          sp='He!U+!N'
          so='O!U+!N'
; egrimes updated for new combined datatype, 15April19
;          mms_sitl_get_hpca, probes=prb, level=level, datatype='rf_corr'
;          options, sc+'_hpca_hplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sh,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
;          ylim,    sc+'_hpca_hplus_RF_corrected', 1, 40000
;          options, sc+'_hpca_heplusplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sa,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
;          ylim,    sc+'_hpca_heplusplus_RF_corrected', 1, 40000
;          options, sc+'_hpca_heplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sp,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
;          ylim,    sc+'_hpca_heplus_RF_corrected', 1, 40000
;          options, sc+'_hpca_oplus_RF_corrected', ytitle=sc+'!CHPCA!C'+so,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
;          ylim,    sc+'_hpca_oplus_RF_corrected', 1, 40000
          
          
          mms_sitl_get_hpca, probes=prb, level=level, datatype='combined'
          options, sc+'_hpca_hplus_omni_flux', ytitle=sc+'!CHPCA!C'+sh,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_hplus_omni_flux', 1, 40000
          options, sc+'_hpca_heplusplus_omni_flux', ytitle=sc+'!CHPCA!C'+sa,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_heplusplus_omni_flux', 1, 40000
         ; options, sc+'_hpca_heplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sp,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
         ; ylim,    sc+'_hpca_heplus_RF_corrected', 1, 40000
          options, sc+'_hpca_oplus_omni_flux', ytitle=sc+'!CHPCA!C'+so,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_oplus_omni_flux', 1, 40000
          answer = 'Yes'
        endif
        
        pcode=61
        ip=where(perror eq pcode,cp)
        level = 'sitl'
        if( (cp eq 0) and $
          (strmatch(paramlist[i],'*_hpca_*number_density') or strmatch(paramlist[i],'*_hpca_*bulk_velocity'))) then begin
          eva_data_load_mms_hpca, prb=prb, level=level
          answer = 'Yes'
        endif

        ;-----------
        ; AE Index
        ;-----------
        pcode=80
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'thg_idx_ae') and (cp eq 0)) then begin
          thm_load_pseudoAE,datatype='ae'
          if tnames('thg_idx_ae') eq '' then begin
            store_data,'thg_idx_ae',data={x:[ts,te], y:replicate(!values.d_nan,2)}
          endif
          options,'thg_idx_ae',ytitle='THM!CAE'
          answer = 'Yes'
        endif
        
        ;-----------
        ; ExB
        ;-----------
        pcode=81
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_exb_fpi_*') and (cp eq 0)) then begin
          eva_data_load_mms_exb,sc=sc,vthres=1500.,/fpi
          answer = 'Yes'
        endif
        pcode=82
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_exb_hpca_*') and (cp eq 0)) then begin
          eva_data_load_mms_exb,sc=sc,vthres=1500.,/hpca
          answer = 'Yes'
        endif
        pcode=83
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_exb_dsl') and (cp eq 0)) then begin
          eva_data_load_mms_exb,sc=sc,vthres=1500.
          answer = 'Yes'
        endif
        
        ;------------
        ; SW
        ;------------
        pcode=84
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_sw_*') and (cp eq 0)) then begin
          eva_data_load_mms_sw,sc=sc
          answer = 'Yes'
        endif
        
        ;-----------
        ; Current 
        ;-----------
        pcode=85
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'mms_sitl_jtot_curl_b') and (cp eq 0)) then begin
          LOADED_4FGM = eva_data_load_mms_jtot(LOADED_4FGM=LOADED_4FGM,/curlB,no_gui=no_gui)
          answer = 'Yes'
        endif
        pcode=86
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'mms_sitl_diffb') and (cp eq 0)) then begin
          LOADED_4FGM = eva_data_load_mms_jtot(LOADED_4FGM=LOADED_4FGM,/diffB,no_gui=no_gui)
          answer = 'Yes'
        endif
        pcode=87
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'mms_sitl_jtot_combb') and (cp eq 0)) then begin
          LOADED_4FGM = eva_data_load_mms_jtot(LOADED_4FGM=LOADED_4FGM,/combB,no_gui=no_gui)
          answer = 'Yes'
        endif
        
      endif;if ct eq 0 then begin; if not loaded
      c+=1
    endfor; for each requested parameter
    
    ;-------------
    ; ORBIT INFO
    ;-------------
    matched=0
    Re = 6371.2
    ; predicted orbit from AFG
    tn=tnames(sc+'_ql_pos_gsm',jmax)
    if (strlen(tn[0]) gt 0) and (jmax eq 1) then begin
      get_data,sc+'_ql_pos_gsm',data=D,lim=lim,dl=dl
      wtime = D.x
      wdist = D.y[*,3]/Re
      wposx = D.y[*,0]/Re
      wposy = D.y[*,1]/Re
      wposz = D.y[*,2]/Re
      wphi  = atan(wposy,wposx)/!DTOR
      wxlt  = 12. + wphi/15.
      wlat  = atan(wposz,sqrt(wposx^2+wposy^2))/!DTOR
      matched=1
    endif
    
    if matched then begin
      store_data,sc+'_position_z',data={x:wtime,y:wposz}
      options,sc+'_position_z',ytitle=sc+' Zgsm (Re)'
      store_data,sc+'_position_y',data={x:wtime,y:wposy}
      options,sc+'_position_y',ytitle=sc+' Ygsm (Re)'
      store_data,sc+'_position_x',data={x:wtime,y:wposx}
      options,sc+'_position_x',ytitle=sc+' Xgsm (Re)'
      store_data,sc+'_position_r',data={x:wtime,y:wdist}
      options,sc+'_position_r',ytitle=sc+' R (Re)'
      store_data,sc+'_position_mlt',data={x:wtime,y:wxlt}
      options,sc+'_position_mlt',ytitle=sc+' MLT (hr)'
      store_data,sc+'_position_mlat',data={x:wtime,y:wlat}
      options,sc+'_position_mlat',ytitle=sc+' MLAT (deg)'
    endif
    
  endfor; for each requested probe
  
  if ~keyword_set(no_gui) then progressbar -> Destroy
  return, answer
END
