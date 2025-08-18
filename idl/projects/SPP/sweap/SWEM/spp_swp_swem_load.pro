; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-16 16:55:09 -0800 (Wed, 16 Dec 2020) $
; $LastChangedRevision: 29529 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_load.pro $
;
;this is a test routine for now.
;

pro spp_swp_swem_load,type=type,trange=trange,save=save,varformat=varformat


;example = 'http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/swem/L1/2018/11/swem_dig_hkp/spp_swp_swem_dig_hkp_L1_20181106_v00.cdf'
;example = 'http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/swem/L1/2018/11/swem_ana_hkp/spp_swp_swem_ana_hkp_L1_20181106_v00.cdf
  Ltype = 'L1'

if ~keyword_set(type) then type = 'swem_dig_hkp'
 ; type = 'swem_ana_hkp'
  
;  pathname = 'psp/data/sci/sweap/swem/L1/YYYY/MM/'+type+'/psp_swp_'+type+'_L1_YYYYMMDD_v??.cdf'
  pathname = 'psp/data/sci/sweap/swem/L1/'+type+'/YYYY/MM/psp_swp_'+type+'_L1_YYYYMMDD_v??.cdf'

  if not keyword_set(files) then files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
  prefix = 'psp_swp_'+type+'_L1_'
  
  if not keyword_set(varformat) then begin
    case type of
      'swem_dig_hkp': varformat = 'SW_SSRWRADDR *OSCPUUSAGE *CMDCOUNTER'
      'swem_ana_hkp': varformat = '*TEMP'
      else:  varformat='*'
    endcase
    
  endif
  
  if keyword_set(save) then begin
    vardata = !null
    novardata = !null
    loadcdfstr,filenames=files,vardata,novardata
    dummy = spp_data_product_hash(type,vardata)
  endif

  cdf2tplot,files,prefix = prefix,verbose=1,varformat = varformat

;ctime,t
;spp_swp_ssrreadreq,t

end
