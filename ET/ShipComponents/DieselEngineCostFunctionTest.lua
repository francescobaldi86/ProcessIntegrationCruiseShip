local osmose = require 'osmose'
local et = osmose.Model 'DieselEngineMultiUnit'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'

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
    EFF_EL_DES = {default=0.445, unit='-'},
    -- Coefficients for linear scaling as a function of the Engine load
    LOAD_SHIFT = {default = 0.865, unit = '='}, -- The shift load between the low load and high load operations
    -- NOTE: All coefficient are normalized: they are all referred to the value at 100% load
    MFR_L_A0 = {default=0.05227, unit='-'},
    MFR_L_A1 = {default=0.9308, unit='-'},
    MFR_H_A0 = {default=-0.007844, unit='-'},
    MFR_H_A1 = {default=1.081, unit='-'},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
    -- Capital costs
    --INV_FIX = {default=100000, unit='CHF'},
    --INV_VAR = {default=250, unit='CHF/kW'},
    AF = {default=0.08, unit='-' },
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
    Q_JW_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_JW'}, --Cylinder cooling
    Q_LO_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_LO'}, --Lubricating oil cooling
    Q_CA_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_CA'}, --Charge air cooling
    -- Heating need for the fuel
    Q_FUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
    -- Operating cost
    COST2 = {unit='CHF',job='PMAX*OP_COST*OP_TIME' },
    -- Investement costName
    INV_FIX = {unit='CHF',job=
      function()
        x0 = PMAX
        cost_function = "cost_diesel_engine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0)
        output = temp.Cinv1
        return output
      end
    },
    INV_VAR = {unit='CHF',job=
      function()
        x0 = PMAX
        cost_function = "cost_diesel_engine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0)
        output = temp.Cinv2 * PMAX
        return output
      end
    },
    INV_FIX_AN = {unit='CHF/yr',job='INV_FIX()*AF'},
    INV_VAR_AN = {unit='CHF/kW/yr',job='INV_VAR()*AF'}
}

-----------
-- Layers
-----------
et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }

------------
-- Equations
------------
--Add equations
et:addEquations {
eq_1 = { statement = string.format("subject to %s {p in Periods, t in TimesOfPeriod[p]}: \n\t Units_Use_t[%s,p,t] + Units_Use_t[%s,p,t] <= 1;",'DieselEngineMultiUnit_neq','DieselEngineL', 'DieselEngineH'), param = {}, addToProblem=1, type ='ampl' },
eq_2 = { statement = string.format("subject to %s {p in Periods}: \n\t Units_Use[%s,p] - Units_Use[%s,p] = 0;",'DieselEngineMultiUnit_eq','DieselEngineL', 'DieselEngineH'), param = {}, addToProblem=1, type ='ampl' },
}

-----------
-- Units
-----------

et:addUnit('DieselEngineL',{type='Utility', Fmin = 0, Fmax = 'LOAD_SHIFT', Cost1=0, Cost2='COST2', Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineL']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'Q_JW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'Q_LO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'Q_CA_MAX', tout='T_CA_OUT', hout=0, dtmin=0}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='Q_FUEL_MAX', dtmin=0}),
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX', a0='MFR_L_A0', a1='MFR_L_A1'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}    
et:addUnit('DieselEngineH',{type='Utility', Fmin = 'LOAD_SHIFT', Fmax = 1, Cost1=0, Cost2=0, Cinv1='INV_FIX', Cinv2='INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngineH']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'Q_JW_MAX', tout='T_JW', hout=0, dtmin=0}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'Q_LO_MAX', tout='T_LO_OUT', hout=0, dtmin=0}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'Q_CA_MAX', tout='T_CA_OUT', hout=0, dtmin=0}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='Q_FUEL_MAX', dtmin=0}),
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX', a0='MFR_H_A0', a1='MFR_H_A1'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}
return et