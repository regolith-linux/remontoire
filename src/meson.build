remontoire_sources = [
  'main.vala',
  'window.vala',
  'helper.vala',
  'config_parser.vala'
]

remontoire_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('gdk-3.0', version: '>= 3.22'),
  dependency('gee-0.8'),
  dependency('grelier', version: '>= 0.1.0')
]

gnome = import('gnome')

executable('remontoire', remontoire_sources,
  vala_args: ['--target-glib=2.50', '--vapidir=/home/kgilmer/dev/repos/remontoire/vapi'],  dependencies: remontoire_deps,
  install: true,
)