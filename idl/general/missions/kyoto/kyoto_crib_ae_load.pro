

;+
;
;Name:
;KYOTO_CRIB_AE_LOAD.PRO
;
;Purpose:
;Demonstrate the Kyoto AE data loader.
;
;Code:
;W. Michael Feuerstein, 4/17/2008.
;
;Modifications:
;  Updated doc'n, WMF, 4/17/2008.
;
;-


;Specify timespan:
;=================
timespan,'2007-12-15',30


;Load all data in timespan:
;==========================
kyoto_ae_load


;Currently all data products are read in.  In the future only AE will be
;read in and the others can be gotten with the DATATYPE kw (e.g.,
;DATATYPE=['ae' 'al' 'ao' 'au'] ) (NOT YET IMPLEMENTED):
;=======================================================
tplot,['kyoto_ae','kyoto_al','kyoto_ao','kyoto_au']


end


