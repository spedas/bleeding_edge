pro mvn_lpw_prd_iv_read_in_structure,dir_name,boom


;exmaple how to read in data from out IV structures

 ;  st='10'
 ;                  ;added  mvn_lpw_load, '2015-01-'+st,filetype='L0', tplot_var='all',packet=['noHSBM']
 ; la_read_in_structure,'/spg/maven/test_products/cmf_temp/filled_lpstruc11/fitstruc_filled_2015-01-11_b1.sav',1
 ; la_read_in_structure,'/Volumes/spg/maven/test_products/cmf_temp/filled_lpstruc4/fitstruc_filled_2015-01-'+st+'_b2.sav',2
 


  print,dir_name
 

 restore,filename=dir_name
  
 st='_'+strcompress(boom,/remove_all) 
  
 ;-------------------------------
  
 ; help,fitstruc.lpstruc.anc,/st
  store_data,'da_posx'+st,   data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.anc.mso_pos.x}
  store_data,'da_posy'+st,   data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.anc.mso_pos.y}
  store_data,'da_posz'+st,   data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.anc.mso_pos.z}
  store_data,'da_alt'+st,    data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.anc.mso_pos.alt}
  store_data,'da_alt_iau'+st,    data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.anc.alt_iau}
  store_data,'da_shadow'+st, data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.anc.MARS_SHADOW}
  store_data,'da_wn_Nen'+st, data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.wn.n}
  store_data,'da_wn_Ne'+st,  data={x:fitstruc.lpstruc.time,y: [[fitstruc.lpstruc.wn.n],[fitstruc.lpstruc.wn.n-fitstruc.lpstruc.wn.nlow],[fitstruc.lpstruc.wn.n+fitstruc.lpstruc.wn.nupp]]}

 ;-------------------------------
 
 ;  help,fitstruc.lpstruc.fit_mm,/st


; error in the structure

fitstruc.lpstruc.fit_mm = mvn_lpw_prd_lp_n_t_clean_swp_pp(fitstruc.lpstruc.fit_mm,/addUsc)

 flag=(fitstruc.lpstruc.fit_mm.flg GE 0) 

 ; store_data,'mm_Vsc'+st,data={x:fitstruc.lpstruc.time,y:-1.0*[[fitstruc.lpstruc.fit_mm.U0],    [fitstruc.lpstruc.fit_mm.U0*0.8],    [fitstruc.lpstruc.fit_mm.U0*1.2]] }
 
  dVsc=fitstruc.lpstruc.fit_mm.dUsc > (0.2)
  store_data,'mm_Vsc'+st,data={x:fitstruc.lpstruc.time,y: -1.0*[[fitstruc.lpstruc.fit_mm.Usc      /flag], $
                                                               [(fitstruc.lpstruc.fit_mm.Usc-dVsc)/flag], $
                                                               [(fitstruc.lpstruc.fit_mm.Usc+dVsc)/flag]]}

;dNe=fitstruc.lpstruc.fit_mm.dNe1+fitstruc.lpstruc.fit_mm.dNe2
 dNe=fitstruc.lpstruc.fit_mm.dNe_tot
  store_data,'mm_Ne'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*[[fitstruc.lpstruc.fit_mm.Ne_tot/flag], $
                                                               [(fitstruc.lpstruc.fit_mm.Ne_tot-dNe)/flag], $
                                                               [(fitstruc.lpstruc.fit_mm.Ne_tot+dNe)/flag]]}
 dTe=fitstruc.lpstruc.fit_mm.dte
  store_data,'mm_Te'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*[[fitstruc.lpstruc.fit_mm.TE/flag],   $
                                                               [(fitstruc.lpstruc.fit_mm.TE-dTe)/flag],   $
                                                               [(fitstruc.lpstruc.fit_mm.TE+dTe)/flag]]}


  store_data,'mm_V0'+st,data={x:fitstruc.lpstruc.time,y:-1.0*fitstruc.lpstruc.fit_mm.U0/ flag}    ; this is flipped sign so Iit can be compared with the IV data

  store_data,'mm_Vscn'+st,data={x:fitstruc.lpstruc.time,y:-1.0*fitstruc.lpstruc.fit_mm.Usc/   flag}    ; this is flipped sign so Iit can be compared with the IV data
  store_data,'mm_Nen'+st ,data={x:fitstruc.lpstruc.time,y:     fitstruc.lpstruc.fit_mm.Ne_tot/flag}
  store_data,'mm_Ten'+st ,data={x:fitstruc.lpstruc.time,y:     fitstruc.lpstruc.fit_mm.TE/   flag}


  store_data,'mm_ni'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*  fitstruc.lpstruc.fit_mm.ni}
  store_data,'mm_vi'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*fitstruc.lpstruc.fit_mm.vi}
  store_data,'mm_ti'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*fitstruc.lpstruc.fit_mm.ti}
  store_data,'mm_mi'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*fitstruc.lpstruc.fit_mm.mi}


 store_data,'mm_flag'+st ,data={x:fitstruc.lpstruc.time,y: 1.0*fitstruc.lpstruc.fit_mm.flg}


 options,'mm_Vsc'+st,colors=[2,3,3]
 options,'mm_Ne'+st,colors=[2,3,3]
 options,'mm_Te'+st,colors=[2,3,3]
  
  
;;  stanna
 ;-------------------------------
 
 
 ; help,fitstruc.lpstruc.ree.val,/st
  store_data,'ree_Vsc'+st,data={x:fitstruc.lpstruc.time,y:-1.0*[[fitstruc.lpstruc.ree.val.Vsc],[fitstruc.lpstruc.ree.val.Vsc+fitstruc.lpstruc.ree.err.vsc],[fitstruc.lpstruc.ree.val.Vsc-fitstruc.lpstruc.ree.err.vsc]]}
  options,'ree_Vsc'+st,colors=[6,4,4]
 
; stanna
 flag= 1.0/(fitstruc.lpstruc.ree.val.erra LT 100)
 corr=1.0/(fitstruc.lpstruc.ree.val.Vsc NE 0)
 dVsc=1.0*0.2  ;fitstruc.lpstruc.ree.val.Vsc

  store_data,'ree_Vsc'+st ,data={x:fitstruc.lpstruc.time,y:  -1.0*[[fitstruc.lpstruc.ree.val.Vsc*corr], $
                                                                   [(fitstruc.lpstruc.ree.val.Vsc-dVsc)*corr],  $
                                                                   [(fitstruc.lpstruc.ree.val.Vsc+dVsc)*corr]]}
  store_data,'ree_Vscn'+st,data={x:fitstruc.lpstruc.time,y:  -1.0*flag*fitstruc.lpstruc.ree.val.Vsc} ; this is flipped sign so Iit can be compared with the IV data
 
 dNe=abs(fitstruc.lpstruc.ree.val.n*0.3) ;fitstruc.lpstruc.ree.err.n
  store_data,'ree_Ne'+st  ,data={x:fitstruc.lpstruc.time,y:   1e-6*[[fitstruc.lpstruc.ree.val.n*corr],   $
                                                                    [fitstruc.lpstruc.ree.val.n  -dNe*corr], $
                                                                    [fitstruc.lpstruc.ree.val.n  +dNe*corr]] }
 
  store_data,'ree_Nen'+st ,data={x:fitstruc.lpstruc.time,y:   1e-6*flag*fitstruc.lpstruc.ree.val.n} 
 
 ; not used dTe= abs(fitstruc.lpstruc.ree.err.Te)
  store_data,'ree_Te'+st  ,data={x:fitstruc.lpstruc.time,y:     [[ fitstruc.lpstruc.ree.val.Te],  $
                                                                 [ fitstruc.lpstruc.ree.err.telow], $
                                                                 [ fitstruc.lpstruc.ree.err.teupp]] }

  store_data,'ree_Ten'+st ,data={x:fitstruc.lpstruc.time,y:          flag* fitstruc.lpstruc.ree.val.Te } 
  
  
   store_data,'ree_Tpoints'+st ,data={x:fitstruc.lpstruc.time,y: fitstruc.lpstruc.ree.err.nptte }

 ; stanna
  ; fitstruc.lpstruc.ree.err.Teupp   - actualvalues
  ; fitstruc.lpstruc.ree.err.Telow - actualvalues
  ; fitstruc.lpstruc.ree.val.Te - actualvalues
  ; fitstruc.lpstruc.ree.err.nptste  - number of points in the fit
  
  
  store_data,'ree_ti'+st ,data={x:fitstruc.lpstruc.time,y :    [[fitstruc.lpstruc.ree.val.ti], [fitstruc.lpstruc.ree.val.ti +fitstruc.lpstruc.ree.err.ti], [(fitstruc.lpstruc.ree.val.ti -fitstruc.lpstruc.ree.err.ti)>0.01]]}
  store_data,'ree_mi'+st ,data={x:fitstruc.lpstruc.time,y :1.0/1.67e-27*  fitstruc.lpstruc.ree.val.mi } ;], [fitstruc.lpstruc.ree.val.mi +fitstruc.lpstruc.ree.err.mi], [fitstruc.lpstruc.ree.val.mi -fitstruc.lpstruc.ree.err.mi]]}
  store_data,'ree_ni'+st ,data={x:fitstruc.lpstruc.time,y :        fitstruc.lpstruc.ree.val.n}
  store_data,'ree_ramv'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.ramv}
  store_data,'ree_rama'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.rama}
  store_data,'ree_fov'+st ,data={x:fitstruc.lpstruc.time,y :       fitstruc.lpstruc.ree.val.fov}
  store_data,'ree_alpha'+st ,data={x:fitstruc.lpstruc.time,y :     fitstruc.lpstruc.ree.val.alpha}
  store_data,'ree_nhot'+st ,data={x:fitstruc.lpstruc.time,y :       1e-6* fitstruc.lpstruc.ree.val.nhot}
  store_data,'ree_thot'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.thot}
  store_data,'ree_nspe'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.nspe}
  store_data,'ree_tspe'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.tspe}
  store_data,'ree_jphe'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.jphe}
 
 tmpx=fitstruc.lpstruc.data.iswp
 nn=n_elements(tmpx[0,*])
 tmp=fltarr(nn)
 for i=0,nn-1 do tmp[i]=max(tmpx[*,i]) GT 1.e-6
; max(data.isweep) > 1e-6  for the error
  store_data,'ree_erra'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.erra}  ; s+500*tmp}   ;is this fit quality??
 
 
  ;vswp1[*,128]   <= fitstruc.lpstruc.data.vswp / iswp
  
  tmp=fltarr(n_elements( fitstruc.lpstruc.data.vswp[0,*]),128)
  for i=0,127 do tmp[*,i]=fitstruc.lpstruc.data.vswp[i,*]
  store_data,'ree_vswp'+st ,data={x:fitstruc.lpstruc.time,y :      tmp}
 ;iswp1[*,128]
 tmp=fltarr(n_elements( fitstruc.lpstruc.data.iswp[0,*]),128)
 for i=0,127 do tmp[*,i]=fitstruc.lpstruc.data.iswp[i,*]
  store_data,'ree_iswp'+st ,data={x:fitstruc.lpstruc.time,y :     tmp}
 ;valid1[*]   <= fitstruc.lpstruc.ree.val.valid
  store_data,'ree_valid'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.valid}

 
  ;store_data,'ree_uvi'+st ,data={x:fitstruc.lpstruc.time,y :      fitstruc.lpstruc.ree.val.uvi}   ;is this fit quality??
 
  
 options,'ree_Vsc'+st,colors=[6,4,4] 
 options,'ree_Ne'+st,colors=[6,4,4]
 options,'ree_Te'+st,colors=[6,4,4]
 options,'ree_ti'+st,colors=[2,3,3]
 options,'ree_ramv'+st,ystyle=1
 options,'ree_ramv'+st,yrange=[3800,4300]
 options,'ree_Ne'+st,ylog=1
 options,'ree_Vsc'+st,yrange=[-6,6]
 options,'ree_Ne'+st,yrange=[20,4e5]
 options,'ree_Ne'+st,ystyle=1
 options,'ree_ti'+st,ylog=1
 options,'ree_Te'+st,ylog=1
 options,'ree_ti'+st,ystyle=1
 options,'ree_Te'+st,ystyle=1
 options,'ree_ti'+st,yrange=[0.05,10.]
 options,'ree_Te'+st,yrange=[0.05,10.]
 options,'ree_t'+st,yrange=[0.05,10.]
 store_data,'ree_t'+st,data=['ree_Te'+st,'ree_ti'+st]
 options,'ree_t'+st,yrange=[0.05,100.]
  



end