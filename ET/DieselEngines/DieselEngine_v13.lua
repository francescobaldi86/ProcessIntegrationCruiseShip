local osmose = require 'osmose'
local et = osmose.Model 'DieselEngine_v13'

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


-- Version 1.3 --> Differences from Version 1
-- The exhaust gas are considered as a heat flow
-- The efficiency of the engines is nonlinear
-- The efficiency related to the heat flows is also nonlinear
-- --- NOTE: Since the efficiency is nonlinear, the minimum load is fixed to 0.1



----------
-- User parameters
----------

et.inputs = {
    -- Size factor
    PMAX = {default=4200, unit='kW'},
  
    -- Heat supply
    T_JW = {default=100, unit='C'},
    T_LO_IN = {default=60, unit='C'},
    T_LO_OUT = {default=60, unit='C'},
    T_CA_IN = {default=120, unit='C'},
    T_CA_OUT = {default=40, unit='C'},
    T_EG_IN = {default=350, unit='C'}, -- For 8M32C values are: load [0.5, 0.85, 1], T_EG [390, 335, 330]
    T_EG_OUT = {default=150, unit='C'}, -- Outlet temperature is limited to 150 degC to avoid sulphuric acid condensation in the exhaust funnel
    -- Heat demand
    T_FUEL_IN = {default=70, unit='C'},
    T_FUEL_OUT = {default=150, unit='C'},
    CP_FUEL = {default=1.8, unit='kJ/kg/K'},
    FUEL_LHV = {default=40500, unit='kJ/kg'},
    
    -- Efficiency
    EFF_JW_DES = {default=0.086, unit=nil},
    EFF_LO_DES = {default=0.058, unit=nil},
    EFF_CA_DES = {default=0.143, unit=nil},
    EFF_EG_DES = {default=0.268, unit=nil},
    EFF_EL_DES = {default=0.445, unit=nil},
    -- Fuel flow nonlinear coefficients
    MFR_A0 = {default=0.05227, unit=nil},
    MFR_A1 = {default=0.9308, unit=nil},
    -- Exhaust gas heat flow
    QEG_A0 = {default=0.15, unit=nil},
    QEG_A1 = {default=0.787, unit=nil},
    -- Charge air cooling heat flow
    QCA_A0 = {default=-0.2, unit=nil},
    QCA_A1 = {default=1.0, unit=nil},
    -- Jacket water cooling heat flow
    QJW_A0 = {default=0.275, unit=nil},
    QJW_A1 = {default=0.9, unit=nil},
    -- Lubricating oil and Jacket water coolers
    QLO_A0 = {default=0.275, unit=nil},
    QLO_A1 = {default=0.9, unit=nil},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
    -- Capital costs
    INV_FIX = {default=0, unit='CHF'},
    INV_VAR = {default=0, unit='CHF/kW'},
    -- Other
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    FUEL_IN_MAX = {unit='kW',job='PMAX/EFF_EL_DES'},
    -- Cooling needs
    QJW_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_JW_DES'}, --Cylinder cooling
    QLO_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_LO_DES'}, --Lubricating oil cooling
    QCA_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_CA_DES'}, --Charge air cooling
    QEG_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_EG_DES*(T_EG_IN-T_EG_OUT)/(T_EG_IN-25)'}, --Exhaust gas. Note that we have to update the fact that we only can cool down to 160
    -- Heating need for the fuel
    QFUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
    -- Operating cost
    COST2 = {unit='CHF/h',job='PMAX*OP_COST'},
    -- Investement costName
    INV_FIX_AN = {unit='CHF',job='INV_FIX'},
    INV_VAR_AN = {unit='CHF',job='INV_VAR*PMAX'}
}

-----------
-- Layers
-----------

et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }
et:addLayers {ExhaustGasHeat = {type= 'HeatCascade', unit = 'kW'}}

-----------
-- Units
-----------

et:addUnit('DieselEngine',{type='Utility', Fmin = 0.05, Fmax = 0.9, Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngine']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=2, a0='QJW_A0', a1='QJW_A1'}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=2, a0='QLO_A0', a1='QLO_A1'}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'QCA_MAX', tout='T_CA_OUT', hout=0, dtmin=5, a0='QCA_A0', a1='QCA_A1'}),
    qt_engine_eg = qt({tin = 'T_EG_IN', hin = 'QEG_MAX', tout='T_EG_OUT', hout=0, dtmin=5, a0='QEG_A0', a1='QEG_A1'}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=2}),
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX', a0='MFR_A0', a1='MFR_A1'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

return et