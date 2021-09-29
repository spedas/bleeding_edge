; $LastChangedBy: davin $
; $LastChangedDate: 2019-05-28 13:51:16 -0700 (Tue, 28 May 2019) $
; $LastChangedRevision: 71 $
; $URL: https://svn.ssl.berkeley.edu/sweapsoft/idl/del/psp/fields/mag/spp_swp_mag_load.pro $
; Created by Davin Larson 2019


pro spp_swp_mag_load,trange=trange,resname=resname,save=save,no_load=no_load,files=files,type=type,rtn=rtn

  tr = timerange(trange)
  if keyword_set(rtn) then type = 'mag_RTN' else type = 'mag_SC'

  if n_elements(resname) eq 0 then resname = '1Hz'

;  tpname0 = 'psp_swp_mago_RES_nT'
;  tpname = str_sub(tpname0,'RES',resname)

;  fileformat = 'psp/data/sci/sweap/external/fields/'+tpname+'/YYYY/MM/'+tpname+'_YYYYMMDD_v00.tplot'
;/cache/psp/data/sci/sweap/external/fields/psp_fld_l2_1Hz_mag_SC/2019/04/psp_fld_l2_1Hz_mag_SC_20190406_v00
;  resname=''
  tpname0 = 'psp_fld_l2_RES_'+type
  
  if keyword_set(resname)  then begin
    tpname = str_sub(tpname0,'RES',resname)
    fileformat = 'psp/data/sci/sweap/external/fields/'+tpname+'/YYYY/MM/'+tpname+'_YYYYMMDD_v00.tplot'
    files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)
    del_data,tpname  ; Delete any previous data stored
    tplot_restore,filenames=files,/verbose,/append    
  endif
  
  
  
  
  if 0 then  begin
    fileformat = 'psp/data/sci/fields/staging/l2_draft/mag/YYYY/MM/psp_fld_l2_mag_YYYYMMDD_v??.cdf'

    files = spp_file_retrieve(key='fields',fileformat,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)
    if ~keyword_set(no_load) then cdf2tplot,files
;    if keyword_set(save) then begin
;      loadcdfstr,filenames=files,vardata,novardata
;      dummy = spp_data_product_hash('spp_mag_full',vardata)
;    endif
;    
  endif
  
  
  
;  get_data,tpname,data=d
;  dprint, 'Rotating 180 deegrees around x'
;  d.y[*,1] = - d.y[*,1] 
;  d.y[*,2] = - d.y[*,2]
;  store_data,tpname,data=d
   
 
end


