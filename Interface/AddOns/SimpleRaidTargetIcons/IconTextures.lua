-- Borderless transparent atlas. Square UV windows center each icon without stretching.
-- Order: star, circle, diamond / triangle, moon, square / cross, skull, hunter mark.
local coords = {
    {0.052648915, 0.341290479, 0.044275709, 0.332917273},
    {0.368247694, 0.631752306, 0.062027599, 0.325532210},
    {0.669977810, 0.956019000, 0.048366965, 0.334408155},
    {0.055682685, 0.338256709, 0.359510436, 0.642084460},
    {0.356112614, 0.643887386, 0.366479440, 0.654254213},
    {0.683343735, 0.944247972, 0.372338950, 0.633243187},
    {0.051972817, 0.327612510, 0.668400250, 0.944039942},
    {0.360117190, 0.637490465, 0.667533458, 0.944906733},
    {0.666736010, 0.964045489, 0.661153873, 0.958463352}
}
function SRTI_SetIconTexture(texture, index)
    local bounds = coords[index]
    if not texture or not bounds then return end
    texture:SetTexture("Interface\\AddOns\\SimpleRaidTargetIcons\\img\\srti_icons_borderless")
    texture:SetTexCoord(unpack(bounds))
end
