# 标记图标去黑边记录

使用内置 **imagegen** 图像编辑工具，将原标记栏中的九种标记制作成一张透明图集，并对猎人印记做了第二次修正，保留中间的细十字形。

已接入标记栏、侧边目标标记和快捷标记圆环。保存位置：

- PNG 源图：`E:/1.18/Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.png`
- 游戏使用的透明 TGA：`E:/1.18/Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.tga`
- 图标坐标与加载：`E:/1.18/Interface/AddOns/SimpleRaidTargetIcons/IconTextures.lua`

原九张图标文件没有覆盖。游戏素材仅作兼容格式导出：256×256、未压缩 32 位 TGA，保留透明通道。通过图标坐标使各图标居中并保持比例。

最终编辑提示词如下（输入 1 为第一版图集，输入 2 为原猎人印记）：

> Make a targeted correction to edit-target image 1, a 3 by 3 WoW icon sprite atlas. Preserve the nine icons, exact cell arrangement, colors, orientations and polished internal bevel shading. Correct ONLY the bottom-right cyan hunter crosshair to match reference image 2: a relatively THIN open cyan circular ring, small interrupting rectangular cyan ticks projecting at north/east/south/west, with a SIMPLE THIN CYAN PLUS SIGN in the transparent center. There must be NO spherical dot, NO round bubble, NO filled disk and NO diamond at the center. Its center is mostly transparent with only thin plus-sign lines. Keep its silhouette cyan with colored antialiased edges. Across all icons also remove any outer glow, speckled halo, scratchy pixels, excessive colored fringe, black contour, black external stroke or drop shadow. Make clean smooth colored edges directly meeting genuine transparent alpha. Do NOT eliminate skull's dark eye and nose cavities or icons' internal shading. Do NOT add outlines or backgrounds. Keep all nine centered in the same 3 by 3 layout with transparent margins. Final single square transparent atlas, ideally 1024x1024 pixels.

已经检查透明通道、素材尺寸、图标坐标和插件模拟测试。实际游戏内的缩放与显示效果仍需重载后确认。
