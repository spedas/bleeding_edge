;+
;FUNCTION:   mvn_lpw_prd_lp_get_this_version_no
; Read idl function headder to obtain the version information.
;
;INPUTS:
;   this_pro: Give procedure/function filename as ascii
;
;KEYWORDS:
;
;EXAMPLE:
; ver = mvn_lpw_prd_lp_get_this_version_no, 'mvn_lpw_prd_lp_get_this_version_no.pro'
;   gives back character 'version mvn_lpw_prd_lp_get_this_version_no: #.#'
;
;CREATED BY:   Michiko Morooka  10-21-14
;FILE:         mvn_lpw_prd_lp_get_this_version_no.pro
;VERSION:      2.0
;LAST MODIFICATION:
; 2014-10-20   M. Morooka
;
;-

; ------ mvn_lpw_prd_lp_get_this_version_no -------------------------------------------------------
function mvn_lpw_prd_lp_get_this_version_no, this_pro

  file_name = file_which(this_pro)
  if keyword_set(file_name) eq 0 then file_name = file_search(this_pro,/FULLY_QUALIFY_PATH)
  
  if keyword_set(file_name) eq 0 then return, file_name
    
  prd_loc = file_which('mvn_lpw_prd_lp_get_this_version_no.pro')
  prd_dir = strsplit(prd_loc,'/') & prd_dir = strmid(prd_loc,0,prd_dir(n_elements(prd_dir)-1))  
  template_file = prd_dir+'idl_txt_file_template.save'
  restore, template_file
  txt = read_ascii(file_name,template=txt_template)
  txt = txt.field1
  
  for ii=0,n_elements(txt)-1 do begin
    if strpos(txt(ii),';VERSION:') eq -1 then continue
    ver = strsplit(txt(ii),/extract)
    ver = ver(1)
    break    
  endfor

  pdr_ver= 'version '+strmid(this_pro,0,strlen(this_pro)-4)+':' + ver
    
  return, pdr_ver
end
; -------------------------------------------------------- mvn_lpw_prd_lp_get_this_version_no -----