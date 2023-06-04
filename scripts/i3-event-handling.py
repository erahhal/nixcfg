#!/usr/bin/env python3

from i3ipc import Connection, WindowEvent


def fix_position_of_floating_windows(i3c: Connection, e: WindowEvent):
    c = e.container
    if c.floating in ['auto_on', 'user_on']:
        print(c.rect.x, c.rect.y)
        c.command('move position center')


i3c = Connection()
i3c.on('window::new', fix_position_of_floating_windows)
i3c.main()
