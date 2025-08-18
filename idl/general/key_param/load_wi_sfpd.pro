;+
;PROCEDURE:	load_wi_sfpd
;PURPOSE:
;   loads WIND 3D Plasma Experiment key parameter data for "tplot".
;
;INPUTS:
;  none, but will call "timespan" if time_range is not already set.
;KEYWORDS:
;  DATA:        Raw data can be returned through this named variable.
;  NVDATA:	Raw non-varying data can be returned through this variable.
;  TIME_RANGE:  2 element vector specifying the time range.
;  MASTERFILE:  (string) full file name to the master file.
;  RESOLUTION:  number of seconds resolution to return.
;  PREFIX:	Prefix for TPLOT variables created.  Default is 'sfpd'
;SEE ALSO:
;  "make_cdf_index","loadcdf","loadcdfstr","loadallcdf"
;
;CREATED BY:	Davin Larson
;FILE:  load_wi_sfpd.pro
;LAST MODIFICATION: 02/04/19
;-
pro load_wi_sfpd $
   ,time_range=trange $
   ,source=source $
   ,data=d $
   ,nvdata = nd $
   ,masterfile=masterfile $
   ,resolution=res $
   ,no_download=no_download, no_update=no_update $
   ,prefix = prefix

if not keyword_set(masterfile) then masterfile = 'wi_sfpd_3dp_files'

cdfnames = ['FLUX', 'ENERGY','PANGLE','MAGF']

if not keyword_set(source) then begin
   wind_init
   source = !wind
endif

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

file_format = 'wind/3dp/3dp_sfpd/YYYY/wi_sfpd_3dp_YYYYMMDD_v0?.cdf'
pathnames = file_dailynames(file_format=file_format,trange=trange)
;filenames = file_retrieve(pathnames,_extra=source,/last_version)
filenames = spd_download(remote_file = pathnames, $
                         remote_path = source.remote_data_dir, $
                         local_path = source.local_data_dir, $
                         no_download = source.no_download, $
                         no_update = source.no_update, /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)

d = 0
nd = 0
loadallcdf,masterfile=masterfile,filenames=filenames,cdfnames=cdfnames,data=d, $
   novarnames=novarnames,novard=nd,time_range=trange,resolution=res

if not keyword_set(d) then return

if data_type(prefix) eq 7 then px=prefix else px = 'sfpd'

store_data,px,data={x:d.time,y:dimen_shift(d.flux,1), $
  v1:dimen_shift(d.energy,1),v2:dimen_shift(d.pangle,1)}$
  ,min=-1e30,dlim={ylog:1}

energies = dimen_shift(d.energy,1)
angles = dimen_shift(d.pangle,1)

ang_size = size(angles)
e_size = size(energies)

n_ang = ang_size(ang_size(0))
n_nrg = e_size(e_size(0))


for i = 0, n_nrg-1, 1 do begin
   reduce_pads,px,1,i,i,e_units=1
ENDFOR

reduce_pads,px,2,6,7,e_units=1
reduce_pads,px,2,0,1,e_units=1


return
end

