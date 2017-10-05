;
; NOSA HEADER START
;
; The contents of this file are subject to the terms of the NASA Open 
; Source Agreement (NOSA), Version 1.3 only (the "Agreement").  You may 
; not use this file except in compliance with the Agreement.
;
; You can obtain a copy of the agreement at
;   docs/NASA_Open_Source_Agreement_1.3.txt
; or 
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
;
; See the Agreement for the specific language governing permissions
; and limitations under the Agreement.
;
; When distributing Covered Code, include this NOSA HEADER in each
; file and include the Agreement file at 
; docs/NASA_Open_Source_Agreement_1.3.txt.  If applicable, add the 
; following below this NOSA HEADER, with the fields enclosed by 
; brackets "[]" replaced with your own identifying information: 
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2010-2017 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the DatasetDescription element
; from the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfDatasetDescription object.
;
; @param id {in} {type=string}
;            dataset identifier.
; @param observatories {in} {type=strarr}
;            observatories that contributed data to this dataset.
; @param instruments {in} {type=strarr}
;            intruments that contributed data to this dataset.
; @param observatoryGroups {in} {type=strarr}
;            observatoryGroups that contributed data to this dataset.
; @param instrumentTypes {in} {type=strarr}
;            instrumentTypes that contributed data to this dataset.
; @param label {in} {type=string}
;            dataset label.
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time interval of this dataset.
; @param piName {in} {type=string}
;            name of Principal Investigator.
; @param piAffiliation {in} {type=string}
;            affiliation of PI.
; @param notes {in} {type=string}
;            notes about this dataset.
; @param datasetLinks {in} {type=objarr of SpdfDatasetLink}
;            links to information about this dataset.
; @returns reference to an SpdfDatasetDescription object.
;-
function SpdfDatasetDescription::init, $
    id, observatories, instruments, observatoryGroups, $
    instrumentTypes, label, timeInterval, piName, piAffiliation, $
    notes, datasetLinks
    compile_opt idl2

    self.id = id
    self.observatories = ptr_new(observatories)
    self.instruments = ptr_new(instruments)
    self.observatoryGroups = ptr_new(observatoryGroups)
    self.instrumentTypes = ptr_new(instrumentTypes)
    self.label = label
    self.timeInterval = timeInterval
    self.piName = piName
    self.piAffiliation = piAffiliation
    self.notes = notes
    self.datasetLinks = ptr_new(datasetLinks)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfDatasetDescription::cleanup
    compile_opt idl2

    if ptr_valid(self.observatories) then ptr_free, self.observatories
    if ptr_valid(self.instruments) then ptr_free, self.instruments
    if ptr_valid(self.observatoryGroups) then ptr_free, self.observatoryGroups
    if ptr_valid(self.instrumentTypes) then ptr_free, self.instrumentTypes
    if obj_valid(self.timeInterval) then obj_destroy, self.timeInterval
    if ptr_valid(self.datasetLinks) then ptr_free, self.datasetLinks
end


;+
; Gets the id value.
;
; @returns id value.
;-
function SpdfDatasetDescription::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the observatories.
;
; @returns strarr of observatories.
;-
function SpdfDatasetDescription::getObservatories
    compile_opt idl2

    return, *self.observatories
end


;+
; Gets the instruments.
;
; @returns strarr of instruments.
;-
function SpdfDatasetDescription::getInstruments
    compile_opt idl2

    return, *self.instruments
end


;+
; Gets the observatoryGroups.
;
; @returns strarr of observatoryGroups.
;-
function SpdfDatasetDescription::getObservatoryGroups
    compile_opt idl2

    return, *self.observatoryGroups
end


;+
; Gets the instrumentTypes.
;
; @returns strarr of instrumentTypes.
;-
function SpdfDatasetDescription::getInstrumentsTypes
    compile_opt idl2

    return, *self.instrumentsTypes
end


;+
; Gets the label value.
;
; @returns label value.
;-
function SpdfDatasetDescription::getLabel
    compile_opt idl2

    return, self.label
end


;+
; Gets the TimeInterval value.
;
; @returns TimeInterval value.
;-
function SpdfDatasetDescription::getTimeInterval
    compile_opt idl2

    return, self.timeInterval
end


;+
; Gets the Principal Investigator value.
;
; @returns Principal Investigator value.
;-
function SpdfDatasetDescription::getPiName
    compile_opt idl2

    return, self.piName
end


;+
; Gets the Principal Investigator's affilation value.
;
; @returns Principal Investigator's affilation value.
;-
function SpdfDatasetDescription::getPiAffiliation
    compile_opt idl2

    return, self.piAffiliation
end


;+
; Gets the notes value.
;
; @returns notes value.
;-
function SpdfDatasetDescription::getNotes
    compile_opt idl2

    return, self.notes
end


;+
; Gets the links.
;
; @returns objarr of links.
;-
function SpdfDatasetDescription::getDatasetLinks
    compile_opt idl2

    return, *self.datasetLinks
end


;+
; Prints a textual representation of this object.
;-
pro SpdfDatasetDescription::print
    compile_opt idl2

    print, 'id: ', self.id, self.label
;    print, 'observatoryGroups: ', *self.observatoryGroups
    self.timeInterval->print

end


;+
; Defines the SpdfDatasetDescription class.
;
; @field id dataset identifier.
; @field observatories observatories that contributed data to this
;            dataset.
; @field instruments intruments that contributed data to this 
;            dataset.
; @field observatoryGroups observatoryGroups that contributed data 
;            to this dataset.
; @field instrumentTypes instrumentTypes that contributed data 
;            to this dataset.
; @field label dataset label.
; @field timeInterval time interval of this dataset.
; @field piName name of Principal Investigator.
; @field piAffiliation affiliation of PI.
; @field notes notes about this dataset.
; @field datasetLinks links to information about this dataset.
;-
pro SpdfDatasetDescription__define
    compile_opt idl2
    struct = { SpdfDatasetDescription, $
        id:'', $
        observatories:ptr_new(), $
        instruments:ptr_new(), $
        observatoryGroups:ptr_new(), $
        instrumentTypes:ptr_new(), $
        label:'', $
        timeInterval:obj_new(), $
        piName:'', $
        piAffiliation:'', $
        notes:'', $
        datasetLinks:ptr_new() $
    }
end
