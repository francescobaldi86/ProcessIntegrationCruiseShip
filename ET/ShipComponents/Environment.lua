local osmose = require 'osmose'
local et = osmose.Model 'Environment'

----------
-- User parameters
----------

et.inputs = {
    Q_MAX = {default = 100000, unit='kW'},
    SeaWater_T_IN = {default = 15, unit='C'},
    SeaWater_T_OUT = {default = 30, unit='C'},
    SeaWaterCoolingCost = {default = 0.001, unit='CHF/kW'},
    MASSF_MAX = {default = 100, unit='kg/s'},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
}

-----------
-- Layers
-----------

et:addLayers {SeaWater = {type= 'MassBalance', unit = 'kg/h'} }
et:addLayers {Air = {type= 'MassBalance', unit = 'kg/h'} }
et:addLayers {Fumes = {type= 'MassBalance', unit = 'kg/h'} }


-----------
-- Units
-----------

-- Hot & cold utilities
et:addUnit('env_seaWaterCooling',{type='Utility', Fmin = 0, Fmax = 1, Cost1 = 0, Cost2 = 0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['env_seaWaterCooling']:addStreams{
    qt_cold = qt({tin = 'SeaWater_T_IN', hin = 0, tout='SeaWater_T_OUT', hout='Q_MAX', dtmin=0})
}
-- Air intake
et:addUnit('env_Air',{type='Utility', Fmin = 0, Fmax = 1, Cost1 = 0, Cost2 = 0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['env_Air']:addStreams{
    air_in = ms({'Air', 'out', 'MASSF_MAX'})
}
-- Fumes waste
et:addUnit('env_Fumes',{type='Utility', Fmin = 0, Fmax = 1, Cost1 = 0, Cost2 = 0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['env_Fumes']:addStreams{
    fumes_out = ms({'Fumes', 'in', 'MASSF_MAX'})
}
-- Air intake and Fumes waste
et:addUnit('env_SeaWater',{type='Utility', Fmin = 0, Fmax = 1, Cost1 = 0, Cost2 = 0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['env_SeaWater']:addStreams{
    seawater_in = ms({'SeaWater', 'out', 'MASSF_MAX'})
}

return et