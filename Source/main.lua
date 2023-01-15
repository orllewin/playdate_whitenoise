import 'CoreLibs/animator'
import 'CoreLibs/graphics'
import 'Coracle/math'

local animator = playdate.graphics.animator

local MODE_CONSTANT, MODE_AUTOMATIC = 0, 1
local mode = MODE_AUTOMATIC

local sound  = playdate.sound
local synthFilterResonance = 0.1
local synthFilterFrequency = 220
local minFreq = 45
local maxFreq = 1200
local synth = sound.synth.new(playdate.sound.kWaveNoise)
local filter = sound.twopolefilter.new("lowpass")

local toastPending = false
local toastMessage = ""
local toastDisplayMS = 1000

-- automatic mode, limit freq range to something that won't disturb someone trying to fall asleep:
local waveAnimator = animator.new(30000, map(1, 0, 10, minFreq, maxFreq), map(4, 0, 10, minFreq, maxFreq), playdate.easingFunctions.outInSine)
waveAnimator.reverses = true
waveAnimator.repeatCount = -1

filter:setResonance(synthFilterResonance)
filter:setFrequency(synthFilterFrequency)
sound.addEffect(filter)
synth:setVolume(1.0)
synth:playNote(330)

playdate.display.setInverted(true)
playdate.display.setRefreshRate(12)

--Waveform
local y = 120
local a = 100.0
local w = 0.02
local redraw = true

function playdate.update()
	
	if(mode == MODE_AUTOMATIC)then
		synthFilterFrequency = waveAnimator:currentValue()
		filter:setFrequency(synthFilterFrequency)
		clear()
	else
		
		local change, acceleratedChange = playdate.getCrankChange()
		
		if(change > 0)then
			clear()
			synthFilterFrequency +=5
			synthFilterFrequency = math.min(synthFilterFrequency, maxFreq)
			filter:setFrequency(synthFilterFrequency)
		elseif(change < 0)then
			clear()
			synthFilterFrequency -=5
			synthFilterFrequency = math.max(synthFilterFrequency, minFreq)
			filter:setFrequency(synthFilterFrequency)
		end
	end
	
	if(redraw)then
		playdate.graphics.drawSineWave(15, 120, 385, 120, 55, 55, maxFreq/(synthFilterFrequency/20))
		playdate.graphics.drawText("Frequency: ".. math.floor(synthFilterFrequency), 3, 220)
		redraw = false
	end
	
	if(toastPending)then
		playdate.graphics.drawText(toastMessage, 3, 3)
		playdate.wait(toastDisplayMS)
		clear()
		toastPending = false
	end
end

function clear()
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	playdate.graphics.fillRect(0,0,400,240)
	playdate.graphics.setColor(playdate.graphics.kColorBlack)
	redraw = true
end

-- Bummer: "playdate.wait() may not be called from an event handler"
function toast(message)
	toastMessage = message
	toastPending = true
end

function playdate.AButtonDown()
	if(mode == MODE_AUTOMATIC)then
		mode = MODE_CONSTANT
		toast("Manual mode - use crank")
	else
		mode = MODE_AUTOMATIC
		toast("Automatic mode")
	end
end