import os

application = defines['app']
files = [application]
symlinks = {'Applications': '/Applications'}
background = defines['background']
format = 'UDZO'
filesystem = 'HFS+'
window_rect = ((200, 160), (640, 400))
icon_locations = {os.path.basename(application): (160, 200), 'Applications': (480, 200)}
icon_size = 104
text_size = 14
default_view = 'icon-view'
show_toolbar = False
show_sidebar = False
show_status_bar = False
show_pathbar = False
show_tab_view = False
include_icon_view_settings = True
include_list_view_settings = False
arrange_by = None
