;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_L2_DATA
;PURPOSE: 
;	Routine to load SWIA Level 0 data from a file and make Level 2 data files
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_L2_DATA, STARTDATE = STARTDATE, DAYS = DAYS, VERSION = VERSION, REVISION = REVISION, TYPE = TYPE, KLOAD = KLOAD, OLDCAL = OLDCAL
;INPUTS:
;KEYWORDS:
;	STARTDATE: Starting date to process
;	DAYS: Number of days to process
;	VERSION: Software version number to put in file (default '00')
;	REVISION: Data version number to put in file (default '00')
;	TYPE: 'svy' or 'arc' (default = 'svy')
;	L0_FILE_PATH: Hardwire the path to the L0 files (mainly for testing)
;	OPATH: Hardwire the output path for L2 files (mainly for testing)
;	KLOAD: Load all the relevant spice kernels if set
;	OLDCAL: Use old calibration factors appropriate for original table
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2022-03-17 07:28:03 -0700 (Thu, 17 Mar 2022) $
; $LastChangedRevision: 30687 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_l2_data.pro $
;
;-

@mvn_swia_load_l2_data
@matrix_array_lib

pro mvn_swia_make_l2_data, startdate = startdate, days = days,version = version, revision = revision, type = type, l0_file_path = l0_file_path, opath = opath, kload = kload, oldcal = oldcal

compile_opt idl2

common mvn_swia_data

timespan, startdate, days

if keyword_set(kload) then mk = mvn_spice_kernels(/all,/load,/reset)

if not keyword_set(version) then version = '02'
if not keyword_set(revision) then revision = '00'
if not keyword_set(type) then type = 'svy'


if type eq 'arc' then archive = 1 else archive = 0

if type eq 'arc' then ftype = 'all' else ftype = 'svy'

if not keyword_set(opath) then opath = '/disks/data/maven/data/sci/swi/l2/'
if not keyword_set(l0_file_path) then l0_file_path = '/disks/data/maven/data/sci/pfp/l0/'

date = startdate


ct0 = 0.d
ft0 = 0.d
cat0 = 0.d
fat0 = 0.d
mt0 = 0.d
st0 = 0.d
newc = 0
newf = 0
newca= 0
newfa= 0
news = 0
newm = 0

for i = 0,days-1 do begin

 	 date0 = strmid(time_string(date, format=6), 0, 8)
	  yyyy = strmid(date0, 0, 4)
	  mmmm = strmid(date0, 4, 2)
	  dddd = strmid(date0, 6, 2)
	  ppp = mvn_file_source()


	filex = mvn_l0_db2file(date,l0_file_type = ftype,l0_file_path=l0_file_path)
	
	if filex ne '' then mvn_swia_load_l0_data,filex,/tplot,/sync,qlevel = 0.0001, oldcal= oldcal
	
	if n_elements(swics) gt 1 then begin
		if swics[0].time_unix ne ct0 then begin
			ct0 = swics[0].time_unix
			newc = 1
		endif else newc = 0
	endif else newc = 0
	
	if n_elements(swifs) gt 1 then begin
		if swifs[0].time_unix ne ft0 then begin
			ft0 = swifs[0].time_unix
			newf = 1
		endif else newf = 0
	endif else newf = 0
	
	if n_elements(swica) gt 1 then begin
		if swica[0].time_unix ne cat0 then begin
			cat0 = swica[0].time_unix
			newca = 1
		endif else newca = 0
	endif else newca = 0
	
	if n_elements(swifa) gt 1 then begin
		if swifa[0].time_unix ne fat0 then begin
			fat0 = swifa[0].time_unix
			newfa = 1
		endif else newfa = 0
	endif else newfa = 0
	
	if type eq 'arc' then begin
		newc = newca
		newf = newfa
	endif
	
	if n_elements(swim) gt 1 then begin
		if swim[0].time_unix ne mt0 then begin
			mt0 = swim[0].time_unix
			newm = 1
		endif else newm = 0
	endif else newm = 0
	
	if n_elements(swis) gt 1 then begin
		if swis[0].time_unix ne st0 then begin
			st0 = swis[0].time_unix
			news = 1
		endif else news = 0
	endif else news = 0
		




	if newc then begin
		if type eq 'svy' then begin
			wind = where(swics.time_unix ge (time_double(date)-600) and swics.time_unix le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then swics = swics[wind]		
		endif else begin
			wind = where(swica.time_unix ge (time_double(date)-600) and swica.time_unix le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then swica = swica[wind]
		endelse		
	
		mvn_swia_make_swic_cdf,archive = archive,data_version='v'+version+'r'+revision,file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_coarse'+type+'3d_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'
	endif

	if newf then begin
		if type eq 'svy' then begin	
			wind = where(swifs.time_unix ge (time_double(date)-600) and swifs.time_unix le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then swifs = swifs[wind]	
		endif else begin
			wind = where(swifa.time_unix ge (time_double(date)-600) and swifa.time_unix le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then swifa = swifa[wind]
		endelse		

		mvn_swia_make_swif_cdf,archive = archive,data_version='v'+version+'r'+revision,file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_fine'+type+'3d_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'

	endif

	if type eq 'svy' then begin
		if newm then mvn_swia_inst2mso

		if news then begin
			wind = where(swis.time_unix ge (time_double(date)-600) and swis.time_unix le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then swis = swis[wind]
			mvn_swia_make_swis_cdf,data_version='v'+version+'r'+revision,file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_onboardsvyspec_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'
		endif

		if newm then begin
			wind = where(swim.time_unix ge (time_double(date)-600) and swim.time_unix le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then swim = swim[wind]

			get_data,'mvn_swim_velocity_mso',data = swv
			get_data,'mvn_swim_temperature_mso',data = swt
			wind = where(swv.x ge (time_double(date)-600) and swv.x le (time_double(date)+24.*3600+600),nwind)
			if nwind gt 0 then begin
				store_data,'mvn_swim_velocity_mso',data = {x:swv.x[wind],y:swv.y[wind,*]}
				store_data,'mvn_swim_temperature_mso',data = {x:swt.x[wind],y:swt.y[wind,*]}
			endif
		
			mvn_swia_make_swim_cdf,data_version='v'+version+'r'+revision,file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_onboardsvymom_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'
		endif
	endif
	
	date = time_string(time_double(date)+24.*3600)
endfor


end
