local osmose = require 'osmose'
local et = osmose.Model 'SeaWaterCooling'

----------
-- User parameters
----------

et.inputs = {
    -- Heat
    T_SW_IN = {default=10, unit='C'},
    T_SW_OUT = {default=20, unit='C'},
    COOL_QMAX = {default=100000, unit='kW'},
    -- Electricity consumption
    COOL_ELEC = {default=0.00, unit=nil},
    -- Operating cost
    OP_COST = {default=0.1, unit='Dollar/kWh' },
    -- Capital costs
    INV_FIX = {default=0, unit='CHF' },
    INV_VAR = {default=0, unit='CHF/kW' },
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Electricity consumption
    EMAX = {unit='kW',job='COOL_ELEC*COOL_QMAX' },
    -- Operating cost
    COST2 = {unit='Dollar/h',job='COOL_QMAX*OP_COST'},
    -- Investment costs
    CINV1 = {unit='CHF', job='INV_FIX'},
    CINV2 = {unit='CHF', job='INV_VAR*COOL_QMAX'},
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('SeaWaterCooler',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='COST2', Cinv1='CINV1', Cinv2='CINV2', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['SeaWaterCooler']:addStreams{
    -- Heat
    qt = qt({tin = 'T_SW_IN', hin = 0, tout='T_SW_OUT', hout='COOL_QMAX', stype = 'liquid'}),
    -- Electricity consumption
    elec_in = rs({'Electricity', 'in', 'EMAX'})
}

return et