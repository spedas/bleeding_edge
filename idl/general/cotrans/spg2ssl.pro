
;+
;procedure: spg2ssl
;
;Purpose: coordinate transformation
;
;         SPG<-->SSL;
;
;
;inputs
;
;	name_thx_xxx_in 	... data in the input coordinate system (t-plot variable name)
;   name_thx_xxx_out    ... name for output  (t-plot variable name)
;
;keywords:
;
;   probe :  explicitly specify a probe, rather than inferring from tplot name
;
;   TRANSFORMATIONS
;
;   /SSL2SPG inverse transformation
;
;   /IGNORE_DLIMITS if the specified from coord is different from the
;coord system labeled in the dlimits structure of the tplot variable
;setting this keyword prevents an error
;
;Example:
;      spg2ssl,'tha_fgl_spg','tha_fgl_ssl'
;      spg2ssl,'tha_fgl_ssl','tha_fgl_spg',/SSL2SPG
;Notes: under construction!!
;
;Written by Hannes Schwarzl
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-05-05 10:29:05Z $
; $LastChangedRevision: 645 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/cotrans/ssl2dsl.pro $
;-
pro spg2ssl,name_thx_xxx_in,name_thx_xxx_out,SSL2SPG=SSL2SPG,ignore_dlimits=ignore_dlimits, probe=probe

if n_elements(probe) NE 0 then begin
   sc=probe
endif else begin
   sc=STRMID(name_thx_xxx_in, 2 ,1)
   dprint,'Probe keyword not specified, using third letter of input variable ('+name_thx_xxx_in+') : '+sc
endelse

;transposed because of idl's array indexing
rotMat_tha=transpose([[-0.709213, 0.704995, 0.000013],[-0.704988,-0.709206, 0.004363],[0.003085, 0.003085,0.999990]]);
rotMat_thb=transpose([[-0.705611, 0.708599,-0.000009],[-0.708593,-0.705604, 0.004363],[0.003085, 0.003085,0.999990]]);
rotMat_thc=transpose([[-0.706805, 0.707409,-0.000002],[-0.707402,-0.706798, 0.004363],[0.003085, 0.003085,0.999990]]);
rotMat_thd=transpose([[-0.707995, 0.706217, 0.000005],[-0.706210,-0.707989, 0.004363],[0.003085, 0.003085,0.999990]]);
rotMat_the=transpose([[-0.706085, 0.708127,-0.000006],[-0.708120,-0.706078, 0.004363],[0.003085, 0.003085,0.999990]]);


case 1 of
	sc eq 'a' : rM= rotMat_tha
	sc eq 'b' : rM= rotMat_thb
	sc eq 'c' : rM= rotMat_thc
	sc eq 'd' : rM= rotMat_thd
	sc eq 'e' : rM= rotMat_the
else: begin
        dprint,  'spacecraft has to be a, b, c, d or e'
        return
      end
endcase


; get the data using t-plot names
get_data,name_thx_xxx_in,data=thx_xxx_in, limit=l_in, dl=dl_in ; krb

data_in_coord = cotrans_get_coord(dl_in) ; krb

thx_xxx_out=thx_xxx_in



if keyword_set(SSL2SPG) then begin
	DPRINT, 'SSL-->SPG'

  if keyword_set(ignore_dlimits) then begin

     data_in_coord='ssl'

  endif

  ; krb
  if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                        'ssl') then begin
     dprint,  'coord of input '+name_thx_xxx_in+': '+data_in_coord+ $
            ' must be ssl'
     return
  end
  out_coord = 'spg'
  ; krb
  isSSL2SPG=1
endif else begin
   DPRINT, 'SPG-->SSL'

   if keyword_set(ignore_dlimits) then begin

     data_in_coord='spg'

  endif

   ; krb
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'spg') then begin
      dprint,  'coord of input '+name_thx_xxx_in+': '+data_in_coord+ $
             ' must be spg'
      return
   end
   out_coord = 'ssl'
   ; krb
   isSSL2SPG=0
endelse



count=SIZE(thx_xxx_in.X,/N_ELEMENTS)
DPRINT, 'number of DATA records: ',count



if isSSL2SPG eq 1 then begin

	;transform back 2 spg
	rm=transpose(rm)

endif

;multiply
thx_xxx_out.Y[*,0]=thx_xxx_in.Y[*,0]*rm(0,0) + thx_xxx_in.Y[*,1]*rm(0,1) + thx_xxx_in.Y[*,2]*rm(0,2)
thx_xxx_out.Y[*,1]=thx_xxx_in.Y[*,0]*rm(1,0) + thx_xxx_in.Y[*,1]*rm(1,1) + thx_xxx_in.Y[*,2]*rm(1,2)
thx_xxx_out.Y[*,2]=thx_xxx_in.Y[*,0]*rm(2,0) + thx_xxx_in.Y[*,1]*rm(2,1) + thx_xxx_in.Y[*,2]*rm(2,2)


dl_out=dl_in ; krb
cotrans_set_coord,  dl_out, out_coord ; krb
;; clear ytitle, so that it won't contain wrong info.
str_element, dl_out, 'ytitle', /delete
l_out=l_in
str_element,l_out,'ytitle',/delete
store_data,name_thx_xxx_out,data=thx_xxx_out, limit=l_out, dl=dl_out ; krb


DPRINT, 'done'

;RETURN, thx_xxx_out
;RETURN, phase
end



;###################################################################




