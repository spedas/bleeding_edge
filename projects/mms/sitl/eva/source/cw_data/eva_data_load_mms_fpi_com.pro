PRO eva_data_load_mms_fpi_com, sc=sc
  tn = tnames(sc+'_fpi_*',cnt)

  ;....... density ......

  tn0 = sc+'_fpi_density'
  idx=where(strmatch(tn,tn0),c)
  if c eq 0 then eva_data_load_mms_fpi_ql, sc=sc

  tn1 = sc+'_fpi_pseudodens'
  idx=where(strmatch(tn,tn1),c)
  if c eq 0 then eva_data_load_mms_fpi_pseudomom, sc=sc

  tn = tnames(sc+'_fpi_*',cnt)
  idx=where(strmatch(tn,tn0),c0)
  idx=where(strmatch(tn,tn1),c1)
  if c0+c1 eq 2 then begin
    store_data,sc+'_fpi_com_dens',data=[tn0,tn1]
    options,sc+'_fpi_com_dens',colors=[6,2,3,1],$
      labels=['Ne (QL)','Ni (QL)','Ni (trig)','Ne (trig)'],labflag=-1
  endif
  
  ;....... velocity ......

  tn0 = sc+'_fpi_ipseudovxy'
  idx=where(strmatch(tn,tn0),c0)
  tn1 = sc+'_fpi_ipseudovz'
  idx=where(strmatch(tn,tn1),c1)
  if (c0 eq 0) or (c1 eq 0) then eva_data_load_mms_fpi_pseudomom, sc=sc

  tn = tnames(sc+'_fpi_*',cnt)
  idx=where(strmatch(tn,tn0),c0)
  idx=where(strmatch(tn,tn1),c1)
  if c0+c1 eq 2 then begin
    store_data,sc+'_fpi_com_vxyz',data=[tn0,tn1]
    options,sc+'_fpi_com_vxyz',colors=[0,6],$
      labels=['Vxy (trig)','Vz (trig)'],labflag=-1
  endif
  
END
