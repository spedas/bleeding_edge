;+
;PROCEDURE:	
;	MVN_SWIA_CALC_DOBJ
;PURPOSE:	
;	Find closest distance to an object along the magnetic field line projection 
;
;INPUT:		
;
;KEYWORDS:
;	BDATA: tplot variable for the magnetic field (needs to be same frame as delta position)
;	DR: tplot variable for the delta position between the two objects
;
;AUTHOR:	J. Halekas	
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-07-14 06:27:29 -0700 (Tue, 14 Jul 2015) $
; $LastChangedRevision: 18119 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_calc_dobj.pro $
;
;-

pro mvn_swia_calc_dobj,bdata = bdata, dr = dr

if not keyword_set(bdata) then bdata = 'mvn_B_1sec_MAVEN_MSO'

if not keyword_set(dr) then begin
	spice_position_to_tplot,'MAVEN','MARS',frame = 'MSO',res=10
	spice_position_to_tplot,'PHOBOS','MARS',frame = 'MSO',res=10
	calc,"'dr' = 'MAVEN_POS_(MARS-MSO)'-'PHOBOS_POS_(MARS-MSO)'"
	dr = 'dr'
endif

tinterpol_mxn,dr,bdata
dr = dr+'_interp'


copy_data,bdata,'b2'
tvectot,'b2'
split_vec,'b2'
copy_data,dr,'dr2'
tvectot,'dr2'
split_vec,'dr2'

tdotp,bdata,dr,newname = 'brcostheta'

calc,"'dobj' = sqrt('dr2_3'*'dr2_3'-'brcostheta'*'brcostheta'/'b2_3'/'b2_3')"

end