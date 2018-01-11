;+
;  Procedure: space_bar
; 
;  Purpose: generates a horizontal bar stored in a tplot variable
;           that is used to adjust the spacing between tplot variables
;           in plots
;
;  Arguments:
;             n(positional,required): a double representing the height
;             of the space bar
;
;             newname(keyword,optional): the name you want the bar to
;             have(default: 'space_bar')
;      
;
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-10 17:03:26 -0800 (Wed, 10 Jan 2018) $
; $LastChangedRevision: 24506 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/space_bar.pro $
;-

pro space_bar,n,newname = newname

  if not keyword_set(newname) then newname = 'space_bar'

  store_data,newname,data={x:[0,1],y:[!values.F_NaN,!values.F_NaN]}

  options,newname,panel_size=n

  options,newname,color=255

end
