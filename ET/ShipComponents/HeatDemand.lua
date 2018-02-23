local osmose = require 'osmose'
local et = osmose.Model 'HeatDemand'

----------
-- User parameters
----------

et.inputs = {
    -- This if valid for the ship under study
    -- Hot water heating (HWH)
    Q_HWH = {default=800, unit='kW'},
    T_HWH_IN = {default=70, unit='C'},
    T_HWH_OUT = {default=80, unit='C'},
    -- Heat Ventilation and Air Conditioning (HVAC)
    Q_HVAC = {default=1300, unit='kW'},
    T_HVAC_IN = {default=10, unit='C'},
    T_HVAC_OUT = {default=30, unit='C'},
    -- Tank Heating (TH)
    Q_TH = {default=800, unit='kW'},
    T_TH_IN = {default=60, unit='C'},
    T_TH_OUT = {default=80, unit='C'},
    -- Steam demand
    Q_ST = {default=700, unit='kW'},
    T_ST_IN = {default=110, unit='C'},
    T_ST_OUT = {default=110, unit='C'}    
}

-----------
-- Calculated parameters
-----------

et.outputs = {
}

-----------
-- Layers
-----------


-----------
-- Units
-----------

et:addUnit('HotWaterHeating',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HotWaterHeating']:addStreams{
    -- Thermal streams
    qt_steam_demand = qt({tin = 'T_HWH_IN', hin = 0, tout='T_HWH_OUT', hout='Q_HWH', dtmin=0}),
}
et:addUnit('HVAC',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HVAC']:addStreams{
    -- Thermal streams
    qt_steam_demand = qt({tin = 'T_HVAC_IN', hin = 0, tout='T_HVAC_OUT', hout='Q_HVAC', dtmin=0}),
}
et:addUnit('TankHeating',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['TankHeating']:addStreams{
    -- Thermal streams
    qt_steam_demand = qt({tin = 'T_TH_IN', hin = 0, tout='T_TH_OUT', hout='Q_TH', dtmin=0}),
}
et:addUnit('SteamDemand',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['SteamDemand']:addStreams{
    -- Thermal streams
    qt_steam_demand = qt({tin = 'T_ST_IN', hin = 0, tout='T_ST_OUT', hout='Q_ST', dtmin=0}),
}

return et