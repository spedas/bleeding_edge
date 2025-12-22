pro fast_fields_summary, test = test, bw = bw, noclean=noclean

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    catch,/cancel
    return
endif
catch,/cancel

tbegan = systime()

default_table = 39
bw = keyword_set(bw)
if bw then begin
    ps_table = 42
endif else begin
    ps_table = default_table
endelse

splot_time = 20                 ; minutes

dir = getenv ('IDLOUTDIR')
if strlen(dir) gt 0 then cd, dir

dcnamebase = 'dcfields'
acnamebase = 'acfields'

show_dqis

store_data,'spin_times',/delete
good_spin = load_spin_times(spin = 180,/orbit_env)
if not good_spin then begin
    message,' unable to load spin times correctly...no point in ' + $
      'continuing...',/continue
    return
endif


summary_plot_times,times = times, ptypes = ptypes, use_data='spin_times', $
  orbit_num = orbit_num, splot_time = splot_time,test = test

if not defined(ptypes) then begin
    message,'no auroral zone data ---> no summary plots!',/continue
    return
endif

load_fields_modebar

tplot_names,names = names
if not defined(names) then store_data,'crap',data={x:findgen(10)}

dcnames = load_dc_fields()
if  load_fields_modes() then begin
    acnames = load_ac_fields()
endif else begin
     message,'Unable to determine fields modes...no AC fields can be ' + $
      'loaded...',/continue
    acnames = ''
endelse

dccdf = dcnamebase + '_'+orbit_num+'.cdf'
accdf = acnamebase + '_'+orbit_num+'.cdf'

if (find_handle('dc_cdf') ne 0) then begin
    get_data,'dc_cdf',data = dc_cdfdat
    old_makecdf,dc_cdfdat,file=dccdf,/overwrite
endif else begin
    message,' no dc fields data available for orbit ' + $
      ''+orbit_num,/continue
endelse

if (find_handle('ac_cdf') ne 0) then begin
    get_data,'ac_cdf',data = ac_cdfdat
    makecdf,ac_cdfdat.vary, datanovary=ac_cdfdat.novary, $
      tagsvary= ac_cdfdat.tv, tagsnovary=  ac_cdfdat.tnv, $
      file=accdf,/overwrite
endif else begin
    message,' no ac fields CDF data available for orbit ' + $
      ''+orbit_num,/continue
endelse

acbadj = where(acnames eq 'NULL',nbad)
if nbad gt 1 then begin
    message,'acfields has more than one NULL stored, very odd...',/continue
endif
acgood = where(acnames ne 'NULL',ngood)
if ngood gt 0 then acnames = acnames(acgood)

dcbadj = where(dcnames eq 'NULL',nbad)
if nbad gt 1 then begin
    message,'dcfields has more than one NULL stored, very odd...',/continue
endif
dcgood = where(dcnames ne 'NULL',ngood)
if ngood gt 0 then dcnames = dcnames(dcgood)

if defined(times) and defined(ptypes) then begin
    gen_fa_k0_acf_gifps,acnames,times=times,ptypes=ptypes, $
      splot_time=splot_time,/single,/sdt, ps_table=ps_table, $
      default_table = default_table
    gen_fa_k0_dcf_gifps,dcnames,times=times,ptypes=ptypes, $
      splot_time=splot_time,/single,/sdt
endif

if not keyword_set(noclean) then begin
    store_data,'spin_times',/delete
    if acnames(0) then begin
        store_data,acnames(0),/delete
    endif
    if dcnames(0) then begin
        store_data,dcnames(0),/delete
    endif
endif

tdone = systime()
done = 'HOORAY! Finished with orbit '+orbit_num+' began '+tbegan+', now '+tdone
message,done,/continue

catch,/cancel


return
end

