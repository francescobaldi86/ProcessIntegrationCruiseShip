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


-- Version 1.2 --> Differences from Version 1
-- The exhaust gas are considered as a heat flow
-- The efficiency of the engines is nonlinear



----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    T_JW = {default=100, unit='°C'},
    T_LO_IN = {default=60, unit='°C'},
    T_LO_OUT = {default=60, unit='°C'},
    T_CA_IN = {default=120, unit='°C'},
    T_CA_OUT = {default=40, unit='°C'},
    T_EG_IN = {default=350, unit='°C'}, -- For 8M32C values are: load [0.5, 0.85, 1], T_EG [390, 335, 330]
    T_EG_OUT = {default=150, unit='°C'}, -- Outlet temperature is limited to 150 degC to avoid sulphuric acid condensation in the exhaust funnel
    -- Heat demand
    T_FUEL_IN = {default=70, unit='°C'},
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
    -- Fuel flow nonlinear coefficients
    MFR_A0 = {default=0.05227, unit='-'},
    MFR_A1 = {default=0.9308, unit='-'},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
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
    FUEL_IN_MAX = {unit='kW',job='PMAX/EFF_EL'},
    -- Cooling needs
    QJW_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_JW_DES'}, --Cylinder cooling
    QLO_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_LO_DES'}, --Lubricating oil cooling
    QCA_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_CA_DES'}, --Charge air cooling
    QEG_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_EG_DES'}, --Exhaust gas. Note that we have to update the fact that we only can cool down to 160
    -- Heating need for the fuel
    QFUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
    -- Operating cost
    COST2 = {unit='CHF',job='PMAX*OP_COST*OP_TIME' },
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

et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }
et:addLayers {ExhaustGas = {type= 'ResourceBalance', unit = 'kW'}}

-----------
-- Units
-----------

et:addUnit('DieselEngine',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngine']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=0, stype='eva'}}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=0, stype='liq'}}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'QCA_MAX', tout='T_CA_OUT', hout=0, dtmin=0, stype='gas'}}),
    qt_engine_eg = qt({tin = 'T_EG_IN', hin = 'QEG_MAX', tout='T_EG_OUT', hout=0, dtmin=0, stype='gas'}}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=0, stype='liq'}}),
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX', a0='MFR_A0', a1='MFR_A1'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

return et