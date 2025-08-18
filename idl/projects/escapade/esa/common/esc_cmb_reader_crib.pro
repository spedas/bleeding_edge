; esc_cmb_reader_crib
; 
; 



; 
; 

;; Kludge to get ctime, /exact to work
pro esc_ctime_kludge
  all_tnames = tnames()
  size_tnames = size(all_tnames)
  n_tnames = size_tnames[1]
  for i = 0, n_tnames-1 do begin
    get_data, all_tnames[i], data = foo
    store_data, all_tnames[i], data = foo
  endfor
end

stop

cmb = cmblk_reader(host = 'abiad-sw',port=5004,directory='ESC_TEST/')
cmb.add_handler,'ESC_ESATM',esc_esatm_reader(/no_widget)

file = '/Users/phyllisw/Desktop/eesa.cmb'
cmb.file_read,file


; Then click on open button

; Configure trange
txt = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1','timebar, systime(1)']
exec, exec_text = txt


; view what has been read in:
cmb.print_status

; get object related to Escapade:
esc = cmb.get_handlers('ESC_ESATM')



; Display help on esc data:
esc.help


;Turn on verbose mode:
esc.verbose=4

;Turn off verbose:
esc.verbose=2


; Get saved data:
da = esc.dyndata


; Create tplot variables to look at data:
store_data,da.name,data=da,tagnames='*'



tplot,'Esc*',trange=systime(1) + [-1,.05] * 60 *5






;Manipulator data:
manip = cmb.get_handlers('MANIP')
store_data,'Manip',data=manip.dyndata,tagnames='*'


ind1 = [34:39]
ind2 = [173,175,177,180,182,184]

get_data, ind1[5], data=d1
get_data, ind2[5], data=d2
store_data, 'tmp1', data={x:d1.x, y:d1.y[*,12]}
store_data, 'tmp2', data={x:d2.x, y:d2.y[*,12]}
store_data, 'valids_comb2', data="tmp1 tmp2"
options, 'valids_comb2', colors='rb'
tplot, 'valids_comb2'
tplot_names, "*frates_*_HZ *dhkp_*_HZ"

tplot, /add, [ind1[5],ind2[5]]

