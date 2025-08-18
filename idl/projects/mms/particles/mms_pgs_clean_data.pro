
;+
;Procedure:
;  mms_pgs_clean_data
;
;
;Purpose:
;  Sanitize mms FPI/HPCA data structures for use with
;  mms_part_products.  Excess fields will be removed and 
;  field names conformed to standard.  
;
;  Reforms energy by theta by phi to energy by angle
;  Converts units
;
;Input:
;  data_in: Single combined particle data structure
;
;
;Output:
;  output: Sanitized output structure for use within mms_part_products.
;
;
;Notes:
;  -not much should be happening here since the combined structures 
;   are already fairly pruned
;  -use for fpi and hpca for now
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-06-30 07:36:07 -0700 (Fri, 30 Jun 2017) $
;$LastChangedRevision: 23532 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_pgs_clean_data.pro $
;
;-
pro mms_pgs_clean_data, data_in, output=output,units=units

  compile_opt idl2,hidden

  mms_convert_flux_units,data_in,units=units,output=data

  dims = dimen(data.data)
  
  output= {  $
    dims: dims, $
    time: data.time, $
    end_time:data.end_time, $
    charge:data.charge, $
    mass:data.mass,$
    species: data.species, $
    magf:[0.,0.,0.],$
    sc_pot:0.,$
    scaling:fltarr(dims[0],dims[1]*dims[2])+1,$
    units:units,$
    psd: reform(data_in.data,dims[0],dims[1]*dims[2]), $
    data: reform(data.data,dims[0],dims[1]*dims[2]), $
    bins: reform(data.bins,dims[0],dims[1]*dims[2]), $
    energy: reform(data.energy,dims[0],dims[1]*dims[2]), $
    denergy: reform(data.denergy,dims[0],dims[1]*dims[2]), $ ;placeholder
    phi:reform(data.phi,dims[0],dims[1]*dims[2]), $
    dphi:reform(data.dphi,dims[0],dims[1]*dims[2]), $
    theta:reform(data.theta,dims[0],dims[1]*dims[2]), $
    dtheta:reform(data.dtheta,dims[0],dims[1]*dims[2]) $
  }

  if tag_exist(data, 'orig_energy') then str_element, output, 'orig_energy', data.orig_energy, /add

  de = output.energy-shift(output.energy,1,0)
  output.denergy=shift((de+shift(de,1,0))/2.,-1)
  output.denergy[0,*] = de[1,*] ;just have to make a guess at the edges(bottom edge)
  output.denergy[dims[0]-1,*] = de[dims[0]-1,*] ;just have to make a guess at the edges(top edge)
 
end