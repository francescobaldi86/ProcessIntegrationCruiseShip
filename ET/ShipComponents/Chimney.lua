local osmose = require 'osmose'
local et = osmose.Model 'Chimney'

----------
-- User parameters
----------

et.inputs = {
    -- Exhaust gas coming from the engine
    T_TC_OUT_M = {default=350, unit='C'},
    T_TC_OUT_L = {default=400, unit='C'},
    LOAD_SHIFT_LM = {default = 0.51, unit = '-'}, -- The shift load between the low load and high medium operations
    T_EG_OUT_MIN = {default=150, unit='C'},
    -- Environment
    COOL_TIN = {default=25, unit='°C'},  -- Environmental temperature
    COOL_TOUT = {default=25, unit='°C'},  -- Same as above
    COOL_QMAX = {default=200000, unit='kW'}, -- Very high value, the environment can basically absorb as much heat as possible
    -- Heat recovery boiler, if present
    QMAX = {default=0, unit='kW'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
  
}

------------
-- Equations
------------
--Add equations
et:addEquations {
eq_112 = { statement = string.format("subject to %s {p in Periods, t in TimesOfPeriod[p]}: \n\t Units_Use_t[%s,p,t] + Units_Use_t[%s,p,t] <= 1;",'ChimneyMultiUnit_neq','ChimneyL','ChimneyM'), param = {}, addToProblem=1, type ='ampl' },
}

-----------
-- Layers
-----------

et:addLayers {ExhaustGas = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------
-- The main scope of the unit "chimney" is basically to convert the mass flow to a qt
et:addUnit('ChimneyM',{type='Utility', Fmin = 0, Fmax = 'LOAD_SHIFT_LM', Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ChimneyM']:addStreams{
    -- Exhaust gas
    exhaust_gas = rs({'ExhaustGas','in','COOL_QMAX'}),
    -- Heat
    qt = qt({tin = 'T_TC_OUT_M', hin = 'COOL_QMAX', tout='T_EG_OUT_MIN', hout=0, dtmin=0})
}
et:addUnit('ChimneyL',{type='Utility', Fmin = 'LOAD_SHIFT_LM', Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ChimneyL']:addStreams{
    -- Exhaust gas
    exhaust_gas = rs({'ExhaustGas','in','COOL_QMAX'}),
    -- Heat
    qt = qt({tin = 'T_TC_OUT_L', hin = 'COOL_QMAX', tout='T_EG_OUT_MIN', hout=0, dtmin=0})
}

et:addUnit('Environment',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['Environment']:addStreams{
    -- Heat
    qt = qt({tin = 'COOL_TIN', hin = 0, tout='COOL_TOUT', hout='COOL_QMAX', dtmin=0})
}

return et