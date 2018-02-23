local osmose = require 'osmose'
local et = osmose.Model 'HeatDemandGen'

----------
-- User parameters
----------

et.inputs = {
    -- This if valid for the ship under study
    -- Hot water heating (HWH)
    Q_HD = {default=800, unit='kW'},
    T_HD_IN = {default=70, unit='C'},
    T_HD_OUT = {default=80, unit='C'}
}
-----------
-- Calculated parameters
-----------

et.outputs = {}

-----------
-- Layers
-----------


-----------
-- Units
-----------

et:addUnit('HeatDemand',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HeatDemand']:addStreams{
    -- Thermal streams
    qt_steam_demand = qt({tin = 'T_HD_IN', hin = 0, tout='T_HD_OUT', hout='Q_HD', stype='liquid'}),
}

return et