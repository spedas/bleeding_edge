;+
;Procedure:
;  mms_part_conv_units
;
;Purpose:
;  simple wrapper around mms_convert_flux_units that can be used 
;  as the 'units_procedure' in our 3d particle data structure
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-10 08:56:27 -0800 (Fri, 10 Mar 2017) $
;$LastChangedRevision: 22934 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_convert_flux_units.pro $
;-

pro mms_part_conv_units,dist,units, output=output, _extra=_extra
  mms_convert_flux_units,dist,units=units,output=output
end