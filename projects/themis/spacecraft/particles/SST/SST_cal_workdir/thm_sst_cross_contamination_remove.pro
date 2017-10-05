
;+
;NAME:
; thm_sst_cross_contamination_remove,data_a,data_b
;
;PURPOSE:
;
;  At higher energies electrons will be present in SST ion data and ions will be present in SST electron data.
;  This uses a matrix approach based on modeled channel efficiencies to remove cross contamination.
;  
;SEE ALSO:
;  thm_sst_energy_cal2
;  moments_3d
;  conv_units
;  thm_sst_convert_units2
;  
;NOTES:
;  
;
;  $LastChangedBy: aaflores $
;  $LastChangedDate: 2012-01-10 10:57:33 -0800 (Tue, 10 Jan 2012) $
;  $LastChangedRevision: 9527 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_cross_contamination_remove.pro $
;-

pro print_mat,mat

  dim = dimen(mat)
  
  s='      '
  for i = 0,dim[0]-1 do begin
    if i lt 10 then begin  
      s += 'Ee'+strtrim(i,2) + '    '
    endif else if i lt 20 then begin
      s += 'Ei'+strtrim(i-10,2) + '    '
    endif else begin
      s += 'Ei'+strtrim(i-10,2) + '   '
    endelse
  endfor
  
  dprint, s
  
  for i = 0,dim[0]-1 do begin
    
    if i lt 10 then begin  
      s = 'Ce'+strtrim(i,2) + '  '
    endif else if i lt 20 then begin
      s = 'Ci'+strtrim(i-10,2) + '  '
    endif else begin
      s = 'Ci'+strtrim(i-10,2) + ' '
    endelse
    
    for j = 0,dim[1]-1 do begin
      s+= string(mat[i,j],format='(D6.3)') + ' '
    endfor
    dprint, s
  endfor

end


function randomp,avg,seed
counts = long(avg)
n= n_elements(avg)
for i=0ul,n-1 do begin
  counts[i] = round(randomn(seed,1,poisson=avg[i] > 1e-40,/double))
endfor
return,counts
end 

pro x_contam_test_load
  
  del_data,'*'
  
  thm_init
  timespan,'2009-11-11/00:00:00'
  !themis.no_download=1
  probe = 'e'
  
  thm_load_sst2,probe=probe
  thm_load_state,probe=probe,/get_support
  ;test full distribution
  thm_part_moments,probe=probe,inst='ps?f',moments='*',/sst_cal,tplotsuffix='_raw',method_clean='automatic',/f_o,/no_geom_factor,units='rate'
  thm_part_moments,probe=probe,inst='ps?f',moments='*',/sst_cal,tplotsuffix='_new',method_clean='automatic',/f_o,units='rate'
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_cal',method_clean='automatic',units='rate'
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_ft',/ft_ot,units='rate'
  thm_part_moments,probe=probe,inst='ps?f',moments='*',/sst_cal,tplotsuffix='_fto',/fto,units='rate'
end

;call this procedure to test the routine below, you'll need to update the path to point at the efficiency files
pro x_contam_test

  thm_init
  timespan,'2009-11-11/00:00:00'
  !themis.no_download=1
  probe = 'e'

  get_data,'th'+probe+'_psif_en_eflux_raw',data=di
  get_data,'th'+probe+'_psef_en_eflux_raw',data=de

  e_dat = thm_part_dist('th'+probe+'_psef',time_double('2009-11-11/06:00:00'),/sst_cal)
  p_dat = thm_part_dist('th'+probe+'_psif',time_double('2009-11-11/06:00:00'),/sst_cal)
  ;FTO
  get_data,'th'+probe+'_psef_en_eflux_fto',data=d_fto
  d_fto={x:d_fto.x,y:reform(d_fto.y[*,15]),v:reform(d_fto.v[*,15])}
  store_data,'th'+probe+'_psef_en_eflux_fto_line',data={x:d_fto.x,y:d_fto.y},dlimits={ylog:1}
  
  thm_sst_cross_contamination_remove,di,de,p_dat.en_low[*],p_dat.en_high[*],e_dat.en_low[*],e_dat.en_high[*],fto_data,out_mat=x_contam_mat
  tplot,['th'+probe+'_psif_en_eflux_new','proton_out','th'+probe+'_psef_en_eflux_new','electron_out']
  get_data,'th'+probe+'_psef_en_eflux_ft',data=de_ft
  
  ;create merged data with cross contamination removal
  get_data,'electron_out',data=de_out
  de_out.y[*,8:10]=de_ft.y[*,12:14]
  de_out.y[*,11:15]=0
  de_out.v[*,8:10]=de_ft.v[*,12:14]
  de_out.v[*,11:15]=max(de_out.v)
  store_data,'electron_out_merged',data=de_out,dlimit={spec:1,zlog:1,ylog:1}
  

  
  plot_vars = ['th'+probe+'_psif_en_eflux_new','proton_out','th'+probe+'_psef_en_eflux_new','electron_out','electron_out_merged','th'+probe+'_psef_en_eflux_cal','th'+probe+'_psef_en_eflux_fto_line']
  options,plot_vars,zrange=[1e1,1e7]
  tplot,plot_vars

;  get_data,'th'+probe+'_psif_en_eflux_new',data=di
;  get_data,'th'+probe+'_psef_en_eflux_new',data=de
;  
;  tmp = min(abs(di.x-time_double('2009-11-11/06:30:00')),idx_i)
;  tmp = min(abs(de.x-time_double('2009-11-11/06:30:00')),idx_e)
;  
;  tst_in = [reform(de.y[idx_e,0:9]),reform(di.y[idx_i,0:11])]
;  print,tst_in#x_contam_mat 
  stop
end

pro thm_sst_cross_contamination_remove,proton_data,electron_data,proton_energy_low,proton_energy_high,electron_energy_low,electron_energy_high,fto_data,out_mat=inv

  fileroot = '~/IDLWorkspace/themis/spacecraft/particles/SST/SST_cal_workdir/cal_files/'
  
  file_electron_foil = fileroot+'ElectronsFoilSideEfficiencies.txt'
  file_electron_open = fileroot+'ElectronsOpenSideEfficiencies.txt'
  file_proton_foil = fileroot+'ProtonsFoilSideEfficiencies.txt'
  file_proton_open = fileroot+'ProtonsOpenSideEfficiencies.txt'
  file_electron_open_gf=fileroot+'ElectronOpenGF.txt'
  file_fto_noise_scale = fileroot+'FTONoiseScale.txt'

  ef_eff_str = read_asc(file_electron_foil) 
  eo_eff_str = read_asc(file_electron_open)
  eo_gf_str = read_asc(file_electron_open_gf)
  pf_eff_str = read_asc(file_proton_foil)
  po_eff_str = read_asc(file_proton_open)
  ;fto_eff_str = read_asc(file_fto_noise_scale)

  ;geometric factor for each quadrant of the transfer matrix
  ef_gf=0.1
  pf_gf=0.1
  po_gf=0.1
  
  ;geometric factor for electron open quadrant is energy dependent
  eo_gf_en = eo_gf_str.(0)*1000 ;convert from MeV to KeV
  eo_gf_dat = eo_gf_str.(1)
  eo_gf_en = [min(eo_gf_en)*0.98,min(eo_gf_en)*0.99,eo_gf_en,max(eo_gf_en)*1.01,max(eo_gf_en)*1.02] ;pad ends for interpolation
  eo_gf_dat = [0,0,eo_gf_dat,max(eo_gf_dat),max(eo_gf_dat)]
  eo_gf = interpol(eo_gf_dat,eo_gf_en,(sqrt(electron_energy_high*electron_energy_low))[0:11])
  dim = 22
  transfer_matrix = dblarr(dim,dim) ;dim1/rows = channels,dim2/cols = energies
  
  ;electron foil quadrant
  for i = 0,9 do begin
    for j = 0,9 do begin
      ;old method, because it is essentially single point, can be hit or miss
      ;transfer_matrix[i,j] = interpol(ef_eff_str.(i+16),ef_eff_str.(0)*1000,electron_energies[j])
      
      ;new method integrates entire channel
      ;it would be faster to make the j loop the outer one to prevent recalculation of this quantity
      
      idx = where(ef_eff_str.(0) ge electron_energy_low[j] and ef_eff_str.(0) lt electron_energy_high[j],c)
      if c eq 0 then begin
        transfer_matrix[i,j] = 0
      endif else begin
        x=(ef_eff_str.(0))[idx]
        f=(ef_eff_str.(i+16))[idx]
        transfer_matrix[i,j] = total(deriv(x)*f)/total(deriv(x))*ef_gf
        ;transfer_matrix[i,j] = int_tabulated(x,f)/(max(x)-min(x))
      endelse
    endfor
    
  endfor
 
  ;electron open quadrant
  for i = 0,11 do begin
    for j = 0,9 do begin
      ;old method, because it is essentially single point, can be hit or miss
      ;transfer_matrix[i+10,j] = interpol(eo_eff_str.(i+1),eo_eff_str.(0)*1000,electron_energies[j])
      
        ;new method integrates entire channel
      ;it would be faster to make the j loop the outer one to prevent recalculation of this quantity
      idx = where(eo_eff_str.(0) ge electron_energy_low[j] and eo_eff_str.(0) lt electron_energy_high[j],c)
      if c eq 0 then begin
        transfer_matrix[i+10,j] = 0
      endif else begin
        x=(eo_eff_str.(0))[idx]
        f=(eo_eff_str.(i+1))[idx]
        transfer_matrix[i+10,j] = total(deriv(x)*f)/total(deriv(x))*eo_gf[j]
        ;transfer_matrix[i+10,j] = int_tabulated(x,f)/(max(x)-min(x))
      endelse
    endfor
  endfor
  
 ;proton foil quadrant
 for i = 0,9 do begin
    for j = 0,11 do begin
      ;old method, because it is essentially single point, can be hit or miss
      ;transfer_matrix[i,j+10] = interpol(pf_eff_str.(i+16),pf_eff_str.(0)*1000,proton_energies[j])
      
        ;new method integrates entire channel
      ;it would be faster to make the j loop the outer one to prevent recalculation of this quantity
      idx = where(pf_eff_str.(0) ge proton_energy_low[j] and pf_eff_str.(0) lt proton_energy_high[j],c)
      if c eq 0 then begin
        transfer_matrix[i,j+10] = 0
      endif else begin
        x=(pf_eff_str.(0))[idx]
        f=(pf_eff_str.(i+16))[idx]
        transfer_matrix[i,j+10] = total(deriv(x)*f)/total(deriv(x))*pf_gf
        ;transfer_matrix[i,j+10] = int_tabulated(x,f)/(max(x)-min(x))
      endelse
    endfor
  endfor
 
  ;proton open quadrant
  for i = 0,11 do begin
    for j = 0,11 do begin
      ;old method, because it is essentially single point, can be hit or miss
      ;transfer_matrix[i+10,j+10] = interpol(po_eff_str.(i+1),po_eff_str.(0)*1000,proton_energies[j])
      
      ;new method integrates entire channel
      ;it would be faster to make the j loop the outer one to prevent recalculation of this quantity
      idx = where(po_eff_str.(0) ge proton_energy_low[j] and po_eff_str.(0) lt proton_energy_high[j],c)
      if c eq 0 then begin
        transfer_matrix[i+10,j+10] = 0
      endif else begin
        x=(po_eff_str.(0))[idx]
        f=(po_eff_str.(i+1))[idx]
        transfer_matrix[i+10,j+10] = total(deriv(x)*f)/total(deriv(x))*po_gf
        ;transfer_matrix[i+10,j+10] = int_tabulated(x,f)/(max(x)-min(x))
      endelse
    endfor
  endfor
  
;  idx = where(transfer_matrix lt 0.0001,c)
;  if c gt 0 then begin
;    transfer_matrix[idx] = 0
;  endif
  
  ;percentage noise
  noise=0.05
  
  ;absolute noise
  ;count=50
  
  ;seed for random # generation
  ;seed=0l
  ;seed=1
  
  print_mat,transfer_matrix
  n=256
  err_data=dblarr(22,n)
  trn=transfer_matrix
  inv = invert(transfer_matrix)
  tst = [exp(reverse(dindgen(10)+1)),exp(reverse(dindgen(12)+1))]
  for i=0,n-1 do begin
    cnt = trn##tst ;## is the operator for the matrix operator that works like in math
    res = inv##randomp(cnt,seed)
    err_data[*,i]=1-res/tst
  endfor

  err_avg = dblarr(22)
  err_sdev=dblarr(22)
  err_max=dblarr(22)

  for i=0,21 do begin
    err_avg[i] = average(abs(err_data[i,*]),/double)
    err_sdev[i] = stddev(abs(err_data[i,*]),/double)
    err_max[i] = max(err_data[i,*],/absolute)
  endfor

 ; res = inv#((trn#tst)*(1+randomn(seed,dim)*noise)) ;percentage noise
  ;res = inv#((trn#tst)+(count*randomn(seed,dim))) ;absolute noise
  ;dprint, res/tst
  
  ;dprint, 'AVG:',err_avg
  ;dprint, 'SDEV:',err_sdev
  ;dprint, 'MAX:',err_max
  ;stop  

  dprint, 'Ch#:'+string(9B)+'Avg:    '+string(9B)+ 'Stdev:     ' + string(9B)+ 'Max'
  for i = 0,dim[0]-1 do begin
    if i lt 10 then begin  
      dprint, 'Ee'+strtrim(i,2) + ',' + string(9B) + strtrim(err_avg[i],2) + ',' + string(9B) + strtrim(err_sdev[i],2) + ',' + string(9B) + strtrim(err_max[i],2) 
    endif else begin
      dprint, 'Ei'+strtrim(i-10,2) + ',' + string(9B) + strtrim(err_avg[i],2) + ',' + string(9B)+ strtrim(err_sdev[i],2) + ',' + string(9B) + strtrim(err_max[i],2) 
    endelse
  endfor

  tinterpol_mxn,proton_data,electron_data.x,out=proton_data_interp
  ;tinterpol_mxn,fto_data,electron_data.x,out=fto
 

  ;noise factors from Drew
  ;only valid if attenuator is enabled
  ftoeEffGF = [0.0005, 0.001, 0.001, 0.001, 0.002, 0.0025, 0.003, 0.004, 0.005, 0.014, 0.015] ; Attenuator GF and efficiencies ONLY VALID WHEN ATTENUATOR IS DOWN!
       
  ftoiEffGF = [0.0005, 0.001, 0.001, 0.001, 0.002, 0.0025, 0.003, 0.004, 0.006, 0.004, 0.001, 0.001] 
  
  ;fto_eff = fto_eff_str.(1)
  fto_eff = [ftoeEffGF[0:9],ftoiEffGF[0:11]]
  
  ;energy of each channel
  en_data=transpose([(sqrt(electron_energy_high*electron_energy_low))[0:9],(sqrt(proton_energy_high*proton_energy_low))[0:11]]#(dblarr((dimen(electron_data.x))[0])+1))
  ;delta energy of each channel
  den_data = transpose([(electron_energy_high-electron_energy_low)[0:9],(proton_energy_high-proton_energy_low)[0:11]]#(dblarr((dimen(electron_data.x))[0])+1))
  ;data prior to noise removal
  in_data=[[electron_data.y[*,0:9]],[proton_data_interp.y[*,0:11]]]
  noise_removed_data=in_data-fto_data.y#fto_eff
  out_data=(inv##(noise_removed_data_data)) 
  
  electron_data.y[*,0:9]=out_data[*,0:9]
  electron_data.y[*,10:15]=0
  proton_data_interp.y[*,0:11]=out_data[*,10:21]
  proton_data_interp.y[*,12:15]=0
  
  store_data,'electron_out',data=electron_data,dlimit={zlog:1,ylog:1,spec:1}
  store_data,'proton_out',data=proton_data_interp,dlimit={zlog:1,ylog:1,spec:1}
  
  tmp = min(abs(proton_data_interp.x-time_double('2009-11-11/06:30:00')),idx)

  ;det = (ion.eff_i*electron.eff_e-electron.eff_i*ion.eff_e)
  
  ;ion_flux      = (1.0d/det)*(electron.eff_e*ion.data-electron.eff_i*electron.data)
  ;electron_flux = (1.0d/det)*(-ion.eff_e*ion.data+ion.eff_i*electron.data)

  ;ion.data=ion_flux
  ;electron.data=electron_flux
  
;  n=2048
;  o=dblarr(n)
;  for i=0,n-1 do begin
;    s=i
;    o[i]=randomu(s,1)
;  endfor
end