local osmose = require 'osmose'
local et = osmose.Model 'CoolingExhaust'

----------
-- Description
----------

-- This component is made for the cooling of the engine exhaust gas. The idea is simply that since it only cools at a quite high temperature, it will not be used by any other thing that demands cooling. 
-- Moreover, it is also realistic (at least for HFO), since it is indeed true that it is not possible to use heat from the exhaust gas at a temperature below 150 degC
-- NOTE: One should anyway be careful with the Charge air cooling
-- NOTE2: With gas engines, everything becomes more complicated, since in theory the exhaust gas CAN be cooled down further. 

----------
-- User parameters
----------

et.inputs = {
    -- Heat
    COOL_TIN = {default=140, unit='°C'},
    COOL_TOUT = {default=150, unit='°C'},
    COOL_QMAX = {default=50000, unit='kW'},
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh' },
    -- Capital costs
    INV_FIX = {default=0, unit='CHF' },
    INV_VAR = {default=0, unit='CHF/kW' },
    AF = {default=0.08, unit='-' },
}

-----------
-- Calculated parameters
-----------

et.outputs = {
}

-----------
-- Layers
-----------

-----------
-- Units
-----------

et:addUnit('SeaWaterCooler',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['SeaWaterCooler']:addStreams{
    -- Heat
    qt = qt({tin = 'COOL_TIN', hin = 0, tout='COOL_TOUT', hout='COOL_QMAX', dtmin=0, alpha = 0.5}),
}

return et