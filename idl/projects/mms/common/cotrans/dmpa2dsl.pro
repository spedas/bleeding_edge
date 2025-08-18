;+
;Procedure:
;  dmpa2dsl
;
;Purpose: MMS coordinate transformation:
;            DMPA <--> DSL
;
;         ----------------------------------------------
;         |  This is currently a placeholder and only  |
;         |  performs an identity transformation!      |
;         -----------------------------------------------
;
;Inputs
;  TBD
;
;Keywords:
;   /dsl2dmpa:  Inverse transformation
;   /IGNORE_DLIMITS:  If the specified from coord is different from the
;                     coord system labeled in the dlimits structure of the 
;                     tplot variable setting this keyword prevents an error.
;
;Example:
;     
;
;Notes: 
;    
;    
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-12-21 19:27:01 -0800 (Mon, 21 Dec 2015) $
;$LastChangedRevision: 19640 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/dmpa2dsl.pro $
;-

pro dmpa2dsl, name_mms_xxx_in, name_mms_xxx_out, DSL2DMPA=DSL2DMPA, ignore_dlimits=ignore_dlimits

    compile_opt idl2, hidden

  cotrans_lib
 
  ;just get metadata until there's an actual transformation
  get_data, name_mms_xxx_in, limit=l_in, dl=dl_in
;  get_data,name_mms_xxx_in,data=mms_xxx_in, limit=l_in, dl=dl_in 

  data_in_coord = cotrans_get_coord(dl_in)
  
;  mms_xxx_out=mms_xxx_in
  
  ;get direction
  if keyword_set(DSL2DMPA) then begin
    DPRINT, 'DSL-->DMPA'
  
    if keyword_set(ignore_dlimits) then begin
      data_in_coord='dsl'
    endif
  
    if ~strmatch(data_in_coord,'unknown') && ~strmatch(data_in_coord,'dsl') then begin
      dprint,  'coord of input '+name_mms_xxx_in+': '+data_in_coord+' must be DSL'
      return
    end

    out_coord = 'dmpa'

  endif else begin
     DPRINT, 'DMPA-->DSL'
  
    if keyword_set(ignore_dlimits) then begin
      data_in_coord='dmpa'
    endif
  
    if ~strmatch(data_in_coord,'unknown') && ~strmatch(data_in_coord,'dmpa') then begin
      dprint,  'coord of input '+name_mms_xxx_in+': '+data_in_coord+' must be DMPA'
      return
    end

    out_coord = 'dsl'

  endelse
  
  
  dprint, dlevel=1, 'WARNING:  DMPA and DSL are currently treated as identical'

  
  l_out=l_in
  dl_out=dl_in
  cotrans_set_coord,  dl_out, out_coord
  
  ;just replace metadata until there's an actual transformation
  store_data, name_mms_xxx_out, limit=l_out, dl=dl_out
;  store_data,name_mms_xxx_out,data=mms_xxx_out, limit=l_out, dl=dl_out
  
  DPRINT, 'done'
  
end





