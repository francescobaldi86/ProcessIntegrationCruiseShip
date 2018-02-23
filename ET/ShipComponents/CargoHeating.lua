local osmose = require 'osmose'
local general = require 'ProjectSpecific.Ship_01_MatlabIntegration.General' ()
local et = osmose.Model 'CargoHeating'

----------
-- User parameters
----------

-- This model represents the whole ship demand of auxiliary heat
-- As a semplification, for the moment this will include:
-- 1. Fuel tank heating
-- 2. Cargo tanks heating
-- 3. Fresh water heating
-- 4. Other heating

et.inputs = {
    -- General data about the cargo holds. Assuming that only two different types of cargo that have to be heated are onboard. 
    NMAX_CARGO_HOLDS = {default=7, unit='-'}, -- Number of cargo holds per side
    T_REF_CARGO_HOLDS = {default=66, unit='°C'},
    -- Some general approximation of the UA of a generic cargo hold of type 1
    DHMAX = {default=1231, unit='kW'},--Sum of total heat need for starbord/port cargo holds: 167+119+209+209+209+137+181
    -- Reference temperature for the calculation of the heat losses
    T_REF = {default=general.T_REF, unit='°C'}, --Reference temperature at which the maximum heat load is calculated
    
    -- Actual data
    T_OUT = {default=general.T_OUT, unit='°C'}, --Actual outer temperature
    T1_CARGO_HOLDS = {default=60, unit='°C'},
    N1_CARGO_HOLDS = {default=1, unit='-'},
    T2_CARGO_HOLDS = {default=60, unit='°C'},
    N2_CARGO_HOLDS = {default=1, unit='-'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Heat exchanger delta enthalpy
    Q1_HEATING_TEMP = {unit='kW', job='DHMAX*N1_CARGO_HOLDS/NMAX_CARGO_HOLDS*(T1_CARGO_HOLDS-T_OUT)/(T_REF_CARGO_HOLDS-T_REF)'},
    Q1_HEATING = {unit='kW', job=
      function()
        if Q1_HEATING_TEMP() == 0 then
          temp = 0.1
        else
          temp = Q1_HEATING_TEMP()
        end
        return temp
      end},
    Q2_HEATING_TEMP = {unit='kW', job='DHMAX*N2_CARGO_HOLDS/NMAX_CARGO_HOLDS*(T2_CARGO_HOLDS-T_OUT)/(T_REF_CARGO_HOLDS-T_REF)'},
    Q2_HEATING = {unit='kW', job=
      function()
        if Q2_HEATING_TEMP() == 0 then
          temp = 0.1
        else
          temp = Q2_HEATING_TEMP()
        end
        return temp
      end},
    USED1 = {unit='-', job=
    function()
      if N1_CARGO_HOLDS == 0 then
        temp = 0
      else
        temp = 1
      end
      return temp
    end},
     USED2 = {unit='-', job=
    function()
      if N2_CARGO_HOLDS == 0 then
        temp = 0
      else
        temp = 1
      end
      return temp
    end}
}

-----------
-- Layers
-----------


-----------
-- Units
-----------

et:addUnit('CargoHold1',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0,addToProblem=1})
et['CargoHold1']:addStreams{
    -- Thermal streams
    qt_cargo_holds1 = qt({tin = 'T1_CARGO_HOLDS', hin = 0, tout='T1_CARGO_HOLDS', hout='Q1_HEATING', dtmin=0}),
}

et:addUnit('CargoHold2',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0,addToProblem=1})
et['CargoHold2']:addStreams{
    -- Thermal streams
    qt_cargo_holds2 = qt({tin = 'T2_CARGO_HOLDS', hin = 0, tout='T2_CARGO_HOLDS', hout='Q2_HEATING', dtmin=0}),
}

return et