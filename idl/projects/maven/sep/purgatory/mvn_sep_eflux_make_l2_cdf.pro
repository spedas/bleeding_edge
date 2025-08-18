

pro mvn_sep_eflux_make_l2_cdf_individual,fileid,det,spec,default_atts=default_atts,escale=escale
energy_name = det+'_energy'
eflux_name  = det+'_eflux'
atts= struct(default_atts,validmin=0.,validmax=1e10)
atts.display_type = ''
e_atts =struct(atts,var_type='support_data',fieldnam=energy_name,lablaxis=energy_name,format='F10.1')
if keyword_set(escale) then e_atts = struct(e_atts,scalemin=escale[0],salemax=escale[1])
ef_atts=struct(atts,var_type='data'        ,fieldnam=eflux_name, lablaxis=eflux_name,depend_1=energy_name,scalemin=1e-3,scalemax=1e5,format='E10.3',scaletyp='log')
ef_atts.display_type = 'spectrogram'
uf_atts=struct(atts,var_type='support_data',fieldnam=eflux_name+'_unc', lablaxis=eflux_name+'_unc',depend_1=energy_name,scalemin=1e-3,scalemax=1e5,format='E10.3')
uf_atts.catdesc = 'uncertainty in differential energy flux for '+det+' FOV'
ef_atts.catdesc = 'differential energy flux for '+det+' FOV'
e_atts.catdesc = 'energy values for '+det+' FOV'
e_atts.units= 'keV'
ef_atts.units = 'keV/(cm^2-s-sr-keV)'
mvn_sep_mvn_sep_cdf_var_att_create,fileid,eflux_name,spec.eflux,attributes=ef_atts
if keyword_set(unc) then mvn_sep_mvn_sep_cdf_var_att_create,fileid,eflux_name+'_unc',unc,attributes=uf_atts
mvn_sep_mvn_sep_cdf_var_att_create,fileid,energy_name,spec.energy,attributes=e_atts
end










;+
;PROCEDURE: 
;	MVN_SEP_EFLUX_MAKE_L2_CDF
;PURPOSE: 
;	Routine to produce deconvoluted energetic electron and ion fluxes
;AUTHOR: 
;	Robert Lillis (rlillis@ssl.Berkeley.edu) and D. Larson
;CALLING SEQUENCE:
;	MVN_SEP_EFLUX_MAKE_L2_CDF, FILENAME=FILENAME
;KEYWORDS:
;	FILE: Output file name
;
; This function assumes the existence of 2 structures: "sep_vary" and "sep_novary" 
; sep_novary should have the following tags:
; 1) ion_energy - an array of 16 (TBR) ion energies 
; 2) electron_energy -an array of 8 (TBR) electron energies
;
; sep_vary should be an array of structures and have the following tags:
; 1) time_UNIX
; 2) time_MET
; 3) Delta_t - the number of 1-second accumulations per spectrum
; 4) Atten_State - 1 = open, 2 = closed
; 5) Electron_Energy_Flux - 16 x 4-element array differential energy flux of ions in each look direction
; 6) Ion_Energy_Flux - 8 x 4-element array differential energy flux of electrons in each look direction
; 7) Look_Directions - 4 x 3-element array of unit vectors of each of the four FOVs in Mars-solar-orbital coordinates.


pro mvn_sep_eflux_make_l2_cdf, sep_vary, sep_novary,filename = filename,pathformat=pathformat,rootdir=rootdir,get_filename=get_filename,res=res

;, global_attribute_names = global_attribute_names, $
;  global_attribute_values = global_attribute_values, $
;  rawdat_sep1 = rawdat_sep1, rawdat_sep2 = rawdat_sep2, bmaps=bmaps, $
; archive = archive, data_version = data_version

time = sep_vary.time
time_name = 'TIME_UNIX'
epoch_name = 'Epoch'

nrec = n_elements(sep_vary)


extra = mvn_sep_sw_version()

if not keyword_set(data_version) then data_version = extra

tr = minmax(time)
dprint,time_string(tr)
days = round( tr /86400)
ndays = days[1]-days[0]
tr = days * 86400d

ver_str = extra.sw_version
timeres_str = '10min'
timeres_str = 'full'
ndays_str = (ndays le 1) ? '' : '_'+strtrim(ndays,2)+'day'
filename=0
data_type = 'S2-cal-eflux-svy-RES'    ;+timeres_str    ;full'
if ~keyword_set(filename) then begin
  if ~keyword_set(pathformat) then pathformat = 'maven/pfp/sep/l2/RES/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_NDAYS_VERS.cdf'
  pf = time_string(tr[0],tformat=pathformat)
  pf = str_sub(pf,'RES',timeres_str)
  pf = str_sub(pf,'_NDAYS',ndays_str)
  pf = str_sub(pf,'VERS',ver_str)
  if ~keyword_set(rootdir) then rootdir = root_data_dir()
  filename = rootdir + pf
endif



cdf_leap_second_init

date_range = time_double(['2010-1-1','2030-1-1'])
met_range = [0d, 30d*86400.*365]

epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(time)
timett2000 = long64((add_tt2000_offset(time)-time_double('2000-01-01/12:00'))*1e9)

file_mkdir2,file_dirname(filename)
fileid = cdf_create(filename,/single_file,/network_encoding,/clobber)


;FIX ME: make sure the variables associated with raw counts are produced.  Currently they are not.
;varlist = strupcase( ['Epoch','Time_TT2000','Time_MET','Time_Unix','Atten_State',$
;           'Accumulation_Time', 'Look_Directions', $
;           'Electron_Energy_Flux', 'Ion_Energy_Flux','Electron_Energy', 'Ion_Energy'])
;nvars = n_elements(varlist)


id0 = cdf_attcreate(fileid,'Title',/global_scope)
id1 = cdf_attcreate(fileid,'Project',/global_scope)
id2 = cdf_attcreate(fileid,'Discipline',/global_scope)
id3 = cdf_attcreate(fileid,'Source_name',/global_scope)
id4 = cdf_attcreate(fileid,'Descriptor',/global_scope)
id5 = cdf_attcreate(fileid,'Data_type',/global_scope)
id6 = cdf_attcreate(fileid,'Data_version',/global_scope)
id7 = cdf_attcreate(fileid,'TEXT',/global_scope)
id8 = cdf_attcreate(fileid,'Mods',/global_scope)
id9 = cdf_attcreate(fileid,'Logical_file_id',/global_scope)
id10 = cdf_attcreate(fileid,'Logical_source',/global_scope)
id11 = cdf_attcreate(fileid,'Logical_source_description',/global_scope)
id12 = cdf_attcreate(fileid,'PI_name',/global_scope)
id13 = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
id14 = cdf_attcreate(fileid,'Instrument_type',/global_scope)
id15 = cdf_attcreate(fileid,'Mission_group',/global_scope)
id16 = cdf_attcreate(fileid,'Parents',/global_scope)

extra = mvn_sep_sw_version()
if keyword_set(extra) then exnames = tag_names(extra)
for i=0,n_elements(exnames)-1 do  idxx = cdf_attcreate(fileid,exnames[i],/global_scope)


;Load global Attributes

cdf_attput,fileid,'Title',0,'MAVEN SEP Electron and Ion spectra'
cdf_attput,fileid,'Project',0,'MAVEN'
;cdf_attput,fileid,'Discipline',0,'Planetary Space Physics>Particles'
cdf_attput,fileid,'Discipline',0,'Space Physics>Interplanetary Studies'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
cdf_attput,fileid,'Data_type',0,data_type+'>Survey calibrated Particle Energy Flux'
cdf_attput,fileid,'Data_version',0,ver_str
cdf_attput,fileid,'TEXT',0,'MAVEN SEP electron and ion spectra'
cdf_attput,fileid,'Mods',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,filename
cdf_attput,fileid,'Logical_source',0,'SEP.calibrated.spec_svy'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SEP (Solar Energetic Particle) electron and ion spectra in 4 look directions'
cdf_attput,fileid,'PI_name',0,'Davin Larson (davin@ssl.berkeley.edu)'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Energetic Particle Detector'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
for i=0,n_elements(dependencies)-1 do    cdf_attput,fileid,'Parents',i,  file_checksum(dependencies[i],/add_mtime)
for i=0,n_elements(exnames)-1 do     cdf_attput,fileid,exnames[i],0,extra.(i)



; Variable attributes

default_atts = {fieldnam:'',monoton:'',format:'F10.2',lablaxis:'',VAR_TYPE:'support_data',fillval:!values.f_nan,DISPLAY_TYPE:'',scaletyp:'linear', $
      VALIDMIN:-1e31,VALIDMAX:1e31,SCALEMIN:0.,SCALEMAX:100.,UNITS:'',CATDESC:'', $
      FORM_PTR:'',DEPEND_TIME:time_name,DEPEND_0:epoch_name,DEPEND_1:'',DEPEND_2:'' }

tags=tag_names(default_atts)
for i=0,n_elements(tags)-1 do dummy=cdf_attcreate(fileid,tags[i],/variable_scope)

;dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
;dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
;dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
;dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
;dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
;dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
;dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
;dummy = cdf_attcreate(fileid,'DEPEND_TIME',/variable_scope)
;dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
;dummy = cdf_attcreate(fileid,'DEPEND_1',/variable_scope)
;dummy = cdf_attcreate(fileid,'DEPEND_2',/variable_scope)
;dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
;dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
;dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
;dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
;dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
;dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
;dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)


;Unix Time

varid = cdf_varcreate(fileid, time_name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,time_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,'Time (UTC)',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0.d,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,1d10,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'sec',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in Unix time',/ZVARIABLE

cdf_varput,fileid,time_name,time



;Epoch

varid = cdf_varcreate(fileid, epoch_name, /CDF_EPOCH, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.0',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,'Epoch Time',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,epoch_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,epoch_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,epoch[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,epoch[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'ms',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in NSSDC Epoch',/ZVARIABLE

cdf_varput,fileid,epoch_name,epoch


;TT2000

varname = 'Time_TT2000'
varid = cdf_varcreate(fileid, varname, /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,0,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,tt2000_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,tt2000_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,timett2000[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,timett2000[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in TT2000 time base',/ZVARIABLE

cdf_varput,fileid,varname,timett2000


;MET
varname = 'Time_MET'
varid = cdf_varcreate(fileid, varname, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,sep_vary[0].met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,sep_vary[nrec-1].met,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in raw mission elapsed time',/ZVARIABLE

cdf_varput,fileid,varname,sep_vary.met



;Ephemeris time
varname = 'Time_Ephemeris'
varid = cdf_varcreate(fileid, varname, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,sep_vary[0].met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,sep_vary[nrec-1].met,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Ephermeris Time, middle of sample, compatible with spice',/ZVARIABLE

str_element,sep_vary,'time_ephemeris',et
str_element,sep_vary,'et',et
if ~keyword_set(et) then et = time_ephemeris(sep_vary.time)
cdf_varput,fileid,varname,et



;Attenuator State
;dim_vary = [1]
;dim = 1
varname = 'Attenuator_State'
varid = cdf_varcreate(fileid, varname,/CDF_INT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,2,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,3,/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Attenuator state for each of the four look directions, 0=Error,  1 = open, 2 = closed,   3= mixed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE

cdf_varput,fileid,varname,sep_vary.att



; Accumulation Time
varname = 'Accum_Time'
varid = cdf_varcreate(fileid, varname, /CDF_INT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,0,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,8192,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,8192,/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Number of 1-second accumulations contained within this data sample.',/ZVARIABLE
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE

cdf_varput,fileid,varname,sep_vary.duration







;Individual look directions
det = 'Sep1_front_elec'
eflux_name = det+'_flux'
energy_name = det+'_energy'
eflux = sep_vary

mvn_sep_eflux_make_l2_cdf_individual,fileid,'SEP-2F_elec',sep_vary.f_elec,default_atts=default_atts
mvn_sep_eflux_make_l2_cdf_individual,fileid,'SEP-2R_elec',sep_vary.r_elec,default_atts=default_atts
mvn_sep_eflux_make_l2_cdf_individual,fileid,'SEP-2F_ion',sep_vary.f_ion,default_atts=default_atts
mvn_sep_eflux_make_l2_cdf_individual,fileid,'SEP-2R_ion',sep_vary.r_ion,default_atts=default_atts

;mvn_sep_eflux_make_l2_cdf_individual,fileid,'Sep-2F_elec_energy',sep_vary.f_elec.energy,default_atts=default_atts
;mvn_sep_eflux_make_l2_cdf_individual,fileid,'Sep-2R_elec_energy',sep_vary.r_elec.energy,default_atts=default_atts
;mvn_sep_eflux_make_l2_cdf_individual,fileid,'Sep-2F_ion_energy',sep_vary.f_ion.energy,default_atts=default_atts
;mvn_sep_eflux_make_l2_cdf_individual,fileid,'Sep-2R_ion_energy',sep_vary.r_ion.energy,default_atts=default_atts




;Individual look directions
if 0 then begin
sepnames = ['Sep1','Sep2']
sepnames = 'Sep2'

dirnames = ['Front','Back']
partnames= ['Electron','Ion']
e_scalemin = [20.,20]
e_scalemax = [700.,10e3]

for p=0,n_elements(partnames)-1 do begin  

for s=0,n_elements(sepnames)-1 do begin
elec_energy = sep_vary.elec_energy                ; fix this!    
ion_energy =  sep_vary.ion_energy
elec_eflux = sep_vary.elec_eflux
ion_eflux =  sep_vary.ion_eflux
elec_eflux_unc = sep_vary.elec_eflux_unc
ion_eflux_unc = sep_vary.ion_eflux_unc
for d=0,n_elements(dirnames)-1 do begin
det = sepnames[s]+'_'+dirnames[d]+'_'+partnames[p]
energy = (p eq 0) ? reform(elec_energy[*,d,*]) :  reform(ion_energy[*,d,*])
eflux = (p eq 0) ? reform(elec_eflux[*,d,*]) :  reform(ion_eflux[*,d,*])
unc = (p eq 0) ? reform(elec_eflux_unc[*,d,*]) :  reform(ion_eflux_unc[*,d,*])

;printdat,energy,eflux
energy_name= det+'_energy'   
eflux_name =  det+'_eflux'  
atts= struct(default_atts,validmin=0.,validmax=1e10)
atts.display_type = ''
e_atts =struct(atts,var_type='support_data',fieldnam=energy_name,lablaxis=energy_name,scalemin=e_scalemin[p],scalemax=e_scalemax[p],format='F10.1')
ef_atts=struct(atts,var_type='data'        ,fieldnam=eflux_name, lablaxis=eflux_name,depend_1=energy_name,scalemin=1e-3,scalemax=1e5,format='E10.3',scaletyp='log')
ef_atts.display_type = 'spectrogram'
uf_atts=struct(atts,var_type='support_data',fieldnam=eflux_name+'_unc', lablaxis=eflux_name+'_unc',depend_1=energy_name,scalemin=1e-3,scalemax=1e5,format='E10.3')
uf_atts.catdesc = partnames[p]+' uncertainty in differential energy flux for '+det+' FOV'
ef_atts.catdesc = partnames[p]+' differential energy flux for '+det+' FOV'
e_atts.catdesc = partnames[p]+' energy values for '+det+' FOV'
e_atts.units= 'keV'
ef_atts.units = 'keV/(cm^2-s-sr-keV)'
mvn_sep_cdf_var_att_create,fileid,eflux_name,eflux,attributes=ef_atts
mvn_sep_cdf_var_att_create,fileid,eflux_name+'_unc',unc,attributes=uf_atts
mvn_sep_cdf_var_att_create,fileid,energy_name,energy,attributes=e_atts
endfor
endfor
endfor

endif

if 0 then begin
; Electron Energy Flux
elec_energy_name = 'Electron_Energy'
ion_energy_name = 'Ion_Energy'
elec_eflux_name = 'Electron_Eflux'
ion_eflux_name = 'Ion_Energy_Flux'

n_electron_energy =34  ; =n_elements(elec_energy)
n_ion_energy = 34   ; n_elements(ion_energy)

dim_vary = [1,1]  
dim = [2, n_electron_energy]  
dim = [n_electron_energy,2]  

varid = cdf_varcreate(fileid, elec_eflux_name,dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,elec_eflux_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,elec_eflux_name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.f_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,1e-2,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'keV/(cm^2-sec-ster-keV)',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Electron differential energy flux in each of the four look directions',/ZVARIABLE
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_1',varid,elec_energy_name,/ZVARIABLE

cdf_varput,fileid,elec_eflux_name,elec_eflux


; Ion Energy Flux

dim_vary = [1,1]  
dim = [2, n_ion_energy]  
dim = [n_ion_energy,2]  
varid = cdf_varcreate(fileid, ion_eflux_name,dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,ion_eflux_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,ion_eflux_name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.f_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,1e-3,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'keV/(cm^2 second steradian keV)',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Ion differential energy flux in each of the four look directions',/ZVARIABLE
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_1',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_2',varid,ion_energy_name,/ZVARIABLE

cdf_varput,fileid,ion_eflux_name,ion_eflux

;Electron Energy

;electon_energy = sep_novary.elec_energy
dim_vary = [1,1]
dim = n_electron_energy
dim = [n_electron_energy,2]  
varid = cdf_varcreate(fileid, elec_energy_name, dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,elec_energy_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,elec_energy_name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.f_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,2e4,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'keV',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Electron energy table',/ZVARIABLE
;cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
;cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE

cdf_varput,fileid,elec_energy_name,elec_energy

;Ion Energy

;ion_energy = sep_novary.elec_energy

ion_energy_name = 'Ion_Energy'
dim_vary = [1,1]
dim = [n_ion_energy,2]

varid = cdf_varcreate(fileid, ion_energy_name, dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,ion_energy_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,ion_energy_name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.f_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,1e4,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,1e5,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,1e3,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,2e4,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'keV',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Ion energy table',/ZVARIABLE

cdf_varput,fileid,ion_energy_name,ion_energy

endif

cdf_close,fileid
dprint,dlevel=2,'Created: ',filename

end
