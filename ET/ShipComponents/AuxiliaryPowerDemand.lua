local osmose = require 'osmose'
local et = osmose.Model 'AuxiliaryPowerDemand'

----------
-- User parameters
----------

et.inputs = {
    -- Units consuming electricity
    GEN_P_EL = {default=400, unit='kW'}, -- General comsumption
    CARGO_PUMPS_P_EL = {default=0, unit='kW'}, -- Cargo Pumps
    BALLAST_P_EL = {default=0, unit='kW'} -- Ballast water pumps
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Total electricity supply
    P_EL_TOT = {unit='kW',job='GEN_P_EL+CARGO_PUMPS_P_EL+BALLAST_P_EL'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }


-----------
-- Units
-----------

et:addUnit('AuxiliaryPowerDemand',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0, failprob=0.8, faillength={1,3}})
et['AuxiliaryPowerDemand']:addStreams{
    -- Electricity stream
    aux_elec_tot = rs({'Electricity', 'in', 'P_EL_TOT'}),
}

return et