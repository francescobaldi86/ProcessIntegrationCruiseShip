local osmose = require 'osmose'
local et = osmose.Model 'FuelInput'

----------
-- User parameters
----------

et.inputs = {
    -- Energy prices
    FUEL_PRICE_BUY = {default=0.6, unit='CHF/kg'},
    -- Network capacity
    MAX_INTAKE = {default=100000, unit='kW'},
    FUEL_LHV = {default=40700, unit='kJ/kg'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    FUEL_IMP_COST2 = {unit='CHF/s',job='FUEL_PRICE_BUY*MAX_INTAKE/FUEL_LHV'},
}

-----------
-- Layers
-----------

et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

-- Gas
et:addUnit('Fuel_Supply',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='FUEL_IMP_COST2', Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['Fuel_Supply']:addStreams{
    fuel_out = rs({'Fuel', 'out', 'MAX_INTAKE'})
}

return et