local osmose = require 'osmose'
local et = osmose.Model 'DieselEngine'

----------
-- Model description
----------
-- This is the model of a Diesel engine. It includes the heat losses from
-- - Jacket water (cylinder) cooling
-- - Charge air cooling (note: this temperature varies between 60 and 210 degrees with the engine load. Here it is fixed at an arbitrary average of 120 degC)
-- - Lubricating oil cooling
-- - Exhaust gas
-- It requires heating for the fuel, from 70 to 150 degC (hence, we are burning HFO)
-- Note that the engine output is to the "MechanicalPower" layer, not to the "Electricity" layer
-- All the default values refer to the 8M32C engine from MaK maker (4000 kW design power, marine engine, 4-stroke)
-- Efficiencies for all heat/fuel flows are constant



----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    T_JW = {default=100, unit='C'},
    T_LO_IN = {default=80, unit='C'},
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
    -- Power output
    PMAX = {default=8000, unit='kW'},
    -- Efficiency
    EFF_JW_DES = {default=0.086, unit=nil},
    EFF_LO_DES = {default=0.058, unit=nil},
    EFF_CA_DES = {default=0.143, unit=nil},
    EFF_EG_DES = {default=0.268, unit=nil},
    EFF_EL_DES = {default=0.445, unit=nil},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
    -- Capital costs
    INV_FIX = {default=0, unit='CHF'},
    INV_VAR = {default=0, unit='CHF/kW'},
    AF = {default=0.08, unit='1/yr'},
    -- Other
    OP_TIME = {default=8760, unit='h'}
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
    QEG_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_EG_DES*(T_EG_IN-T_EG_OUT)/(T_EG_IN-298)'}, --Exhaust gas. Note that we have to update the fact that we only can cool down to 160
    -- Heating need for the fuel
    QFUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
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

et:addUnit('DieselEngine',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngine']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'QCA_MAX', tout='T_CA_OUT', hout=0, dtmin=0}),
    qt_engine_eg = qt({tin = 'T_EG_IN', hin = 'QEG_MAX', tout='T_EG_OUT', hout=0, dtmin=0}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=0}),
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

return et