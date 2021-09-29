;+
; PRO:  das2dlm_cassini_crib_rpws_survey
;
; Description:
;   A crib sheet demonstrates how to load and plot Radio and Plasma Wave Science Cassini data
;   Note, it requres das2dlm library
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-10-09 18:16:50 -0700 (Fri, 09 Oct 2020) $
; $Revision: 29237 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/examples/das2dlm_cassini_crib_rpws_survey.pro $
;-

; Load the mag rpws_survey and display the loaded tplot variable
; Use Survey mode and 0 dataset
das2dlm_load_cassini_rpws_survey, trange=['2013-01-01', '2013-01-02'], source='Survey', nset=0

; Plot the spectrogram
tplot, 'cassini_rpws_survey_amplitude_01'
end