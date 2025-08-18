local CS = game:GetService("Chat")
local MS = game:GetService("MarketplaceService")
local Phones = script.Parent.Phones
local Settings = require(script.Parent.Settings)
local GroupId = Settings.GroupId
local MinRank = Settings.MinRank
local Parcel = require(9428572121)
local neptuneHub = require(82494717887252)
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Prefix = "neptunePhones || "

print(Prefix.. "Checking licence...")

if game.PlaceId == 0 then warn(Prefix.."Please publish the game first!") return end

local s, e = pcall(function()
	if Parcel:Whitelist("62d91b088d9869cb89c2472f", "a37kzdhalgqdojhrdc5o5ghgea1c") == true or neptuneHub:OwnsProduct(game.CreatorId,"966698810984239124","neptunePhones") == "true" then
		print(Prefix.. "Loading neptunePhones. Thanks for using our system!")
	else
		warn(Prefix.. "Did you purchase on BuiltByBit/our online store? Then please create a 'Billing' ticket here: https://discord.gg/YCnwUEynsq")
		warn(Prefix.. "Please purchase a valid licence in order to use this product!")
		script.Parent:Destroy()
	end
end)

if e then
	print(e)
	warn(Prefix.."An error occured while checking the licence! Did you enable HTTP Services?")

	return
end

for _, Tel in Phones:GetChildren() do
	if Tel:IsA("Model") then
		task.spawn(function()
			local TelNum = Tel:FindFirstChild("PhoneNumber")
			if TelNum then
				local LastNum
				TelNum = TelNum.Value
				Tel.Display.GUI.Home.Top.Number.Text = TelNum
				for _, Btn in Tel:WaitForChild("Numbers"):GetChildren() do
					local clickDetector = Btn:FindFirstChildWhichIsA("ClickDetector")
					if clickDetector then
						clickDetector.MouseClick:Connect(function(Plr)
							if GroupId > 0 then
								if Plr:GetRankInGroup(GroupId) < MinRank then
									return
								end
							end
							Tel.Phone.KeyPress:Play()
							Tel.Values.PlayerName.Value = Plr.Name
							if tonumber(Btn.Name) then
								Tel.Display.GUI.Home.Dial.Visible = true
								LastNum = Tel.Values.Dialing.Value
								local str = Tel.Values.Dialing.Value
								Tel.Values.Dialing.Value = str..tostring(Btn.Name)
								Tel.Display.GUI.Home.Dial.Number.Text = Tel.Values.Dialing.Value
							end
							if Btn.Name == "#" then
								local str = tostring(Tel.Values.Dialing.Value)
								if #str > 1 then
									Tel.Display.GUI.Home.Dial.Visible = true
									LastNum = tostring(str:sub(1, #str-1))
									Tel.Values.Dialing.Value = LastNum
									Tel.Display.GUI.Home.Dial.Number.Text = tostring(Tel.Values.Dialing.Value)
								else
									Tel.Display.GUI.Home.Dial.Number.Text = ""
									Tel.Values.Dialing.Value = ""
									Tel.Display.GUI.Home.Dial.Visible = false
								end
							end
							if Btn.Name == "PickUp" then
								if Tel.Values.Calling.Value == true then
									local Num = Tel.PhoneNumber.Value
									local DialingPhone = nil
									for _, Phone in Phones:GetChildren() do
										local s, e = pcall(function()
											if Phone:FindFirstChild("PhoneNumber") then
												if Phone.Values.ReceivingCall.Value == Num then
													DialingPhone = Phone
												end
												task.wait()
											end
										end)
									end
									if DialingPhone then
										DialingPhone.Display.GUI.Home.Dial.Visible = false
										DialingPhone.Phone.Ringtone.Playing = false
										Tel.Phone.Dial.Playing = false
										DialingPhone.Values.ReceivingCall.Value = "false"
										Tel.Display.GUI.Home.Dial.Visible = false
										Tel.Display.GUI.Home.Calling.Visible = false
										Tel.Display.GUI.Home.Calling.Number.Text = ""
										DialingPhone.Display.GUI.Home.Incoming.Visible = false
										DialingPhone.Display.GUI.Home.Incoming.Number.Text = ""
										DialingPhone.Display.GUI.Home.Incoming.Image.Blink.Value = false
										Tel.Display.GUI.Home.Calling.Image.Blink.Value = false
										DialingPhone.Values.Calling.Value = false
										CS:Chat(DialingPhone.ChatPart, "Call ended.")
										CS:Chat(Tel.ChatPart, "You ended the call.")
										Tel.Values.Dialing.Value = ""
										Tel.Display.GUI.Home.Dial.Number.Text = ""
									end
									Tel.Values.Calling.Value = false
								end
								if Tel.Phone.Error.Playing == true then
									Tel.Phone.Error.Playing = false
									Tel.Display.GUI.Home.Dial.Visible = false
									Tel.Values.Dialing.Value = ""
									Tel.Display.GUI.Home.Dial.Number.Text = ""
									Tel.Phone.HangUp:Play()
								end
								if tonumber(Tel.Values.CallingWith.Value) then
									local DialingPhone = nil
									for _, Phone in Phones:GetChildren() do
										local s, e = pcall(function()
											if Phone:FindFirstChild("PhoneNumber") then
												if tostring(Phone.PhoneNumber.Value) == Tel.Values.CallingWith.Value then
													DialingPhone = Phone
												end
												task.wait()
											end
										end)
									end
									if DialingPhone then
										Tel.Values.Dialing.Value = ""
										DialingPhone.Values.Dialing.Value = ""
										Tel.Values.CallingWith.Value = "false"
										DialingPhone.Values.CallingWith.Value = "false"
										Tel.Phone.End:Play()
										Tel.Phone.HangUp:Play()
										Tel.Display.GUI.Home.Calling.Number.Text = ""
										Tel.Display.GUI.Home.Calling.Visible = false
										DialingPhone.Display.GUI.Home.Calling.Number.Text = ""
										DialingPhone.Display.GUI.Home.Calling.Visible = false
										DialingPhone.Display.GUI.Home.Incoming.Number.Text = ""
										DialingPhone.Display.GUI.Home.Incoming.Visible = false
										CS:Chat(DialingPhone.ChatPart, "Call ended.")
										CS:Chat(Tel.ChatPart, "You ended the call.")
										Tel.Values.Calling.Value = false
										DialingPhone.Values.Calling.Value = false
									end
								else
									task.spawn(function()
										local DialingPhone = nil
										for _, Phone in Phones:GetChildren() do
											local s, e = pcall(function()
												if Phone:FindFirstChild("PhoneNumber") then
													if tostring(Phone.PhoneNumber.Value) == Tel.Values.ReceivingCall.Value then
														DialingPhone = Phone
													end
													task.wait()
												end
											end)
										end
										if DialingPhone then
											if tonumber(Tel.Values.ReceivingCall.Value) then
												repeat
													Tel.Phone.Ringtone:Stop()
													Tel.Phone.Ringtone.Playing = false
												until Tel.Phone.Ringtone.Playing == false
												repeat
													DialingPhone.Phone.Dial:Stop()
													DialingPhone.Phone.Dial.Playing = false
												until DialingPhone.Phone.Dial.Playing == false
												Tel.Values.CallingWith.Value = tostring(Tel.Values.ReceivingCall.Value)
												Tel.Values.ReceivingCall.Value = "false"
												DialingPhone.Values.CallingWith.Value = tostring(Tel.PhoneNumber.Value)
												Tel.Display.GUI.Home.Incoming.Image.Blink.Value = false
												DialingPhone.Display.GUI.Home.Calling.Image.Blink.Value = false
												Tel.Display.GUI.Home.Incoming.Visible = false
												Tel.Display.GUI.Home.Calling.Visible = true
												Tel.Display.GUI.Home.Calling.Number.Text = tostring(Tel.Values.CallingWith.Value)
												Tel.Values.Calling.Value = true
												DialingPhone.Values.Calling.Value = true
											end
										end
									end)
								end
							end
							if Btn.Name == "DnD" then
								Tel.Values.DnD.Value = not Tel.Values.DnD.Value
								Tel.Display.GUI.Home.DnD.Visible = Tel.Values.DnD.Value
							end
							if Btn.Name == "Cam" then
								game.ReplicatedStorage.NeptunePhoneChangeCamera:FireClient(Plr, Tel.CamPart)
							end
							if Btn.Name == "Call" then
								if Tel.Values.Calling.Value == true then return end
								task.spawn(function()
									local Num = Tel.Values.Dialing.Value
									local DialingPhone = nil
									if Num == TelNum then
										Tel.Values.Dialing.Value = ""
										return
									end
									for _, Phone in Phones:GetChildren() do
										local s, e = pcall(function()
											if Phone:FindFirstChild("PhoneNumber") then
												if Phone.PhoneNumber.Value == Num then
													DialingPhone = Phone
												end
												task.wait()
											end
										end)
									end
									if DialingPhone and DialingPhone.Values.Calling.Value == false and DialingPhone.Values.DnD.Value == false then
										Tel.Values.Calling.Value = true
										DialingPhone.Display.GUI.Home.Dial.Visible = false
										DialingPhone.Phone.Ringtone.Playing = true
										Tel.Phone.Dial.Playing = true
										DialingPhone.Values.ReceivingCall.Value = TelNum
										Tel.Display.GUI.Home.Dial.Visible = false
										Tel.Display.GUI.Home.Calling.Visible = true
										Tel.Display.GUI.Home.Calling.Number.Text = tostring(DialingPhone.PhoneNumber.Value)
										DialingPhone.Display.GUI.Home.Incoming.Visible = true
										DialingPhone.Display.GUI.Home.Incoming.Number.Text = tostring(TelNum)
										DialingPhone.Display.GUI.Home.Incoming.Image.Blink.Value = true
										Tel.Display.GUI.Home.Calling.Image.Blink.Value = true
										DialingPhone.Values.Calling.Value = true
										CS:Chat(DialingPhone.ChatPart, Plr.Name.." is calling you.")
										task.wait(.1)
										CS:Chat(DialingPhone.ChatPart, "Press the handset 1x to accept, 2x to decline.")
									else
										if DialingPhone then
											if DialingPhone.Values.Calling.Value == true then
												Tel.Values.Calling.Value = true
												Tel.Display.GUI.Home.Dial.Visible = false
												Tel.Display.GUI.Home.Dial.Number.Text = ""
												Tel.Values.Dialing.Value = ""
												Tel.Phone.Unavailable:Play()
												Tel.Phone.Unavailable.Ended:Wait()
												task.wait(.5)
												Tel.Phone.End:Play()
												Tel.Phone.End.Ended:Wait()
												Tel.Values.Calling.Value = false
											elseif DialingPhone.Values.DnD.Value == true then
												Tel.Values.Calling.Value = true
												Tel.Display.GUI.Home.Dial.Visible = false
												Tel.Display.GUI.Home.Dial.Number.Text = ""
												Tel.Values.Dialing.Value = ""
												Tel.Phone.Unavailable:Play()
												Tel.Phone.Unavailable.Ended:Wait()
												task.wait(.5)
												Tel.Phone.End:Play()
												Tel.Phone.End.Ended:Wait()
												Tel.Values.Calling.Value = false
											else
												Tel.Values.Calling.Value = true
												Tel.Display.GUI.Home.Dial.Visible = false
												Tel.Display.GUI.Home.Dial.Number.Text = ""
												Tel.Values.Dialing.Value = ""
												Tel.Phone.NotInService:Play()
												Tel.Phone.NotInService.Ended:Wait()
												task.wait(.5)
												Tel.Phone.End:Play()
												Tel.Phone.End.Ended:Wait()
												Tel.Values.Calling.Value = false
											end
										else
											Tel.Values.Calling.Value = true
											Tel.Display.GUI.Home.Dial.Visible = false
											Tel.Display.GUI.Home.Dial.Number.Text = ""
											Tel.Values.Dialing.Value = ""
											Tel.Phone.NotInService:Play()
											Tel.Phone.NotInService.Ended:Wait()
											task.wait(.5)
											Tel.Phone.End:Play()
											Tel.Phone.End.Ended:Wait()
											Tel.Values.Calling.Value = false
										end
									end
								end)
							end
						end)
					end
				end
			end
		end)
	end
end

local function handlePlayer(player)
	player.Chatted:Connect(function(Msg)
		local filteredMsg
		local success, result = pcall(function()
			return TextService:FilterStringAsync(Msg, player.UserId)
		end)
		if success then
			local ok, filtered = pcall(function()
				return result:GetNonChatStringForBroadcastAsync()
			end)
			if ok then
				filteredMsg = filtered
			else
				filteredMsg = "[Message failed to filter]"
			end
		else
			return
		end

		local playerPhone = nil
		for _, phone in Phones:GetChildren() do
			if phone:FindFirstChild("PhoneNumber") and phone.Values.PlayerName.Value == player.Name then
				playerPhone = phone
				break
			end
		end

		if playerPhone then
			local targetNumber = tostring(playerPhone.Values.CallingWith.Value)
			if targetNumber ~= "" then
				for _, phone in Phones:GetChildren() do
					if phone:FindFirstChild("PhoneNumber") and phone.PhoneNumber.Value == targetNumber then
						if phone.Values.Calling.Value or phone.Values.ReceivingCall.Value == player.Name then
							CS:Chat(phone.ChatPart, player.Name..": "..filteredMsg)
						end
					end
				end
			end
		end

		for _, phone in Phones:GetChildren() do
			if phone:FindFirstChild("PhoneNumber") and phone.Values.CallingWith.Value == player.Name then
				CS:Chat(phone.ChatPart, player.Name..": "..filteredMsg)
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	handlePlayer(player)
end)

for _, player in Players:GetPlayers() do
	handlePlayer(player)
end

