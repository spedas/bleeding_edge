pro mvn_lpw_ql_instr_page
 
  options,'mvn_lpw_euv','psym',1
  options,'mvn_lpw*temp*','psym',1
  options,'mvn_lpw_hsk_temp','yrange',[-60,100]
  
  store_data,'modes',data=['mvn_lpw_swp2_mode','mvn_lpw_atr_mode','mvn_lpw_adr_mode']
  options, 'mvn_lpw_adr_mode','color',2
  options, 'mvn_lpw_atr_mode','color',6
  ylim,'modes',0,16
  options,'modes','ytitle','LPW Modes' 
  options,'*mode','psym',1
 
  store_data,'E12',data=['mvn_lpw_pas_E12','mvn_lpw_act_E12']
  options,'mvn_lpw_act_E12','color',6
  options,'E12','ytitle','E12 !C [V]'
  options,'mvn_lpw_pas_E12','psym',1
  options,'mvn_lpw_act_E12','psym',1
 
  store_data,'SC_pot',data=['mvn_lpw_swp1_V2','mvn_lpw_act_V2','mvn_lpw_pas_V2', $
                            'mvn_lpw_swp2_V1','mvn_lpw_act_V1','mvn_lpw_pas_V1']
  options,'SC_pot','ytitle','SC_pot !C!C [V]'                           
  options,'mvn_lpw_act_V2','color',1
  options,'mvn_lpw_pas_V2', 'color',2
  options,'mvn_lpw_swp2_V1','color',3
  options,'mvn_lpw_act_V1','color',5
  options,'mvn_lpw_pas_V1','color',6
  options,'*V1','psym',1
  options,'*V2','psym',1
   
 
  store_data,'htime',data=['mvn_lpw_htime_cap_lf','mvn_lpw_htime_cap_mf','mvn_lpw_htime_cap_hf'] 
  options,'htime','ytitle','HSBM data !C'  
  options,'htime','ylog',0     
  options,'mvn_lpw_htime_cap_mf','color',4   
  options,'mvn_lpw_htime_cap_hf','color',6   
  options,'*htime_cap*','psym',1   
  ylim,'htime',0,4   

end 


