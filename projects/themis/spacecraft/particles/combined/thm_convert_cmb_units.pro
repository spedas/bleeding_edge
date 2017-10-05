;+
;Procedure:
;  thm_convert_cmb_units.pro
;
;Purpose:
;  Unit conversion routine for combined (ESA+SST) particle distributions.
;  
;  
;Calling Sequence:
;  This procedure is called implicitly by conv_units.pro
;
;
;Inputs:
;  data: single combined distribution structure
;  units: string specifying the target units (flux, eflux, or df)
;  scale: set to named variable to pass out conversion factor
;
;
;Outputs:
;  none, modifies input structure
;  
;
;Notes:
;  
;  
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:12:33 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20333 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/combined/thm_convert_cmb_units.pro $
;
;-

pro thm_convert_cmb_units, data, units, scale=scale

    compile_opt idl2, hidden


  scale = 1.
  
  if strlowcase(units) eq strlowcase(data.units_name) then return
  
  length_factor = 1e5 ;km <--> cm
  mass = data.mass
  
  ;get scaling factors between current units and eflux
  case strlowcase(data.units_name) of
    'eflux': in_scale = 1d                ;eV/(cm^2 sec sr eV)
    'flux' : in_scale = 1d * data.energy  ; #/(cm^2 sec sr eV)
    'df'   : in_scale = 1d * (data.energy^2 * 2./mass/mass*length_factor) ; sec^3 /(km^3 /cm^3)
    else: begin
      dprint, dlevel=1, 'Unknown starting units: '+data.units_name
      return
    end
  endcase
  
  ;get scaling factors between eflux and target units
  case strlowcase(units) of
    'eflux': out_scale = 1d                ;eV/(cm^2 sec sr eV)
    'flux' : out_scale = 1d / data.energy  ; #/(cm^2 sec sr eV)
    'df'   : out_scale = 1d / (data.energy^2 * 2./mass/mass*length_factor) ; sec^3 /(km^3 /cm^3)
    else: begin
      dprint, dlevel=1, 'Unknown target units: '+units
      return
    end
  endcase
  
  ;combine factors
;  scale = in_scale * out_scale
  
  ;convert
  data.data = in_scale * out_scale * data.data
  
  data.units_name = strlowcase(units)
  
  return  
  
end
