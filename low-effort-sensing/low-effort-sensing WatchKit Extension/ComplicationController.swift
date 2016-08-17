//
//  ComplicationController.swift
//  low-effort-sensing WatchKit Extension
//
//  Created by Kapil Garg on 1/24/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Timeline Configuration
    func getSupportedTimeTravelDirections(for complication: CLKComplication,
                                          withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication,
                                 withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void){
    }
    
    func getPlaceholderTemplate(for complication: CLKComplication,
                                         withHandler handler: @escaping (CLKComplicationTemplate?) -> Void){
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                               withHandler handler: @escaping (CLKComplicationTemplate?) -> Void){
        
    }
}
