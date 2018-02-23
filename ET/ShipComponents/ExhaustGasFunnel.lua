local osmose = require 'osmose'
local et = osmose.Model 'ExhaustGasFunnel'

----------
-- User parameters
----------

et.inputs = {
    -- Maximum power
    QMAX_IN = {default=10000 , unit={'kW'}}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Electricity consumption
    QMAX_OUT = {unit='kW',job='QMAX_IN'}
}

-----------
-- Layers
-----------

et:addLayers {ExhaustGas = {type= 'MassBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ExhaustGasInlet',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ExhaustGasInlet']:addStreams{
    -- Mechanical power input
    funnel_in = ms({'ExhaustGas', 'in', 'QMAX_IN'})
}
et:addUnit('ExhaustGasOutlet',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ExhaustGasOutlet']:addStreams{
    -- Mechanical power output
    funnel_out = ms({'ExhaustGas', 'out', 'QMAX_OUT'})
}

return et