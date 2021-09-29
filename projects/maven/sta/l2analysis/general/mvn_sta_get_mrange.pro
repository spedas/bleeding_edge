;+
;Hard code mass ranges for the key ions. These are what Jim uses. Returns a structures for each major mass (H+, He+, O+, O2+, CO2+).
;Masse ranges are not necessarily symmetric - remember to m_int keywords where needed. 
;
;-
;

function mvn_sta_get_mrange

output = create_struct('H'    ,     [0., 1.55]    , $
                       'He'   ,     [1.55, 2.7]   , $
                       'O'    ,     [14., 20.]    , $
                       'O2'   ,     [24., 40.]    , $
                       'CO2'  ,     [40., 60.] )

return, output

end

