;+
;procedure: cotrans, name_in, name_out [, time]
;
;Purpose: geophysical coordinate transformations
;
;         GEI<-->GSE;
;         GSE<-->GSM;
;         GSM<-->SM;
;         GEI<-->GEO;
;         GEO<-->MAG;
;         GEI<-->J2000;
;         
;         interpolates the spinphase, right ascension, declination
;         updates coord_sys attribute of output tplot variable.
;
;inputs
;
;   name_in 	... data in the input coordinate system (t-plot variable name, 
;                                                        or array)
;   name_out    ... variable name for output            (t-plot variable name,
;                                                        or array)
;   time        ... optional input: array of times for input values, if provided
;                   then the first parameter is an array, and the second
;                   parameter is a named variable to contain the output array.
;
;
;keywords:
;   TRANSFORMATIONS
;
;
;	/GEI2GSE
;	/GSE2GEI
;
;	/GSE2GSM
;	/GSM2GSE
;
; /GSM2SM
; /SM2GSM
;
; /GEI2GEO
; /GEO2GEI
;
; /GEO2MAG
; /MAG2GEO
;
; /GEI2J2000
; /J20002GEI
; 
; /IGNORE_DLIMITS: set so it won't require the coordinate
;system of the input tplot variable to match the coordinate
;system from which the data is being converted
;
;Examples:
;
;
;      cotrans,'tha_fgl_gse','tha_fgl_gsm',/GSE2GSM
;      cotrans,'tha_fgl_gsm','tha_fgl_gse',/GSM2GSE
;
;      cotrans,'tha_fgl_gse','tha_fgl_gei',/GSE2GEI
;      cotrans,'tha_fgl_gei','tha_fgl_gse',/GEI2GSE
;
;      cotrans,'tha_fgl_gsm','tha_fgl_sm',/GSM2SM
;      cotrans,'tha_fgl_sm','tha_fgl_gsm',/SM2GSM
;
;Notes: under construction!!
;       clrussell, 03-30-12, added GEO2MAG and MAG2GEO conversions
;
;Written by: Hannes Schwarzl & Patrick Cruce(pcruce@igpp.ucla.edu)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-22 08:59:06 -0700 (Tue, 22 Sep 2015) $
; $LastChangedRevision: 18869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/cotrans.pro $
;-
pro cotrans, name_in, name_out, time, GSM2GSE=GSM2GSE, GSE2GEI=GSE2GEI,          $
             GSE2GSM=GSE2GSM,GEI2GSE=GEI2GSE,GSM2SM=GSM2SM,SM2GSM=SM2GSM,        $
             GEI2GEO=GEI2GEO, GEO2GEI=GEO2GEI, GEO2MAG=GEO2MAG, MAG2GEO=MAG2GEO, $
             GEI2J2000=GEI2J2000, J20002GEI=J20002GEI, ignore_dlimits=ignore_dlimits

cotrans_lib

;PRINT,'will run faster soon ...'

if n_params() eq 2 then begin
; get the data using t-plot name
   get_data,name_in,data=data_in, limit=l_in, dl=dl_in ; krb
   data_in_coord = cotrans_get_coord(dl_in) ; krb
endif else begin
   data_in={x:time, y:name_in}
   data_in_coord = 'unknown'
endelse

;Here be sure data_in.y is float or double
tpp = size(data_in.y, /type)
If(tpp Ne 4 And tpp Ne 5) Then Begin
    str_element, data_in, 'y', float(data_in.y), /add_replace
Endif

is_valid_keyws=0


;GSE GSM
if keyword_set(GSE2GSM) then begin

   if keyword_set(ignore_dlimits) then begin

      data_in_coord='gse'

   endif
   
   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'gse') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be GSE'
      return
   end
   sub_GSE2GSM,data_in,data_conv
   out_coord = 'gsm'
endif


;GSM GSE
if keyword_set(GSM2GSE) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='gsm'

   endif

   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                              'gsm') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be GSM'
      return
   end
   sub_GSE2GSM,data_in,data_conv,/GSM2GSE
   out_coord = 'gse'
endif


;GEI GSE
if keyword_set(GEI2GSE) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='gei'
      
   endif
   
	is_valid_keyws=1
  if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                        'gei') then begin
     dprint, 'coord of input '+name_in+': '+data_in_coord+ $
             ' must be GEI'
     return
  end
  sub_GEI2GSE,data_in,data_conv
  out_coord = 'gse'
endif


;GSE GEI
if keyword_set(GSE2GEI) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='gse'
      
   endif
   
   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'gse') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
                  ' must be GSE'
      return
   end
   sub_GEI2GSE,data_in,data_conv,/GSE2GEI
   out_coord = 'gei'
endif

;GSM SM
if keyword_set(GSM2SM) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='gsm'

   endif

   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'gsm') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
                   ' must be GSM'
      return
   end
   sub_GSM2SM,data_in,data_conv
   out_coord = 'sm'
endif

;SM GSM
if keyword_set(SM2GSM) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='sm'
      
   endif

   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'sm') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be SM'
      return
   end
   sub_GSM2SM,data_in,data_conv,/SM2GSM
   out_coord = 'gsm'
endif


;GEI GEO
if keyword_set(GEI2GEO) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='gei'

   endif
   
   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'gei') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be GEI'
      return
   end
   sub_GEI2GEO,data_in,data_conv
   out_coord = 'geo'
endif


;GEO GEI
if keyword_set(GEO2GEI) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='geo'

   endif

   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'geo') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be GEO'
      return
   end
   sub_GEI2GEO,data_in,data_conv,/GEO2GEI
   out_coord = 'gei'
endif


;GEO MAG
if keyword_set(GEO2MAG) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='geo'

   endif

   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'geo') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be GEO'
      return
   end
   sub_GEO2MAG,data_in,data_conv
   out_coord = 'mag'
endif


;MAG GEO
if keyword_set(MAG2GEO) then begin

   if keyword_set(ignore_dlimits) then begin
      
      data_in_coord='mag'

   endif

   is_valid_keyws=1
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'mag') then begin
      dprint, 'coord of input '+name_in+': '+data_in_coord+ $
              ' must be MAG'
      return
   end
   sub_GEO2MAG,data_in,data_conv,/MAG2GEO
   out_coord = 'geo'
endif

;GEI J2000
if keyword_set(GEI2J2000) then begin

  if keyword_set(ignore_dlimits) then begin

    data_in_coord='gei'

  endif

  is_valid_keyws=1
  if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
    'gei') then begin
    dprint, 'coord of input '+name_in+': '+data_in_coord+ $
      ' must be GEI'
    return
  end
  sub_GEI2J2000,data_in,data_conv
  out_coord = 'j2000'
endif


;J2000 GEI
if keyword_set(J20002GEI) then begin

  if keyword_set(ignore_dlimits) then begin

    data_in_coord='j2000'

  endif

  is_valid_keyws=1
  if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
    'j2000') then begin
    dprint, 'coord of input '+name_in+': '+data_in_coord+ $
      ' must be J2000'
    return
  end
  sub_GEI2J2000,data_in,data_conv,/J20002GEI
  out_coord = 'gei'
endif

if (is_valid_keyws eq 0) then begin
   DPRINT,'Not a valid combination of input arguments'
endif

if n_params() eq 2 then begin
   dl_conv = dl_in
   cotrans_set_coord,  dl_conv, out_coord ;krb
   ;; clear ytitle, so that it won't contain wrong info.
   str_element, dl_conv, 'ytitle', /delete
   l_conv=l_in
   str_element, l_conv, 'ytitle', /delete

   store_data,name_out,data=data_conv, limit=l_conv, dl=dl_conv ;krb
endif else name_out = data_conv.y

;RETURN, data_conv
end











