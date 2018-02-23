local osmose = require 'osmose'
local general = require 'ProjectSpecific.Ship_01_MatlabIntegration.General' ()
local et = osmose.Model 'FuelTankHeating'

----------
-- User parameters
----------

et.inputs = {
    -- General data about the cargo holds. Assuming that only two different types of cargo that have to be heated are onboard. 
    T_STORAGE_TANK = {default=50, unit='°C'},
    T_SERVICE_TANK = {default=70, unit='°C'},
    T_SETTLING_TANK = {default=60, unit='°C'},
    T_OTHER_TANK = {default=40, unit='°C'},
    -- Some general approximation of the UA of the different fuel tanks
    --UA_DAY_TANK = {default=0.2, unit='kW/K'},
    --UA_SETTLING_TANK = {default=0.30, unit='kW/K'},
    --UA_STORAGE_TANK = {default=0.1, unit='kW/K'},
    
    -- Heat demand calculated based on the heat balance sheets
    QSTEAM_STORAGE_TANK = {default=442, unit='kg/h'}, --169.3+182.1+32.86+57.7, to be maintained at 50 degC
    QSTEAM_SERVICE_TANK = {default=20, unit='kg/h'}, --11.3+8.4, to be maintained at 70 degC
    QSTEAM_SETTLING_TANK = {default=17, unit='kg/h'}, --4257W+5271W, to be maintained at 60 degC
    QSTEAM_OTHER_TANK = {default=87, unit='kg/h'}, --23.2+7.2+5+5+11+9.1+23.2+3.5, to be maintained at 40 degC
    -- Temperature at which the heat losses are maximum. Average of 5 degC for water and 2 degC for air
    T_REF = {default=general.T_REF, unit='C'},
    T_OUT = {default=general.T_OUT, unit='C'} -- Actual ambient temperature
    --T_REF = {default=4, unit='C'},
    --T_OUT = {default=20, unit='C'},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Heat exchanger delta enthalpy
    DH_STORAGE = {unit='kW', job='QSTEAM_STORAGE_TANK*(T_STORAGE_TANK-T_OUT)/(T_STORAGE_TANK-T_REF)/3600*2031'},
    DH_SERVICE = {unit='kW', job='QSTEAM_SERVICE_TANK*(T_SERVICE_TANK-T_OUT)/(T_SERVICE_TANK-T_REF)/3600*2031'},
    DH_SETTLING = {unit='kW', job='QSTEAM_SETTLING_TANK*(T_SETTLING_TANK-T_OUT)/(T_SETTLING_TANK-T_REF)/3600*2031'},
    DH_OTHER = {unit='kW', job='QSTEAM_OTHER_TANK*(T_OTHER_TANK-T_OUT)/(T_OTHER_TANK-T_REF)/3600*2031'},
}

-----------
-- Layers
-----------


-----------
-- Units
-----------

et:addUnit('FuelTankHeating',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['FuelTankHeating']:addStreams{
    -- Thermal streams
    qt_fueltank_storage = qt({tin = 'T_STORAGE_TANK', hin = 0, tout='T_STORAGE_TANK', hout='DH_STORAGE', dtmin=0}),
    qt_fueltank_service = qt({tin = 'T_SERVICE_TANK', hin = 0, tout='T_SERVICE_TANK', hout='DH_SERVICE', dtmin=0}),
    qt_fueltank_settling = qt({tin = 'T_SETTLING_TANK', hin = 0, tout='T_SETTLING_TANK', hout='DH_SETTLING', dtmin=0}),
    qt_fueltank_other = qt({tin = 'T_OTHER_TANK', hin = 0, tout='T_OTHER_TANK', hout='DH_OTHER', dtmin=0})
}

return et