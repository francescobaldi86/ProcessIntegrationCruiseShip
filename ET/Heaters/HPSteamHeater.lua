local osmose = require 'osmose'
local et = osmose.Model 'HPSteamHeater'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    HPSTEAM_T = {default=150, unit='C'},
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

et:addLayers {HPSteam = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('HPSteamHeater',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HPSteamHeater']:addStreams{
    -- Input heat
    qt_hp_steam_use = qt({tin = 'HPSTEAM_T', hin = 'QMAX', tout='HPSTEAM_T', hout=0, stype='cond'}),
    -- Steam network
    hpsteam_in = rs({'HPSteam', 'in', 'QMAX'}),
}

return et