local osmose = require 'osmose'
local et = osmose.Model 'DieselBurner'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    TIN = {default=900, unit='C'},
    TOUT = {default=200, unit='C'},
    QMAX = {default=10000, unit='kW'},
    -- Efficiency
    EFF = {default=0.9, unit=nil},
    -- Capital costs
    INV_FIX = {default=0, unit='CHF' },
    INV_VAR = {default=0, unit='CHF/kW' },
}

-----------
-- Calculated parameters
-----------

et.outputs = {

    -- Fuel consumption
    GAS_IN_MAX = {unit='kW',job='QMAX/EFF'},
    -- Investment costs
    INV_FIX = {unit='CHF',job='INV_FIX'},
    INV_VAR = {unit='CHF',job='INV_VAR*QMAX'}
    
}

-----------
-- Layers
-----------

et:addLayers {Fuel = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('DieselBurner',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='INV_FIX', Cinv2='INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['DieselBurner']:addStreams{
    -- Output heat
    qt_hot = qt({tin = 'TIN', hin = 'QMAX', tout='TOUT', hout=0, stype='gas'}),
    -- Fuel consumption
    gas_in = rs({'Fuel', 'in', 'GAS_IN_MAX'})
}

return et