;+
;PROCEDURE:     load_ace_swepam
;PURPOSE:
;   loads ACE SWEPAM (Ion) Experiment key parameter data for "tplot".
;
;INPUTS:
;  none, but will call "timespan" if time_range is not already set.
;KEYWORDS:
;  DATA:        Raw data can be returned through this named variable.
;  TIME_RANGE:  2 element vector specifying the time range.
;  MASTERFILE:  (String) full filename of master file.
;  POLAR:	Computes proton velocity and SC position in polar coordinates.
;SEE ALSO:
;  "loadallhdf"
;
;CREATED BY:    Peter Schroeder
;Modified by D. Larson 5/2008  to automatically download files from the ACE data center (masterfile is ignored)
;LAST MODIFIED: @(#)load_ace_swepam.pro	1.3 02/04/12
;-
pro load_ace_swepam,data=data,time_range=time_range,masterfile=masterfile,$
	polar=polar,filenames=filenames

vdataname = 'SWEPAM_ion'
tplot_prefix = 'ace_swepam_'

if not keyword_set(indexfile) then indexfile='ace_swepam_ion_files'
hdfnames=['ACEepoch','proton_density','proton_temp','He4toprotons',$
'x_dot_GSE','y_dot_GSE','z_dot_GSE','pos_gse_x','pos_gse_y','pos_gse_z']


if not keyword_set(source) then begin
   source = file_retrieve(/struct)
   source.local_data_dir = root_data_dir() + 'ace/'
   source.remote_data_dir = 'http://www.srl.caltech.edu/ACE/ASC/DATA/'
endif

pathnames = file_dailynames(trange=trange,file_format='level2/swepam/swepam_data_64sec_yearYYYY.hdf',/unique)
filenames = file_retrieve(pathnames,_extra=source)

loadallhdf,time_range=time_range,vdataname=vdataname,data=data,$
	indexfile=indexfile,masterfile=masterfile,hdfnames=hdfnames,$
  filenames=filenames

timearray = data.ACEepoch + time_double('96-1-1')

bad = where(data.proton_density lt 0,nbad)
;printdat,data,'data'
if nbad ne 0 then begin
  data.proton_density[bad] = !values.f_nan
  data.proton_temp[bad]    = !values.f_nan
  data.He4toprotons[bad]   = !values.f_nan
  data.x_dot_GSE[bad]      = !values.f_nan
  data.y_dot_GSE[bad]      = !values.f_nan
  data.z_dot_GSE[bad]      = !values.f_nan
endif

store_data,tplot_prefix+'Np',data={x: timearray, y: data.proton_density}
store_data,tplot_prefix+'proton_temp',data={x: timearray, y: data.proton_temp}
store_data,tplot_prefix+'He4toprotons',data={x: timearray, y: data.He4toprotons}
store_data,tplot_prefix+'Vp',data={x: timearray, $
	y: [[data.x_dot_GSE],[data.y_dot_GSE],[data.z_dot_GSE]]}
if keyword_set(polar) then xyz_to_polar,tplot_prefix+'Vp',/ph_0_360
store_data,tplot_prefix+'pos_gse',data={x: timearray, $
	y: [[data.pos_gse_x],[data.pos_gse_y],[data.pos_gse_z]]/6370.}
if keyword_set(polar) then xyz_to_polar,tplot_prefix+'pos_gse',/ph_0_360

return
end
