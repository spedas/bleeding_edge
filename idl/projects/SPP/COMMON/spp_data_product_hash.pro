;+
;  spp_data_product_hash
;  This basic object is the entry point for defining and obtaining all data for all data products
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-05-01 14:31:49 -0700 (Thu, 01 May 2025) $
; $LastChangedRevision: 33284 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_data_product_hash.pro $
;-
;COMPILE_OPT IDL2


FUNCTION spp_data_product_hash,name,data,help=help,delete=delete
  COMPILE_OPT IDL2
  common spp_data_product_com, alldat
  if ~isa(alldat)  then begin
    dprint,'Initializing Storage space'
    alldat = orderedhash()
  endif
  if keyword_set(help) then begin
    print,alldat.keys()
  endif
  if n_params() eq 2 then begin
    if  ~alldat.haskey(name) then begin
      dp = spp_data_product(name=name)
      alldat[name] = dp
    endif else dp= alldat[name]
    if isa(data) then begin
      dp.savedat, data, /add_index
    endif
    return,dp    
  endif
  
  if n_params() eq 1 then begin
    if isa(name) && ~alldat.haskey(name) then begin
      dprint,'Nothing saved with the name: '+name
      return,obj_new()
    endif
    dp = alldat[name]
    if keyword_set(delete) then begin
      alldat.remove,name
      obj_destroy,dp
      return,!null
    endif
    return,dp
  endif  
  return, !null
end
  






