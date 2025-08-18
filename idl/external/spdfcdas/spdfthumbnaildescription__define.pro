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
; This class is an IDL representation of the ThumbnailDescription
; element from the
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
; Creates an SpdfThumbnailDescription object.
;
; @param type {in} {type=string}
; @param name {in} {type=string}
; @param dataset {in} {type=string}
; @param timeInterval {in} {type=SpdfTimeIntervals}
;            time interval covered by the thumbnail images.
; @param varName {in} {type=string}
; @param options {in} {type=long64}
; @param numFrames {in} {type=long}
;            number of thumbnail images.
; @param numRows {in} {type=long}
;            number of rows of thumbnail images.
; @param numCols {in} {type=long}
;            number of columns of thumbnail images.
; @param titleHeight {in} {type=long}
;            height of title in pixels.
; @param thumbnailHeight {in} {type=long}
;            height of thumbnail image in pixels.
; @param thumbnailWidth {in} {type=long}
;            width of thumbnail image in pixels.
; @param startRecord {in} {type=long}
; @param myScale {in} {type=double}
; @param xyStep {in} {type=double}
; @returns reference to an SpdfThumbnailDescription object.
;-
function SpdfThumbnailDescription::init, $
    type, name, dataset, timeInterval, varName, options, numFrames, $
    numRows, numCols, titleHeight, thumbnailHeight, thumbnailWidth, $
    startRecord, myScale, xyStep
    compile_opt idl2

    self.type = type
    self.name = name
    self.dataset = dataset
    self.timeInterval = ptr_new(timeInterval)
    self.varName = varName
    self.options = options
    self.numFrames = numFrames
    self.numRows = numRows
    self.numCols = numCols
    self.titleHeight = titleHeight
    self.thumbnailHeigth = thumbnailHeigth
    self.thumbnailWidth = thumbnailWidth
    self.startRecord = startRecord
    self.myScale = myScale
    self.xyStep = xyStep

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfThumbnailDescription::cleanup
    compile_opt idl2

    if ptr_valid(self.timeInterval) then ptr_free, self.timeInterval
end


;+
; Gets the dataset value.
;
; @returns dataset value.
;-
function SpdfThumbnailDescription::getDataset
    compile_opt idl2

    return, self.dataset
end


;+
; Gets the number of frames.
;
; @returns number of frames.
;-
function SpdfThumbnailDescription::getNumFrames
    compile_opt idl2

    return, self.numFrames
end


;+
; Gets the number of rows of thumbnail images.
;
; @returns number of rows of thumbnail images.
;-
function SpdfThumbnailDescription::getNumRows
    compile_opt idl2

    return, self.numRows
end


;+
; Gets the number of columns of thumbnail images.
;
; @returns number of columns of thumbnail images.
;-
function SpdfThumbnailDescription::getNumCols
    compile_opt idl2

    return, self.numCols
end


;+
; Gets the height of the title.
;
; @returns height of title in pixels.
;-
function SpdfThumbnailDescription::getTitleHeight
    compile_opt idl2

    return, self.titleHeight
end


;+
; Gets the height of each thumbnail image.
;
; @returns height of each thumbnail image in pixels.
;-
function SpdfThumbnailDescription::getThumbnailHeight
    compile_opt idl2

    return, self.thumbnailHeight
end


;+
; Gets the width of each thumbnail image.
;
; @returns width of each thumbnail image in pixels.
;-
function SpdfThumbnailDescription::getThumbnailWidth
    compile_opt idl2

    return, self.thumbnailWidth
end


;+
; Defines the SpdfThumbnailDescription class.
;
; @field type
; @field name
; @field dataset dataset identifier.
; @field timeInterval
; @field varName
; @field options
; @field numFrames number of thumbnail images.
; @field numRows number of rows of thumbnail images.
; @field numCols number of columns of thumbnail images.
; @field titleHeight height of title in pixels.
; @field thumbnailHeight height of thumbnail image in pixels.
; @field thumbnailWidth width of thumbnail image in pixels.
; @field startRecord
; @field myScale
; @field xyStep
;-
pro SpdfThumbnailDescription__define
    compile_opt idl2
    struct = { SpdfThumbnailDescription, $
        type:'', $
        name:'', $
        dataset:'', $
        timeInterval:ptr_new(), $
        varName:'', $
        options:0LL, $
        numFrames:0L, $
        numRows:0L, $
        numCols:0L, $
        titleHeight:0L, $
        thumbnailHeight:0L, $
        thumbnailWidth:0L, $
        startRecord:0L, $
        myScale:0.0D, $
        xyStep:0.0D $
    }
end
