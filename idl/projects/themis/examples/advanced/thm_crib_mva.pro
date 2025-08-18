;+
;Procedure:
;  thm_crib_mva
;
;Purpose:
;  A crib on showing how to transform into minimum variance
;  analysis coordinates
;
;Notes:
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
; $LastChangedRevision: 17598 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_mva.pro $
;-

del_data,'*'

;timespan,'2007-07-10/07:48:00',16,/minute

timespan,'2007-07-10',1,/day
thm_load_fgm,probe='c',coord='gse', level = 'l2'

;default call just makes a single transformation matrix that covers
;the entire interval
minvar_matrix_make,'thc_fgs_gse',tstart='2007-07-10/07:54:00',tstop='2007-07-10/07:56:30'

tvector_rotate,'thc_fgs_gse_mva_mat','thc_fgs_gse',newname='mva_data_day'

;plot with this timespan
timespan,'2007-07-10/08:10:00',22,/minute
tplot,'thc_fgs_gse mva_data_day'

;tlimit,'2007-05-30/10:00:00','2007-05-30/14:00:00'

print,'Heres the fgm data translated into mva coordinates using a single transformation matrix'

stop

minvar_matrix_make,'thc_fgs_gse',twindow=3600,tslide=300

tvector_rotate,'thc_fgs_gse_mva_mat','thc_fgs_gse',newname='mva_data_hour'

;timespan for plotting
timespan,'2007-07-10/07:30:00',1,/hour
tplot,'thc_fgs_gse mva_data_hour'

print,'Heres the fgm data translated into mva coordinates using a different transformation every hour'

stop

minvar_matrix_make,'thc_fgs_gse',twindow=300,tslide=150

tvector_rotate,'thc_fgs_gse_mva_mat','thc_fgs_gse',newname='mva_data_min'

tplot,'mva_data_min'

print,'Heres the fgm data translated into mva coordinates using a different transformation every 5 minutes'

stop

tplot,'mva_data_*'

print,'Heres all 3'

end


