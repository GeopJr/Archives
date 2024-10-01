project('dev.geopjr.Archives', ['c', 'vala'],
          version: '0.2.0',
    meson_version: '>= 0.62.0',
  default_options: [ 'warning_level=2', 'werror=false', ],
)

# https://gitlab.gnome.org/GNOME/vala/-/issues/1413#note_1707480
if meson.get_compiler ('c').get_id () == 'clang'
  add_project_arguments('-Wno-incompatible-function-pointer-types', language: 'c')
endif

devel = get_option('devel')

if get_option('offline_update_bundle')
  run_command('make', 'offline=1', 'update_bundle', check: true)
endif

# Setup configuration file
config = configuration_data()
config.set('EXEC_NAME', meson.project_name())
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config.set('DOMAIN', meson.project_name ())
config.set('G_LOG_DOMAIN', 'Archives')
config.set('RESOURCES', '/' + '/'.join(meson.project_name().split('.')) + '/')
config.set('VERSION', meson.project_version())
config.set('PREFIX', get_option('prefix'))
config.set('NAME', 'Archives')
config.set('WEBSITE', 'https://gitlab.gnome.org/GeopJr/Archives')
config.set('ISSUES_WEBSITE', 'https://gitlab.gnome.org/GeopJr/Archives/issues')
config.set('SUPPORT_WEBSITE', '')
config.set('DONATE_WEBSITE', 'https://geopjr.dev/donate')
config.set('TRANSLATE_WEBSITE', '')
config.set('PROFILE', devel ? 'development' : 'production')

if devel
  git = find_program('git')
  if git.found()
    branch = run_command('git', 'branch', '--show-current', check: true).stdout().strip()
    revision = run_command('git', 'rev-parse', '--short', 'HEAD', check: true).stdout().strip()
    version = '@0@-@1@'.format(branch, revision)
    config.set('VERSION', version)
  endif
endif

add_project_arguments (
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-DG_LOG_DOMAIN="Archives"',
  language: 'c'
)

i18n = import('i18n')
gnome = import('gnome')

asresources = gnome.compile_resources(
    'as-resources',
    'data/gresource.xml',
    source_dir: 'data',
    c_name: 'as',
)

gtk_dep = dependency('gtk4', version: '>=4.13.4', required: true)
libadwaita_dep = dependency('libadwaita-1', version: '>=1.5', required: true)

sources = files()
subdir('src')

final_deps = [
  dependency('glib-2.0', version: '>=2.76.0'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0', version: '>=1.4.4'),
  gtk_dep,
  libadwaita_dep,
  dependency('webkitgtk-6.0'),
]

executable(
    meson.project_name(),
    asresources,
    sources,
    dependencies: final_deps,
    install: true,
)

subdir('data')
subdir('po')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
