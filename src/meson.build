grelier_sources = [
  'grelier.vala'
]

remontoire_sources = [
  'main.vala',
  'slider_window.vala',
  'helper.vala',
  'config_parser.vala',
  'arg_parser.vala'
]

grelier_deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-unix-2.0', version: '>= 2.50'),
  dependency('json-glib-1.0')
]

remontoire_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('gdk-3.0', version: '>= 3.22'),
  dependency('gee-0.8')
]

remontoire_sources += import( 'gnome' ).compile_resources(
    'project-resources',
    '../data/style.xml',
    source_dir: '../data',
)

gnome = import('gnome')

executable('remontoire', [grelier_sources, remontoire_sources],
  vala_args: ['--target-glib=2.50'],  dependencies: [grelier_deps, remontoire_deps],
  install: true,
)