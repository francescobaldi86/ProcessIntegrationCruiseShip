local osmose = require 'osmose'
local et = osmose.Model 'LPSteamHeater'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    LPSTEAM_T = {default=150, unit='C'},
    QMAX = {default=10000, unit='kW'},
    
    -- Electricity consumption (for pumping/maintain pressure)
    --EL_SPEC = {default=0.01, unit='kWh_el/kWh_th'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {}

-----------
-- Layers
-----------

et:addLayers {LPSteam = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('LPSteamHeater',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['LPSteamHeater']:addStreams{
    -- Input heat
    qt_lp_steam_use = qt({tin = 'LPSTEAM_T', hin = 'QMAX', tout='LPSTEAM_T', hout=0, dtmin=0}),
    -- Steam network
    lpsteam_in = rs({'LPSteam', 'in', 'QMAX'}),
}

return et