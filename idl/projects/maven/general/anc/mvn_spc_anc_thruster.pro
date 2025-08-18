;+
;FUNCTION:
; mvn_spc_anc_thruster
;Purpose:
;  returns and array of structures that contain data from MAVEN SFF (thruster) files
;USAGE:
;  data = mvn_spc_anc_thruster()
;  printdat,data         ; display contents
;  store_data,'THRUSTER',data=data   ; store for tplot
;
; KEYWORDS:
;   TRANGE=TRANGE  ; Optional 2 element time range vector
; $LastChangedBy: Chris Fowler  $
; $LastChangedDate: CMF: 2015-02-20 $
; $LastChangedRevision: CMF: routine returns the string 'none_found' if no file is found, to avoid crashes in IDL.  $
; $URL:  $
;-
function  mvn_spc_anc_thruster,pformat,trange=trange,verbose=verbose         ;,var_name=var_name,thruster_time= time_x

if ~keyword_set(pformat) then pformat='maven/data/anc/eng/sff/mvn_rec_yyMMDD_*.sff'

tr = timerange(trange) + 86400L * [-3,0]
src = mvn_file_source(source,last_version=0,no_update=0,/valid_only)
filenames = mvn_pfp_file_retrieve(pformat,trange=tr,/daily_names,source=src)
count = n_elements(filenames) * keyword_set(filenames)
;printdat,filenames

lasttime = 0
for ii=0,count-1 do begin
  file=filenames[ii]
  dprint,dlevel=2,verbose=verbose,file
  if file_test(/regular,file) eq 0 then continue
  openr,unit,file ,/get_lun

;1, R, 2014-04-19 10:38:04, 2014-04-19 03:54:34.050, 2014-04-19 04:01:21.183, 407.133, 0.000000, -0.000000117939, -0.000000056108, 0.000000132249, -0.4950504004955292, 0.261560469865799, -0.7722193598747253, -0.3003140389919281, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100, 0, 100, 0, 0, 0, 0, 0, 0, 29566698091434

  dat = {time:0d,  n:0, label:'', t_produced:0d, trange:[0d,0d]  ,deltat:0.d, v1:0d, v3:[0d,0d,0d,0d], qu:[0d,0d,0d,0d],  L28:replicate(0L,28),  L:0LL}
  str=''
  while ~EOF(unit) do begin
    readf,unit,str
    col=strsplit(str,',',/extract)
    if n_elements(col) ne 43 then begin
      dprint,str,dlevel=5,verbose=verbose
      continue
    endif
    dat.n = fix(col[0])
    dat.label = col[1]
    dat.t_produced = time_double(col[2])
    dat.trange = time_double(col[3:4])
    dat.deltat = double(col[5])
    dat.v1 = double(col[6])
    dat.v3 = double(col[7:9])
    dat.qu = double(col[10:13])
    dat.L28 = fix(col[14:41])
    dat.L = long64(col[42])
    dat.time = dat.trange[0]
    if dat.time lt lasttime then begin
       dprint,dlevel=4,verbose=verbose, rec,dat.n
       nrec = max( where(data[0:rec-1].time lt dat.time,nw) )  > 0
       dprint,dlevel=3,verbose=verbose,'Overwriting records at '+time_string(dat.time)   , ' Record=',nrec, rec-nrec
       rec=nrec 
    endif
    lasttime = dat.time
    append_array,data,dat,index=rec
  endwhile

FREE_LUN ,unit

endfor
append_array,data,index=rec

if size(data, /type) eq 0 then data = 'none_found' ;CMF 2015-02-20: return string if no file is found to avoid crash in IDL

return,data
end

