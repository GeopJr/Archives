<div align="center">
  <img alt="An archive box in the style of GNOME icons" width="160" src="./data/icons/color.svg">
  <h1>Archives</h1>
  <h3>Create and view web archives</h3>
  <img alt="" src="./data/screenshots/screenshot-1.png">
  <a href='https://flathub.org/apps/details/dev.geopjr.Archives'>
    <img width='192' alt='Get it on Flathub' src='https://flathub.org/api/badge?svg&locale=en'/>
  </a>
</div>

# Description

Archives allows you to archive any website, including its assets, into a self-contained hybrid HTML/ZIP. These HTML files can be viewed in any browser (or in-app), be shared or be extracted like a regular ZIP file. Archives can additionally view WARC, WACZ, HAR and SWF files.

The goal is to become a toolbox full of offline archival tools without depending on a huge number of external dependencies. Countless of these tools have been targeting the web as a platform, especially with the introduction of wasm and web extensions, making bundling them and running them in a stable and secure environment easy.

The app is still in an early stage, there are more tools and settings planned but if you have something in mind, please let me know! Personally, I've been mirroring websites to TOR for ages and this tool started as a personal way to make it easier.

# Building

## GNOME Builder

1. Install and open [GNOME Builder](https://flathub.org/apps/details/org.gnome.Builder)
1. Select "Clone Repository…"
1. Clone `https://gitlab.gnome.org/GeopJr/Archives.git`
1. Run the project with the ▶ button at the top, or by pressing <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Space</kbd>

## Manually

1. Run `$ make update_bundle` to fetch the vendored files
1. Run `$ make` to build Archives
1. Run `$ make install` to install Archives

## Manually (Offline)

1. You need to fetch the vendored files manually, take a look at the [flatpak config](./build-aux/dev.geopjr.Archives.Devel.json) for the expected locations and links to the files
1. Run `$ make offline=1 update_bundle` to process the vendored files
1. Run `$ make` to build Archives
1. Run `$ make install` to install Archives

> NOTE: Running or packaging Archives for use outside of sandboxed environments is discouraged.

# Sponsors

<div align="center">

[![GeopJr Sponsors](https://cdn.jsdelivr.net/gh/GeopJr/GeopJr@main/sponsors.svg)](https://github.com/sponsors/GeopJr)

</div>

# Acknowledgements

- [SingleFile](https://github.com/gildas-lormeau/SingleFile) for website archiving
- [ReplayWeb.page](https://github.com/webrecorder/replayweb.page) for viewing WARC, WACZ and HAR files
- [Ruffle](https://ruffle.rs/) for viewing SWF files

Archives wouldn't exist without these powerful tools, check them out!

# Contributing

1. Read the [Code of Conduct](./CODE_OF_CONDUCT.md)
2. Fork it ( https://gitlab.gnome.org/GeopJr/Archives/-/forks/new )
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request
