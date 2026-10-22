# The IPC client, the parser and the helpers are built as a library that
# remontoire and the tests in ../tests link with.
common_sources = [
  'grelier.vala',
  'config_parser.vala',
  'helper.vala'
]

remontoire_sources = [
  'main.vala',
  'slider_window.vala',
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

common_lib = static_library('remontoire-common', common_sources,
  vala_args: ['--target-glib=auto'],  dependencies: [grelier_deps, remontoire_deps],
)

common_dep = declare_dependency(link_with: common_lib,
  include_directories: include_directories('.'),
  dependencies: [grelier_deps, remontoire_deps],
)

remontoire_sources += import( 'gnome' ).compile_resources(
    'project-resources',
    '../data/style.xml',
    source_dir: '../data',
)

gnome = import('gnome')

remontoire_exe = executable('remontoire', remontoire_sources,
  vala_args: ['--target-glib=auto'],  dependencies: common_dep,
  install: true,
)
