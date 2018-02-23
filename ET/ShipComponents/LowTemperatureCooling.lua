local osmose = require 'osmose'
local et = osmose.Model 'LowTemperatureCooling'

----------
-- User parameters
----------

et.inputs = {
    -- Cooling supply
    HS_TIN = {default=35, unit='°C'},
    HS_TOUT = {default=50, unit='°C'},
    HS_QMAX = {default=10000, unit='kW'},
    -- Cooling intake
    HI_TIN = {default=50, unit='°C'},
    HI_TOUT = {default=35, unit='°C'},
    HI_QMAX = {default=10000, unit='kW'},
    -- Electricity consumption (for pumping/maintain pressure)
    EL_SPEC = {default=0.01, unit='kWh_el/kWh_th'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Electricity consumption
    EMAX = {unit='kW',job='EL_SPEC*HS_QMAX'}
}

-----------
-- Layers
-----------

et:addLayers {LTWater = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('LTCooling',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['LTCooling']:addStreams{
    -- Input heat
    qt_dc = qt({tin = 'HS_TIN', hin = 0, tout='HS_TOUT', hout='HS_QMAX', dtmin=0}),
    -- FW network
    fw_out = rs({'LTWater', 'in', 'HS_QMAX'}),
    -- Electricity
    elec_in = rs({'Electricity', 'in', 'EMAX'})
}

et:addUnit('LTRegeneration',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['LTRegeneration']:addStreams{
    -- Output heat
    qt_hot = qt({tin = 'HI_TIN', hin = 'HI_QMAX', tout='HI_TOUT', hout=0, dtmin=0}),
    -- FW network
    fw_in = rs({'LTWater', 'out', 'HI_QMAX'}),
}

return et