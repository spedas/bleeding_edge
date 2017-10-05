;+
;Procedure:
;     mms_neutral_sheet_crib
;
;Purpose:
;     Example of how to load MMS position data and retrieve the 
;     distance from the S/C to the neutral sheet
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-07 12:34:30 -0800 (Mon, 07 Nov 2016) $
;$LastChangedRevision: 22333 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_neutral_sheet_crib.pro $
;-

; load the position data
mms_load_mec, probe=1, trange=['2015-10-16', '2015-10-17']

; convert from km to Re
tkm2re, 'mms1_mec_r_gsm'

get_data, 'mms1_mec_r_gsm_re', data=pos_data

; get neutral sheet z position in RE, measured from the spacecraft location
neutral_sheet, pos_data.x, pos_data.y, model='lopez', distance2NS=z2NS, /sc2NS

; save the distance to the neutral sheet
store_data, 'z_distance_to_neutral_sheet', data={x: pos_data.X, y: z2NS}
options, 'z_distance_to_neutral_sheet', ysubtitle='[Re]'
tplot, 'z_distance_to_neutral_sheet'

end