
;+
;procedure: ssl2dsl
;
;Purpose: despins (spins) THEMIS  data
;
;         SSL<-->DSL;
;
;         interpolates the spinphase, spin period
;         updates coord_sys atribute of output tplot variable.
;
;inputs
;
;	name_thx_xxx_in 	... data in the input coordinate system (t-plot variable name)
;
;keywords:
;   /NAME_INPUT : Always required; this argument is the name of a tplot
;     variable to use as the input data.
;
;   /NAME_OUTPUT: Always required; this argument is the name of a tplot
;     variable to receive the output.
;
;   TRANSFORMATIONS
;
;   /DSL2SSL inverse transformation
;
;   /IGNORE_DLIMITS if the specified from coord is different from the
;coord system labeled in the dlimits structure of the tplot variable
;setting this keyword prevents an error
; 
;  /INTERPOLATE_STATE : if specified, interpolate the spin phase
;    from the 1-minute samples in the state CDF.  Otherwise,
;    use the spinmodel routines by default.
;
;  /NAME_THX_SPINPER : required if /INTERPOLATE_STATE is specified;
;    this is the name of a tplot variable containing the 1-minute
;    spinper samples from the state CDF.
;
;  /NAME_THX_SPINPHASE : required if /INTERPOLATE_STATE is specified;
;    this is the name of a tplot variable containing the 1-minute
;    spinphase samples from the state CDF.
; 
;  /SPINMODEL_PTR : required if /INTERPOLATE_STATE is NOT specified;
;    this argument is a pointer to the appropriate spin model data structure.
;
;Example:
;      ssl2dsl,name_input='tha_fgl_ssl',$
;          name_output='tha_fgl_dsl',$
;          /INTERPOLATE_STATE,$
;          name_thx_spinper='tha_state_spinper',$
;          name_thx_spinphase='tha_state_spinphase'
;
;      ssl2dsl,name_input='tha_fgl_dsl',$
;        /INTERPOLATE_STATE,$
;        name_thx_spinper='tha_state_spinper',$
;        name_thx_spinphase='tha_state_spinphase',$
;        name_output='tha_fgl_ssl',$
;        /DSL2SSL
;
;      ssl2dsl,name_input='tha_fgl_dsl',$
;         spinmodel_ptr=spinmodel_get_ptr('a'),$
;         name_output='tha_fgl_ssl'
;
;Notes: under construction!!
;
;Written by Hannes Schwarzl
; $LastChangedBy: jwl $
; $LastChangedDate: 2012-06-04 10:26:03 -0700 (Mon, 04 Jun 2012) $
; $LastChangedRevision: 10493 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/ssl2dsl.pro $
;-
pro ssl2dsl,name_input=name_input,name_thx_spinper=name_thx_spinper,$
    name_thx_spinphase=name_thx_spinphase,name_output=name_output,$
    DSL2SSL=DSL2SSL,ignore_dlimits=ignore_dlimits,$
    INTERPOLATE_STATE=INTERPOLATE_STATE,spinmodel_ptr=spinmodel_ptr,$
    use_spinphase_correction=use_spinphase_correction

; Check required arguments

if n_elements(name_input) EQ 0 then begin
   message,'Missing required argument name_input'
end

if n_elements(name_output) EQ 0 then begin
   message,'Missing required argument name_output'
end

if keyword_set(interpolate_state) then begin
   if n_elements(name_thx_spinphase) EQ 0 then begin
      message,'/INTERPOLATE_STATE specified, but name_thx_spinphase not specified'
   end
   if n_elements(name_thx_spinper) EQ 0 then begin
      message,'/INTERPOLATE_STATE specified, but name_thx_spinper not specified'
   end
end else begin
   if n_elements(spinmodel_ptr) EQ 0 then begin
      message,'/INTERPOLATE_STATE not specified; missing required argument spinmodel_ptr'
   end
endelse

; get the data using t-plot names
get_data,name_input,data=thx_xxx_in, limit=l_in, dl=dl_in ; krb

data_in_coord = cotrans_get_coord(dl_in) ; krb

thx_xxx_out=thx_xxx_in


if keyword_set(DSL2SSL) then begin
	DPRINT, 'DSL-->SSL'

  if keyword_set(ignore_dlimits) then begin
     data_in_coord='dsl'
  endif

  ; krb
  if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                        'dsl') then begin
     dprint,  'coord of input '+name_input+': '+data_in_coord+ $
            ' must be DSL'
     return
  end
  out_coord = 'ssl'
  ; krb
  isDSL2SSL=1
endif else begin
   DPRINT, 'SSL-->DSL'
   if keyword_set(ignore_dlimits) then begin
     data_in_coord='ssl'
   endif

   ; krb
   if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                         'ssl') then begin
      dprint,  'coord of input '+name_input+': '+data_in_coord+ $
             ' must be SSL'
      return
   end

   out_coord = 'dsl'
   ; krb
   isDSL2SSL=0
endelse

count=SIZE(thx_xxx_in.X,/N_ELEMENTS)
DPRINT, 'number of DATA records: ',count

;interpolate phase
thx_xxx_in=thx_xxx_out

if keyword_set(interpolate_state) then begin
   get_data,name_thx_spinper,data=thx_spinper
   get_data,name_thx_spinphase,data=thx_spinphase

   if size(thx_spinper, /type) ne 8 || size(thx_spinphase, /type) ne 8 then begin
      message, 'aborted: must load spin data from state file'
   endif
   
   if min(thx_spinper.x,/nan)-min(thx_xxx_in.x,/nan) gt 60*60 || max(thx_xxx_in.x,/nan) - max(thx_spinper.x,/nan) gt 60*60 then begin
     dprint,'NON-FATAL-ERROR: ' + name_thx_spinper + ' and ' + name_input + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
   endif
  
   if min(thx_spinphase.x,/nan)-min(thx_xxx_in.x,/nan) gt 60*60 || max(thx_xxx_in.x,/nan) - max(thx_spinphase.x,/nan) gt 60*60 then begin
     dprint,'NON-FATAL-ERROR: ' + name_thx_spinphase + ' and ' + name_input + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
   endif
   
   countPhase=SIZE(thx_spinphase.X,/N_ELEMENTS)
   DPRINT, 'number of Phase records: ',countPhase

;  phase constructed according to the nearest neighbor spin phase, 
;  spin period

   thx_spinphase_highres=thm_interpolate_state(thx_xxx_in=thx_xxx_in,$
      thx_spinper=thx_spinper,$
      thx_spinphase=thx_spinphase)
   phase=thx_spinphase_highres.Y*!dpi/180.d0

endif else begin

   dprint, 'Using spin model to calculate phase versus time...'
   spinmodel_interp_t,model=spinmodel_ptr,time=thx_xxx_in.X,spinphase=phase_deg,use_spinphase_correction=use_spinphase_correction
   spinmodel_phase=phase_deg*!dpi/180.0D
   phase=spinmodel_phase

endelse



if isDSL2SSL eq 0 then begin
	;despin
	thx_xxx_out.Y[*,0]=thx_xxx_in.Y[*,0]*  cos(phase) -thx_xxx_in.Y[*,1]* sin(phase)
	thx_xxx_out.Y[*,1]=thx_xxx_in.Y[*,0]*  sin(phase) +thx_xxx_in.Y[*,1]* cos(phase)
endif else begin
	;spin
	thx_xxx_out.Y[*,0]= thx_xxx_in.Y[*,0]*  cos(phase) +thx_xxx_in.Y[*,1]* sin(phase)
	thx_xxx_out.Y[*,1]=-thx_xxx_in.Y[*,0]*  sin(phase) +thx_xxx_in.Y[*,1]* cos(phase)
endelse

dl_out=dl_in ; krb
cotrans_set_coord,  dl_out, out_coord ; krb
;; clear ytitle, so that it won't contain wrong info.
str_element, dl_out, 'ytitle', /delete
l_out=l_in
str_element, l_out, 'ytitle', /delete

store_data,name_output,data=thx_xxx_out, limit=l_out, dl=dl_out ; krb


DPRINT, 'done'

end
