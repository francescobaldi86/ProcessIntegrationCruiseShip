local osmose = require 'osmose'
local general = require 'ProjectSpecific.Ship_01_MatlabIntegration.General' ()
local et = osmose.Model 'CargoCleaning'

----------
-- User parameters
----------

et.inputs = {
    -- General data about the cargo holds. Assuming that only two different types of cargo that have to be heated are onboard. 
    T_CLEANING = {default=85, unit='°C'},
    QSTEAM_REF = {default=16530, unit='kg/h'}, -- Value provided from the heat balance, in kg/h of steam at 14 bar
    -- Reference temperature for the calculation of the heat losses
    T_REF = {default=general.T_REF, unit='°C'}, --Reference temperature at which the maximum heat load is calculated
    T_OUT = {default=general.T_OUT, unit='C'}, -- Actual ambient temperature
    USAGE = {default=0, unit='-'} -- This variable is used to define the load of the cargo cleaning system is used or not. 1: used. 0: not used
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Heat exchanger delta enthalpy
    DH = {unit='kW', job='QSTEAM_REF*(T_CLEANING-T_OUT)/(T_CLEANING-T_REF)*USAGE/3600*2000'},
}

-----------
-- Layers
-----------


-----------
-- Units
-----------

et:addUnit('CargoTankCleaning',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['CargoTankCleaning']:addStreams{
    -- Thermal streams
    qt_cargo_cleaning = qt({tin = 'T_OUT', hin = 0, tout='T_CLEANING', hout='DH', dtmin=0}),
}

------------
-- Equations
------------
--et:addEquations {eq1 = { statement = "subject to constraint_cargo_cleaning{p in Periods, t in TimesOfPeriod[p]}: \n\t Units_Use_t[CargoTankCleaning, p, t] = cargo_tank_cleaning_use[t];", param = {}, addToProblem = 1, type ='ampl' } }
--et:addParameters {
--cargo_tank_cleaning_use = {indexedOver = {'Time'}}
--}
--et:addParameterData{
--cargo_tank_cleaning_use= {value = 'USED', indexedOver = {'Time'}}
--}


return et