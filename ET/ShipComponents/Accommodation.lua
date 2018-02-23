local osmose = require 'osmose'
local et = osmose.Model 'Accommodation'

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
    -- Heat exchangers
    AC_TIN = {default=60, unit='°C'},
    AC_TOUT = {default=80, unit='°C'},
    AC_DH_REF = {default=200, unit='kW'},
    T_REF = {default=4, unit='°C'},
    T_OUT = {default=25, unit='°C'},
    T_IN = {default=20, unit='°C'},
    AC_DH_MIN = {default=50,unit='°C'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
  AC_DH = {unit='kW', job=
   function()
     if T_OUT < T_IN then
      output = AC_DH_MIN + (AC_DH_REF-AC_DH_MIN)*(T_IN-T_OUT)(T_IN-T_REF) 
    else
      output = AC_DH_MIN
    end
    return output
  end
}}

-----------
-- Layers
-----------


-----------
-- Units
-----------

et:addUnit('AirConditioning',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['AirConditioning']:addStreams{
    -- Thermal streams
    qt_AC = qt({tin = 'AC_TIN', hin = 0, tout='AC_TOUT', hout='AC_DH', dtmin=0}),
}

return et