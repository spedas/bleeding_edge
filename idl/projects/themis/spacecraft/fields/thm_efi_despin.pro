;+
; Despin routine for EFI high-res (eff/efp/efw) data.
;
; Syntax:
;                thm_efi_despin , probe, datatype, offset, gain [, NOTCH ] [, TWEAK_GAINS ] [, STORED_TNAMES ]
;
; Inputs:
;         PROBE: Input, 1-character string identifying which spacecraft.
;      DATATYPE: Input, string.  3-character string identifying data type ('eff','efp' or 'efw')
;        OFFSET: Input, float, 1 x n (2 dimensions) 3-element array: Ex, Ey, Ez offset.
;          GAIN: Input, float.  3-element array: E12, E34, E56 gain.
;    TPLOT_NAME: Input.  String scalar containing the name of the TPLOT variable to operate on (regardless of PROBE and DATATYPE kwd's).
;
; Options:
;         NOTCH: Numeric, 0 or 1.  Set equal to the # of harmonics to remove (including fundamental) (i.e. notch=1 removes fundamental only, notch=2 also
;		 removes 1st harmonic) (default=0 does not notch filter anything).  *** DISABLED ***.
;   TWEAK_GAINS: Numeric, 0 or 1.  Set flag to tweak the E12/E34 gains to minimize the spin tone newname: If specified, the cleaned data is stored as a
;		 tplot variable with name=newname instead of the default 'th'+sc+'_'+datatype+'_dsl'.
;
; Outputs:
;    *** Creates a new tplot variable with the name 'th'+sc+'_'+datatype+'_dsl' or whatever is specified by the newname keyword. ***
;
; STORED_TNAMES: Returns a string array containing each TPLOT variable name invoked in a STORE_DATA operation (chronological order).  (Not sorted or uniqued.)
;
; Restrictions:
;      Required data must be loaded, including spin phase data.
; Notes:
;    This routine ignores E56 when despinning.  That is desireable over
;      the full transform (a la THM_COTRANS.PRO) because the resolution on E56
;      is much lower than for the spin plane sensors (E12 and E34) so mixing
;      in E56 would often increase the noise, and because the geometric
;      axis is w/in 1 degree of the spin axis making the result effectively
;      in DSL.
;
; Modifications:
;    Switched from THM_SPIN_PHASE.PRO to Jim Lewis' SPINMODEL_INTERP_T.PRO,
;      (commented out GET_DATA's to _state_spinper/spinphase, modified error
;      conditional), edited warning message, up'd doc'n, W.M.Feuerstein,
;      3/19/08.
;    Added TPLOT_NAME to specify var. to read.  Otherwise, PROBE and DATATYPE
;      parameters are used to derive tplot var. name to read.  Changed default
;      suffix to "_dsz" to match the "THEMIS Science Coordinate Systems
;      Definition" (THM-SOC-110).
;    Made sure "V" field is carried through data (otherwise it crashes
;      THM_CAL_EFI.PRO), redined suffix to "_dsl" (effectively true), fixed
;      potential bitwise vs. logical conditional bug, updated doc'n, WMF,
;      3/21/2008 (F).
;    Put in return on errors w/ messages for DLIMITS.DATA_ATT.COORD_SYS equal
;      to 'dsl' or 'spg', set said field to 'dsl' on conclusion of
;      processing, updat'd doc'n, WMF, 3/24/2008.
;    Checks validity of pointer from SPINMODEL_GET_PTR.PRO and calls
;      THM_LOAD_SPIN,PROBE=PROBE[0] on fail, installed an alternate test for
;      spinmodel data (TNAMES('th?_spin*')) to check an error from
;      SPINMODEL_INTERP_T.PRO but the error is unrelated, WMF, 3/26/2008.
;    Removed check on pointer in favor of incorporating THM_LOAD_SPIN.PRO into
;      THM_LOAD_STATE.PRO, WMF, 3/27/2008.
;    Updated doc'n, WMF, 3/27/2008.
;    Changed "Despinning <variable>" PRINT to MESSAGE, if data already despun
;      save TPLOT var. instead of just returning (BugzID 111), WMF, 4/4/08 (F).
;    Disabled BOOM_OFFSET parameter which is obsolete, WMF, 4/22/2008 (Tu).
;    Upd'd doc'n, WMF, 5/21/2008.
;    Change (spin-dependent) offset parameter to optional kw OFFSET.  Subtract OFFSET only if provided and only if there are 2 spin-dependent
;      offsets in boom plane, WMF, 3/2/2009.
;    Return OFFSET to a parameter: Subtract X, Y, Z for 2 spin-dependent offsets in boom plane; subtract Z only for 4 spin-dependent offsets, WMF, 3/5/09.
;
; $LastChangedBy: michf $
; $LastChangedDate: 2008-05-15 11:17:41 -0700 (Thu, 15 May 2008) $
; $LastChangedRevision: 3095 $
; $URL: $
;-

pro thm_efi_despin , probe, datatype, offset, gain, $
;  notch=notch, $
  newname=newname, $
  tweak_gains=tweak_gains, $
  tplot_name=tplot_name, $
  stored_tnames = stored_tnames, $
  use_eclipse_corrections=use_eclipse_corrections,$
  _extra=_extra


  ;==========
  ; Get data:
  ;==========
  if ~size(tplot_name,/type) then $
    get_data,'th'+probe[0]+'_'+datatype,data=data,lim=lim,dlim=dlim else $
    get_data,tplot_name,data=data,lim=lim,dlim=dlim
  eff_t=data.x
  eff=data.y
  ;

  ;===========================
  ;Check that data is present:
  ;===========================
  if n_elements(eff_t) eq 1 then begin
       dprint,'ERROR in thm_efi_despin: data not available.  Returning...'
       return
  endif


  ;=========================================================================
  ;Return if data is in a coord. sys. that this routine is not designed for:
  ;=========================================================================
  coord=cotrans_get_coord(dlim)
  if coord ne 'spg' && coord ne 'dsl' then begin
    message,'*** WARNING!:  THM_EFI_DESPIN.PRO only accepts input data in ' + 'SPG or DSL coordinates.  Returning...'
    return
  endif

  ;===================================
  ;If data is already in the DSL coordinate system,
  ;assign Ex,Ey,Ez without despinning:
  ;===================================
  if coord eq 'dsl' then begin
    dprint,'Data is already despun.  '+ 'Saving without applying EFI despin...'
    Ex=eff[*,0]
    Ey=eff[*,1]
    Ez=eff[*,2]


  ;=============
  ;Else, despin:
  ;=============
  endif else begin


    ;=================================================
    ;Notify the user that EFI despin is being applied:
    ;=================================================
    if ~(~size(tplot_name,/type)) then $
      dprint,'Applying EFI despin to: '+tplot_name else $
      dprint,'Applying EFI despin to: ','th'+probe[0]+'_'+datatype


    ;=======================
    ;Interpolate spin phase:
    ;=======================
    model=spinmodel_get_ptr(probe[0],use_eclipse_corrections=use_eclipse_corrections)
    If(obj_valid(model) Eq 0) Then Begin ;load state data, if not present
      thm_load_state, probe = probe[0], trange = minmax(eff_t), /get_support_data
      model = spinmodel_get_ptr(probe[0],use_eclipse_corrections=use_eclipse_corrections)
    Endif

    spinmodel_interp_t,model=model,time=eff_t, spinphase=phase,spinper=spinper,use_spinphase_correction=1       ;a la J. L.


    ;============================
    ;Despin and subtract offsets:
    ;============================
    phase*=!dtor
    phase-=45*!dtor
    if keyword_set(tweak_gains) then begin
      Ex1 = eff[*,0]*gain[0]*sin(phase)
      Ex2 = eff[*,1]*gain[1]*cos(phase)
      Ey1 = -eff[*,0]*gain[0]*cos(phase)
      Ey2 = eff[*,1]*gain[1]*sin(phase)
      tweak1 = smooth(Ex1,60)/smooth(Ex2,60)
      tweak2 = smooth(Ey1,60)/smooth(Ey2,60)
      Ex = Ex1+Ex2*median(tweak1)
      Ey = Ey1+Ey2*median(tweak1)
    endif else begin

      Ex = eff[*,0]*gain[0]*sin(phase)  + eff[*,1]*gain[1]*cos(phase)

;      ;To analyze frequency spectra.  Comment for normal use:
;      ;******************************************************
;      ;
;      Ex0=eff[*,0]*gain[0]*sin(phase)
;      Ex1=eff[*,1]*gain[1]*cos(phase)
;      ;
;      case (size(offset,/dimensions))[1] of  ;Needed for Ey section below as well.
;	3: suffix= '_2sdo'                       ;2 spin-dependent offsets in boom plane.
;	5: suffix= '_4sdo'                  ;4 spin-dependent offsets in boom plane.
;      endcase
;      ;
;      tempname= newname+'_E12'+suffix
;      store_data, tempname, data={x:eff_t,y:eff[*,0]},lim=lim,dlim=dlim
;      options, tempname, 'ytitle', 'E12
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      tempname= newname+'_E34'+suffix
;      store_data, tempname, data={x:eff_t,y:eff[*,1]}, lim=lim, dlim=dlim
;      options, tempname, 'ytitle', 'E34
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      ;
;      tempname= newname+'_Ex0'+suffix
;      store_data, tempname, data= {x:eff_t,y:Ex0}, lim=lim, dlim=dlim
;      options, tempname, 'ytitle', 'Ex0
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      tempname= newname+'_Ex1'+suffix
;      store_data, tempname, data= {x:eff_t,y:Ex1}, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'Ex1
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      tempname= newname+'_Ex'+suffix
;      store_data, tempname, data= {x:eff_t,y:Ex}, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'Ex
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      tempname= newname+'_cos'+suffix
;      store_data, tempname, data= {x:eff_t, y:cos(phase)}, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'cos(phase)
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 


      Ey = -eff[*,0]*gain[0]*cos(phase) + eff[*,1]*gain[1]*sin(phase)

;      ;To analyze frequency spectra.  Comment for normal use:
;      ;******************************************************
;      ;
;      Ey0= -eff[*,0]*gain[0]*cos(phase)
;      Ey1=  eff[*,1]*gain[1]*sin(phase)
;      ;
;      tempname= newname+'_Ey0'+suffix
;      store_data, tempname, data= {x:eff_t,y:Ey0}, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'Ey0
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      tempname= newname+'_Ey1'+suffix
;      store_data, tempname, data= {x:eff_t, y:Ey1}, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'Ey1
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      ;
;      tempname= newname+'_Ey'+suffix
;      store_data, tempname, data= {x:eff_t,y:Ey}, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'Ey
;      options, tempname, 'labels', ''
;      tdpwrspc, tempname 
;      tempname= newname+'_Ex_Ey'+suffix
;      store_data, tempname, data= {x: eff_t, y: [[Ex],[Ey]] }, lim=lim, dlim=dlim
;      options, tempname , 'ytitle', 'Ex, Ey
;      options, tempname, 'labels', ['Ex_'+suffix,'Ey_'+suffix]


    endelse
    Ez = eff[*,2]*gain[2]
    ;
    case (size(offset,/dimensions))[1] of
      3: begin                            ;2 spin-dependent offsets in boom plane.
	Ex-=offset[0]
	Ey-=offset[1]
	Ez-=offset[2]
      end
      5: Ez-=offset[2]                    ;4 spin-dependent offsets in boom plane.
    endcase


    ;===========================
    ;Notch filter (if required):
    ;===========================
;    if n_elements(notch) ne 0 then if notch gt 0 then begin
;      rate = eff_t[1]-eff_t[0]
;      notch_filter,Ex,notch,rate
;      notch_filter,Ey,notch,rate
;      notch_filter,Ez,notch,rate
;    endif


    ;======================
    ;Change COORD_SYS flag:
    ;======================
    cotrans_set_coord,dlim,'dsl'

  endelse


  ;===========
  ;Write data:
  ;===========
  if ~(~size(tplot_name,/type)) then begin
    if n_elements(newname) eq 0 then newname=tplot_name+'_dsl'
  endif else begin
    if n_elements(newname) eq 0 then newname='th'+probe[0]+'_'+datatype+'_dsl'
  endelse
  store_data,newname,data={x:eff_t,y:[[Ex],[Ey],[Ez]],v:data.v}, lim=lim,dlim=dlim
  if ~(~size(stored_tnames,/type)) then stored_tnames = [ stored_tnames, newname ] else stored_tnames = [ newname ]

  dprint,'Stored despun data (SPG -> DSL) in tplot variable '+newname

end
