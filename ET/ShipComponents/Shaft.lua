local osmose = require 'osmose'
local et = osmose.Model 'Shaft'

----------
-- User parameters
----------

et.inputs = {
    -- Shaft efficiency
    EFF = {default=0.99 , unit={'-'}},
    -- Maximum power
    PMAX_IN = {default=10000 , unit={'kW'}}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Electricity consumption
    PMAX_OUT = {unit='kW',job='EFF*PMAX_IN'}
}

-----------
-- Layers
-----------

et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }
et:addLayers {ShaftPower = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ShaftInput',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ShaftInput']:addStreams{
    -- Mechanical power input
    mech_in = ms({'MechanicalPower', 'in', 'PMAX_IN'}),
    shaft_out = rs({'ShaftPower', 'out', 'PMAX_OUT'})
}
et:addUnit('ShaftOutput',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ShaftOutput']:addStreams{
    -- Mechanical power output
    shaft_in = rs({'ShaftPower', 'in', 'PMAX_IN'}),
    mech_out = ms({'MechanicalPower', 'out', 'PMAX_OUT'})
}

return et