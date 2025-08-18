;+
;Procedure:
;  mms_pgs_split_hpca
;
;Purpose:
;  Split hpca elevation bins so that dphi == dtheta.
;  Combined with updates to spectra generation code this should allow
;  the regrid step for FAC spectra to be skipped in mms_part_products.
;   
;Input:
;  data:  Sanitized hpca data structure
;
;Output:
;  output:  New structure with theta bins split in two
;           (2x data points in angle dimension)
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-06-30 07:36:07 -0700 (Fri, 30 Jun 2017) $
;$LastChangedRevision: 23532 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_pgs_split_hpca.pro $
;-
pro mms_pgs_split_hpca, data, output=output

  compile_opt idl2,hidden
  
  if tag_exist(data, 'orig_energy') then begin
    output = {  $
      dims: data.dims, $
      time: data.time, $
      end_time: data.end_time, $
      charge: data.charge, $
      mass: data.mass, $
      species: data.species, $
      magf: data.magf, $
      sc_pot: data.sc_pot, $
      scaling:[[data.scaling],[data.scaling]], $
      units: data.units, $
      data: [[data.data],[data.data]], $
      psd: [[data.psd],[data.psd]], $
      bins: [[data.bins],[data.bins]], $
      orig_energy: data.orig_energy, $
      energy: [[data.energy],[data.energy]], $
      denergy: [[data.denergy],[data.denergy]], $ ;placeholder
      phi: [[data.phi],[data.phi]], $
      dphi: [[data.dphi],[data.dphi]], $
      theta: [[data.theta+(0.25*data.dtheta)],[data.theta-(0.25*data.dtheta)]], $
      dtheta: [[data.dtheta],[data.dtheta]]/2 $
    }
  endif else begin
    output = {  $
      dims: data.dims, $
      time: data.time, $
      end_time: data.end_time, $
      charge: data.charge, $
      mass: data.mass, $
      species: data.species, $
      magf: data.magf, $
      sc_pot: data.sc_pot, $
      scaling:[[data.scaling],[data.scaling]], $
      units: data.units, $
      data: [[data.data],[data.data]], $
      psd: [[data.psd],[data.psd]], $
      bins: [[data.bins],[data.bins]], $
      energy: [[data.energy],[data.energy]], $
      denergy: [[data.denergy],[data.denergy]], $ ;placeholder
      phi: [[data.phi],[data.phi]], $
      dphi: [[data.dphi],[data.dphi]], $
      theta: [[data.theta+(0.25*data.dtheta)],[data.theta-(0.25*data.dtheta)]], $
      dtheta: [[data.dtheta],[data.dtheta]]/2 $
    } 
  endelse

end