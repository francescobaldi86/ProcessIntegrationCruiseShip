local osmose = require 'osmose'
local et = osmose.Model 'HeatPump'

----------
-- User parameters
----------

et.inputs = {
    -- Evaporator
    EVAP_TIN = {default=50, unit='°C'},
    EVAP_TOUT = {default=50, unit='°C'},
    -- Condensor
    COND_TIN = {default=70, unit='°C'},
    COND_TOUT = {default=70, unit='°C'},
    COND_QMAX = {default=5000, unit='kW'},
    -- Performance
    COP = {default=3.5, unit='-' },
    -- Operating cost
    OP_COST = {default=0, unit='CHF/kWh' },
    -- Other
    OP_TIME = {default=8760, unit='h'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Electricity consumption
    EMAX = {unit='kW',job='COND_QMAX/COP' },
    -- Evaporator
    EVAP_QMAX = {unit='kW',job='COND_QMAX*(COP-1)/COP' },
    -- Operating cost
    COST2 = {unit='CHF',job='COND_QMAX*OP_COST*OP_TIME'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('HP',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='COST2', Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HP']:addStreams{
    -- Heat
    qt_evap = qt({tin = 'EVAP_TIN', hin = 0, tout='EVAP_TOUT', hout='EVAP_QMAX', dtmin=0}),
    qt_cond = qt({tin = 'COND_TIN', hin = 'COND_QMAX', tout='COND_TOUT', hout=0, dtmin=0}),
    -- Electricity consumption
    elec_in = rs({'Electricity', 'in', 'EMAX'})
}

return et