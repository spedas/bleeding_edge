;+
; PRO: das2dlm_get_ds_meta, ...
;
; Description:
;    Extracts metadata from dataset (ds) 
;
; Keywords:
;    ds: Dataset returned by das2c_datasets(query)
;    meta: structure of metadata
;    title: Name that can be obtained from the dataset properies
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;    
; NOTE:
;   This function is under active development. Its behavior can change in the future.
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-28 20:47:39 -0700 (Fri, 28 Aug 2020) $
; $Revision: 29092 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_get_ds_meta.pro $
;-

pro das2dlm_get_ds_meta, ds, meta=meta, title=title
 
  meta = das2c_props(ds)
  title = ds.name
  
  ; Check if we have key in the structure
  res = where(tag_names(meta[0]) eq 'KEY', cnt)  
  if cnt gt 0 then begin  
    if strupcase(meta[0].key) eq 'TITLE' $
      then title = meta[0].value
      
    title = title.Split('%')
    title = title[0]
  end

end