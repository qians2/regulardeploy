name = "Round Deploy（开发版）"
description = "辅助造圆, 使用时需要先关闭几何放置mod"
author = "浅の诗"
version = "3.2.2" --大版本.小版本.小调整
api_version_dst = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true
all_clients_require_mod = false
client_only_mod = true
configuration_options = {
    {
        name = "language",
        label = "language",
        hover = "设置语言",
        options = {
            { description = "中文", data = "ch_s" },
            { description = "English", data = "en" },
        },
        default = "ch_s",
    }
}