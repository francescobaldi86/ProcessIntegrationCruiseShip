local osmose = require 'osmose'
local et = osmose.Model 'DieselEngine'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'

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
---------- DIFFERENCES from v1.0
-- The exhaust gas are considered as a resource flow, to prevent the problem of needing to cool them down



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
    -- Heat demand
    T_FUEL_IN = {default=70, unit='C'},
    T_FUEL_OUT = {default=150, unit='C'},
    CP_FUEL = {default=1.8, unit='kJ/kg/K'},
    FUEL_LHV = {default=40500, unit='kJ/kg'},
    -- Power output
    PMAX = {default=6000, unit='kW'},
    -- Efficiency
    EFF_JW_DES = {default=0.086, unit=nil},
    EFF_LO_DES = {default=0.058, unit=nil},
    EFF_CA_DES = {default=0.143, unit=nil},
    EFF_EG_DES = {default=0.268, unit=nil},
    EFF_EL_DES = {default=0.445, unit=nil},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh'},
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
    QEG_MAX = {unit='kW',job='PMAX/EFF_EL_DES*EFF_EG_DES'}, --Exhaust gas
    -- Heating need for the fuel
    QFUEL_MAX = {unit='kW', job='FUEL_IN_MAX()/FUEL_LHV*CP_FUEL*(T_FUEL_OUT-T_FUEL_IN)'}, --Fuel heating from temperature in the tank to engine inlet
    -- Investment costs
    -- Calculating the investment cost.
    
    INV_FIX = {unit='CHF',job=
      function()
        x0_vector = {PMAX}
        cost_function = "cost_diesel_engine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv1
        return output
      end
    },
    INV_VAR = {unit='CHF',job=
      function()
        x0_vector = {PMAX} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_diesel_engine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv2
        return output
      end
    },
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

et:addUnit('DieselEngine',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='INV_FIX', Cinv2='INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselEngine']:addStreams{
    -- Output heat
    qt_engine_jw = qt({tin = 'T_JW', hin = 'QJW_MAX', tout='T_JW', hout=0, dtmin=0, stype='eva'}),
    qt_engine_lo = qt({tin = 'T_LO_IN', hin = 'QLO_MAX', tout='T_LO_OUT', hout=0, dtmin=0, stype='liquid'}),
    qt_engine_ca = qt({tin = 'T_CA_IN', hin = 'QCA_MAX', tout='T_CA_OUT', hout=0, dtmin=0, stype='gas'}),
    -- Exhaust gas
    exhaust_eng = rs({'ExhaustGas', 'out' , 'QEG_MAX'}),
    -- Input heat
    qt_engine_fuel = qt({tin = 'T_FUEL_IN', hin = 0, tout='T_FUEL_OUT', hout='QFUEL_MAX', dtmin=0, stype='liq'}),
    -- Fuel consumption
    fuel_in = rs({'Fuel', 'in', 'FUEL_IN_MAX'}),
    -- Mechanical power output
    engine_power_out = ms({'MechanicalPower', 'out', 'PMAX'})
}

return et