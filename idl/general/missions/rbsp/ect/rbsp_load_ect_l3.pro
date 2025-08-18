;+
; NAME: rbsp_load_ect_l3
;
; SYNTAX:
;
;       timespan,'2012-10-13'
;       rbsp_load_ect_l3,'a','mageis'
;
; PURPOSE: Fetches and loads RBSP ECT (hope, mageis, rept) particle data
;
; INPUT: N/A
;
; OUTPUT: N/A
;
; KEYWORDS:
;	probe ->  'a' or 'b'
;       type  ->  'hope','mageis','rept'
;       get_support_data -> if not set then only the essentials are
;       saved
;
; HISTORY:
;	Created Jan 2015, Aaron Breneman
;
; NOTES:
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2018-12-06 10:48:41 -0800 (Thu, 06 Dec 2018) $
;   $LastChangedRevision: 26267 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/ect/rbsp_load_ect_l3.pro $
;
;-


pro rbsp_load_ect_l3,probe,type,get_support_data=get_support_data

  rbsp_ect_init
  p_var = probe

  ;  if keyword_set(probe) then p_var=probe else p_var='*'
  vprobes = ['a','b']
  p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

  level=3
  slevel=string(level,format='(I0)')

  for p=0,size(p_var,/n_elements)-1 do begin

    rbspx = 'rbsp'+ p_var[p]

    tr = timerange()
    date = time_string(tr[0],/date_only,tformat='YYYYMMDD')
    yyyy = strmid(date,0,4)

    if type eq 'mageis' then begin

      prefix=rbspx+'_ect_mageis_L'+slevel+'_'
      dprint,dlevel=3,verbose=verbose,relpathnames,/phelp

      rp = !rbsp_ect.remote_data_dir + rbspx+'/mageis/level3/pitchangle/'+yyyy+'/'
      rf = rbspx+'_rel04_ect-mageis-L3_'+date+'_v*.cdf'
      files = spd_download(remote_path=rp,remote_file=rf,$
      local_path=!rbsp_ect.local_data_dir+'mageis/L3/',$
       /last_version)



      cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
      tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

      if ~keyword_set(get_support_data) then begin
        del = [rbspx+'_ect_mageis_L3_FEDU_Energy_DELTA_minus',$
        rbspx+'_ect_mageis_L3_FEDU_Energy_DELTA_plus',$
        rbspx+'_ect_mageis_L3_FEDU_PA_LABL',$
        rbspx+'_ect_mageis_L3_FEDU_ENERGY_LABL',$
        rbspx+'_ect_mageis_L3_SQRT_COUNTS',$
        rbspx+'_ect_mageis_L3_FPDU_ENERGY_LABL',$
        rbspx+'_ect_mageis_L3_FPDU_Energy_DELTA_minus',$
        rbspx+'_ect_mageis_L3_FPDU_Energy_DELTA_plus',$
        rbspx+'_ect_mageis_L3_FPDU_PA_LABL',$
        rbspx+'_ect_mageis_L3_L_star',$
        rbspx+'_ect_mageis_L3_L',$
        rbspx+'_ect_mageis_L3_I',$
        rbspx+'_ect_mageis_L3_B_Calc',$
        rbspx+'_ect_mageis_L3_B_Eq',$
        rbspx+'_ect_mageis_L3_MLT',$
        rbspx+'_ect_mageis_L3_MLAT',$
        rbspx+'_ect_mageis_L3_Position',$
        rbspx+'_ect_mageis_L3_LstarVsAlpha',$
        rbspx+'_ect_mageis_L3_LstarVsAlpha_Alpha']

        store_data,del,/delete
      endif


    endif

    if type eq 'hope' then begin

      prefix=rbspx+'_ect_hope_L'+slevel+'_'
      dprint,dlevel=3,verbose=verbose,relpathnames,/phelp

stop

      rp = !rbsp_ect.remote_data_dir + rbspx+'/hope/level3/moments/'+yyyy+'/'
      rf = rbspx+'_rel04_ect-hope-MOM-L3_'+date+'_v*.cdf'
      files = spd_download(remote_path=rp,remote_file=rf,$
      local_path=!rbsp_ect.local_data_dir+'hope/L3/',$
       /last_version)

      cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
      tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables


      rp = !rbsp_ect.remote_data_dir + rbspx+'/hope/level3/pitchangle/'+yyyy+'/'
      rf = rbspx+'_rel04_ect-hope-PA-L3_'+date+'_v*.cdf'
      files = spd_download(remote_path=rp,remote_file=rf,$
      local_path=!rbsp_ect.local_data_dir+'hope/L3/',$
       /last_version)


      cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
      tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

      if ~keyword_set(get_support_data) then begin
        del = [rbspx+'_ect_hope_L3_B_Calc_Ele',$
        rbspx+'_ect_hope_L3_B_Calc_Ion',$
        rbspx+'_ect_hope_L3_B_Eq_Ele',$
        rbspx+'_ect_hope_L3_B_Eq_Ion',$
        rbspx+'_ect_hope_L3_ENERGY_Ele_DELTA',$
        rbspx+'_ect_hope_L3_ENERGY_Ion_DELTA',$
        rbspx+'_ect_hope_L3_Flags_Ele',$
        rbspx+'_ect_hope_L3_Flags_Ion',$
        rbspx+'_ect_hope_L3_HOPE_ENERGY_Ele',$
        rbspx+'_ect_hope_L3_HOPE_ENERGY_Ion',$
        rbspx+'_ect_hope_L3_I_Ele',$
        rbspx+'_ect_hope_L3_I_Ion',$
        rbspx+'_ect_hope_L3_L_Ele',$
        rbspx+'_ect_hope_L3_L_Ion',$
        rbspx+'_ect_hope_L3_L_star_Ele',$
        rbspx+'_ect_hope_L3_L_star_Ion',$
        rbspx+'_ect_hope_L3_MLT_Ele',$
        rbspx+'_ect_hope_L3_MLT_Ion',$
        rbspx+'_ect_hope_L3_Position_Ele',$
        rbspx+'_ect_hope_L3_Position_Ion',$
        rbspx+'_ect_hope_L3_Mode_Ion',$
        rbspx+'_ect_hope_L3_Mode_Ele',$
        rbspx+'_ect_hope_L3_Counts_E_Omni',$
        rbspx+'_ect_hope_L3_Counts_E',$
        rbspx+'_ect_hope_L3_Counts_He_Omni',$
        rbspx+'_ect_hope_L3_Counts_He',$
        rbspx+'_ect_hope_L3_Counts_O_Omni',$
        rbspx+'_ect_hope_L3_Counts_O',$
        rbspx+'_ect_hope_L3_Counts_P_Omni',$
        rbspx+'_ect_hope_L3_Counts_P',$
        rbspx+'_ect_hope_L3_Ele_SAMPLES_Omni',$
        rbspx+'_ect_hope_L3_Ele_SAMPLES',$
        rbspx+'_ect_hope_L3_Ion_SAMPLES_Omni',$
        rbspx+'_ect_hope_L3_Ion_SAMPLES',$
        rbspx+'_ect_hope_L3_B_Eq',$
        rbspx+'_ect_hope_L3_Dens_e_200',$
        rbspx+'_ect_hope_L3_Dens_he_30',$
        rbspx+'_ect_hope_L3_Dens_o_30',$
        rbspx+'_ect_hope_L3_Dens_p_30',$
        rbspx+'_ect_hope_L3_I',$
        rbspx+'_ect_hope_L3_L',$
        rbspx+'_ect_hope_L3_L_star',$
        rbspx+'_ect_hope_L3_MLT',$
        rbspx+'_ect_hope_L3_Position']

        store_data,del,/delete

      endif

    endif

    if type eq 'rept' then begin

      prefix=rbspx+'_ect_rept_L'+slevel+'_'
      dprint,dlevel=3,verbose=verbose,relpathnames,/phelp

      rp = !rbsp_ect.remote_data_dir + rbspx+'/rept/level3/pitchangle/'+yyyy+'/'
      rf = rbspx+'_rel03_ect-rept-sci-L3_'+date+'_v*.cdf'
      files = spd_download(remote_path=rp,remote_file=rf,$
      local_path=!rbsp_ect.local_data_dir+'rept/L3/',$
       /last_version)

      cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
      tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables




      if ~keyword_set(get_support_data) then begin

        del = [rbspx+'_ect_rept_L3_FEDU_Unbinned_Alpha_DELTA',$
        rbspx+'_ect_rept_L3_FEDU_Unbinned_Alpha',$
        rbspx+'_ect_rept_L3_FEDU_Unbinned_Alpha360',$
        rbspx+'_ect_rept_L3_FPDU_Unbinned_Alpha_DELTA',$
        rbspx+'_ect_rept_L3_FPDU_Unbinned_Alpha',$
        rbspx+'_ect_rept_L3_FPDU_Unbinned_Alpha360',$
        rbspx+'_ect_rept_L3_FEDU_PA_LABL',$
        rbspx+'_ect_rept_L3_FEDU_PA_0TO180_LABL',$
        rbspx+'_ect_rept_L3_FEDU_PA_180TO360_LABL',$
        rbspx+'_ect_rept_L3_FEDU_ENERGY_LABL',$
        rbspx+'_ect_rept_L3_FPDU_PA_LABL',$
        rbspx+'_ect_rept_L3_FPDU_PA_0TO180_LABL',$
        rbspx+'_ect_rept_L3_FPDU_PA_180TO360_LABL',$
        rbspx+'_ect_rept_L3_FPDU_ENERGY_LABL',$
        rbspx+'_ect_rept_L3_L_star',$
        rbspx+'_ect_rept_L3_L',$
        rbspx+'_ect_rept_L3_I',$
        rbspx+'_ect_rept_L3_B_Calc',$
        rbspx+'_ect_rept_L3_B_Eq',$
        rbspx+'_ect_rept_L3_MLT',$
        rbspx+'_ect_rept_L3_MLAT',$
        rbspx+'_ect_rept_L3_Position']

        store_data,del,/delete
      endif
    endif

  endfor
end
