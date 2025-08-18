;+
; Function:
;       mms_hpca_mode
;
; Input:
;       brst_in: hpca burst data tplot variable
;       srvy_in: hpca survey data tplot variable 
;
; Output:
;       mode_out: creates a tplot variable with the name data_in + _mode
;       (with brst or srvy stripped off, containing flags 
;       for each mode (e.q. data.x=brst_srvy time and 
;       data.y:[brst_flag, srvy_flag]. 
;       Returns the name of the tplot variable it created.
;
;       NOTE: This only handles burst and survey type hpca data.
;             When fast data becomes available this will need
;             to be modified to handle that mode as well. 
;             
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-27 12:47:46 -0700 (Wed, 27 Apr 2016) $
; $LastChangedRevision: 20937 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_mode.pro $
;-


function mms_hpca_mode, brst_in, srvy_in

  get_data, brst_in, data=brst_data, dlimits=brst_dl, limits=brst_l
  get_data, srvy_in, data=srvy_data, dlimits=srvy_dl, limits=srvy_l

  ; setup d.x and d.y 
  nbrst=n_elements(brst_data.x)
  nsrvy=n_elements(srvy_data.x)
  mode_x=[srvy_data.x, brst_data.x]
  mode_y=dblarr(nsrvy+nbrst, 2)
  mode_y[0:nsrvy-1,0]=1.0
  mode_y[nsrvy:(nsrvy+nbrst)-1,1]=2.0
  
  mode_out=strmid(brst_in, 0, strlen(brst_in)-4) + 'mode' 
  mode_data = { x:mode_x, y:mode_y }

  ; modify the dlimits and limits structure for this new data
  this_l = {ylog:0, ytitle:'HPCA Modes', ysubtitle:'', yrange:[.5,2.5]}
  this_dl=brst_dl
  this_dl.spec=0
  this_dl = create_struct(this_dl, 'colors', ['r','b'], 'labels', ['Survey','Burst'], 'labflag', 1, $
        'psym', 6, 'ticklen', 0, 'symsize', .25, 'ytickname', [' ', ' ', ' ', ' ', ' '] )
  store_data, mode_out, data=mode_data, dlimits=this_dl, limits=this_l

  return, mode_out

end