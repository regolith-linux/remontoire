# Each test below is registered only when its file is present. The fixes
# that add these tests share this file and the library in ../src, so they
# can be merged in any order.
fs = import('fs')

if fs.exists('test_ipc_reply.vala')
  test_ipc_reply = executable('test-ipc-reply', 'test_ipc_reply.vala',
    vala_args: ['--target-glib=auto'],  dependencies: common_dep,
    c_args: ['-Wno-unused-but-set-variable', '-Wno-unused-variable'],
  )
  test('ipc-reply', test_ipc_reply)
endif

if fs.exists('test_ipc_includes.vala')
  test_ipc_includes = executable('test-ipc-includes', 'test_ipc_includes.vala',
    vala_args: ['--target-glib=auto'],  dependencies: common_dep,
    c_args: ['-Wno-unused-but-set-variable', '-Wno-unused-variable'],
  )
  test('ipc-included-configs', test_ipc_includes)
endif

if fs.exists('test_parser_malformed.vala')
  test_parser_malformed = executable('test-parser-malformed', 'test_parser_malformed.vala',
    vala_args: ['--target-glib=auto'],  dependencies: common_dep,
    c_args: ['-Wno-unused-but-set-variable', '-Wno-unused-variable'],
  )
  test('parser-invalid-comments', test_parser_malformed)
endif

if fs.exists('startup_errors.sh')
  test('startup-errors', find_program('startup_errors.sh'),
    args: [remontoire_exe, join_paths(meson.current_source_dir(), '..', 'data')],
  )
endif

if fs.exists('option_without_value.sh')
  test('option-without-value', find_program('option_without_value.sh'),
    args: [remontoire_exe],
  )
endif

if fs.exists('test_expanded_categories.vala')
  test_expanded_categories = executable('test-expanded-categories', 'test_expanded_categories.vala',
    vala_args: ['--target-glib=auto'],  dependencies: common_dep,
    c_args: ['-Wno-unused-but-set-variable', '-Wno-unused-variable'],
  )
  test('expanded-categories', test_expanded_categories)
endif

if fs.exists('test_parser_utf8.vala')
  test_parser_utf8 = executable('test-parser-utf8', 'test_parser_utf8.vala',
    vala_args: ['--target-glib=auto'],  dependencies: common_dep,
    c_args: ['-Wno-unused-but-set-variable', '-Wno-unused-variable'],
  )
  test('parser-invalid-utf8', test_parser_utf8)
endif
