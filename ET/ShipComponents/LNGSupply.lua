local osmose = require 'osmose'
local et = osmose.Model 'LNGSupply'

----------
-- User parameters
----------

et.inputs = {
    -- Energy prices
    GAS_PRICE_BUY = {default=0.5, unit='CHF/kg'},
    -- CO2 emissions
    GAS_CO2 = {default=0.206, unit='kgCO2/kWh'}, --Calculated starting from the given value for CH4 (0.206 kgCO2/kWh) scaled based on Selma's thesis (HFO: 77 gCO2/MJ, LNG: 54 gCO2/MJ)  CAREFUL IT IS WRONG!
    -- Network capacity
    MAX_INTAKE = {default=100000, unit='kW'},
    -- Other
    OP_TIME = {default=8760, unit='h'},
    GAS_LHV = {default=50000, unit='kJ/kg'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    GAS_IMP_COST2 = {unit='CHF',job='OP_TIME*GAS_PRICE_BUY*MAX_INTAKE'},
    GAS_IMP_IMPACT = {unit='CHF',job='OP_TIME*GAS_CO2*MAX_INTAKE'}
}

-----------
-- Layers
-----------

et:addLayers {Lng = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

-- Gas
et:addUnit('LNG_Supply',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='GAS_IMP_COST2', Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2='GAS_IMP_IMPACT'})
et['LNG_Supply']:addStreams{
    lng_out = rs({'Lng', 'out', 'MAX_INTAKE'})
}

return et