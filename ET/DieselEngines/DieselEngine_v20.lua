local osmose = require 'osmose'
local et = osmose.Model 'DieselEngine'


----------
-- Model description
----------
-- This is the model of a Diesel engine. It includes the heat losses from
-- - Jacket water (cylinder) cooling
-- - Charge air cooling (see note below: the temperatures are assigned to vary with the engine load)
-- - Lubricating oil cooling
-- It requires heating for the fuel, from 70 to 150 degC (hence, we are burning HFO)
-- All the default values refer to the 8M32C engine from MaK maker (4000 kW design power, marine engine, 4-stroke)
-- The exhaust gas are considered as a resource flow, to prevent the problem of needing to cool them down

-- DIFFERENCES FROM v1:
-- The engine is split in THREE PARTS
-- - Low load
-- - Medium load
-- - High load
-- Each of the three is a different model. What varies are:
-- - The charge air temperature
-- Note that the new variable "load shift" is defined, that tells the maximum/minimum load of each of the "sub-engines". As an example, the sub-engine (M) can only operate between "LOAD_SHIFT_LM" (e.g. 0.4) and "LOAD_SHIFT_MH" (e.g. 0.8)



----------
-- User parameters
----------

et.inputs = {
    -- Temperatures: Heat supply
    -- Jacket water cooler
    T_JW = {default=100, unit='°C'},
    -- Lubricating oil cooler
    T_LO_IN = {default=80, unit='°C'},
    T_LO_OUT = {default=60, unit='°C'},
    -- Charge air cooler
    T_CA_IN_L = {default=90, unit='°C'},
    T_CA_OUT_L = {default=40, unit='°C'},
    T_CA_IN_M = {default=160, unit='°C'},
    T_CA_OUT_M = {default=50, unit='°C'},
    T_CA_IN_H = {default=210, unit='°C'},
    T_CA_OUT_H = {default=50, unit='°C'},
    -- Heat demand
    T_FUEL_IN = {default=50, unit='°C'},
    T_FUEL_OUT = {default=150, unit='°C'},
    CP_FUEL = {default=1.8, unit='kW/kg/K'},
    FUEL_LHV = {default=40500, unit='kJ/kg'},
    -- Power output
    PMAX = {default=8000, unit='kW'},
    -- Efficiency
    EFF_JW_DES = {default=0.086, unit='-'},
    EFF_LO_DES = {default=0.058, unit='-'},
    EFF_CA_DES = {default=0.143, unit='-'},
    EFF_EG_DES = {default=0.268, unit='-'},
    EFF_EL_DES = {default=0.445, unit='-'},
    -- Coefficients for linear scaling as a function of the Engine load
    LOAD_SHIFT_MH = {default = 0.871, unit = '-'}, -- The shift load between the medium load and high load operations
    LOAD_SHIFT_LM = {default = 0.51, unit = '-'}, -- The shift load between the low load and high medium operations
    -- NOTE: All coefficient are normalized: they are all referred to the value at 100% load
    -- Fuel flow
    MFR_L_A0 = {default=0.05227, unit='-'},
    MFR_L_A1 = {default=0.9308, unit='-'},
    MFR_H_A0 = {default=-0.007844, unit='-'},
    MFR_H_A1 = {default=1.081, unit='-'},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
    -- Capital costs
    INV_FIX = {default=0, unit='CHF'},
    INV_VAR = {default=0, unit='CHF/kW'},
    AF = {default=0.08, unit='-' },
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    FUEL_IN_MAX = {unit='kW',job='PMAX/EFF_EL_DES'},
    -- Cooling needs
    QJW_MAX = {unit='kW',job='FUEL_IN_MAX()*EFF_JW_DES'}, --Cylinder cooling
    QLO_MAX = {unit='kW',job='FUEL_IN_MAX()*EFF_LO_DES'}, --Lubricating oil cooling
    QCA_MAX = {unit='kW',job='FUEL_IN_MAX()*EFF_CA_DES'}, --Charge air cooling
    QEG_MAX = {unit='kW',job='FUEL_IN_MAX()*EFF_EG_DES'}, -- Exhaust gas
    -- Heating need for the fuel
    QFUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
    -- Operating cost
    COST2 = {unit='CHF',job='PMAX*OP_COST' },
    -- Investement costName        
    INV_FIX_AN = {unit='CHF/yr',job='INV_FIX*AF'},
    INV_VAR_AN = {unit='CHF/kW/yr',job='INV_VAR*AF*PMAX'}
}

-----------
-- Layers
-----------
et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }
et:addLayers {ExhaustGas = {type= 'ResourceBalance', unit = 'kW'}}

------------
-- Equations
------------
--Add equations
et:addEquations {
eq_1 = { statement = string.format("subject to %s {p in Periods, t in TimesOfPeriod[p]}: \n\t Units_Use_t[%s,p,t] + Units_Use_t[%s,p,t] + Units_Use_t[%s,p,t] <= 1;",'DieselEngineMultiUnit_neq','DieselEngineL','DieselEngineM','DieselEngineH'), param = {}, addToProblem=1, type ='ampl' },
}

-----------
-- Units
-----------

et:addUnit('DieselEngineL',{type='Utility', Fmin = 0.05, Fmax = 'LOAD_SHIFT_LM', Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineL']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN_L', hin = 'QCA_MAX', tout='T_CA_OUT_L', hout=0, dtmin=0}),
    -- Exhaust gas
    exhaust_eng = rs({'ExhaustGas', 'out' , 'QEG_MAX'}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=0}),
    -- Fuel consumption
    --fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}
et:addUnit('DieselEngineM',{type='Utility', Fmin = 'LOAD_SHIFT_LM', Fmax = 'LOAD_SHIFT_MH', Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineM']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN_M', hin = 'QCA_MAX', tout='T_CA_OUT_M', hout=0, dtmin=0}),
    -- Exhaust gas
    exhaust_eng = rs({'ExhaustGas', 'out' , 'QEG_MAX'}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=0}),
    -- Fuel consumption
    --fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}   
et:addUnit('DieselEngineH',{type='Utility', Fmin = 'LOAD_SHIFT_MH', Fmax = 1, Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineH']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN_H', hin = 'QCA_MAX', tout='T_CA_OUT_H', hout=0, dtmin=0}),
    -- Exhaust gas
    exhaust_eng = rs({'ExhaustGas', 'out' , 'QEG_MAX'}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=0}),
    -- Fuel consumption
    --fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}
return et