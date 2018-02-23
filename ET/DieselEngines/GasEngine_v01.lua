local osmose = require 'osmose'
local et = osmose.Model 'GasEngine'

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


-- Version 1.2 --> Differences from Version 1
-- The exhaust gas are considered as a heat flow
-- The efficiency of the engines is nonlinear



----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    T_HT_IN = {default=90, unit='C'},
    T_HT_OUT = {default=85, unit='C'},
    T_LT_IN = {default=50, unit='C'},
    T_LT_OUT = {default=40, unit='C'},
    T_EG_IN = {default=350, unit='C'}, -- For 8M32C values are: load [0.5, 0.85, 1], T_EG [390, 335, 330]
    T_EG_OUT = {default=150, unit='C'}, -- Outlet temperature is limited to 150 degC to avoid sulphuric acid condensation in the exhaust funnel
    -- Heat demand
    -- Power output
    PMAX = {default=35000, unit='kW'},
    -- Efficiency
    EFF_JW_DES = {default=0.086, unit=nil},
    EFF_LO_DES = {default=0.058, unit=nil},
    EFF_CA_DES = {default=0.143, unit=nil},
    EFF_EG_DES = {default=0.20, unit=nil},
    EFF_EL_DES = {default=0.445, unit=nil},
    -- Fuel flow nonlinear coefficients
    MFR_A0 = {default=0.05227, unit=nil},
    MFR_A1 = {default=0.9308, unit=nil},
    -- Operating cost
    OP_COST = {default=0, unit='Dollar/kWh'},
    -- Capital costs
    c_inv_fix = {default=0, unit='Dollar'},
    c_inv_var = {default=700, unit='Dollar/kW'},
    LIFETIME = {default=20, unit=nil},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    FUEL_IN_MAX = {unit='kW',job='PMAX/EFF_EL_DES'},
    -- Cooling needs
    QHT_MAX = {unit='kW',job='PMAX/EFF_EL_DES*(EFF_JW_DES+EFF_CA_DES/3)'}, --Cylinder cooling
    QLT_MAX = {unit='kW',job='PMAX/EFF_EL_DES*(EFF_LO_DES+EFF_CA_DES*2/3)'}, --Lubricating oil cooling
    QEG_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_EG_DES'}, --Lubricating oil cooling
    -- Operating cost
    COST2 = {unit='Dollar/h',job='PMAX*OP_COST' },
    -- Investement costName
    ANNUALIZATION_FACTOR = {unit=nil, job = '((1+InterestRate)^LIFETIME - 1) / (InterestRate*(1+InterestRate)^LIFETIME)'},
  C_INV_VAR = {unit='Dollar', job='c_inv_var * PMAX / ANNUALIZATION_FACTOR()'},
  C_INV_FIX = {unit='Dollar', job='c_inv_fix / ANNUALIZATION_FACTOR()'},
  --C_INV_VAR = {unit='Dollar', job='c_inv_var * PMAX'},
  --C_INV_FIX = {unit='Dollar', job='c_inv_fix'},
}

-----------
-- Layers
-----------

et:addLayers {NG = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }
et:addLayers {ExhaustGas = {type= 'ResourceBalance', unit = 'kW'}}

-----------
-- Units
-----------

et:addUnit('GasEngine',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='COST2', Cinv1='C_INV_FIX', Cinv2='C_INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['GasEngine']:addStreams{
    -- Output heat
    qt_engine_ht = qt({tin = 'T_HT_IN', hin = 'QHT_MAX', tout='T_HT_OUT', hout=0, stype='liquid'}),
    qt_engine_lt = qt({tin = 'T_LT_IN', hin = 'QLT_MAX', tout='T_LT_OUT', hout=0, stype='liquid'}),
    qt_engine_eg = qt({tin = 'T_EG_IN', hin = 'QEG_MAX', tout='T_EG_OUT', hout=0, stype='gas'}),
    -- Input heat
    -- Fuel consumption
    fuel_in = rs({'NG', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

return et