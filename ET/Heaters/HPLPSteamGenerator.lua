local osmose = require 'osmose'
local et = osmose.Model 'HPSteamGenerator'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    HPSTEAM_TOUT = {default=150, unit='C'},
    LPSTEAM_TOUT = {default=100, unit='C'},
    QMAX = {default=10000, unit='kW'},
    
    -- Electricity consumption (for pumping/maintain pressure)
    --EL_SPEC = {default=0.01, unit='kWh_el/kWh_th'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Steam properties. Assuming a minor pressure loss
    HPSTEAM_TIN = {unit='C', job='HPSTEAM_TOUT'},
    LPSTEAM_TIN = {unit='C', job='LPSTEAM_TOUT'},
}

-----------
-- Layers
-----------

et:addLayers {HPSteam = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {LPSteam = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('HPSteamGenerator',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HPSteamBoiler']:addStreams{
    -- Input heat
    qt_cold = qt({tin = 'HPSTEAM_TIN', hin = 0, tout='HPSTEAM_TOUT', hout='QMAX', dtmin=0}),
    -- Steam network
    hpsteam_out = rs({'HPSteam', 'out', 'QMAX'}),
}

et:addUnit('LPSteamGenerator',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['LPSteamBoiler']:addStreams{
    -- Input heat
    qt_cold = qt({tin = 'LPSTEAM_TIN', hin = 0, tout='LPSTEAM_TOUT', hout='QMAX', dtmin=0}),
    -- Steam network
    lpsteam_out = rs({'LPSteam', 'out', 'QMAX'}),
}

return et