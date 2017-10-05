;OBSOLETE FILE - WAS replaced by thm_gen_overplot

;+
; Purpose: To make mission overview plots of all instruments
;
; Inputs:  PROBES: spacecraft ('a','b','c','d','e')
;          DATE: the date string or seconds since 1970 ('2007-03-23')
;          DUR: duration (default units are days)
;          DAYS: redundant keyword to set  the units of duration (but its comforting to have)
;          HOURS: keyword to make the duration be in units of hours
;          DEVICE: sets the device (x or z) (default is x)
;          MAKEPNG: keyword to generate 5 png files
;          DIRECTORY: sets the directory where the above pngs are placed (default is './')
;	   DONT_DELETE_DATA:  keyword to not delete all existing tplot variables before loading data in for
;			        the overview plot (sometimes old variables can interfere with overview plot)
;		ERROR:  Tells the calling routine whether an error that prevented overplot completion occured. (error=1 indicates an error, error=0 indicates no error)
;
;WARNING:
;  Any code that requires windowStorage or loadedData should be put in the "~keyword_set(no_draw)" block.  
;  spd_ui_overplot is called without valid values for these parameters during document load 
;
;
; Example: thm_gen_overplot,probe='a',date='2007-03-23',dur=1
;	   The above example will produce a full day plot in the X window.
;
;
;Version:
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-26 13:06:46 -0700 (Wed, 26 Oct 2016) $
; $LastChangedRevision: 22203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/deprecated/spd_ui_overplot.pro $
;-


;functionalizes repeated code, this is called after each panel is added to gui
;it should help manage memory
pro spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data

  compile_opt hidden
  
  if ~keyword_set(dont_delete_data) then begin
    to_delete = ssl_set_complement([tn_before],[tnames('*'),''])
    if(size(to_delete,/n_dim) ne 0 || to_delete[0] ne -1L) then $
      del_data,to_delete
  endif

end

Pro quick_set_panel_labels, panel_in, string_in, colors_in = colors_in, zaxis = zaxis, zhorizontal = zhorizontal

  compile_opt hidden

If(is_string(string_in,/blank) Eq 0) Then Return
n = n_elements(string_in)
If(keyword_set(colors_in)) Then Begin
    nc = n_elements(colors_in[0,*])
;Colors_in should be 3xN, if there aren't the same number of colors,
;as labels, then use the first color
    If(nc Ne n) Then colors = rebin(colors_in[*,0], 3, n) $
    Else colors = colors_in
Endif Else colors = rebin([0b, 0b, 0b], 3, n)
If(keyword_set(zaxis)) Then Begin
    panel_in -> getproperty, zaxis = zobj
    If(obj_valid(zobj)) Then Begin
        to = obj_new('spd_ui_text')
        to -> setproperty, value = string_in[0] ;only one label
        to -> setproperty, size = 8.0
        zobj -> setproperty, labeltextobject = to
        if keyword_set(zhorizontal) then begin
           zobj -> setproperty, labelorientation = 0
           zobj -> setproperty, labelmargin = 30.0
        endif else zobj -> setproperty, labelmargin = 45.0  
    Endif
Endif Else Begin
    panel_in -> getproperty, yaxis = yobj
    If(obj_valid(yobj)) Then Begin
        yobj -> setproperty, margin = 32.0
        yobj -> getproperty, labels = obj2
        ;added to support single simplified labels
        yobj -> setproperty, blacklabels=1
        If obj_valid(obj2) then begin
          lobj = obj2 -> get(/all)
  ;Keep only the first object, clean out the rest
          lobj0 = lobj[0]
          If(n_elements(lobj) Gt 1) Then For j = 1, n_elements(lobj)-1 Do obj_destroy, lobj[j]
          obj2 -> remove, /all
          lobj0 -> setproperty, color = colors[*, 0]
          lobj0 -> setproperty, value = string_in[0]
          lobj0 -> setproperty, size = 10.0
          lobj0 -> setproperty, show = 1
          obj2 -> add, lobj0
          If(n Gt 1) Then Begin
              For j = 1, n-1 Do Begin
                  lobjj = lobj0 -> copy()
                  lobjj -> setproperty, color = colors[*, j]
                  lobjj -> setproperty, value = string_in[j]
                  lobjj -> setproperty, show = 1
                  obj2 -> add, lobjj
              Endfor
          Endif
        Endif
    Endif
Endelse
Return
End

;boolean helper function to check that time dimensions
;match y dimensions
function check_keogram_dims,names

  compile_opt idl2,hidden
  
  if names[0] eq '' then return, ''
  
  tr = timerange(/current)
  
  for i = 0,n_elements(names)-1 do begin
  
    name = names[i]
  
    get_data,name,data=d
    
    ;checks that the quantity is well formed
    if is_struct(d) && $
       in_set('x',strlowcase(tag_names(d))) && $
       in_set('y',strlowcase(tag_names(d))) then begin
       
      dim_x = dimen(d.x)
      dim_y = dimen(d.y)
    
      ;this checks that the dimensions aren't messed
      ;It also checks that this particular quantity is
      ;from the date/duration requested
      if dim_x[0] eq dim_y[0] && $
        d.x[0] le tr[1] && $
        d.x[dim_x[0]-1] ge tr[0] then return,name
    
    endif
  endfor
  
  return,''
    
end

;updates the metadata of quantities being loaded into the gui
;This way the information will be properly autodetected
pro spd_ui_update_dlimits,varname,observatory,instrument,coord_sys,units

  compile_opt idl2,hidden

  if tnames(varname) eq '' then return

  get_data,varname,data=d,dlimit=dl
  
  ;handle pseudo variables with a recursive call
  if is_string(d[0]) then begin
    
    if n_elements(d) eq 1 then begin
      d = strsplit(d,' ')
    endif
    
    for i = 0,n_elements(d)-1 do begin
      spd_ui_update_dlimits,d[i],observatory,instrument,coord_sys,units
    endfor
    return
  endif
  
  
  if ~is_struct(dl) then begin
    dl = {data_att:''}
  endif

  str_element,dl,'data_att',success=s
  
  if ~s then begin
    str_element,dl,'data_att',/add, {PROJECT:'SPEDAS',$
                                     OBSERVATORY:observatory,$
                                     INSTRUMENT:instrument,$
                                     COORD_SYS:coord_sys,$
                                     UNITS:units}
  endif else begin
    data_att = dl.data_att
    str_element,data_att,'PROJECT',/add,'SPEDAS'
    str_element,data_att,'OBSERVATORY',/add,observatory
    str_element,data_att,'INSTRUMENT',/add,instrument
    str_element,data_att,'COORD_SYS',/add,coord_sys
    str_element,data_att,'UNITS',/add,units
    str_element,dl,'data_att',/add,data_att
  endelse 
    
  store_data,varname,dl=dl

end

;WARNING:
;  Any code that requires windowStorage or loadedData should be put in the "~keyword_set(no_draw)" block.  
;  spd_ui_overplot is called without valid values for these parameters during document load 
;
;This code adds overview plot to the current window.  Calling routine should create a new window for the overview plot.
;This prevents weak window menu management code from exploding.
pro spd_ui_overplot, windowStorage,loadedData,drawObject,$
                     probes = probes, date = date, dur = dur, $
                     days = days, hours = hours, device = device, $
                     directory = directory, makepng = makepng, $
                     dont_delete_data = dont_delete_data, $
                     oplot_calls=oplot_calls,no_draw=no_draw,$
                     error=error

;catch errors and fail gracefully
;-------------------------------------------------------


common overplot_position, load_position, error_count

error=1 ;indicate error to calling routine(set to zero if the routine reaches completion
!quiet=0
error_count=0
load_position = 'init'

tn_before  = tnames('*') ; get list of pre-existing tvars

;catch statement to allow program to recover from errors
;-------------------------------------------------------

catch,error_status

if error_status ne 0 then begin

   error_count++
   if error_count ge 1000. then begin
     dprint,  ' '
     dprint,  'The program is quitting because it fears its in an infinite loop.'
     dprint,  'To eliminate this fear add the keyword /fearless to the call.'
     return
   endif

   if !error_state.name eq 'THM_SPINMODEL_POST_PROCESS_NO_TVAR' then begin
     ok = dialog_message('Cannot find STATE data. Check the GUI configuration'+ $
                         'to verify data is being downloaded.', /center, $
                         title='Error creating overview plot')
     return
   endif

   print, '***********Catch error**************'
   help, /last_message, output = err_msg
   For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
   print, 'load_position: ' , load_position

   case load_position of
    'init'          : goto, SKIP_DAY
   	'fgm'		: goto, SKIP_FGM_LOAD
   	'fbk'		: goto, SKIP_FBK_LOAD
   	'sst'		: goto, SKIP_SST_LOAD
   	'esa'		: goto, SKIP_ESA_LOAD
   	'gmag'		: goto, SKIP_GMAG_LOAD
   	'roi'     : goto, SKIP_ROI_LOAD
   	'asi'		: goto, SKIP_ASI_LOAD
   	'pos'		: goto, SKIP_POS_LOAD
   	'mode'		: goto, SKIP_SURVEY_MODE
   	'bound'		: goto, SKIP_BOUNDS
    	else		: goto, SKIP_DAY

  endcase

endif

;check some inputs
;-------------------------------------------------------
if keyword_set(probes) then sc = strlowcase(probes) ; quick change of variable name

vsc = ['a','b','c','d','e']
if not keyword_set(sc) then begin
  dprint, 'You did not enter a spacecraft into the program call.'
  dprint,  "Valid inputs are: 'a','b','c','d','e'  (ie, sc='b')"
  return
endif
if total(strmatch(vsc,strtrim(strlowcase(sc)))) gt 1 then begin
  dprint,  'This program is only designed to accept a single spacecraft as input.'
  dprint,  "Valid inputs are: 'a','b','c','d','e'  (ie, sc='b')"
  return
endif
if total(strmatch(vsc,strtrim(strlowcase(sc)))) eq 0 then begin
  dprint, "The input sc= '",strtrim(sc),"' is not a valid input."
  dprint,  "Valid inputs are: 'a','b','c','d','e'  (ie, sc='b')"
  return
endif

if ~keyword_set(dur) then begin
  dprint, 'duration not input, setting dur = 1'
  dur = 1
endif
if (dur Lt 0) then begin
  dprint, 'Invalid duration, setting dur = 1'
  dur = 1
endif

if keyword_set(hours) then dur=dur/24.

if ~keyword_set(date) then begin
  dprint, 'You did not enter a date into the program call.'
  dprint, "Example: thm_gen_overplot,sc='b',date='2007-03-23'"
  return
endif else begin
  t0 = time_double(date)
  t1 = t0+dur*60D*60D*24D
  
  if(t1 Lt time_double('2007-02-17/00:00:00')) then begin
    dprint,  'Invalid time entered: ', time_string(date)
    ok = dialog_message(time_string(date) + ' is not a valid date.  '+ $
                        'Overview plots cannot be generated before 2007-02-17.', $
                        /center, title='Generate Overview Plot')
    return
  endif
  if(t0 Gt systime(/seconds)) then begin
    dprint,  'Invalid time entered: ', time_string(date)
    ok = dialog_message(time_string(date) + ' is not a valid date.  '+ $
                        'Overview plots cannot be generated for future dates.', $
                        /center, title='Generate Overview Plot')
    return
  endif
endelse


if not keyword_set(device) then begin
  help,/device,output=plot_device
  plot_device=strtrim(strlowcase(strmid(plot_device(1),24)),2)
  if plot_device eq 'z' then device, set_resolution = [750, 800]
endif else begin
  set_plot,device
  help,/device,output=plot_device
  plot_device=strtrim(strlowcase(strmid(plot_device(1),24)),2)
  if plot_device eq 'z' then device, set_resolution = [750, 800]
endelse

thx = 'th'+sc[0]                ;need a scalar for this

date=time_string(date)

if ~keyword_set(dont_delete_data) then begin
  clear_esa_common_blocks
  common data_cache_com, dcache
  dcache = ''
endif

widget_control, /hourglass

tn_before = tnames('*')

; clear any previously set var_labels. This prevents the SPEDAS overview plots from
; using tplot's var_label from a different plot in the same session
tplot_options, var_label = ''

; set the suffix to identify different calls to overplot
osuffix = ('_op' + strcompress(string(*oplot_calls + 1), /remove_all))[0]

timespan,date,dur

; load gmag data
;----------------

load_position='gmag'

;-----------------------------------------------------------------------
;Comment this block of code to disable AE index generation from GMAG
;thm_load_gmag,/subtract_median
;If(is_string(tnames('thg_mag_*'))) Then Begin
;  split_vec,'thg_mag_*'
;  superpo_histo,'thg_mag_*_x', dif='thg_pseudoAE', res=60.0
;  tdespike_AE,-2000.0,1500.0
;  clean_spikes, 'thg_pseudoAE_despike', new_name = 'thg_pseudoAE', thresh = 5
;  options,'thg_pseudoAE',ytitle='SPEDAS AE Index'
;Endif Else Begin
;  filler=fltarr(2)
;  filler[*]=float('NaN')
;  store_data,'thg_pseudoAE',data={x:time_double(date)+findgen(2),y:filler}
;  options,'thg_pseudoAE',ytitle='SPEDAS AE Index'
;Endelse
;spd_ui_update_dlimits,'thg_pseudoAE',sc,'ae_index','none','none'
;copy_data,'thg_pseudoAE','thg_pseudoAE'+osuffix
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
;Uncomment this block of code to implement AE index loading from CDF
thm_load_pseudoAE
If ~(is_string(tnames('thg_idx_ae'))) then begin
  filler=fltarr(2)
  filler[*]=float('NaN')
  store_data,'thg_idx_ae',data={x:[time_double(date),time_double(date)+dur*60*60*24],y:filler}
endif
options,'thg_idx_ae',ytitle='SPEDAS_AE Index'

spd_ui_update_dlimits,'thg_idx_ae',sc,'ae_index','none','none'
copy_data,'thg_idx_ae','thg_pseudoAE'+osuffix
;----------------------------------------------------------------------


tplot_gui,'thg_pseudoAE'+osuffix,/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw)
spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data
SKIP_GMAG_LOAD:

load_position='roi'

thm_load_state,probe=sc,/get_support
If(is_string(tnames(thx+'_state_roi'))) Then Begin ;test for state, jmm, 21-apr-2009
    roi_bar = thm_roi_bar(thx+'_state_roi')
;change roi_bar to a 16xN tplot variable to avoid the need to write a
;GUI compatible bitplot routine, jmm, 9-apr-2009
    get_data,roi_bar,data=ppp,limit=l
    If(is_struct(ppp)) Then Begin
        bits2,ppp.y,new_bar ;the extracts the bit values into a bytarr of 16xntimes
        nbv=n_elements(new_bar[*,0])
        nxv=n_elements(ppp.x)
        new_bar=rebin(1+bindgen(nbv), nbv, nxv)*new_bar ;this assigns each non-zero bit the value equal to its bit number
        new_bar=float(new_bar)  ;to allow for NaN's to plot correctly
        zerov=where(new_bar Eq 0,nzerov)
        If(nzerov Gt 0) Then new_bar[zerov]=!values.f_nan
        str_element,ppp,'y',transpose(new_bar),/add_replace ;need transpose to make it ntimesX16
        str_element,l,'panel_size',/delete  ;panel sizing handled using different method in gui overview plots
        store_data,roi_bar,data=ppp,limit=l
        options,roi_bar,tplot_routine='mplot' ;reset this for testing
    Endif Else Goto, dummy_roi_bar
Endif Else Begin
    dummy_roi_bar:
    filler=fltarr(2,16)
    filler[*,*]=float('NaN')
    store_data,thx+'_roi_bar',data={x:time_double(date)+findgen(2),y:filler}
    roi_bar=thx+'_roi_bar'
Endelse

spd_ui_update_dlimits,roi_bar,sc,'roi','none','none'
copy_data,roi_bar,roi_bar+osuffix
tplot_gui,roi_bar+osuffix,/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw)
spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data
SKIP_ROI_LOAD:

; load ASK data and plot 3 specific ones (can be changed)
;---------------------------------------------------------

load_position='asi'

thm_load_ask, site='fsmi'

filler = fltarr(2, 10)          ; (10 chosen arbitrarily)
filler(*, *) = float('NaN')
;Harald requests using FSMI as first choice:
fsmi_site = tnames('*ask*fsmi*')
if (fsmi_name = check_keogram_dims(fsmi_site)) ne '' then begin
  copy_data, fsmi_name, 'Keogram'
  keo_site = 'fsmi'
endif else begin

  thm_load_ask,site=site_list,/valid_names
  
  found_k_site = 0
  
  for i = 0,n_elements(site_list)-1 do begin
    thm_load_ask,site=site_list[i]
  
    asi_sites = tnames('*ask*')
    if (asi_name = check_keogram_dims(asi_sites)) ne '' then begin
      copy_data, asi_name, 'Keogram'
      split_name = strsplit(asi_name,'_',/extract) ;don't want entire name of quantity just site, which should be the last part
      keo_site = split_name[n_elements(split_name)-1]
      found_k_site = 1
      break
    endif
    
   endfor
   
   if ~keyword_set(found_k_site) then begin
     store_data, 'Keogram', data = {x:time_double(date)+findgen(2), y:filler, v:findgen(10)}
     keo_site = 'filler'
   endif
   
endelse
options, 'Keogram', 'ytitle', ' '
spd_ui_update_dlimits,'Keogram',keo_site,'ask','none','counts'
copy_data,'Keogram','Keogram'+osuffix
tplot_gui,'Keogram'+osuffix,/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw)
spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data
SKIP_ASI_LOAD:

;load magnetic field fit data
;-----------------------------

load_position='fgm'

thm_load_state,probe=sc,/get_support
thm_load_fit,lev=1,probe=sc,/get_support

;kluge to prevent missing data from crashing things
index_fit=where(thx+'_fgs' eq tnames())
index_state=where(thx+'_state_spinras' eq tnames())
if (index_fit(0) eq -1 or index_state(0) eq -1) then begin
  filler=fltarr(2,3)
  filler(*,*)=float('NaN')
  store_data,thx+'_fgs_gse',data={x:time_double(date)+findgen(2),y:filler}
  ylim,thx+'_fgs_gse',-100,100,0
endif else begin
  thm_cotrans,thx+'_fgs',out_suf='_gse', in_c='dsl', out_c='gse'
endelse

;clip data
;tclip, thx+'_fgs_gse', -100.0, 100.0, /overwrite
name = thx+'_fgs_gse'
options, name, 'ytitle', 'B FIT_GSE (nT)'
options, name, 'labels', ['Bx', 'By', 'Bz']
options, name, 'labflag', 1
options, name, 'colors', [2, 4, 6]
options, name, 'yrange', [-100,100]

copy_data,name,name+osuffix
tplot_gui,name+osuffix,/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw)
spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data

SKIP_FGM_LOAD:
;load SST spectrograms
;----------------------

load_position='sst'
thm_load_sst, probe = sc, level = 'l2'
;If Level 2 data didn't show up, check for L1
index_sst_e = where(thx+'_psef_en_eflux' eq tnames())
index_sst_i = where(thx+'_psif_en_eflux' eq tnames())
if(index_sst_e[0] eq -1 Or index_sst_i[0] Eq -1) then begin
  thm_part_load,probe=probe,trange=trange,datatype='psif'
  thm_part_load,probe=probe,trange=trange,datatype='psef'
  thm_part_moments, probe = sc, instrument = ['psif', 'psef'], $
    moments = ['density', 'velocity', 't3'],method_clean='automatic'
endif

SKIP_SST_LOAD:
;kluge to prevent missing data from crashing things
index_sst=where(thx+'_psif_en_eflux' eq tnames())
if index_sst eq -1 then begin
  filler = fltarr(2, 16)
  filler[*,*]=float('NaN')
  store_data, thx+'_psif_en_eflux', $
    data = {x:time_double(date)+findgen(2)*86400., y:filler, v:findgen(16)}
  name = thx+'_psif_en_eflux'
  options, name, 'spec', 1
  ylim, name, 1, 1000, 1
  zlim, name, 1d1, 5d2, 1
  options, name, 'ytitle', thx+'!CSST ions!CeV'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
endif else begin
;SST ion panel
  name = thx+'_psif_en_eflux'
  tdegap, name, /overwrite, dt = 600.0
  options, name, 'spec', 1
  options, name, 'ytitle', thx+'!CSST ions!CeV'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
  options, name, 'y_no_interp', 1
  options, name, 'x_no_interp', 1
  zlim, name, 1d1, 5d2, 1
endelse
index_sst = where(thx+'_psef_en_eflux' eq tnames())
if index_sst eq -1 then begin
  filler = fltarr(2, 16)
  filler[*, *] = float('NaN')
  store_data, thx+'_psef_en_eflux', $
    data = {x:time_double(date)+findgen(2), y:filler, v:findgen(16)}
  name = thx+'_psef_en_eflux'
  options, name, 'spec', 1
  ylim, name, 1, 1000, 1
  zlim, name, 1d1, 5d2, 1
  options, name, 'ytitle', thx+'!CSST elec!CeV'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
endif else begin
;SST electron panel
  name = thx+'_psef_en_eflux'
  tdegap, name, /overwrite, dt = 600.0
  options, name, 'spec', 1
  options, name, 'ytitle', thx+'!CSST elec!CeV'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
  options, name, 'y_no_interp', 1
  options, name, 'x_no_interp', 1
  zlim, name, 1d1, 5d2, 1
endelse

;load ESA spectrograms and moments
;----------------------------------
load_position='esa'
;load both full and reduced data:
mtyp = ['f', 'r']
ok_esai_flux = bytarr(2)
ok_esae_flux = bytarr(2)
ok_esai_moms = bytarr(2)
ok_esae_moms = bytarr(2)
For j = 0, 1 Do Begin
  thm_load_esa, probe = sc, datatype = 'pe?'+mtyp[j]+'*', level = 'l2'
  itest = thx+'_pei'+mtyp[j]
  etest = thx+'_pee'+mtyp[j]
;If Level 2 data didn't show up, check for L1
  index_esa_e_en = where(etest+'_en_eflux' eq tnames())
  index_esa_e_d = where(etest+'_density' eq tnames())
  index_esa_e_v = where(etest+'_velocity_dsl' eq tnames())
  index_esa_e_t = where(etest+'_t3' eq tnames())

  index_esa_i_en = where(itest+'_en_eflux' eq tnames())
  index_esa_i_d = where(itest+'_density' eq tnames())
  index_esa_i_v = where(itest+'_velocity_dsl' eq tnames())
  index_esa_i_t = where(itest+'_t3' eq tnames())

  if(index_esa_e_en[0] eq -1 Or index_esa_i_en[0] Eq -1) then begin
    thm_load_esa_pkt, probe = sc
    instr_all = ['pei'+mtyp[j], 'pee'+mtyp[j]]
    for k = 0, 1 do begin
      test_index = where(thx+'_'+instr_all[k]+'_en_counts' eq tnames())
      If(test_index[0] Ne -1) Then Begin
        thm_part_moments, probe = sc, instrument = instr_all[k], $
          moments = '*'
        copy_data, thx+'_'+instr_all[k]+'_velocity', $
          thx+'_'+instr_all[k]+'_velocity_dsl'
     Endif
    endfor
    index_esa_e_en = where(etest+'_en_eflux' eq tnames())
    index_esa_e_d = where(etest+'_density' eq tnames())
    index_esa_e_v = where(etest+'_velocity_dsl' eq tnames())
    index_esa_e_t = where(etest+'_t3' eq tnames())
    
    index_esa_i_en = where(itest+'_en_eflux' eq tnames())
    index_esa_i_d = where(itest+'_density' eq tnames())
    index_esa_i_v = where(itest+'_velocity_dsl' eq tnames())
    index_esa_i_t = where(itest+'_t3' eq tnames())
  endif
  if index_esa_i_en[0] eq -1 then begin
    filler = fltarr(2, 32)
    filler[*, *] = float('Nan')
    name1 = itest+'_en_eflux'
    store_data, name1, data = {x:time_double(date)+findgen(2), y:filler, v:findgen(32)}
    zlim, name1, 1d3, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
;    options, name1, 'ytitle', 'ESA i+ '+thx+'!C eV'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
  endif else begin
    name1 = itest+'_en_eflux'
    tdegap, name1, /overwrite, dt = 600.0
    zlim, name1, 1d3, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA i+ '+thx+'!C eV'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
    options, name1, 'x_no_interp', 1
    options, name1, 'y_no_interp', 1
    ok_esai_flux[j] = 1
  endelse

  if index_esa_i_d[0] eq -1 then begin
    filler = fltarr(2)
    filler[*] = float('Nan')
    store_data, itest+'_density', data = {x:time_double(date)+findgen(2), y:filler}
;    options, itest+'_density', 'ytitle', 'Ni '+thx+'!C!C1/cm!U3'
    options, itest+'_density', 'ytitle', 'Ni '+thx
  endif else begin
    name1 = itest+'_density'
    tdegap, name1, /overwrite, dt = 600.0
    ylim, name1, .1, nmax, 1
    options, name1, 'ytitle', 'Ni '+thx
    ok_esai_moms[j] = 1
  endelse

  if index_esa_i_v[0] eq -1 then begin
    filler = fltarr(2, 3)
    filler[*, *] = float('Nan')
    store_data, itest+'_velocity_dsl', data = {x:time_double(date)+findgen(2), y:filler}
    options, itest+'_velocity_dsl', 'ytitle', 'VI '+thx+'!Ckm/s'
    options, itest+'_velocity_dsl', 'ysubtitle', ''
  endif else begin
    name1 = itest+'_velocity_dsl'
    tdegap, name1, /overwrite, dt = 600.0
    itstrg=[t0,t1]
    get_ylimits, name1, itslimits, itstrg
    minmaxvals=itslimits.yrange
    maxvel=max(abs(minmaxvals))
    maxlim=min([maxvel,2000.])
    minlim=0.-maxlim
    if maxvel le 100. then ylim, name1, -50,50,0 else ylim, name1, minlim, maxlim, 0
    options, name1, 'colors', [2, 4, 6]
    options, name1, 'labflag', 1
    options, name1, 'ytitle', 'VI '+thx+'!Ckm/s'
    options, name1, 'ysubtitle', ''
;;    options, name1, labels = ['Vi!dx!n', 'Vi!dy!n', 'Vi!dz!n'], constant = 0.
    options, name1, labels = ['VIx', 'VIy', 'VIz'], constant = 0.
  endelse

  if index_esa_i_t[0] eq -1 then begin
    filler = fltarr(2, 6)
    filler[*, *] = float('Nan')
    store_data, itest+'_t3', data = {x:time_double(date)+findgen(2), y:filler}
    options, itest+'_t3', 'ytitle', 'Ti '+thx+'!CeV'
    options, itest+'_t3', 'ysubtitle', ''
  endif else begin
    name1 = itest+'_t3'
    tdegap, name1, /overwrite, dt = 600.0
    ylim, name1, 10, 10000., 1
    options, name1, 'colors', [2, 4, 6, 0]
    options, name1, 'ytitle', 'Ti '+thx+'!C eV'
    options, name1, 'ysubtitle', ''
  endelse
  
  index_esa_e_en = where(etest+'_en_eflux' eq tnames())
  if index_esa_e_en[0] eq -1 then begin
    filler = fltarr(2, 32)
    filler[*, *] = float('Nan')
    name1 = etest+'_en_eflux'
    store_data, name1, data = {x:time_double(date)+findgen(2), y:filler, v:findgen(32)}
    zlim, name1, 1d4, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA e- '+thx+'!C eV'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
  endif else begin 
    name1 = etest+'_en_eflux'
    tdegap, name1, /overwrite, dt = 600.0
    zlim, name1, 1d4, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA e- '+thx+'!C eV'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
    options, name1, 'x_no_interp', 1
    options, name1, 'y_no_interp', 1
    ok_esae_flux[j] = 1
  endelse

  if index_esa_e_d[0] eq -1 then begin
    filler = fltarr(2)
    filler[*] = float('Nan')
    store_data, etest+'_density', data = {x:time_double(date)+findgen(2), y:filler}
;    options, etest+'_density', 'ytitle', 'Ne '+thx+'!C!C1/cm!U3'
    options, etest+'_density', 'ytitle', 'Ne '+thx+'!C1/cc'
    options, etest+'_density', 'ysubtitle', ''
no_npot:
    filler = fltarr(2)
    filler[*] = float('Nan')
    store_data, etest+'_density_npot', data = {x:time_double(date)+findgen(2), y:filler}
    options, etest+'_density_npot', 'ytitle', 'Ne '+thx+'!C1/cc'
    options, etest+'_density_npot', 'ysubtitle', ''
  endif else begin 
    name1 = etest+'_density'
    ylim, name1, .1, nmax, 1
;    options, name1, 'ytitle', 'Ne '+thx+'!C!C1/cm!U3'
    options, name1, 'ytitle', 'Ne '+thx+'!C1/cc'
    options, name1, 'ysubtitle', ''
    ok_esae_moms[j] = 1
;Npot calculation, 2009-10-12, jmm
    thm_scpot2dens_opt_n, probe = sc, /no_data_load, datatype_esa = 'pee'+mtyp[j]
;degap after npot calculation
    tdegap, name1, /overwrite, dt = 600.0
    name1x = tnames(etest+'_density_npot')
    get_data, name1x, data = npot_test
    If(is_struct(temporary(npot_test)) Eq 0) Then Goto, no_npot
    tdegap, name1x, /overwrite, dt = 600.0
    options, name1x, 'ytitle', 'Ne '+thx+'!C1/cc'
    options, name1x, 'ysubtitle', ''
  endelse
  
  if index_esa_e_v[0] eq -1 then begin
    filler = fltarr(2, 3)
    filler[*, *] = float('Nan')
    store_data, etest+'_velocity_dsl', data = {x:time_double(date)+findgen(2), y:filler}
;    options, etest+'_velocity_dsl', 'ytitle', 'Ve '+thx+'!C!Ckm/s'
    options, etest+'_velocity_dsl', 'ytitle', 'VE '+thx+'!Ckm/s'
    options, etest+'_velocity_dsl', 'ysubtitle', ''
  endif else begin
    name1 = etest+'_velocity_dsl'
    tdegap, name1, /overwrite, dt = 600.0
    ylim, name1, -500, 200., 0
;    options, name1, 'ytitle', 'Ve '+thx+'!C!Ckm/s'
    options, name1, 'ytitle', 'VE '+thx+'!Ckm/s'
    options, name1, 'ysubtitle', ''
  endelse

  if index_esa_e_t[0] eq -1 then begin
    filler = fltarr(2, 6)
    filler[*, *] = float('Nan')
    store_data, etest+'_t3', data = {x:time_double(date)+findgen(2), y:filler}
    options, etest+'_t3', 'ytitle', 'Te '+thx+'!CeV'
    options, etest+'_t3', 'ysubtitle', ''
  endif else begin
  ;options,name1,'colors',[cols.blue,cols.green,cols.red]
;    options, name1, labels = ['V!dex!n', 'V!dey!n', 'V!dez!n'], constant = 0.
    name1 = etest+'_t3'
    tdegap, name1, /overwrite, dt = 600.0
    options, name1, labels = ['TEx', 'TEy', 'TEz'], constant = 0.
    options, name1, labels = ['Ti_para', 'Ti_perp', 'Te_para', 'Te_perp']
    ylim, name1, 10, 10000., 1
    options, name1, 'colors', [2, 0, 4, 6]
    options, name1, 'ytitle', 'TE '+thx+'!CeV'
    options, name1, 'ysubtitle', ''
  endelse

; plot quantities (manipulating the plot quantities for the sake of plot aesthetics)
;kluge for labeling the density, added Npot, 2009-10-12, jmm
  get_data, etest+'_density', data = d
  get_data, etest+'_density_npot', data = d1
  Ne_kluge_name = 'Ne_'+etest+'_kluge'
  If(n_elements(d1.x) Eq n_elements(d.x)) Then Begin
    dummy = fltarr(n_elements(d.y), 3)
    dummy[*, 0] = d1.y
    dummy[*, 1] = d.y
    dummy[*, 2] = d.y
    store_data, Ne_kluge_name, data = {x:d.x, y:dummy}
    options, Ne_kluge_name, labels = ['Npot', 'Ni', 'Ne']
    options, Ne_kluge_name, colors = [2, 0, 6]
    options, Ne_kluge_name, 'labflag', 1
  Endif Else Begin
    dummy = fltarr(n_elements(d.y), 2)
    dummy[*, 0] = d.y
    dummy[*, 1] = d.y
    store_data, Ne_kluge_name, data = {x:d.x, y:dummy}
    options, Ne_kluge_name, labels = ['Ni', 'Ne']
    options, Ne_kluge_name, colors = [0, 6]
    options, Ne_kluge_name, 'labflag', 1
  Endelse
  
  ;copy data to a different name so that it doesn't overwrite gui data when imported
  copy_data,itest+'_density', itest+'_density'+osuffix
  copy_data,Ne_kluge_name, Ne_kluge_name+osuffix
  store_data, thx+'_Nie'+mtyp[j], data = [itest+'_density', Ne_kluge_name]+osuffix
;  options, thx+'_Nie'+mtyp[j], 'ytitle', 'Ni,e '+thx+'!C1/cm!U3'
;  options, thx+'_Nie'+mtyp[j], 'ytitle', 'Ni,e '+thx
  options, thx+'_Nie'+mtyp[j], 'ytitle', 'Ni,e '+thx+'!C1/cc'
  options, thx+'_Nie'+mtyp[j], 'ysubtitle', ''
  nameti=itest+'_t3'
  namete=etest+'_t3'
  ;copy data to a different name so that it doesn't overwrite gui data when imported
  copy_data,nameti,nameti+osuffix
  copy_data,namete,namete+osuffix
  store_data, thx+'_Tie'+mtyp[j], data = [nameti,namete]+osuffix
  options, thx+'_Tie'+mtyp[j], 'ytitle', 'Ti,e '+thx+'!CeV'
  options, thx+'_Tie'+mtyp[j], 'ysubtitle', ''
  options,nameti,'labels',['Ti!9'+string(120B)+'!X','','Ti!9'+string(35B)+'!X']
  options,namete,'labels',['    Te!9'+string(120B)+'!X','    ','    Te!9'+string(35B)+'!X']
  options, thx+'_Tie'+mtyp[j], 'labflag', 1
  options,nameti, 'colors', [2,2, 4]
  options,namete, 'colors', [6,6, 0]
Endfor
SKIP_ESA_LOAD:

load_position='mode'

; make tplot variable tracking the sample rate (0=SS,1=FS,2=PB,3=WB)
;-------------------------------------------------------------------
sample_rate_var = thm_sample_rate_bar(date, dur, sc, /outline)
get_data,sample_rate_var,limit=l
str_element,l,'panel_size',/delete ;panel arrangement handled through kluge below.  Using proper keywords breaks results
store_data,sample_rate_var,limit=l
options, sample_rate_var,'ytitle',''

;copy data to prevent overwriting data when importing into GUI
get_data,sample_rate_var,data=d
for sample_loop_var = 0,n_elements(d)-1 do begin
  copy_data,d[sample_loop_var],d[sample_loop_var]+osuffix
endfor


;run degap procedure on sample_rate_bar variables
tdegap, ['wave_burst_sym_', 'particle_burst_sym_']+sc[0], dt=600.0, /overwrite
spd_ui_update_dlimits,'sample_rate_'+sc,sc,'sample_rate','none','none'

SKIP_SURVEY_MODE:
load_position='bound'

; final tplot preparations
;--------------------------

; plot it!
thm_spec_lim4overplot, thx+'_peif_en_eflux', zlog = 1, ylog = 1, /overwrite
thm_spec_lim4overplot, thx+'_peef_en_eflux', zlog = 1, ylog = 1, /overwrite
thm_spec_lim4overplot, thx+'_peir_en_eflux', zlog = 1, ylog = 1, /overwrite
thm_spec_lim4overplot, thx+'_peer_en_eflux', zlog = 1, ylog = 1, /overwrite
ssti_name=thx+'_psif_en_eflux'
sste_name=thx+'_psef_en_eflux'
thm_spec_lim4overplot, ssti_name, zlog = 1, ylog = 1, /overwrite
;reset sst ylimit maxima to 3.0e6
get_data, ssti_name, data = d
If(is_struct(d)) Then ylim, ssti_name, min(d.v), 3.0e6, 1
thm_spec_lim4overplot, sste_name, zlog = 1, ylog = 1, /overwrite
get_data, sste_name, data = d
If(is_struct(d)) Then ylim, sste_name, min(d.v), 3.0e6, 1


;tplot_options, 'lazy_ytitle', 0 ; prevent auto formatting on ytitle (namely having carrage returns at underscores)

;!p.background=255.
;!p.color=0.
;time_stamp,/off
;loadct2,43
;!p.charsize=0.6

scv = strcompress(strlowcase(sc[0]),/remove_all)
pindex = where(vsc Eq scv) ;this is always true for one probe by the time we are here
;tplot_options,'ygap',0.0D

;For esa data we would like to plot full mode if possible, but reduced
;mode if no full mode is available
esaif_flux_name = thx+'_peif_en_eflux'
If(ok_esai_flux[0] Eq 0) Then Begin  ;esa ion flux is not present full resolution,
  If(ok_esai_flux[1]) Then esaif_flux_name = thx+'_peir_en_eflux'
Endif
esaif_v_name = thx+'_peif_velocity_dsl'
If(ok_esai_moms[0] Eq 0) Then Begin
  If(ok_esai_moms[1]) Then esaif_v_name = thx+'_peir_velocity_dsl'
Endif
esaef_flux_name = thx+'_peef_en_eflux'
If(ok_esae_flux[0] Eq 0) Then Begin  ;esa electron flux is not present full resolution, rename if possible
  If(ok_esae_flux[1]) Then esaef_flux_name = thx+'_peer_en_eflux'
Endif
esaef_v_name = thx+'_peef_velocity_dsl'
If(ok_esae_moms[0] Eq 0) Then Begin
  If(ok_esae_moms[1]) Then esaef_v_name = thx+'_peer_velocity_dsl'
Endif
esaf_t_name = thx+'_Tief'       ;T and N are done for ions, electrons together
esaf_n_name = thx+'_Nief'
If(ok_esai_moms[0] Eq 0) Then Begin
  If(ok_esai_moms[1]) Then Begin
    esaf_t_name = thx+'_Tier'
    esaf_n_name = thx+'_Nier'
  Endif
Endif
; kludge to make y titles consistent with the summary plots from the website
;options, esaf_n_name, 'ytitle', ' '
;options, esaif_v_name, 'ytitle', ' '
options, roi_bar, 'ytitle', ' '
options, thg_pseudoAE, 'ytitle', ' '
options, 'sample_rate_'+sc, 'ytitle', ' '
options, ssti_name, 'ysubtitle', ' '
options, esaif_flux_name, 'ysubtitle', ' '
options, sste_name, 'ysubtitle', ' ' 
options, esaef_flux_name, 'ytitle', ' '
options, ssti_name, 'ytitle', ' '
options, esaif_flux_name, 'ytitle', ' '
options, sste_name, 'ytitle', ' ' 
options, esaef_flux_name, 'ytitle', ' '
names = [esaf_n_name, esaif_v_name, esaf_t_name, 'sample_rate_'+sc, $
             ssti_name, esaif_flux_name, sste_name,  $
             esaef_flux_name]

for i = 0,n_elements(names)-1 do begin
  copy_data,names[i],names[i]+osuffix
endfor
tplot_gui,names+osuffix,/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw)
spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data

SKIP_BOUNDS:

;load FBK data
;--------------

load_position='fbk'

thm_load_fbk,probe=sc

;fbk_tvars=tnames(thx+'_fb_*') ;this should give us two tplot variables (but sometimes more)
;Set fbk variables to spectrograms, in dlimits
fbk_tvars = [tnames(thx+'_fb_e*'), tnames(thx+'_fb_s*')]
if is_string(fbk_tvars) eq 0 then fbk_tvars=['fbk_filler','fbk_filler'] ;need two blank panels
if n_elements(fbk_tvars) eq 1 then fbk_tvars=[fbk_tvars,'fbk_filler']  ;need one blank panel
for i=0,n_elements(fbk_tvars)-1 do begin
;kluge to prevent missing data from crashing things
  get_data,fbk_tvars[i],data=dd,dlimits=dl
  if size(dd,/type) ne 8 then begin
    filler = fltarr(2, 6)
    filler[*, *] = float('NaN')
    name = thx+'_fb_NaN'+strcompress(string(i+1), /remove_all)
    store_data, name, data = {x:time_double(date)+findgen(2), y:filler, v:findgen(6)}
    options, name, 'spec', 1
    ylim, name, 1, 1000, 1
    zlim, name, 0, 0, 1
    fbk_tvars[i] = name
  endif else begin
    options, fbk_tvars[i], 'spec', 1
    options, fbk_tvars[i], 'zlog', 1
    ylim, fbk_tvars[i], 2.0, 2048.0, 1
    thm_spec_lim4overplot, fbk_tvars[i], ylog = 1, zlog = 1, /overwrite
    options, fbk_tvars[i], 'ysubtitle', ' '
    options, fbk_tvars[i], 'ytitle', ' '
;    options, fbk_tvars[i], 'ytitle', thx+'_FBK '+strmid(fbk_tvars[i], 7)
;for ztitle, we need to figure out which type of data is there
;      for V channels, <|V|>.
;      for E channels, <|mV/m|>.
;      for SCM channels, <|nT|>.
    x1 = strpos(fbk_tvars[i], 'scm')
    If(x1[0] Ne -1) Then Begin
      options, fbk_tvars[i], 'ztitle', '<|nT|>'
;reset the upper value of zlimit to 2.0, jmm, 30-nov-2007
      get_data, fbk_tvars[i], data = d
      If(is_struct(d)) Then zlim,  fbk_tvars[i], min(d.y), 2.0, 1
    Endif
    xv = strpos(fbk_tvars[i], 'v')
    If(xv[0] Ne -1) Then options, fbk_tvars[i], 'ztitle', '<|V|>'
    xe = strpos(fbk_tvars[i], 'e')
    If(xe[0] Ne -1) Then Begin
      options, fbk_tvars[i], 'ztitle', '<|mV/m|>'
;reset the upper value of zlimit to 2.0, jmm, 30-nov-2007
      get_data, fbk_tvars[i], data = d
      If(is_struct(d)) Then zlim,  fbk_tvars[i], min(d.y), 2.0, 1
    Endif
;Explicitly set fbk variables to spectrograms, in dlimits
    If(is_struct(dl)) Then Begin
        str_element, dl, 'spec', 1, /add_replace
        str_element, dl, 'log', 1, /add_replace
        store_data, fbk_tvars[i], dlimits = dl
    Endif
  endelse

endfor

for i = 0,n_elements(fbk_tvars)-1 do begin
  copy_data,fbk_tvars[i],fbk_tvars[i]+osuffix
endfor

tplot_gui,fbk_tvars+osuffix,/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw)
spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data

SKIP_FBK_LOAD:

; Get position info
;---------------------------------------------------------

load_position='pos'

thm_load_state,probe=sc
thm_cotrans,thx+'_state_pos',out_suf='_gse',in_coord='gei',out_coord='gse'
get_data, thx+'_state_pos_gse',data=tmp
;creating new state variables in unnecessary now, jmm, 15-apr-2009
If(is_struct(tmp)) Then begin
  store_data,thx+'_state_pos_gse',data={x:tmp.x,y:tmp.y/6371.2} ;mean radius
endif else begin
  store_data,thx+'_state_pos_gse',data={x:time_double(date)+findgen(2),y:dblarr(2,3)+!VALUES.D_NAN}
endelse

SKIP_POS_LOAD:

load_position='plot'

vars_full = ['thg_pseudoAE', roi_bar, 'Keogram', thx+'_fgs_gse', $
             esaf_n_name, esaif_v_name, esaf_t_name, 'sample_rate_'+sc, $
             ssti_name, esaif_flux_name, sste_name,  $
             esaef_flux_name, fbk_tvars]
             



; add suffix to tplot vars so that multiple loads won't interfere w/each other
;nvars = n_elements(vars_full)
;;osuffix = '_test'
;vars_full_sfx = vars_full + osuffix
;for i=0, nvars-1 do begin
;  
;  get_data, vars_full[i], data=d, dlimits=dl, limits=l
;  if size(d,/type) eq 7 then begin
;    ;handle pseudovariables
;  
;    for j=0, n_elements(d)-1 do begin
;      copy_data, d[j], d[j] + osuffix
;      del_data, d[j]
;    endfor
;    store_data, vars_full[i], data=d+osuffix, dlimits=dl, limits=l
;  endif
;  copy_data, vars_full[i], vars_full_sfx[i]
;endfor
;del_data, vars_full
;
;tplot_gui, vars_full_sfx, /no_verify,no_draw=no_draw

probes_title = ['P5',  'P1',  'P2',  'P3', 'P4']

;Ok, this is the 2nd plot, what you need to do here is get the GUI
;info object and redo the plots once.

if ~keyword_set(no_draw) then begin

  ;Only one active window at a time
  wo = windowstorage -> getactive()
  If(n_elements(wo) gt 0 && obj_valid(wo[0])) Then Begin
      wo[0] -> setproperty, tracking = 0
      wo[0] -> getproperty, panels = panelsj
      panel = panelsj -> get(/all)
  
  Endif
  
  current_row = 1
  
  for i = 0,n_elements(panel)-1 do begin
  
    panel[i]->getProperty,xAxis=xobj,yAxis=yobj,zAxis=zObj,settings=panel_settings
  
    ;fix the range of the plot to the requested range.
    if i eq 0 then begin
      xobj->setProperty,rangeOption=2,minFixedRange=time_double(date),maxFixedRange=time_double(date)+dur*24*60*60
    endif
     
    ;decrease the number of ticks on the panels to avoid clutter
    if i eq 1 || i eq 7 then begin
      xObj->setProperty,majorLength=2,minorLength=1
      yobj->setProperty,numMajorTicks=0,autoticks=0,numMinorTicks=0
    endif else begin
      xObj->setProperty,majorLength=4,minorLength=2
      yobj->setProperty,numMajorTicks=3,numMinorTicks=1
    endelse
  ;  
  ;  ;autoticks = 0 guarantees that our y/z axis tick settings will not be overridden
  ;  yObj->setProperty,autoticks=1
  ;
  ;  if obj_valid(zObj) then begin
  ;
  ;    zObj->setProperty,tickNum=3,minorTickNum=1,autoticks=1
  ;
  ;  endif
  
    ;modify layout to make status bars smaller
    if i eq 1 || i eq 7 then begin
      if i eq 1 then begin
        panel_settings->setProperty,row=current_row,rSpan=2
        current_row += 2
      endif else begin
        panel_settings->setProperty,row=current_row,rSpan=1
        current_row += 1
      endelse
    endif else begin
      panel_settings->setProperty,row=current_row,rSpan=4
      current_row += 4
    endelse
  
  endfor
  
  ;set the vertical spacing to a smaller number, to save space on a many panel layout
  wo[0]->getProperty,settings=page
  page->setProperty,yPanelSpacing=0
  
  ;set the total number of rows
  wo[0]->setProperty,nRows=current_row-1
  
  
  ;get trace for the first panel and change the color to black, and set
  ;the title
  to = obj_new('spd_ui_text')
  to -> setproperty, value = probes_title[pindex[0]]+' (TH-'+strupcase(sc)+')'
  to -> setproperty, size=8.
  ;panel[0] -> getproperty, settings = p0settings
  ;p0settings -> setproperty, titleobj = to
  page->setproperty, title=to
  panel[0] -> getproperty, tracesettings = obj0
  trace_obj = obj0 -> get(/all)
  
  if obj_valid(trace_obj[0]) then begin
    trace_obj[0] -> getproperty, linestyle = linestyleobj
    linestyleobj -> setproperty, color = [0b, 0b, 0b]
  endif
  
  ;set labels
;  quick_set_panel_labels, panel[0], ['SPEDAS AE Index']
  
  ;quick_set_panel_labels, panel[0], ['SPEDAS', 'AE Index']
  ;ROI panel now, this needs 1 black label
  ;ROI also needs 1:1 labels:traces
;  quick_set_panel_labels, panel[1], ['ROI','','','','','','','','','','','','','','','']
;  quick_set_panel_labels, panel[1], ['Region_Panel']
  panel[1]->getProperty,yaxis=yobj
  yobj->setProperty,annotateAxis=0,lineatzero=0
  yobj->getProperty, labels = ylbls
  if obj_valid(ylbls) then begin
    lobj = ylbls->get(/all)
    lobj0 = lobj[0]
    lobj0->setProperty, size=8.0
;    lobj0->setProperty, value='Region_Panel'
  endif
;  to = obj_new('spd_ui_text')
;  to->setProperty, value='Region_Panel'
;  to->setProperty, size=9
;  ylbls->add, to
;  yobj->setProperty, labels=ylbls
;  panel[1]->setProperty, yaxis=yobj
  
;  quick_set_panel_labels, panel[1], ['Region_Panel']
  panel[1] -> getproperty, tracesettings = obj0
  trace_obj = obj0 -> get(/all)
  ntr = 11 ; 11 is based on the total of the bit mask in thm_roi_bar.pro
  
  ; setup colors for ROI plot
  
  
  ;this code will break if spedas color table is not loaded.
  ;roi_cols = 10+indgen(ntr)*7*245/ntr mod 245
  ;tvlct, r,g,b,/get
  ;ctbl = [[r],[g],[b]]
  
  ctbl = transpose([[7,0,5],$
          [235,255,0],$
          [0,97,255],$
          [253,0,0],$
          [90,255,0],$
          [43,0,232],$
          [255,103,0],$
          [0,255,133],$
          [83,0,117],$
          [255,199,0],$
          [0,235,254]])
  
  for i = 0,ntr-1 do begin
    trace_obj[i]->getProperty,linestyle=linestyleObj
    lineStyleObj->setProperty,thickness=2, color=ctbl[i,*]
  endfor
  
  ;Fix the keogram panel, needs linear Z scaling & labels
  ;;;;;;;;;;;;;;;;;;;; eric's test stuff
;vars_full = ['thg_pseudoAE', roi_bar, 'Keogram', thx+'_fgs_gse', $
;             esaf_n_name, esaif_v_name, esaf_t_name, 'sample_rate_'+sc, $
;             ssti_name, esaif_flux_name, sste_name,  $
;             esaef_flux_name, fbk_tvars]

  ;;;;;;;;;;;;;;;;;;;;
  quick_set_panel_labels, panel[2], 'Keogram'
  
  quick_set_panel_labels, panel[2], ' ', /zaxis
  panel[2] -> getproperty, zaxis = zobj
  if(obj_valid(zobj)) then zobj -> setproperty, scaling = 0
  ;Reset labels for FGS data:
; quick_set_panel_labels, panel[3], ['B FIT_GSE(nT)','',''], $
;  quick_set_panel_labels, panel[3], ['Bx', 'By', 'Bz'], $
;    colors_in = [[0b, 0b, 255b], [0b, 255b, 0b], [255b, 0b, 0b]]
panel[3]->getProperty, yaxis=yobj
yobj->setProperty, stackLabels = 1, orientation = 0
  quick_set_panel_labels, panel[3], ['Bx', 'By', 'Bz'], $
    colors_in = [2, 4, 6], /zaxis
    
  ;Density and Temperature variables need log scaling, and new colors
  ;and labels
  panel[4] -> getproperty, tracesettings = obj0
  trace_obj = obj0 -> get(/all)
  If(n_elements(trace_obj) Eq 4) Then Begin;we have an n_pot
      trace_obj[0] -> getproperty, linestyle = linestyleobj
      linestyleobj -> setproperty, color = [0b, 0b, 0b]
      trace_obj[1] -> getproperty, linestyle = linestyleobj
      linestyleobj -> setproperty, color = [0b, 0b, 255b]
      trace_obj[2] -> getproperty, linestyle = linestyleobj
      linestyleobj -> setproperty, color = [255b, 0b, 0b]
      panel[4] -> getproperty, yaxis = yobj
      yobj -> setproperty, scaling = 1
;      yobj -> getProperty, labels=labels
      ;quick_set_panel_labels, panel[4], ['ESA Ni', 'ESA Ne', 'ESA Npot', '[cm^-3]'],$
;      quick_set_panel_labels, panel[4], ['Ni,e_1/cc','', '', ''],$
;        colors_in = [[0b, 0b, 0b], [255b, 0b, 0b], [0b, 0b, 255b], [0b, 0b, 0b]]

      yobj->setProperty, orientation = 0
      yobj->setProperty, stackLabels = 1
      quick_set_panel_labels, panel[3], ['Ne', 'Ni', 'Npot'], $
        colors_in = [2, 0, 6], /zaxis
      quick_set_panel_labels, panel[3], ['Ne', 'Ni', 'Npot'],/zaxis
  Endif Else Begin              ;no n_pot
      trace_obj[0] -> getproperty, linestyle = linestyleobj
      linestyleobj -> setproperty, color = [0b, 0b, 0b]
      trace_obj[1] -> getproperty, linestyle = linestyleobj
      linestyleobj -> setproperty, color = [255b, 0b, 0b]
      panel[4] -> getproperty, yaxis = yobj
      yobj -> setproperty, scaling = 1
      quick_set_panel_labels, panel[4], ['Ni,e_1/cc','', ''],$
        colors_in = [[0b, 0b, 0b], [255b, 0b, 0b], [0b, 0b, 0b]]
  Endelse
  ;reset velocity labels
  ;quick_set_panel_labels, panel[5], ['Vx DSL', 'Vy DSL', 'Vz DSL', '[km/s]', 'ESA Ion'], $
;  quick_set_panel_labels, panel[5], ['Vi_km/s', '', '', '', ''], $
;    colors_in = [[0b, 0b, 255b], [0b, 255b, 0b], [255b, 0b, 0b], $
;                 [0b, 0b, 0b], [0b, 0b, 0b]]
  panel[5]->getProperty, yaxis=yobj
  yobj->setProperty, stackLabels = 1, orientation = 0
  quick_set_panel_labels, panel[5], ['Viz', 'Viy', 'Viz'], $
    colors_in = [2, 4, 6], /zaxis, /zhorizontal
    
  ;t3 needs labels, and logs
  panel[6] ->  getproperty, yaxis = yobj
  yobj -> setproperty, scaling = 1
  yobj->setProperty, stackLabels = 2, orientation = 0
;  quick_set_panel_labels, panel[6], ['Ti_para', 'Te_para', 'Ti_perp', 'Te_perp'], colors_in = [2, 0, 4, 6], /zaxis
;  quick_set_panel_labels, panel[6], ['Ti,e_eV', '', $
;                                     '', '', $
;                                     ''], $
                          
  ;statusbar panel needs different colors
  panel[7] -> getproperty, tracesettings = obj0
  trace_obj = obj0 -> get(/all)
  ntraces = n_elements(trace_obj)
  If(ntraces Gt 1) Then Begin
      If(obj_valid(trace_obj[1])) Then Begin
          trace_obj[1] -> getproperty, linestyle = linestyleobj
          linestyleobj -> setproperty, color = [255b, 0b, 0b]
      Endif
      If(obj_valid(trace_obj[2])) Then Begin
          trace_obj[2] -> getproperty, linestyle = linestyleobj
          linestyleobj -> setproperty, color = [255b, 255b, 0b]
      Endif
      If(obj_valid(trace_obj[4])) Then Begin
          trace_obj[4] -> getproperty, linestyle = linestyleobj
          linestyleobj -> setproperty, color = [0b, 0b, 0b]
      Endif
      for i = 0,n_elements(trace_obj)-1 do begin
          trace_obj[i]->getProperty,linestyle=linestyleObj,symbol=symbolobj
          lineStyleObj->setProperty,thickness=2
          lineStyleObj->getProperty,color=linecolor
          symbolobj->setProperty,show=0,name=symbolobj->getSymbolName(symbolid=4),id=4,color=linecolor
      endfor
  Endif
  
  quick_set_panel_labels, panel[7], ['', '','','','']
  
  panel[7]->getProperty,yaxis=yobj ;, tracesettings = trobj
  yobj->setProperty,annotateAxis=0
  
  ;;make sure SST and ESA panels have same z-range
  ;panel[8]->getproperty, zaxis=zobj_sst
  ;zobj_sst->getproperty, minRange=zmin0, maxRange=zmax0
  ;panel[9]->getproperty, zaxis=zobj_esa
  ;zobj_esa->getproperty, minRange=zmin1, maxRange=zmax1
  ;zmin=min([zmin0,zmin1])
  ;if zmin le 0 then zmin=1.
  ;zmax=max([zmax0,zmax1])
  ;zobj_sst->setproperty, minRange=zmin, maxRange=zmax, fixed=1
  ;zobj_esa->setproperty, minRange=zmin, maxRange=zmax, fixed=1
  ;panel[8]->setproperty, zaxis=zobj_sst
  ;panel[9]->setproperty, zaxis=zobj_esa
  ;
  ;panel[10]->getproperty, zaxis=zobj_sst
  ;zobj_sst->getproperty, minRange=zmin0, maxRange=zmax0
  ;panel[11]->getproperty, zaxis=zobj_esa
  ;zobj_esa->getproperty, minRange=zmin1, maxRange=zmax1
  ;zmin=min([zmin0,zmin1])
  ;if zmin le 0 then zmin=1.
  ;zmax=max([zmax0,zmax1])
  ;zobj_sst->setproperty, minRange=zmin, maxRange=zmax, fixed=1
  ;zobj_esa->setproperty, minRange=zmin, maxRange=zmax, fixed=1
  ;panel[10]->setproperty, zaxis=zobj_sst
  ;panel[11]->setproperty, zaxis=zobj_esa
  
  ;Keep ESA and SST spectra's z-range consistant
  panel[8]->getproperty, zaxis = zobj_ssti
  zobj_ssti->setproperty, minrange = 1d0, maxrange = 5d7, fixed=1
  panel[9]->getproperty, zaxis = zobj_esai
  zobj_esai->setproperty, minrange = 1d3, maxrange = 7.5d8, fixed=1
  panel[10]->getproperty, zaxis = zobj_sste
  zobj_sste->setproperty, minrange = 1d0, maxrange = 5d7, fixed=1
  panel[11]->getproperty, zaxis = zobj_esae
  zobj_esae->setproperty, minrange = 1d4, maxrange = 7.5d8, fixed=1
  
  ;SST needs to have y scaling set to log
  panel[8] -> getproperty, yaxis = yobj
  yobj -> setproperty, scaling = 1
  yobj -> setproperty, rangeoption = 2
  get_data, ssti_name, data = d
  yobj -> setproperty, maxfixedrange = 3.0e6
  If(is_struct(d) && tag_exist(d, 'v')) Then yobj -> setproperty, minfixedrange = min(d.v) $
  Else yobj -> setproperty, minfixedrange = 3.0e4
  quick_set_panel_labels, panel[8], ['SSTi_Eflux_[eV]']
;  quick_set_panel_labels, panel[8], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
   quick_set_panel_labels, panel[8], 'Eflux, EFU', /zaxis
  ;ESA needs logs too
  panel[9] -> getproperty, yaxis = yobj
  yobj -> setproperty, scaling = 1
  quick_set_panel_labels, panel[9], ['ESAi_Eflux_[eV]']
;  quick_set_panel_labels, panel[9], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
  quick_set_panel_labels, panel[9], 'Eflux, EFU', /zaxis
  ;SST electrons
  panel[10] -> getproperty, yaxis = yobj
  yobj -> setproperty, scaling = 1
  yobj -> setproperty, rangeoption = 2
  get_data, sste_name, data = d
  yobj -> setproperty, maxfixedrange = 3.0e6
  If(is_struct(d) && tag_exist(d, 'v')) Then yobj -> setproperty, minfixedrange = min(d.v) $
  Else yobj -> setproperty, minfixedrange = 3.0e4
  quick_set_panel_labels, panel[10], ['SSTe_eflux_[eV]']
;  quick_set_panel_labels, panel[10], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
  quick_set_panel_labels, panel[10], 'Eflux, EFU', /zaxis
  ;ESA electrons
  panel[11] -> getproperty, yaxis = yobj
  yobj -> setproperty, scaling = 1
  quick_set_panel_labels, panel[11], ['ESAe_eflux_[eV]']
;  quick_set_panel_labels, panel[11], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
  quick_set_panel_labels, panel[11], 'Eflux, EFU', /zaxis
  ;FBK panels
  npanels = n_elements(panel)
  For j = 0, n_elements(fbk_tvars)-1 Do Begin
      jp = j+12
      If(jp Le npanels-1) Then Begin
          panel[jp] -> getproperty, yaxis = yobj
          yobj -> setproperty, scaling = 1
          get_data, fbk_tvars[j], dlimits = dl, limits = al
          lbl0 =  strupcase(strmid(fbk_tvars[j], 4)) & lbl1 = '  '
          If(is_struct(al) && tag_exist(al, 'ztitle')) Then lbl1 = al.ztitle
;          quick_set_panel_labels, panel[jp], [lbl0, '[Hz]']
          quick_set_panel_labels, panel[jp], lbl1, /zaxis
          quick_set_panel_labels, panel[jp], thx+'_FBK '+strmid(fbk_tvars[j], 7)
      Endif
      quick_set_panel_labels, panel[12], '<|mV/m|>', /zaxis
      quick_set_panel_labels, panel[13], '<|nT|>', /zaxis
  Endfor
  
endif

;for variable options, the state data needs to get into the
;loaded_data object:

; but first we need to add suffix
copy_data, thx+'_state_pos_gse', thx+'_state_pos_gse'+osuffix

If(is_string(tnames(thx+'_state_pos_gse'+osuffix))) Then Begin
    ok = loadeddata -> add(thx+'_state_pos_gse'+osuffix)
    
    if ~keyword_set(no_draw) then begin
    
      vo = objarr(3)
      panel[n_elements(panel)-1] -> getproperty, variables = var_container
      lbl = 'GSE '+['Z', 'Y', 'X']+' (Re)'
      vname = thx+'_state_pos_gse'+osuffix+'_'+['z', 'y', 'x']
      For j = 0, 2 Do Begin
          to0 = obj_new('spd_ui_text')
          to0 -> setproperty, value = lbl[j]
          to0 -> setproperty, size = 8.0
          vo[j] = obj_new('spd_ui_variable')
          vo[j] -> setproperty, text = to0
          vo[j] -> setproperty, controlname = thx+'_state_pos_gse'+osuffix+'_time'
          vo[j] -> setproperty, fieldname = vname[j]
      Endfor
      var_container -> add, vo
    endif
Endif

;WARNING:
;  Any code that requires windowStorage or loadedData should be put in the "~keyword_set(no_draw)" block.  
;  spd_ui_overplot is called without valid values for these parameters during document load 

if ~keyword_set(no_draw) then begin
  ;update the draw object and redraw the panels
  spd_ui_orientation_update,drawObject,windowStorage
  drawObject -> update, windowStorage, loadedData
  drawObject -> draw
endif

SKIP_DAY:

spd_ui_overplot_data_clean,tn_before,dont_delete_data=dont_delete_data

message, /info, 'Returning:'
error=0
Return

end
