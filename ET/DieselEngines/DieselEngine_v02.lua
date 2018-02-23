local osmose = require 'osmose'
local et = osmose.Model 'DieselEngine'

----------
-- Model description
----------
-- This is the model of a Diesel engine. It includes the heat losses from
-- - Jacket water (cylinder) cooling
-- - Charge air cooling (note: this temperature varies between 60 and 210 degrees with the engine load. Here it is fixed at an arbitrary average of 120 degC)
-- - Lubricating oil cooling
-- It requires heating for the fuel, from 70 to 150 degC (hence, we are burning HFO)
-- All the default values refer to the 8M32C engine from MaK maker (4000 kW design power, marine engine, 4-stroke)
-- Efficiencies for all heat/fuel flows are constant




----------
-- User parameters
----------

et.inputs = {
    -- Power output
    PMAX = {default=1864.5, unit='kW'},
    -- Efficiency
    EFF_EL_DES = {default=0.445, unit=nil},
    -- Load limitations
    LOAD_MIN = {default=0.1, unit=nil},
    LOAD_SWITCH = {default=0.8, unit=nil},
    LOAD_MAX = {default=1, unit=nil},
    -- Fuel flow nonlinear coefficients
    MFR_A0 = {default=0.05227, unit=nil},
    MFR_A1 = {default=0.9308, unit=nil},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
    -- Capital costs
    INV_FIX = {default=0, unit='CHF'},
    INV_VAR = {default=0, unit='CHF/kW'},
    AF = {default=0.00, unit='1/yr'},
    -- Other
    OP_TIME = {default=8760, unit='h'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    FUEL_IN_MAX = {unit='kW',job='PMAX/EFF_EL_DES'},
    -- Operating cost
    COST2 = {unit='CHF',job='PMAX*OP_COST*OP_TIME' },
    -- Investement costName
    INV_FIX_AN = {unit='CHF/yr',job='INV_FIX*AF'},
    INV_VAR_AN = {unit='CHF/yr',job='INV_VAR*AF*PMAX'}
}

-----------
-- Layers
-----------

et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('DieselEngineL',{type='Utility', Fmin = 'LOAD_MIN', Fmax = 'LOAD_SWITCH', Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineL']:addStreams{
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

et:addUnit('DieselEngineH',{type='Utility', Fmin = 'LOAD_SWITCH', Fmax = 'LOAD_MAX', Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineH']:addStreams{
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

------------
-- Equations
------------
--Add equations
et:addEquations {
eq_1 = { statement = string.format("subject to %s {p in Periods, t in TimesOfPeriod[p]}: \n\t Units_Use_t[%s,p,t] + Units_Use_t[%s,p,t] <= 1;",'DieselEngineMultiUnit_neq','DieselEngineL','DieselEngineH'), param = {}, addToProblem=1, type ='ampl' },
}

return et