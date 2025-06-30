//
//  MockTestObservations.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 6/30/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import CoreGraphics
@testable import airbank_ocr_demo

struct MockTextObservation: TextObservationRepresentable {
    let text: String
    let boundingBox: CGRect
}

let observations: [MockTextObservation] = [
    .init(text: "A1079CD91", boundingBox: CGRect(x: 0.18604650751700483, y: 0.37936046574651394, width: 0.019379852940796555, height: 0.0726744182526119)),
    .init(text: "MARYLANDS", boundingBox: CGRect(x: 0.2810077542143172, y: 0.5523255810005264, width: 0.27325580738208916, height: 0.031976745242164206)),
    .init(text: "Driver's License", boundingBox: CGRect(x: 0.28100775819837853, y: 0.5319767444886354, width: 0.1879844867363178, height: 0.02184270014838574)),
    .init(text: "Customer identifier", boundingBox: CGRect(x: 0.4127906999881474, y: 0.5071924603263498, width: 0.13178294550174124, height: 0.011702888541751388)),
    .init(text: "MD-10276414752", boundingBox: CGRect(x: 0.41231459364414136, y: 0.48512513138579705, width: 0.19863736187970193, height: 0.023629996511671192)),
    .init(text: "DL", boundingBox: CGRect(x: 0.6337209301760197, y: 0.5450581402813661, width: 0.031007751585945154, height: 0.01744185932098874)),
    .init(text: "Family name", boundingBox: CGRect(x: 0.4146029269415612, y: 0.4573709557617063, width: 0.08552282827871815, height: 0.014037157808031386)),
    .init(text: "YANG", boundingBox: CGRect(x: 0.41257165317718864, y: 0.44147971054525104, width: 0.0488877018923482, height: 0.016749881562732494)),
    .init(text: "Given names", boundingBox: CGRect(x: 0.41666666632440114, y: 0.4228670635939077, width: 0.08527132064577131, height: 0.01027247120463659)),
    .init(text: "ROSEMARY ELAINE", boundingBox: CGRect(x: 0.4140163715725447, y: 0.40477037058103404, width: 0.15834038345902057, height: 0.020060755903758665)),
    .init(text: "Address", boundingBox: CGRect(x: 0.41658819982224576, y: 0.38788920691284157, width: 0.05635848373332353, height: 0.013465772545526944)),
    .init(text: "10763 DEBORAH DR", boundingBox: CGRect(x: 0.414728680503876, y: 0.37202380947353786, width: 0.16666666666666663, height: 0.017609126984126977)),
    .init(text: "POTOMAC MD 20854", boundingBox: CGRect(x: 0.41426817967948415, y: 0.3553152334767531, width: 0.17346029937582674, height: 0.01902202954367993)),
    .init(text: "Date of birth", boundingBox: CGRect(x: 0.4147286806729578, y: 0.33720930255740755, width: 0.09108527249129356, height: 0.014534883082859107)),
    .init(text: "Sex", boundingBox: CGRect(x: 0.5329457370676612, y: 0.3415697673140694, width: 0.023255812427985023, height: 0.011627906844729474)),
    .init(text: "Height", boundingBox: CGRect(x: 0.56965912078357, y: 0.3398939828892421, width: 0.05254222223998384, height: 0.014979476020449689)),
    .init(text: "02/24/2004", boundingBox: CGRect(x: 0.41658309823845874, y: 0.32236676005651876, width: 0.10288031643660611, height: 0.01660368934510248)),
    .init(text: "5'-04\"", boundingBox: CGRect(x: 0.5717054262166609, y: 0.32558139524469143, width: 0.05620155132636828, height: 0.015988372621082103)),
    .init(text: "Restrictions", boundingBox: CGRect(x: 0.4205426346925909, y: 0.30668604677143363, width: 0.0794573637543532, height: 0.011627906844729474)),
    .init(text: "Classifications", boundingBox: CGRect(x: 0.5736434115459507, y: 0.309593023234612, width: 0.09496123702437786, height: 0.011627906844729474)),
    .init(text: "B", boundingBox: CGRect(x: 0.41860465149438275, y: 0.2892441861748114, width: 0.013565891003482544, height: 0.011627906844729474)),
    .init(text: "02/24/2004", boundingBox: CGRect(x: 0.7692895893205883, y: 0.5127486089525743, width: 0.10289368806061916, height: 0.016653944575597435)),
    .init(text: "Weight", boundingBox: CGRect(x: 0.6782945751248178, y: 0.34302325622019836, width: 0.05426356401393018, height: 0.014534883082859107)),
    .init(text: "125", boundingBox: CGRect(x: 0.6782945746104513, y: 0.32703488329701713, width: 0.038759688220957655, height: 0.015988372621082103)),
    .init(text: "Endorsements", boundingBox: CGRect(x: 0.6821569245339636, y: 0.3124371055344045, width: 0.09498847477019778, height: 0.011753696297842287)),
    .init(text: "Date of exp", boundingBox: CGRect(x: 0.7810077543759416, y: 0.3459302327318262, width: 0.0775193764419152, height: 0.014534883082859107)),
    .init(text: "02/24/2033", boundingBox: CGRect(x: 0.7847676367804547, y: 0.3295873587968645, width: 0.10100736062993443, height: 0.019604351785447838)),
    .init(text: "Date of issue", boundingBox: CGRect(x: 0.7828649790889843, y: 0.3150640432703532, width: 0.08543282968026622, height: 0.012313773707738007)),
    .init(text: "05/11/2025", boundingBox: CGRect(x: 0.7848837208160881, y: 0.2979651158551565, width: 0.09689922433681586, height: 0.015988372621082103))
]


