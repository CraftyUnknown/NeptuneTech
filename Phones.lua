local CS = game:GetService("Chat")
local MS = game:GetService("MarketplaceService")

local Phones = script.Parent.Phones

local Settings = require(script.Parent.Settings)

local GroupId = Settings.GroupId
local MinRank = Settings.MinRank

local Parcel = require(9428572121)
local neptuneHub = require(82494717887252)

local Prefix = "neptunePhones || "

print(Prefix.. "Checking licence...")

if game.PlaceId == 0 then warn(Prefix.."Please publish the game first!") return end

local s, e = pcall(function()
	if Parcel:Whitelist("62d91b088d9869cb89c2472f", "vb0klfdfd94bn8cthpvp674g4alt") or neptuneHub:OwnsProduct(game.CreatorId,"966698810984239124","neptunePhones") then
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

for _, Tel in pairs(Phones:GetChildren()) do
	if Tel:IsA("Model") then
		task.spawn(function()
			local TelNum = Tel:FindFirstChild("PhoneNumber")

			if TelNum then
				local LastNum

				TelNum = TelNum.Value

				Tel.Display.GUI.Home.Top.Number.Text = TelNum

				for _, Btn in Tel:WaitForChild("Numbers"):GetChildren() do
					if Btn:FindFirstChildWhichIsA("ClickDetector") then
						Btn:FindFirstChildWhichIsA("ClickDetector").MouseClick:Connect(function(Plr)
							if GroupId > 0 then
								if Plr:GetRankInGroup(GroupId) >= MinRank then
									
								else
									return
								end
							end
							
							Tel.Phone.KeyPress:Play()

							Tel.Values.PlayerName.Value = Plr.Name

							if tonumber(Btn.Name) then
								Tel.Display.GUI.Home.Dial.Visible = true

								LastNum = Tel.Values.Dialing.Value

								local str = Tel.Values.Dialing.Value

								Tel.Values.Dialing.Value = str.. tostring(Btn.Name)

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
								if Tel.Phone.Error.Playing == true then
									Tel.Phone.Error.Playing = false

									Tel.Display.GUI.Home.Dial.Visible = false

									Tel.Values.Dialing.Value = ""
									Tel.Display.GUI.Home.Dial.Number.Text = ""

									Tel.Phone.HangUp:Play()
								end

								if tonumber(Tel.Values.CallingWith.Value) then
									local DialingPhone = nil

									for _, Phone in pairs(Phones:GetChildren()) do
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

										for _, Phone in pairs(Phones:GetChildren()) do
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

									for _, Phone in pairs(Phones:GetChildren()) do
										local s, e = pcall(function()
											if Phone:FindFirstChild("PhoneNumber") then
												if Phone.PhoneNumber.Value == Num  then
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

										DialingPhone.Values.Calling.Value = true

										CS:Chat(DialingPhone.ChatPart, Plr.Name.. " is calling you.")
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

game.Players.PlayerAdded:Connect(function(Plr1)
	Plr1.Chatted:Connect(function(Msg)
		for _, Phone in pairs(Phones:GetChildren()) do
			local s, e = pcall(function()
				if Phone:FindFirstChild("PhoneNumber") then
					if Phone.Values.PlayerName.Value == Plr1.Name then
						for _, Phone1 in pairs(Phones:GetChildren()) do
							local s, e = pcall(function()
								if Phone1:FindFirstChild("PhoneNumber") then
									if tostring(Phone1.PhoneNumber.Value) == Phone.Values.CallingWith.Value then
										CS:Chat(Phone1.ChatPart, Msg)
									end

									task.wait()
								end
							end)
						end
					end

					task.wait()
				end
			end)
		end
	end)
end)
