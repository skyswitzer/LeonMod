--[[###############################################################
# Informations # ================================================	#
#																						#
# Author:			Black.Cobra a.k.a. Logharn								#
# Creation Date:	23/01/2014				 									#
#																						#
# Description:								 										#
# In this file you can customize the color of highlighted plots,  #
# you MUST only change the numeric values and NOT the constant    #
# names.                                                          #
# To customize the colors just follow the RGB model, plus add the #
# alpha value (forth value), where a value of 255 means SOLID and #
# 0 FULLY TRANSPARENT.                                            #
# 																						#
# Notes:																				#
# None                                                            #
# 																						#
# ===============================================================	#
###############################################################--]]

-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                              COLORS                               |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->

-- SOLID WHITE PLOTS -- Discarded Plots
CupWhite_R, CupWhite_G, CupWhite_B, CupWhite_A = 255, 255, 255, 255

-- ALPHA WHITE PLOTS -- Destination Plots without focus during CTRL + SHIFT
CupWhiteA_R, CupWhiteA_G, CupWhiteA_B, CupWhiteA_A = 255, 255, 255, 208

-- SOLID CYAN PLOTS -- Predicted Path Plots
CupCyan_R, CupCyan_G, CupCyan_B, CupCyan_A = 0, 200, 255, 255

-- SOLID RED PLOTS -- Destination Plot
CupRed_R, CupRed_G, CupRed_B, CupRed_A = 255, 0, 0, 255

-- SOLID ORANGE PLOTS -- Plot where Unit stand during CTRL + SHIFT
CupOrange_R, CupOrange_G, CupOrange_B, CupOrange_A = 255, 112, 0, 255

-- SOLID YELLOW PLOTS -- Path Starting Plot
CupYellow_R, CupYellow_G, CupYellow_B, CupYellow_A = 224, 255, 0, 255

-- SOLID GREEN PLOTS -- "Route To" Worker Last Plot
CupGreen_R, CupGreen_G, CupGreen_B, CupGreen_A = 0, 255, 0, 255

-- SOLID DARK GREEN PLOTS -- "Route To" Worker Predicted Path Plots (when using second method)
CupDarkGreen_R, CupDarkGreen_G, CupDarkGreen_B, CupDarkGreen_A = 0, 200, 0, 255

-- SOLID FUCHSIA PLOTS -- Common Destination Plot during CTRL + SHIFT
CupFuchsia_R, CupFuchsia_G, CupFuchsia_B, CupFuchsia_A = 255, 0, 255, 255