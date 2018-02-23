local osmose = require 'osmose'
local et = osmose.Model 'FreshWaterGenerator'

-- Refers to the need for heating the water up to around 60 degrees to have low-temperature water evaporation. 
-- Also needs cooling afterwards for condensation. 

-- V2: Differences with v1:
-- - The component is considered a utility
-- - The amount of water to be evaporated is the free variable, and is not calculated a priori
-- - 

----------
-- User parameters
----------

et.inputs = {
    -- Sizing factor
    WATER_IN = {default = 5, unit='kg/s'},
    -- Heat exchangers
    EX1_TIN = {default=15, unit='C'},
    EX1_TOUT = {default=61, unit='C'},
    EXEVA_T = {default=61, unit='C'},
    EXCOND_T = {default=59, unit='C'},
    EX2_TIN = {default=59, unit='C'},
    EX2_TOUT = {default=25, unit='C'},
    -- Units consuming electricity
    EFF_PUMP = {default=0.7, unit=nil},
    DP_PUMP = {default=80000, unit='Pa'},
    -- Water thermodynamic properties
    DH_EVA = {default = 2370, unit='kJ/kg'},
    WATER_CP = {default = 4.187, unit = 'kJ/kg/K'},
    WATER_DENS = {default = 1000, unit='kg/m^3'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Heat exchanger delta enthalpy
    EX_MCP = {unit='kW/K', job='WATER_CP*WATER_IN'},
    EX1_DH = {unit='kW',job='EX_MCP()*(EX1_TOUT-EX1_TIN)'},
    EX2_DH = {unit='kW',job='EX_MCP()*(EX2_TOUT-EX2_TIN)'},
    EXEVA_DH = {unit='kW',job='WATER_IN*DH_EVA'},
    -- Total electricity supply
    P_EL_TOT = {unit='W',job='DP_PUMP*WATER_IN/EFF_PUMP/WATER_DENS'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {SeaWater = {type= 'MassBalance', unit = 'kg/h'} }
et:addLayers {Water = {type= 'MassBalance', unit = 'kg/h'} }


-----------
-- Units
-----------

et:addUnit('PureWaterProd',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['PureWaterProd']:addStreams{
    -- Thermal streams
    fwg_qt_ex1 = qt({tin = 'EX1_TIN', hin = 0, tout='EX1_TOUT', hout='EX1_DH', dtmin=0}),
    fwg_qt_ex2 = qt({tin = 'EX2_TIN', hin = 0, tout='EX2_TOUT', hout='EX2_DH', dtmin=0}),
    fwg_qt_exeva = qt({tin = 'EXEVA_T', hin = 0, tout='EXEVA_T', hout='EXEVA_DH', dtmin=0}),
    fwg_qt_excond = qt({tin = 'EXCOND_T', hin = 'EXEVA_DH', tout='EXCOND_T', hout=0, dtmin=0}),   -- Electricity stream
    fwg_elec_tot = rs({'Electricity', 'in', 'P_EL_TOT'}),
    fwg_SeaWater_ms = ms({'SeaWater', 'in', 'WATER_IN'}),
    fwg_Water_ms = ms({'Water', 'out', 'WATER_IN'})
}

return et