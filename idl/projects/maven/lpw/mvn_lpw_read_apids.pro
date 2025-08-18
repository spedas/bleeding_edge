; Program MVN_LPW_READ_APIDS
;
; Simple routine to read in apid files for maven LPW
;
; Rev 1-0 2012-07-26  GTD
; Rev 1-1 2012-07-30

pro mvn_lpw_read_apids, path=path, $
                        apids = apids

if not keyword_set(path) then begin
  print,'MVN_LPW_READ_APIDS: path name to data is required'
  return
endif

if not keyword_set(apids) then apids = ['52','58','59','5A','5B','5C','5D','5E']
type = size(apids,/type)
if type NE 7 then apids = strcompress(string(fix(apids)),/remove_all)

test = where(apids EQ '58')
if test[0] EQ -1 then $
  print,'MVN_LPW_READ_APIDS: Warning, ApID 58 must be read prior to spectra packet ApIDs'
 
ind = sort(apids)
apids = apids[ind]
                        
; ApID 0x58 must be present for spectra packets to work

for i = 0,n_elements(apids)-1 do begin
  filename = 'apid_'+apids[i]+'_all.dat'
  mvn_lpw_extract_data,path=path,filename=filename
  print,'MVN_LPW_READ_APIDS: ApID ' + apids[i] + ' read.'
endfor


end

