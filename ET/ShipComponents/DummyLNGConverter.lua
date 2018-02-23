local osmose = require 'osmose'
local et = osmose.Model 'DummyLNGConverter'

----------
-- User parameters
----------

et.inputs = {
  -- Gas flows
  MAX_CAPACITY = {default=100000, unit='kW'},
  LHV_GAS = {default=50000, unit='kJ/kg'},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    --Gas capacity in kW
}

-----------
-- Layers
-----------
et:addLayers {Gas = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Lng = {type= 'ResourceBalance', unit = 'kW'} }


-----------
-- Units
-----------

et:addUnit('CH4EvapProd',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['CH4EvapProd']:addStreams{
    -- Gas Stream
    gas_out = rs({'Gas', 'out', 'MAX_CAPACITY'})
}

et:addUnit('CH4EvapIntake',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['CH4EvapIntake']:addStreams{
    -- Gas Stream
    lng_in = rs({'Lng', 'in', 'MAX_CAPACITY'})
}
return et