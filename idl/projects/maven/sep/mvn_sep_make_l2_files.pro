; the purpose of this routine is to deconvolve the data and make level 2 CDF files.
; It assumes that sep?_svy has already been loaded

pro mvn_sep_make_l2_files,pathnames=pathnames,trange=trange, filename = filename

  common mav_apid_sep_handler_com , sep_all_ptrs,  sep1_hkp,sep2_hkp,sep1_svy,sep2_svy,sep1_arc,sep2_arc,sep1_noise,sep2_noise ,sep1_memdump,sep2_memdump

  trange = timerange(trange)
;res = 86400.d
;days =  round( time_double(trange )/res)
;ndays = days[1]-days[0]
;tr = days * res
 
  ;dprint,/phelp,mapids
  ;     mapids=mapnums   ; do only most common one  
  
  ndays=1
  if not keyword_set(pathname) then pathname =  'maven/pfp/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_$NDAY.sav' 
  pn = str_sub(pathname, '$NDAY', strtrim(ndays,2) +'day')
  files = mvn_pfp_file_retrieve(pn,/daily,trange=trange,source=source,verbose=verbose,/valid_only,no_update=0,last_version=0)
  
  mvn_sep_handler,/clear
for i=0,n_elements(files)-1 do begin

  undefine, s1_hkp,s1_svy,s1_arc,s1_nse
  undefine, s2_hkp,s2_svy,s2_arc,s2_nse
  restore,verbose=verbose,filename=files[i]
  mav_gse_structure_append  ,sep1_hkp  , s1_hkp
  mav_gse_structure_append  ,sep1_svy  , s1_svy
  mav_gse_structure_append  ,sep1_arc  , s1_arc
  mav_gse_structure_append  ,sep1_noise, s1_nse
  mav_gse_structure_append  ,sep2_hkp  , s2_hkp
  mav_gse_structure_append  ,sep2_svy  , s2_svy
  mav_gse_structure_append  ,sep2_arc  , s2_arc
  mav_gse_structure_append  ,sep2_noise, s2_nse
  mav_gse_structure_append  ,mag1_hkp  , m1_hkp
  mav_gse_structure_append  ,mag2_hkp  , m2_hkp
  
endfor
  
  
  sepn = [1,2]
  for J = 0, 1 do begin
  data_str = 'mvn_sep'+roundst(sepn[j]) +'_svy'
  mvn_sep_extract_data,data_str,rawdat,trange=trange,num=num
  if keyword_set(rawdat) eq 0 then return
  mapnums = byte(median(rawdat.mapid))    ;  get most common mapnum
  mapids = where( histogram(rawdat.mapid) ne 0 ,n_mapids)   ; all mapids found
 
  for i = 0,n_elements(mapids)-1 do begin
     mapnum = mapids[i]
     if mapnum eq 0 then continue
     tname = 'mvn_sep'+strtrim(sepn[J],2)
     mapname = mvn_sep_mapnum_to_mapname(mapnum)
     wt = where(rawdat.mapid eq mapnum or finite(rawdat.time) eq 0,nt)   ; include gaps
     t = rawdat[wt].time
     dt = rawdat[wt].duration
     att_state = rawdat[wt].ATT
     ;geom = geoms[att_state]
     all_counts = transpose(rawdat[wt].data)
     value = findgen(256)
     bmaps = mvn_sep_lut2map(mapnum=mapnum)
     mvn_sep_det_cal,bmaps,sepn[J],units=1    
     level_2_now = mvn_sep_deconvolve_data(bmaps, rawdat[wt], nofit =1, /no_plot, $
                                           output_electron_energies = l2_electron_energies, $
                                           output_ion_energies = l2_ion_energies)
     if i eq 0 then level_2 = level_2_now else level_2 = [level_2, level_2_now]
   endfor
   if J eq 0 then sep1_l2= level_2 else sep2_l2 = level_2
   endfor
   
   sep_dataa = {time:sep1_l2[0].TIME, MET: sep1_l2[0].met, ET: sep1_l2[0].et,Delta_time:0, atten_state:fltarr(4), $
                         electron_energy_flux:replicate(1.0, 4)#$
                         reform (sep1_l2[0].electron_eflux_front), $
                         ion_energy_flux: replicate (1.0, 4)#reform (sep1_l2[0].ion_eflux_front), $
                         look_directions: fltarr(4,3)}
; now combine SEP 1 and SEP 2
   nt_sep1 = n_elements (sep1_l2.time)
   nt_sep2 = n_elements (sep2_l2.time)
   if nt_sep1 ne nt_sep2 then stop
   sep_data = replicate (sep_dataa,nt_sep1)
            
; add the look directions, 
   look_directions = mvn_sep_look_directions(sep1_l2.time, coordinate_frame ='MAVEN_SSO',/load)
   
            for J = 0, nt_sep1-1 do begin
                sep_data[j].time= sep1_l2[j].time
                sep_data[j].MET = sep1_l2[j].MET
                
                sep_data[j].Delta_time = sep1_l2[J].delta_time
                sep_data[J].atten_state[0:1] = [1,1]#sep1_l2[J].atten_state
                sep_data[J].atten_state[2:3] = [1,1]#sep2_l2[J].atten_state
                sep_data[j].electron_energy_flux[0,*] = sep1_l2[J].electron_eflux_front
                sep_data[j].electron_energy_flux[1,*] = sep1_l2[J].electron_eflux_back
                sep_data[j].electron_energy_flux[2,*] = sep2_l2[J].electron_eflux_front
                sep_data[j].electron_energy_flux[3,*] = sep2_l2[J].electron_eflux_back
                sep_data[j].ion_energy_flux[0,*] = sep1_l2[J].ion_eflux_front
                sep_data[j].ion_energy_flux[1,*] = sep1_l2[J].ion_eflux_back
                sep_data[j].ion_energy_flux[2,*] = sep2_l2[J].ion_eflux_front
                sep_data[j].ion_energy_flux[3,*] = sep2_l2[J].ion_eflux_back
                                ; NOTE: this is a placeholder for the look directions!!
                sep_data[j].look_directions = look_directions [J,*,*]
            endfor  
            sep_info = {electron_energy: l2_electron_energies, ion_energy: l2_ion_energies}
; NOW make             the CDF FILES
            ;file = '~/work/maven/data_analysis/mvn_sep_l2_spec_20140326_v002_r001.cdf'
             if not keyword_set(pathname) then pathname =  'maven/pfp/sep/l2/sav/YYYY/MM/mvn_sep_l2_YYYYMMDD_$NDAY.sav' 
             pn = str_sub(pathname, '$NDAY', strtrim(ndays,2)+'day')
             if not keyword_set (filename) then filename = $
               mvn_pfp_file_retrieve(pn,/daily,trange=trange[0],source=source,verbose=verbose,/create_dir)
            ;filename = '~/work/maven/data_analysis/mvn_sep_l2_spec_20140512_v002_r001.cdf'
            mvn_sep_make_l2_cdf, sep_data, sep_info,file = filename
   
end




