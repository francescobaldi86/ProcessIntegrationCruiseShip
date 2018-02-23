local osmose = require 'osmose'
local et = osmose.Model 'Propeller'

----------
-- User parameters
----------

et.inputs = {
    -- Units consuming electricity
    P_PROP = {default=7680, unit='kW'},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
}

-----------
-- Layers
-----------

et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }


-----------
-- Units
-----------

et:addUnit('Propeller',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0, failprob=0.8, faillength={1,3}})
et['Propeller']:addStreams{
    -- Mechanical power stream
    power_prop = ms({'MechanicalPower', 'in', 'P_PROP'}),
}

return et