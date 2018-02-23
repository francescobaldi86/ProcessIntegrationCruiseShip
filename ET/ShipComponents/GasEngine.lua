local osmose = require 'osmose'
local et = osmose.Model 'GasEngineMech'

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
    -- Heat demand
    T_FUEL_IN = {default=70, unit='°C'},
    T_FUEL_OUT = {default=150, unit='°C'},
    CP_FUEL = {default=1.8, unit='kW/kg/K'},
    FUEL_LHV = {default=40500, unit='kJ/kg'},
    -- Power output
    PMAX = {default=8000, unit='kW'},
    -- Efficiency
    EFF_JW = {default=0.1, unit='-'},
    EFF_LO = {default=0.05, unit='-'},
    EFF_CA = {default=0.05, unit='-'},
    EFF_EL = {default=0.5, unit='-'},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
    -- Capital costs
    INV_FIX = {default=0, unit='CHF'},
    INV_VAR = {default=0, unit='CHF/kW'},
    AF = {default=0.08, unit='-' },
    -- Other
    OP_TIME = {default=8760, unit='h'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    FUEL_IN_MAX = {unit='kW',job='PMAX/EFF_EL'},
    -- Cooling needs
    Q_JW_MAX = {unit='kW',job='PMAX/EFF_EL*EFF_JW'}, --Cylinder cooling
    Q_LO_MAX = {unit='kW',job='PMAX/EFF_EL*EFF_LO'}, --Lubricating oil cooling
    Q_CA_MAX = {unit='kW',job='PMAX/EFF_EL*EFF_CA'}, --Charge air cooling
    -- Heating need for the fuel
    Q_FUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
    -- Operating cost
    COST2 = {unit='CHF',job='PMAX*OP_COST*OP_TIME' },
    -- Investement costName
    INV_FIX_AN = {unit='CHF/yr',job='INV_FIX*AF'},
    INV_VAR_AN = {unit='CHF/kW/yr',job='INV_VAR*AF*PMAX'}
}

-----------
-- Layers
-----------

et:addLayers {Gas = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('GasEngine',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='COST2', Cinv1='INV_FIX_AN', Cinv2='INV_VAR_AN', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['GasEngine']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'Q_JW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'Q_LO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'Q_CA_MAX', tout='T_CA_OUT', hout=0, dtmin=0}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='Q_FUEL_MAX', dtmin=0}),
    -- Fuel consumption
    gas_in = rs({'Gas', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

return et