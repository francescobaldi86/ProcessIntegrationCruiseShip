local osmose = require 'osmose'
local et = osmose.Model 'Chimney'

----------
-- User parameters
----------

et.inputs = {
    -- Exhaust gas coming from the engine
    T_TC_OUT = {default=350, unit='C'},
    T_EG_OUT_MIN = {default=150, unit='C'},
    -- Environment
    COOL_TIN = {default=25, unit='°C'},  -- Environmental temperature
    COOL_TOUT = {default=25, unit='°C'},  -- Same as above
    COOL_QMAX = {default=20000, unit='kW'}, -- Very high value, the environment can basically absorb as much heat as possible
    -- Heat recovery boiler, if present
    HRSG_PMAX = {default=15000, unit='kW'}
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

-----------
-- Layers
-----------

et:addLayers {ExhaustGas = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------
-- The main scope of the unit "chimney" is basically to convert the mass flow to a qt
et:addUnit('HRSG',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HRSG']:addStreams{
    -- Exhaust gas
    exhaust_gas = rs({'ExhaustGas','in','HRSG_PMAX'}),
    -- Heat
    qt = qt({tin = 'T_TC_OUT', hin = 'HRSG_PMAX', tout='T_EG_OUT_MIN', hout=0, stype='gas'})
}

et:addUnit('Chimney',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['Chimney']:addStreams{
    -- Exhaust gas
    exhaust_gas = rs({'ExhaustGas','in','COOL_QMAX'}),
}

return et