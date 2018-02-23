local osmose = require 'osmose'
local et = osmose.Model 'HighTemperatureCooling'

----------
-- User parameters
----------

et.inputs = {
    -- Cooling supply
    HS_TIN = {default=75, unit='C'},
    HS_TOUT = {default=90, unit='C'},
    HS_QMAX = {default=1000, unit='kW'},
    -- Cooling intake
    HI_TIN = {default=90, unit='C'},
    HI_TOUT = {default=75, unit='C'},
    HI_QMAX = {default=1000, unit='kW'},
    -- Electricity consumption (for pumping/maintain pressure)
    EL_SPEC = {default=0.01, unit=nil}
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

et:addLayers {HTWater = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('HTCooling',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HTCooling']:addStreams{
    -- Input heat
    qt_dc = qt({tin = 'HS_TIN', hin = 0, tout='HS_TOUT', hout='HS_QMAX', dtmin=3}),
    -- FW network
    fw_out = rs({'HTWater', 'in', 'HS_QMAX'}),
    -- Electricity
    elec_in = rs({'Electricity', 'in', 'EMAX'})
}

et:addUnit('HTRegeneration',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HTRegeneration']:addStreams{
    -- Output heat
    qt_hot = qt({tin = 'HI_TIN', hin = 'HI_QMAX', tout='HI_TOUT', hout=0, dtmin=3}),
    -- FW network
    fw_in = rs({'HTWater', 'out', 'HI_QMAX'}),
}

return et