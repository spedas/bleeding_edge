;+
;procedure: dsl2gse
;
;Purpose: THEMIS coordinate transformations
;
;         DSL<-->GSE;
;
;         interpolates, right ascension, declination
;         updates coord_sys atribute of output tplot variable.
;
;inputs
;
;	name_thx_xxx_in 	... data in the input coordinate system (t-plot variable name)
;   name_thx_spinras     ... right ascension (t-plot variable name)
;   name_thx_spindec     ... declination (t-plot variable name)
;   name_thx_xxx_out     ... name for output (t-plot variable name)
;
;keywords:
;   TRANSFORMATIONS
;
;
;   /GSE2DSL inverse transformation
;
;   /IGNORE_DLIMITS if the specified from coord is different from the
;coord system labeled in the dlimits structure of the tplot variable
;setting this keyword prevents an error
;
;Example:
;      dsl2gse('tha_fgl_dsl','tha_spinras','tha_spindec','tha_fglc_gse')
;
;        expects attitude in GEI (tha_spinras,tha_spindec)
;
;      dsl2gse('tha_fglc_gse','tha_spinras','tha_spindec','tha_fgl_dsl',/GSE2DSL)
;
;        expects attitude in GEI (tha_spinras,tha_spindec)
;
;Notes: under construction!! will run faster in the near future!!
;
;Written by Hannes Schwarzl
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-07-29 10:24:04 -0700 (Mon, 29 Jul 2013) $
; $LastChangedRevision: 12735 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/dsl2gse.pro $
;-

pro dsl2gse,name_thx_xxx_in,name_thx_spinras,name_thx_spindec,name_thx_xxx_out,GSE2DSL=GSE2DSL,ignore_dlimits=ignore_dlimits

cotrans_lib

;PRINT,'will run faster soon ...'

; get the data using t-plot names
get_data,name_thx_xxx_in,data=thx_xxx_in, limit=l_in, dl=dl_in ; krb
get_data,name_thx_spinras,data=thx_spinras
get_data,name_thx_spindec,data=thx_spindec

if size(thx_spinras, /type) ne 8 || size(thx_spindec, /type) ne 8 then begin
   message, 'aborted: must load spin vector data from state file.  Try calling thm_load_state,/get_support'
endif

if min(thx_spinras.x,/nan)-min(thx_xxx_in.x,/nan) gt 60*60 || max(thx_xxx_in.x,/nan) - max(thx_spinras.x,/nan) gt 60*60 then begin
  dprint,'NON-FATAL-ERROR: ' + name_thx_spinras + ' and ' + name_thx_xxx_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
endif
  
if min(thx_spindec.x,/nan)-min(thx_xxx_in.x,/nan) gt 60*60 || max(thx_xxx_in.x,/nan) - max(thx_spindec.x,/nan) gt 60*60 then begin
  dprint,'NON-FATAL-ERROR: ' + name_thx_spindec + ' and ' + name_thx_xxx_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
endif

data_in_coord = cotrans_get_coord(dl_in) ; krb

thx_xxx_out=thx_xxx_in

;convert the time
timeS=time_struct(thx_xxx_in.X)

;convert the time
timeSAtt=time_struct(thx_spinras.X)

;get direction
if keyword_set(GSE2DSL) then begin
	DPRINT, 'GSE-->DSL'
        ; krb

  if keyword_set(ignore_dlimits) then begin

     data_in_coord='gse'

  endif

  if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                              'gse') then begin
     dprint,  'coord of input '+name_thx_xxx_in+': '+data_in_coord+ $
            ' must be GSE'
     return
  end
  out_coord = 'dsl'
  ; krb
  isGSE2DSL=1
endif else begin
   DPRINT, 'DSL-->GSE'

   if keyword_set(ignore_dlimits) then begin

     data_in_coord='dsl'

  endif

   ; krb
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'dsl') then begin
      dprint,  'coord of input '+name_thx_xxx_in+': '+data_in_coord+ $
                  ' must be DSL'
      return
   end
   out_coord = 'gse'
   ; krb
   isGSE2DSL=0
endelse


;linearly interpolate the elevation and the right ascencion angle
;rasInterp = interpol( thx_spinras.Y,thx_spinras.X,thx_xxx_in.X)
;decInterp = interpol( thx_spindec.Y,thx_spindec.X,thx_xxx_in.X)


thx_spinras_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinras=thx_spinras) ;--> linear interpolation
thx_spindec_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spindec=thx_spindec) ;--> linear interpolation

;cdatj00,2,3,4,5

;convert the time
timeS=time_struct(thx_xxx_in.X)

; get array sizes
count=SIZE(thx_xxx_in.X,/N_ELEMENTS)
DPRINT, 'number of records: ',count

; get array sizes
countAtt=SIZE(thx_spinras.X,/N_ELEMENTS)
DPRINT, 'number of records: ',countAtt

;make a unit vector that points along the spin axis
spla=(90.d0-(thx_spindec_highres.Y))*!dpi/180.d0
splo=thx_spinras_highres.Y*!dpi/180.d0
zscs=[[(sin(spla)*cos(splo))],[(sin(spla)*sin(splo))],[(cos(spla))]] ;spherical to cartesian
if isGSE2DSL eq 0 then begin
	subGEI2GSE,timeS,zscs,zscsGSE;unit vector that points along the spin axis in GSE
	sun=[1.d0,0.d0,0.d0]
	;yscs= crossp(zscsGSE,sun) ;NORMALIZE
	yscs=[[zscsGSE[*,1]*sun[2]-zscsGSE[*,2]*sun[1]],[zscsGSE[*,2]*sun[0]-zscsGSE[*,0]*sun[2]],[zscsGSE[*,0]*sun[1]-zscsGSE[*,1]*sun[0]]]
	yscsNorm=sqrt(yscs[*,0]^2.0+yscs[*,1]^2.0+yscs[*,2]^2.0)
	yscs[*,0]=yscs[*,0]/yscsNorm
	yscs[*,1]=yscs[*,1]/yscsNorm
	yscs[*,2]=yscs[*,2]/yscsNorm
	;xscs=crossp(yscs,zscsGSE)
	xscs=[[yscs[*,1]*zscsGSE[*,2]-yscs[*,2]*zscsGSE[*,1]],[yscs[*,2]*zscsGSE[*,0]-yscs[*,0]*zscsGSE[*,2]],[yscs[*,0]*zscsGSE[*,1]-yscs[*,1]*zscsGSE[*,0]]]

	;gse2scs=[transpose(xscs),transpose(yscs),transpose(zscs)]
	;scs2gse=invert(gse2scs,/double)
	;DATA_out=scs2gse#binp



	;do dot products (inverse from **** below) (the inverse is just the transpose for rotation matrices)
	thx_xxx_out.Y[*,0]=thx_xxx_in.Y[*,0]*xscs[*,0]+thx_xxx_in.Y[*,1]*yscs[*,0]+thx_xxx_in.Y[*,2]*zscsGSE[*,0]

	thx_xxx_out.Y[*,1]=thx_xxx_in.Y[*,0]*xscs[*,1]+thx_xxx_in.Y[*,1]*yscs[*,1]+thx_xxx_in.Y[*,2]*zscsGSE[*,1]

	thx_xxx_out.Y[*,2]=thx_xxx_in.Y[*,0]*xscs[*,2]+thx_xxx_in.Y[*,1]*yscs[*,2]+thx_xxx_in.Y[*,2]*zscsGSE[*,2]


endif else begin
	subGEI2GSE,timeS,zscs,zscsGSE;unit vector that points along the spin axis in GSE
	;zscsGSE=zscs;unit vector that points along the spin axis in GSE
	sun=[1.d0,0.d0,0.d0]
	;yscs= crossp(zscsGSE,sun) ;NORMALIZE
	yscs=[[zscsGSE[*,1]*sun[2]-zscsGSE[*,2]*sun[1]],[zscsGSE[*,2]*sun[0]-zscsGSE[*,0]*sun[2]],[zscsGSE[*,0]*sun[1]-zscsGSE[*,1]*sun[0]]]
	yscsNorm=sqrt(yscs[*,0]^2.0+yscs[*,1]^2.0+yscs[*,2]^2.0)
	yscs[*,0]=yscs[*,0]/yscsNorm
	yscs[*,1]=yscs[*,1]/yscsNorm
	yscs[*,2]=yscs[*,2]/yscsNorm
	;xscs=crossp(yscs,zscsGSE)
	xscs=[[yscs[*,1]*zscsGSE[*,2]-yscs[*,2]*zscsGSE[*,1]],[yscs[*,2]*zscsGSE[*,0]-yscs[*,0]*zscsGSE[*,2]],[yscs[*,0]*zscsGSE[*,1]-yscs[*,1]*zscsGSE[*,0]]]
	;gse2scs=[transpose(xscs),transpose(yscs),transpose(zscsGSE)]

	;DATA_out=gse2scs#binp


	;do dot products (****)
	thx_xxx_out.Y[*,0]=thx_xxx_in.Y[*,0]*xscs[*,0]+thx_xxx_in.Y[*,1]*xscs[*,1]+thx_xxx_in.Y[*,2]*xscs[*,2]

	thx_xxx_out.Y[*,1]=thx_xxx_in.Y[*,0]*yscs[*,0]+thx_xxx_in.Y[*,1]*yscs[*,1]+thx_xxx_in.Y[*,2]*yscs[*,2]

	thx_xxx_out.Y[*,2]=thx_xxx_in.Y[*,0]*zscsGSE[*,0]+thx_xxx_in.Y[*,1]*zscsGSE[*,1]+thx_xxx_in.Y[*,2]*zscsGSE[*,2]


endelse

;thx_xxx_out.Y=DATA_out

dl_out=dl_in
cotrans_set_coord,  dl_out, out_coord ; krb
;; clear ytitle, so that it won't contain wrong info.
str_element, dl_out, 'ytitle', /delete
l_out=l_in
str_element, l_out, 'ytitle', /delete

store_data,name_thx_xxx_out,data=thx_xxx_out, limit=l_out, dl=dl_out ; krb

DPRINT, 'done'

;RETURN,thx_xxx_out
end





