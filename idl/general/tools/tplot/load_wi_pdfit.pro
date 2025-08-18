;+
;PROCEDURE:	load_wi_pdfit
;PURPOSE:	
;   loads WIND 3D Plasma Experiment key parameter data for "tplot".
;
;INPUTS:
;  none, but will call "timespan" if time_range is not already set.
;KEYWORDS:
;  DATA:        Raw data can be returned through this named variable.
;  TIME_RANGE:  2 element vector specifying the time range
;RESTRICTIONS:
;  This routine expects to find the master file: 'wi_elsp_3dp_files'
;  In the directory specified by the environment variable: 'CDF_INDEX_DIR'
;  See "make_cdf_index" for more info.
;SEE ALSO: 
;  "make_cdf_index","loadcdf","loadcdfstr","loadallcdf"
;
;CREATED BY:	Davin Larson
;FILE:  load_wi_elpd4.pro
;LAST MODIFICATION: 99/05/27
;-
pro load_wi_pdfit $
   ,trange=trange $
   ,filenames=fnames $
   ,masterfile = mfile $
   ,data=d $
   ,nvdata = nd $
   ,resolution=res $
   ,prefix = prefix $
   ,polar=polar




;cdfnames = ['elpd_125eV', 'elpd_125eV_v', 'elpd_250eV', 'elpd_250eV_v', 'elpd_500eV', 'elpd_500eV_v', 'elpd_125eV_f.P.A', 'elpd_125eV_f.X2', 'elpd_250eV_f.P.A', 'elpd_250eV_f.X2', 'elpd_500eV_f.P.A', 'elpd_500eV_f.X2', 'wi_pos']

if not keyword_set(mfile) then mfile = 'wi_pdfit_3dp_files'
loadallcdf,master=mfile,time_range=trange,cdfnames=cdfnames,data=d, $
   resolution=res

if not keyword_set(d) then return

if data_type(prefix) eq 7 then px=prefix else px = 'wi_pdfit_'


store_data,px+'Nsw',data={x:d.time,y:d.nsw}
pitchangle = ((findgen(13)+.5)/13) * 180
store_data,px+'125eV_pad',data={x:d.time,y:transpose(d.elpd_125ev),v:pitchangle}, $
                          dlim={spec:1,yrange:[0.,180.],ystyle:1}
store_data,px+'250eV_pad',data={x:d.time,y:transpose(d.elpd_250ev),v:pitchangle}, $
                          dlim={spec:1,yrange:[0.,180.],ystyle:1}
store_data,px+'500eV_pad',data={x:d.time,y:transpose(d.elpd_500ev),v:pitchangle}, $
                          dlim={spec:1,yrange:[0.,180.],ystyle:1}

store_data,px+'125eV_A',data={x:d.time,y:transpose(d.elpd_125ev_f.p.a),v:pitchangle} 
store_data,px+'250eV_A',data={x:d.time,y:transpose(d.elpd_250ev_f.p.a),v:pitchangle} 
store_data,px+'500eV_A',data={x:d.time,y:transpose(d.elpd_500ev_f.p.a),v:pitchangle} 


store_data,'wi_pos',data={x:d.time,y:transpose(d.wi_pos)}

return
end

