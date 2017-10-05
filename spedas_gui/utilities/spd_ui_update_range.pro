spd_ui_update_range, windowStorage, xRange=xrange, YRange=yrange, ZRange=zrange

    panelObj->GetProperty, XAxis=xaxis, YAxis=yaxis
    IF N_Elements(xRange) NE 0 THEN xaxis->UpdateRange, xRange
    IF N_Elements(yRange) NE 0 THEN yaxis->UpdateRange, yRange
    panelObj->SetProperty, XAxis=xaxis, YAxis=yaxis
    
END
