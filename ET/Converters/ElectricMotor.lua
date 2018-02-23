local osmose = require 'osmose'
local et = osmose.Model 'ElectricMotor'

----------
-- User parameters
----------

et.inputs = {
    -- Shaft generator efficiency
    EFF = {default=0.95 , unit=nil},
    -- Maximum power
    PMAX_IN = {default=40000 , unit='kW'}
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
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ElectricMotor',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ElectricMotor']:addStreams{
    -- Mechanical power output
    sm_mech_out = ms({'MechanicalPower', 'out', 'PMAX_OUT'}),
    -- Electric power input
    sm_el_in = rs({'Electricity', 'in', 'PMAX_IN'})
}

return et