pro mvn_sep_cdf_variable_load ,filename,varstruct    ; change name to write or create

cdf_default_attributes,global_att_names=gn,global_struct=ga,variable_struct=va  ,inq=inq,vars_template=vars_template
     
ga.title   = 'MAVEN SEP ion spectra'
ga.project = 'Planetary'
ga.discipline = 'Planetary Science>Planetary Plasma Interactions'
ga.descriptor = 'SEP> Solar Energetic Particle Instrument'
ga.data_type =  'Level 2'
ga.data_version= '1'
ga.logical_file_id = 'mvn_sep
ga.logical_source = 'sep.calibrated.spectra'
ga.logical_source_description = 'Energetic ion and electron fluxes'
ga.pi_name = 'Davin Larson'
ga.pi_affiliation = 'University of California, SSL'
ga.Instrument_type = 'Particles (space)'
ga.mission_group = 'MAVEN'
ga.HTTP_LINK ='http://lasp.colorado.edu/home/maven/'
ga.LINK_TEXT ='General Information about the MAVEN mission'
ga.LINK_TITLE = 'MAVEN homepage'

;  Get relevent SEP data:


printdat,sep1
;print_struct,sep1[0:20]

tagnames = tag_names(sep1)
n = n_elements(tagnames)
vars = replicate( vars_template , n )
for i = 0,n-1 do begin
   vars[i].name = tagnames[i]   
endfor

;dummy = cdf_save_vars()


if 0 then begin
id=cdf_create(filename,/clobber,/single_file,/host_decoding,/network_encoding,/col_major)

; Global Attributes
for i=0,n_elements(gn)-1 do begin
  global_dummy = cdf_attcreate(id, gn[i], /global_scope)
  n_atts = n_elements(cdf_structure.g_attributes.(i))   ; Some global attributes can have multiple values - save all
  for j = 0, n_atts-1 do    cdf_attput, id, gn[i], j,  (ga.(i))[j]
endfor 

;Variable Attributes  - First create them....
vatt_names=tag_names(va)
for i=0,n_elements(vatt_names)-1 do begin
  dummy = cdf_attcreate(id, vatt_names[i], /Variable_scope)
endfor

var_names = tag_names(varstruct)
for i=0,n_elements(var_names)-1 do begin
  dprint,var_names[i]
endfor
return
endif else begin

inq = {ndims:0L, $
       decoding: 'HOST_DECODING', $
       encoding: 'NETWORK_ENCODING', $
       majority: 'ROW_MAJOR', $
       maxrec: -1L, $
       nvars: 0L, $
       nzvars: n_elements(varstruct), $
       Natts:  n_elements(vatt_names), $
       dim: [0L] }

;not finished

endelse

end 

